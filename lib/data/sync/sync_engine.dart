import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/outbox_store.dart';
import 'package:novawallet/data/remote/fake_novapay_api.dart';

/// What one sync pass did. Handy for tests, the debug screen and deciding
/// whether to show "your transfer went through".
class SyncReport {
  const SyncReport({
    this.succeeded = 0,
    this.rejected = 0,
    this.stoppedForNetwork = false,
  });

  final int succeeded;
  final int rejected;

  /// True when the pass stopped because the connection went away. The queue is
  /// untouched and waits for the next trigger.
  final bool stoppedForNetwork;

  int get handled => succeeded + rejected;

  SyncReport _add({int succeeded = 0, int rejected = 0, bool stopped = false}) =>
      SyncReport(
        succeeded: this.succeeded + succeeded,
        rejected: this.rejected + rejected,
        stoppedForNetwork: stoppedForNetwork || stopped,
      );

  @override
  String toString() =>
      'SyncReport(succeeded: $succeeded, rejected: $rejected, '
      'stoppedForNetwork: $stoppedForNetwork)';
}

/// Replays the outbox against NovaPay.
///
/// The guarantee is *effectively once*, built from two halves:
///
/// 1. **This side promises at least once.** A queued action is only cleared
///    after the server answers. If the app dies mid-send, the row is still
///    `in_flight` and gets sent again.
/// 2. **The server promises no duplicates.** Every attempt carries the same
///    idempotency key, and a key the server has already handled returns the
///    original answer instead of moving money twice.
///
/// Neither half is enough alone, which is why the client cannot promise
/// "exactly once" by itself.
class SyncEngine {
  SyncEngine({required OutboxStore outbox, required FakeNovaPayApi api})
    : _outbox = outbox,
      _api = api;

  final OutboxStore _outbox;
  final FakeNovaPayApi _api;

  /// The in-progress pass, if any. Two triggers arriving together — the
  /// connectivity listener and a pull-to-refresh — join the same pass instead
  /// of replaying the queue twice.
  Future<SyncReport>? _running;

  bool get isRunning => _running != null;

  Future<SyncReport> run() {
    final existing = _running;
    if (existing != null) return existing;

    final pass = _run().whenComplete(() => _running = null);
    _running = pass;
    return pass;
  }

  Future<SyncReport> _run() async {
    var report = const SyncReport();

    for (final item in await _outbox.itemsToSend()) {
      await _outbox.markInFlight(item.id);

      final TransferOutcome outcome;
      try {
        outcome = await _send(item);
      } on NetworkException catch (error) {
        // No answer, so we do not know whether the server saw it. Leave it
        // queued with the same key and stop: the next connectivity event or
        // pull-to-refresh starts a fresh pass. No retry loop, no backoff timer.
        await _outbox.revertToPending(item.id, error: error.message);
        return report._add(stopped: true);
      }

      switch (outcome) {
        case TransferAccepted():
          await _outbox.markSucceeded(item.id);
          report = report._add(succeeded: 1);
        case TransferRejected(reason: final reason):
          // The server decided. Final, and never retried automatically.
          await _outbox.markFailed(item.id, reason);
          report = report._add(rejected: 1);
      }
    }

    return report;
  }

  Future<TransferOutcome> _send(OutboxItem item) {
    final payload = item.payload;
    final amount = Kobo(payload['amountKobo'] as int);

    return switch (item.type) {
      AppDatabase.typeTransfer => _api.sendMoney(
        idempotencyKey: item.idempotencyKey,
        accountNumber: payload['accountNumber'] as String,
        bankName: payload['bankName'] as String,
        amount: amount,
        narration: payload['narration'] as String?,
      ),
      AppDatabase.typeContribution => _api.contributeToGoal(
        idempotencyKey: item.idempotencyKey,
        goalId: payload['goalId'] as String,
        amount: amount,
      ),
      _ => throw StateError('Unknown outbox item type: ${item.type}'),
    };
  }
}
