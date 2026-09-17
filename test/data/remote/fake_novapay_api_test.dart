import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/remote/fake_novapay_api.dart';

void main() {
  late Database db;
  var online = true;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    online = true;
    db = await AppDatabase.openServer(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    await FakeNovaPayApi.seedAccount(db, balance: Kobo.fromNaira(248350, 75));
  });

  tearDown(() => db.close());

  FakeNovaPayApi buildApi() => FakeNovaPayApi(
    db,
    isOnline: () => online,
    latency: Duration.zero,
  );

  Future<TransferOutcome> send(
    FakeNovaPayApi api, {
    required String key,
    Kobo amount = const Kobo(1500000),
  }) => api.sendMoney(
    idempotencyKey: key,
    accountNumber: '0123456789',
    bankName: 'GTBank',
    amount: amount,
  );

  test('accepts a transfer and debits the balance once', () async {
    final api = buildApi();

    final outcome = await send(api, key: 'key-1');

    expect(outcome, isA<TransferAccepted>());
    expect((outcome as TransferAccepted).reference, startsWith('NP-'));
    expect(await FakeNovaPayApi.balanceOf(db), Kobo.fromNaira(233350, 75));
    expect(await FakeNovaPayApi.processedCount(db), 1);
  });

  test('replaying the same key returns the first answer and does not debit again', () async {
    final api = buildApi();

    final first = await send(api, key: 'key-1') as TransferAccepted;
    final replay = await send(api, key: 'key-1') as TransferAccepted;
    final replayAgain = await send(api, key: 'key-1') as TransferAccepted;

    expect(replay.reference, first.reference);
    expect(replayAgain.reference, first.reference);
    // Debited once, not three times.
    expect(await FakeNovaPayApi.balanceOf(db), Kobo.fromNaira(233350, 75));
    expect(await FakeNovaPayApi.processedCount(db), 1);
  });

  test('two replays arriving together still process once', () async {
    final api = buildApi();

    final outcomes = await Future.wait([
      send(api, key: 'key-1'),
      send(api, key: 'key-1'),
    ]);

    final references = outcomes.cast<TransferAccepted>().map((o) => o.reference);
    expect(references.toSet(), hasLength(1), reason: 'same receipt for both');
    expect(await FakeNovaPayApi.balanceOf(db), Kobo.fromNaira(233350, 75));
    expect(await FakeNovaPayApi.processedCount(db), 1);
  });

  test('different keys are different transfers', () async {
    final api = buildApi();

    await send(api, key: 'key-1');
    await send(api, key: 'key-2');

    expect(await FakeNovaPayApi.balanceOf(db), Kobo.fromNaira(218350, 75));
    expect(await FakeNovaPayApi.processedCount(db), 2);
  });

  test('throws NetworkException while offline, and records nothing', () async {
    final api = buildApi();
    online = false;

    expect(() => send(api, key: 'key-1'), throwsA(isA<NetworkException>()));
    await Future<void>.delayed(Duration.zero);

    expect(await FakeNovaPayApi.processedCount(db), 0);
    expect(await FakeNovaPayApi.balanceOf(db), Kobo.fromNaira(248350, 75));
  });

  test('rejects over the daily limit, and the rejection sticks on replay', () async {
    final api = buildApi();

    final outcome = await send(api, key: 'key-1', amount: Kobo.fromNaira(60000));
    expect(outcome, isA<TransferRejected>());
    expect((outcome as TransferRejected).reason, contains("today's transfer limit"));

    // Balance untouched, and replaying gives the same refusal rather than
    // re-evaluating against a limit that may have moved on.
    expect(await FakeNovaPayApi.balanceOf(db), Kobo.fromNaira(248350, 75));
    final replay = await send(api, key: 'key-1', amount: Kobo.fromNaira(60000));
    expect(replay, isA<TransferRejected>());
    expect(await FakeNovaPayApi.processedCount(db), 1);
  });

  test('rejects more than the wallet holds', () async {
    final api = buildApi();

    final outcome = await send(api, key: 'key-1', amount: Kobo.fromNaira(900000));

    expect(outcome, isA<TransferRejected>());
    expect((outcome as TransferRejected).reason, contains('Not enough money'));
    expect(await FakeNovaPayApi.balanceOf(db), Kobo.fromNaira(248350, 75));
  });

  test('a contribution uses the same idempotency rules', () async {
    final api = buildApi();

    final first = await api.contributeToGoal(
      idempotencyKey: 'goal-key-1',
      goalId: 'rent-2027',
      amount: Kobo.fromNaira(5000),
    );
    final replay = await api.contributeToGoal(
      idempotencyKey: 'goal-key-1',
      goalId: 'rent-2027',
      amount: Kobo.fromNaira(5000),
    );

    expect((first as TransferAccepted).reference,
        (replay as TransferAccepted).reference);
    expect(await FakeNovaPayApi.balanceOf(db), Kobo.fromNaira(243350, 75));
    expect(await FakeNovaPayApi.processedCount(db), 1);
  });
}
