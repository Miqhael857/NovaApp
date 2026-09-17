import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/outbox_store.dart';
import 'package:novawallet/data/remote/fake_novapay_api.dart';
import 'package:novawallet/data/sync/sync_engine.dart';

void main() {
  late Directory dir;
  late Database clientDb;
  late Database serverDb;
  late OutboxStore outbox;
  late FakeNovaPayApi api;
  late SyncEngine sync;
  var online = true;

  const startingBalance = Kobo(24835075); // ₦248,350.75
  const transferAmount = Kobo(1500000); // ₦15,000.00

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    online = true;
    // Separate files, not `:memory:`: sqflite treats every `:memory:` handle as
    // the same database, so the client and server would share one schema.
    dir = Directory.systemTemp.createTempSync('novapay_sync_test');
    clientDb = await AppDatabase.openClient(
      factory: databaseFactoryFfi,
      path: '${dir.path}/client.db',
    );
    serverDb = await AppDatabase.openServer(
      factory: databaseFactoryFfi,
      path: '${dir.path}/server.db',
    );
    await FakeNovaPayApi.seedAccount(serverDb, balance: startingBalance);

    outbox = OutboxStore(clientDb);
    api = FakeNovaPayApi(
      serverDb,
      isOnline: () => online,
      latency: Duration.zero,
    );
    sync = SyncEngine(outbox: outbox, api: api);
  });

  tearDown(() async {
    await clientDb.close();
    await serverDb.close();
    dir.deleteSync(recursive: true);
  });

  Future<OutboxItem> queueTransfer(
    String key, {
    Kobo amount = transferAmount,
    DateTime? at,
  }) => outbox.enqueue(
    idempotencyKey: key,
    type: AppDatabase.typeTransfer,
    payload: {
      'accountNumber': '0123456789',
      'bankName': 'GTBank',
      'amountKobo': amount.value,
      'narration': 'Rent contribution',
    },
    createdAt: at,
  );

  test('sends a queued transfer once and clears it', () async {
    await queueTransfer('key-1');

    final report = await sync.run();

    expect(report.succeeded, 1);
    expect(report.stoppedForNetwork, isFalse);
    expect(await outbox.itemsToSend(), isEmpty);
    expect(await FakeNovaPayApi.processedCount(serverDb), 1);
    expect(
      await FakeNovaPayApi.balanceOf(serverDb),
      startingBalance - transferAmount,
    );
  });

  test('offline: the item stays queued and nothing reaches the server', () async {
    await queueTransfer('key-1');
    online = false;

    final report = await sync.run();

    expect(report.handled, 0);
    expect(report.stoppedForNetwork, isTrue);
    expect(await FakeNovaPayApi.processedCount(serverDb), 0);
    expect(await FakeNovaPayApi.balanceOf(serverDb), startingBalance);

    final queued = await outbox.itemsToSend();
    expect(queued.single.status, AppDatabase.statusPending);
    expect(queued.single.lastError, isNotNull);
  });

  test('reconnecting sends the same item, with the same key, exactly once', () async {
    await queueTransfer('key-1');

    online = false;
    await sync.run();
    online = true;
    final report = await sync.run();

    expect(report.succeeded, 1);
    expect(await outbox.itemsToSend(), isEmpty);
    expect(await FakeNovaPayApi.processedCount(serverDb), 1);
    expect(
      await FakeNovaPayApi.balanceOf(serverDb),
      startingBalance - transferAmount,
    );
  });

  test(
    'an item the server already processed is not charged twice after a restart',
    () async {
      // The app sent this, the server took the money, then the app died before
      // the answer arrived — so the row is still in flight with the same key.
      final item = await queueTransfer('key-1');
      await api.sendMoney(
        idempotencyKey: 'key-1',
        accountNumber: '0123456789',
        bankName: 'GTBank',
        amount: transferAmount,
      );
      await outbox.markInFlight(item.id);
      expect(await FakeNovaPayApi.processedCount(serverDb), 1);

      final report = await sync.run();

      expect(report.succeeded, 1, reason: 'the client learns it went through');
      expect(await outbox.itemsToSend(), isEmpty);
      expect(await FakeNovaPayApi.processedCount(serverDb), 1);
      expect(
        await FakeNovaPayApi.balanceOf(serverDb),
        startingBalance - transferAmount,
        reason: 'debited once, not twice',
      );
    },
  );

  test('two passes started together join the same run', () async {
    await queueTransfer('key-1');

    final first = sync.run();
    final second = sync.run();
    final reports = await Future.wait([first, second]);

    expect(identical(first, second), isTrue, reason: 'single-flight');
    expect(reports.first.succeeded, 1);
    expect(await FakeNovaPayApi.processedCount(serverDb), 1);
    expect(
      await FakeNovaPayApi.balanceOf(serverDb),
      startingBalance - transferAmount,
    );
  });

  test('a rejection is final and is never retried', () async {
    await queueTransfer('key-1', amount: Kobo.fromNaira(60000)); // over the limit

    final first = await sync.run();
    final second = await sync.run();

    expect(first.rejected, 1);
    expect(second.handled, 0, reason: 'nothing left to send');
    expect(await FakeNovaPayApi.processedCount(serverDb), 1);
    expect(await FakeNovaPayApi.balanceOf(serverDb), startingBalance);

    final failed = await outbox.all();
    expect(failed.single.isFailed, isTrue);
    expect(failed.single.lastError, contains("today's transfer limit"));
  });

  test('sends oldest first, and stops at the first network failure', () async {
    final now = DateTime(2026, 9, 16, 22);
    await queueTransfer('first', at: now);
    await queueTransfer('second', at: now.add(const Duration(minutes: 1)));

    // The API checks the connection twice per request (before and after the
    // round trip), so the first request uses up the first two checks and the
    // second request finds the connection gone.
    var checks = 0;
    api = FakeNovaPayApi(
      serverDb,
      isOnline: () => checks++ < 2,
      latency: Duration.zero,
    );
    sync = SyncEngine(outbox: outbox, api: api);

    final report = await sync.run();

    expect(report.succeeded, 1);
    expect(report.stoppedForNetwork, isTrue);
    expect(await FakeNovaPayApi.processedCount(serverDb), 1);

    final left = await outbox.itemsToSend();
    expect(left.single.idempotencyKey, 'second');
  });

  test('contributions go through the same queue', () async {
    await outbox.enqueue(
      idempotencyKey: 'goal-key-1',
      type: AppDatabase.typeContribution,
      payload: {'goalId': 'rent-2027', 'amountKobo': Kobo.fromNaira(5000).value},
    );

    final report = await sync.run();

    expect(report.succeeded, 1);
    expect(await FakeNovaPayApi.processedCount(serverDb), 1);
    expect(
      await FakeNovaPayApi.balanceOf(serverDb),
      startingBalance - Kobo.fromNaira(5000),
    );
  });
}
