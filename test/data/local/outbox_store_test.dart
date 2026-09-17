import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/outbox_store.dart';

void main() {
  late Database db;
  late OutboxStore store;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await AppDatabase.openClient(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    store = OutboxStore(db);
  });

  tearDown(() => db.close());

  Future<OutboxItem> queueTransfer(
    String key, {
    DateTime? at,
    int amountKobo = 1500000,
  }) => store.enqueue(
    idempotencyKey: key,
    type: AppDatabase.typeTransfer,
    payload: {
      'accountNumber': '0123456789',
      'bankName': 'GTBank',
      'amountKobo': amountKobo,
    },
    createdAt: at,
  );

  test('a queued action starts pending, with its payload intact', () async {
    final item = await queueTransfer('key-1');

    final stored = await store.byId(item.id);
    expect(stored!.idempotencyKey, 'key-1');
    expect(stored.type, AppDatabase.typeTransfer);
    expect(stored.status, AppDatabase.statusPending);
    expect(stored.attempts, 0);
    expect(stored.payload['bankName'], 'GTBank');
    expect(stored.payload['amountKobo'], 1500000);
    expect(stored.needsSending, isTrue);
  });

  test('the same idempotency key cannot be queued twice', () async {
    await queueTransfer('key-1');

    expect(
      () => queueTransfer('key-1'),
      throwsA(isA<DatabaseException>()),
      reason: 'one key per attempt, enforced by the schema',
    );
  });

  test('items to send come back oldest first', () async {
    final now = DateTime(2026, 9, 16, 22);
    await queueTransfer('newest', at: now.add(const Duration(minutes: 2)));
    await queueTransfer('oldest', at: now);
    await queueTransfer('middle', at: now.add(const Duration(minutes: 1)));

    final queue = await store.itemsToSend();

    expect(
      queue.map((i) => i.idempotencyKey),
      ['oldest', 'middle', 'newest'],
    );
  });

  test('marking in flight counts the attempt', () async {
    final item = await queueTransfer('key-1');

    await store.markInFlight(item.id);

    final stored = await store.byId(item.id);
    expect(stored!.status, AppDatabase.statusInFlight);
    expect(stored.attempts, 1);
    expect(stored.isInFlight, isTrue);
  });

  test('an in-flight item is still owed to the server', () async {
    final item = await queueTransfer('key-1');
    await store.markInFlight(item.id);

    final queue = await store.itemsToSend();

    expect(queue.map((i) => i.idempotencyKey), ['key-1']);
  });

  test('succeeded items leave the queue', () async {
    final item = await queueTransfer('key-1');
    await store.markInFlight(item.id);

    await store.markSucceeded(item.id);

    expect(await store.itemsToSend(), isEmpty);
    expect(await store.countWithStatus(AppDatabase.statusSucceeded), 1);
  });

  test('failed items leave the queue and keep the reason', () async {
    final item = await queueTransfer('key-1');
    await store.markInFlight(item.id);

    await store.markFailed(item.id, "You've reached today's transfer limit.");

    expect(await store.itemsToSend(), isEmpty);
    final stored = await store.byId(item.id);
    expect(stored!.isFailed, isTrue);
    expect(stored.lastError, contains('transfer limit'));
  });

  test('a dropped connection puts the item back, with the error kept', () async {
    final item = await queueTransfer('key-1');
    await store.markInFlight(item.id);

    await store.revertToPending(item.id, error: 'No connection');

    final stored = await store.byId(item.id);
    expect(stored!.status, AppDatabase.statusPending);
    expect(stored.lastError, 'No connection');
    expect(stored.attempts, 1, reason: 'the attempt still counts');
    expect(await store.itemsToSend(), hasLength(1));
  });

  test('the queue survives the app being killed mid-send', () async {
    // A real file, not in-memory: this is the brief's "must survive an app
    // restart while offline" requirement.
    final dir = Directory.systemTemp.createTempSync('novapay_outbox_test');
    addTearDown(() => dir.deleteSync(recursive: true));
    final path = '${dir.path}/client.db';

    var database = await AppDatabase.openClient(
      factory: databaseFactoryFfi,
      path: path,
    );
    var outbox = OutboxStore(database);
    final queued = await outbox.enqueue(
      idempotencyKey: 'key-survives',
      type: AppDatabase.typeTransfer,
      payload: {'amountKobo': 1500000},
    );
    await outbox.markInFlight(queued.id);

    // The app dies here, after sending but before any answer arrived.
    await database.close();

    database = await AppDatabase.openClient(
      factory: databaseFactoryFfi,
      path: path,
    );
    outbox = OutboxStore(database);
    addTearDown(() => database.close());

    final queue = await outbox.itemsToSend();
    expect(queue, hasLength(1));
    expect(queue.single.idempotencyKey, 'key-survives');
    expect(
      queue.single.isInFlight,
      isTrue,
      reason: 'it is retried with the same key; the server dedupes it',
    );
  });
}
