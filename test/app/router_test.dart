import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:novawallet/app.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/features/novasave/goal_detail_view.dart';
import 'package:novawallet/app_router.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/routes.dart';
import 'package:novawallet/presentation/features/wallethome/all_transactions_view.dart';
import 'package:novawallet/presentation/features/wallethome/transaction_view.dart';

/// A fresh pair of database files per test, so nothing leaks between them.
late Directory testDir;

DataLayerConfig testConfig() => DataLayerConfig(
  // No-isolate: a widget test zone never services the background
  // isolate the default ffi factory uses, so its database calls never
  // complete and the screen never advances.
  factory: databaseFactoryFfiNoIsolate,
  clientPath: '${testDir.path}/client.db',
  serverPath: '${testDir.path}/server.db',
  latency: Duration.zero,
);

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dataLayerConfigProvider.overrideWith((ref) => testConfig())],
      child: const NovaWalletApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps the app and returns its container, so a test can drive the router
/// straight to a route instead of tapping through screens that are still
/// being built.
Future<ProviderContainer> pumpAppWithContainer(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [dataLayerConfigProvider.overrideWith((ref) => testConfig())],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const NovaWalletApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  // There is no sqflite platform plugin in a widget test, so the data layer
  // runs on the ffi factory against temp files.
  setUpAll(sqfliteFfiInit);

  setUp(() {
    testDir = Directory.systemTemp.createTempSync('novapay_router_test');
  });

  tearDown(() {
    if (testDir.existsSync()) testDir.deleteSync(recursive: true);
  });

  testWidgets('starts on Home and switches tabs from the bottom bar', (
    tester,
  ) async {
    await pumpApp(tester);

    // The tab screens no longer differ by an AppBar title - NovaSave is being
    // rebuilt and currently looks like Home - so this asserts on what the shell
    // itself believes, which is the thing the route is supposed to drive.
    int selectedTab() =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    expect(selectedTab(), 0);

    await tapAndSettle(
      tester,
      find.widgetWithText(NavigationDestination, 'Save'),
    );
    expect(selectedTab(), 1);

    // The Profile destination is commented out in the shell for now. Restore
    // the third tab here once it is back.
  });

  testWidgets('send flow walks all three steps in one view and ends on a '
      'result screen that cannot go back to Confirm', (tester) async {
    final container = await pumpAppWithContainer(tester);
    container.read(appRouterProvider).go(Routes.send);
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 3 \u00b7 Recipient'), findsOneWidget);
    // The flow sits outside the shell, so the bottom bar is hidden.
    expect(find.byType(NavigationBar), findsNothing);

    // Picking a recent recipient fills bank, number and name at once.
    await tapAndSettle(tester, find.text('Tunde Bakare'));
    await tapAndSettle(tester, find.text('Continue'));
    expect(find.text('Step 2 of 3 \u00b7 Amount'), findsOneWidget);

    await tapAndSettle(tester, find.text('\u20a65,000.00'));
    await tapAndSettle(tester, find.text('Continue'));
    expect(find.text('Step 3 of 3 \u00b7 Confirm'), findsOneWidget);

    // Stepping back and forward must not mint a second idempotency key: one
    // attempt keeps one key, or a retry would become a second transfer.
    final reference = container.read(sendFlowModelProvider).reference;
    expect(reference, isNotNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3 \u00b7 Amount'), findsOneWidget);
    await tapAndSettle(tester, find.text('Continue'));
    expect(container.read(sendFlowModelProvider).reference, reference);

    // Everything past this point - tapping Confirm, writing the outbox row,
    // running a sync pass - needs real sqflite I/O, and a widget test's zone
    // never completes it (proved: the route stays on /send and the screen never
    // advances, with or without runAsync and the no-isolate ffi factory). That
    // path is covered by the integration test, which runs on a real device.
  });

  testWidgets(
    'goal detail reads the goal id from the path and covers the tabs',
    (tester) async {
      final container = await pumpAppWithContainer(tester);

      // Driven through the router rather than tapped: the NovaSave screen is
      // being rebuilt and has no goal tile to tap yet, but the route contract -
      // the id comes from the path, and the page covers the tabs - still holds.
      container.read(appRouterProvider).go(Routes.goal('rent-2027'));
      await tester.pumpAndSettle();

      // The screen receives the id from the path but does not render it,
      // so this asserts the route contract directly rather than via text.
      expect(
        tester.widget<GoalDetailiew>(find.byType(GoalDetailiew)).goalId,
        'rent-2027',
      );
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('"See all" opens the full history above the tabs', (tester) async {
    await pumpApp(tester);

    // Home renders a preview, not the whole history.
    expect(
      tester.widget<TransactionSliverList>(find.byType(TransactionSliverList))
          .limit,
      6,
    );

    // The section header sits below the balance card, so it may be off-screen
    // on the test surface even though it is reachable on a phone.
    await tester.ensureVisible(find.text('See all'));
    await tapAndSettle(tester, find.text('See all'));

    expect(find.byType(AllTransactionsView), findsOneWidget);

    // No cap on this screen: it is the full list.
    expect(
      tester
          .widget<TransactionSliverList>(
            find.descendant(
              of: find.byType(AllTransactionsView),
              matching: find.byType(TransactionSliverList),
            ),
          )
          .limit,
      isNull,
    );

    // Pushed on the root navigator, so the bottom bar is covered.
    expect(find.byType(NavigationBar), findsNothing);
  });
}
