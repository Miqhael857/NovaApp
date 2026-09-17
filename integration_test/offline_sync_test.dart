import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:novawallet/app.dart';
import 'package:novawallet/app_router.dart';
import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/data/remote/fake_novapay_api.dart';
import 'package:novawallet/routes.dart';

/// The scenario the brief singles out: offline queue, then sync — across a
/// restart.
///
/// This lives here rather than in `test/` because it needs real sqflite I/O.
/// A widget test's zone never completes a database call, so the Send flow test
/// stops at the Confirm tap; on a device the write actually lands, which is the
/// only place the whole path can be proved end to end.
///
/// Run with:
///   flutter test integration_test/offline_sync_test.dart -d `device-id`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;

  /// Both app launches point at the same two files. That is what makes the
  /// second launch a restart rather than a fresh install.
  DataLayerConfig configFor(Directory dir) => DataLayerConfig(
    clientPath: '${dir.path}/client.db',
    serverPath: '${dir.path}/server.db',
    latency: Duration.zero,
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('novapay_integration');
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// [offline] is applied before the first frame on purpose. The data layer
  /// runs a sync pass as soon as it is built, so setting the flag afterwards
  /// lets that pass drain the queue before the test can look at it — which is
  /// exactly how the first version of this test fooled itself.
  Future<ProviderContainer> launch(
    WidgetTester tester, {
    required bool offline,
  }) async {
    final container = ProviderContainer(
      overrides: [
        dataLayerConfigProvider.overrideWith((ref) => configFor(dir)),
      ],
    );
    container.read(offlineOverrideProvider.notifier).setOffline(offline);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NovaWalletApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets(
    'a transfer made offline survives a restart and is sent exactly once',
    (tester) async {
      // ---- First launch: offline ----
      var container = await launch(tester, offline: true);
      var services = await container.read(novaPayServicesProvider.future);
      final startingBalance = await FakeNovaPayApi.balanceOf(services.serverDb);

      // Walk the real Send flow rather than enqueuing directly: the point is
      // that the screen queues the transfer, not that the store can.
      container.read(appRouterProvider).go(Routes.send);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tunde Bakare'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('₦5,000.00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm and send ₦5,000.00'));
      await tester.pumpAndSettle();

      // Queued, not sent: the row is on disk and the server has seen nothing.
      var queued = await services.outbox.itemsToSend();
      expect(queued, hasLength(1), reason: 'the transfer is queued, not lost');
      final key = queued.single.idempotencyKey;
      expect(await FakeNovaPayApi.processedCount(services.serverDb), 0);
      expect(
        await FakeNovaPayApi.balanceOf(services.serverDb),
        startingBalance,
        reason: 'nothing may leave the balance while offline',
      );

      // ---- Kill the app ----
      // Tear the tree down before disposing the container, so no widget is
      // left reading a container that no longer exists.
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      // The databases close without being awaited, so give them a moment
      // before the next launch opens the same files.
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // ---- Second launch: still offline, queue must have survived ----
      container = await launch(tester, offline: true);
      services = await container.read(novaPayServicesProvider.future);

      queued = await services.outbox.itemsToSend();
      expect(
        queued.single.idempotencyKey,
        key,
        reason: 'the same attempt, with the same key, survived the restart',
      );

      // ---- Reconnect ----
      container.read(offlineOverrideProvider.notifier).setOffline(false);
      await tester.pumpAndSettle();
      await services.sync.run();
      await tester.pumpAndSettle();

      expect(await services.outbox.itemsToSend(), isEmpty);
      expect(await FakeNovaPayApi.processedCount(services.serverDb), 1);
      expect(
        await FakeNovaPayApi.balanceOf(services.serverDb),
        startingBalance - Kobo.fromNaira(5000),
        reason: 'debited exactly once',
      );

      // ---- And again, because replaying a drained queue must be free ----
      await services.sync.run();
      expect(await FakeNovaPayApi.processedCount(services.serverDb), 1);
      expect(
        await FakeNovaPayApi.balanceOf(services.serverDb),
        startingBalance - Kobo.fromNaira(5000),
        reason: 'a second pass must not send it twice',
      );

      final settled = await services.outbox.all();
      expect(
        settled.where((i) => i.idempotencyKey == key).single.status,
        AppDatabase.statusSucceeded,
      );
    },
  );
}
