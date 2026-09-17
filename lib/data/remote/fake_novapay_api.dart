import 'dart:math';

import 'package:sqflite/sqflite.dart';

import 'package:novawallet/core/money/kobo.dart';

/// Thrown when the request never reached NovaPay — no connection, or it dropped
/// mid-flight. The caller does not know whether the server saw it, so the action
/// stays queued and is retried with the same idempotency key.
class NetworkException implements Exception {
  const NetworkException([this.message = 'No connection']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// What the server decided about a request. Distinct from [NetworkException] on
/// purpose: an outcome is final and must never be retried, a network failure
/// must be.
sealed class TransferOutcome {
  const TransferOutcome();
}

final class TransferAccepted extends TransferOutcome {
  const TransferAccepted({required this.reference, required this.amount});

  final String reference;
  final Kobo amount;
}

final class TransferRejected extends TransferOutcome {
  const TransferRejected({required this.reason, required this.amount});

  /// Shown to the user, e.g. "You've reached today's transfer limit."
  final String reason;
  final Kobo amount;
}

/// Stands in for the NovaPay backend.
///
/// The important part is not that it moves money, but that it is an **idempotent
/// receiver**: every request carries a key, and a key it has already handled
/// returns the original answer instead of being processed again. That is what
/// makes replaying the outbox safe, and it is why the client only has to
/// guarantee "at least once".
class FakeNovaPayApi {
  FakeNovaPayApi(
    this._db, {
    required bool Function() isOnline,
    Duration latency = const Duration(milliseconds: 300),
    Kobo dailyLimit = const Kobo(5000000),
  }) : _isOnline = isOnline,
       _latency = latency,
       _dailyLimit = dailyLimit;

  final Database _db;
  final bool Function() _isOnline;
  final Duration _latency;

  /// Tier 1 accounts can send ₦50,000.00 a day. Assumed value, documented in
  /// the README.
  final Kobo _dailyLimit;

  final _random = Random();

  /// Sends money, or returns what this key was already told.
  Future<TransferOutcome> sendMoney({
    required String idempotencyKey,
    required String accountNumber,
    required String bankName,
    required Kobo amount,
    String? narration,
  }) async {
    return _process(
      idempotencyKey: idempotencyKey,
      amount: amount,
      countsTowardsDailyLimit: true,
    );
  }

  /// Moves money from the wallet into a savings goal. Same idempotency rules.
  Future<TransferOutcome> contributeToGoal({
    required String idempotencyKey,
    required String goalId,
    required Kobo amount,
  }) async {
    return _process(
      idempotencyKey: idempotencyKey,
      amount: amount,
      countsTowardsDailyLimit: false,
    );
  }

  Future<TransferOutcome> _process({
    required String idempotencyKey,
    required Kobo amount,
    required bool countsTowardsDailyLimit,
  }) async {
    if (!_isOnline()) throw const NetworkException();
    await Future<void>.delayed(_latency);
    if (!_isOnline()) throw const NetworkException('Connection dropped');

    final seen = await _db.query(
      'processed_requests',
      where: 'idempotency_key = ?',
      whereArgs: [idempotencyKey],
      limit: 1,
    );
    if (seen.isNotEmpty) return _outcomeFromRow(seen.first);

    return _db.transaction((txn) async {
      // Re-check inside the transaction: two replays can arrive together.
      final raced = await txn.query(
        'processed_requests',
        where: 'idempotency_key = ?',
        whereArgs: [idempotencyKey],
        limit: 1,
      );
      if (raced.isNotEmpty) return _outcomeFromRow(raced.first);

      final account = (await txn.query('account', limit: 1)).firstOrNull;
      final balance = Kobo((account?['balance_kobo'] as int?) ?? 0);
      final sentToday = Kobo((account?['sent_today_kobo'] as int?) ?? 0);

      String? reason;
      if (amount > balance) {
        reason = 'Not enough money in your wallet.';
      } else if (countsTowardsDailyLimit &&
          (sentToday + amount) > _dailyLimit) {
        reason =
            "You've reached today's transfer limit of ${_dailyLimit.format()}.";
      }

      final accepted = reason == null;
      final reference = accepted ? _reference() : null;

      await txn.insert('processed_requests', {
        'idempotency_key': idempotencyKey,
        'outcome': accepted ? 'accepted' : 'rejected',
        'reference': reference,
        'reason': reason,
        'amount_kobo': amount.value,
        'processed_at': DateTime.now().millisecondsSinceEpoch,
      });

      if (accepted) {
        await txn.update(
          'account',
          {
            'balance_kobo': (balance - amount).value,
            'sent_today_kobo': countsTowardsDailyLimit
                ? (sentToday + amount).value
                : sentToday.value,
          },
          where: 'id = 1',
        );
        return TransferAccepted(reference: reference!, amount: amount);
      }

      return TransferRejected(reason: reason, amount: amount);
    });
  }

  TransferOutcome _outcomeFromRow(Map<String, Object?> row) {
    final amount = Kobo(row['amount_kobo'] as int);
    if (row['outcome'] == 'accepted') {
      return TransferAccepted(
        reference: row['reference'] as String,
        amount: amount,
      );
    }
    return TransferRejected(reason: row['reason'] as String, amount: amount);
  }

  String _reference() {
    const alphabet = '0123456789ABCDEF';
    String block() => List.generate(
      4,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
    return 'NP-${block()}-${block()}';
  }

  /// Seeds the fake account. Only used at startup and in tests.
  static Future<void> seedAccount(
    Database db, {
    required Kobo balance,
    Kobo sentToday = Kobo.zero,
  }) async {
    await db.insert('account', {
      'id': 1,
      'balance_kobo': balance.value,
      'sent_today_kobo': sentToday.value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// The server's balance. Tests use it to prove money moved exactly once.
  static Future<Kobo> balanceOf(Database db) async {
    final row = (await db.query('account', limit: 1)).firstOrNull;
    return Kobo((row?['balance_kobo'] as int?) ?? 0);
  }

  /// How many requests the server has actually processed.
  static Future<int> processedCount(Database db) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM processed_requests',
    );
    return (rows.first['c'] as int?) ?? 0;
  }
}
