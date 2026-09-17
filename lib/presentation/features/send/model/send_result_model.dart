import 'package:novawallet/core/enums.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/outbox_store.dart';

class SendResultState {
  const SendResultState({
    required this.result,
    required this.createdAt,
    this.reason,
  });

  /// Reads the outcome off the queue row the transfer left behind.
  ///
  /// The row is the only honest source. `SyncEngine` is single-flight, so the
  /// report handed back by the pass we triggered may describe a pass that
  /// started *before* our row existed. Asking the row removes that guesswork.
  ///
  /// Kept as a pure function so the three-way decision can be tested without a
  /// database or a widget tree — a widget test's zone never completes sqflite
  /// I/O, so this path is unreachable from one.
  factory SendResultState.fromOutboxRow(OutboxItem? row, {DateTime? at}) {
    final now = at ?? DateTime.now();

    // No row: the enqueue was swallowed as a duplicate key. The original
    // attempt is still owed to the server, so "queued" is the truthful answer.
    if (row == null) {
      return SendResultState(result: SendResult.queued, createdAt: now);
    }

    if (row.status == AppDatabase.statusSucceeded) {
      return SendResultState(result: SendResult.sent, createdAt: now);
    }

    // Refused by the server. Carry its reason through: the user is owed the
    // "why", and this outcome will never be retried.
    if (row.isFailed) {
      return SendResultState(
        result: SendResult.rejected,
        reason: row.lastError,
        createdAt: now,
      );
    }

    return SendResultState(result: SendResult.queued, createdAt: now);
  }

  final SendResult result;
  final DateTime createdAt;

  /// The server's own words for a rejection, shown verbatim rather than
  /// paraphrased — it is the only explanation the user gets.
  final String? reason;

  bool get isSent => result == SendResult.sent;
  bool get isQueued => result == SendResult.queued;
  bool get isRejected => result == SendResult.rejected;
}
