import 'package:flutter_test/flutter_test.dart';

import 'package:novawallet/core/enums.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/outbox_store.dart';
import 'package:novawallet/presentation/features/send/model/send_result_model.dart';

/// What the result screen is allowed to tell the user.
///
/// This is the decision that used to be a boolean, and the boolean lied: a
/// transfer the server *refused* fell into "queued" and the screen promised it
/// would be sent automatically on reconnect. The sync engine marks a rejection
/// failed and never retries it, so that promise could never be kept.
void main() {
  OutboxItem rowWith(String status, {String? lastError}) => OutboxItem(
    id: 1,
    idempotencyKey: 'key-1',
    type: AppDatabase.typeTransfer,
    payload: const {
      'accountNumber': '0123456789',
      'bankName': 'GTBank',
      'amountKobo': 3000000,
    },
    status: status,
    attempts: 1,
    createdAt: DateTime(2026, 9, 17),
    lastError: lastError,
  );

  test('a succeeded row is sent', () {
    final state = SendResultState.fromOutboxRow(
      rowWith(AppDatabase.statusSucceeded),
    );

    expect(state.result, SendResult.sent);
    expect(state.isSent, isTrue);
    expect(state.reason, isNull);
  });

  test('a failed row is rejected, and keeps the server’s reason', () {
    final state = SendResultState.fromOutboxRow(
      rowWith(
        AppDatabase.statusFailed,
        lastError: "You've reached today's transfer limit of ₦50,000.00.",
      ),
    );

    expect(state.result, SendResult.rejected);
    expect(state.isRejected, isTrue);
    expect(
      state.reason,
      "You've reached today's transfer limit of ₦50,000.00.",
      reason: 'the user is owed the why, in the server\'s own words',
    );
    expect(
      state.isQueued,
      isFalse,
      reason: 'a rejection is never retried, so it must not read as pending',
    );
  });

  test('a rejection with no recorded reason is still a rejection', () {
    final state = SendResultState.fromOutboxRow(
      rowWith(AppDatabase.statusFailed),
    );

    expect(state.result, SendResult.rejected);
    expect(state.reason, isNull, reason: 'the screen falls back to its own copy');
  });

  test('a pending row is queued', () {
    final state = SendResultState.fromOutboxRow(
      rowWith(AppDatabase.statusPending),
    );

    expect(state.result, SendResult.queued);
    expect(state.isQueued, isTrue);
  });

  test('an in-flight row is queued, not sent', () {
    // The app died without hearing back. It is still owed to the server and
    // will be replayed with the same key, so it has not been sent yet.
    final state = SendResultState.fromOutboxRow(
      rowWith(AppDatabase.statusInFlight),
    );

    expect(state.result, SendResult.queued);
  });

  test('no row at all is queued', () {
    // The enqueue was refused for a duplicate key, so the original attempt is
    // still out there. Claiming "sent" here would be the dangerous guess.
    final state = SendResultState.fromOutboxRow(null);

    expect(state.result, SendResult.queued);
  });

  test('the timestamp can be injected, so the screen is testable', () {
    final state = SendResultState.fromOutboxRow(
      rowWith(AppDatabase.statusSucceeded),
      at: DateTime(2026, 9, 17, 13, 45),
    );

    expect(state.createdAt, DateTime(2026, 9, 17, 13, 45));
  });
}
