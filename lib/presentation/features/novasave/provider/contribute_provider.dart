import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart'
    show kAvailableBalance;

/// A contribution the user is composing.
///
/// Deliberately the same shape as the Send flow: an amount in whole kobo and an
/// idempotency key minted once per attempt. A contribution goes through the
/// same outbox and the same sync engine as a transfer, so it inherits the same
/// guarantee — queued while offline, replayed once when the connection returns.
class ContributeFlow {
  const ContributeFlow({this.goalId, this.amount, this.idempotencyKey});

  final String? goalId;

  final Kobo? amount;

  final String? idempotencyKey;

  bool get hasAmount => amount != null && !amount!.isZero;

  bool get exceedsWallet => amount != null && amount! > kAvailableBalance;

  bool get canSubmit => goalId != null && hasAmount && !exceedsWallet;

  String? get reference {
    final key = idempotencyKey;
    if (key == null) return null;
    final hex = key.replaceAll('-', '').toUpperCase();
    return 'NP-${hex.substring(0, 4)}-${hex.substring(4, 8)}';
  }
}

class ContributeFlowNotifier extends Notifier<ContributeFlow> {
  @override
  ContributeFlow build() => const ContributeFlow();

  void start(String goalId) => state = ContributeFlow(goalId: goalId);

  void setAmountText(String text) {
    state = ContributeFlow(
      goalId: state.goalId,
      amount: Kobo.tryParse(text),
      idempotencyKey: state.idempotencyKey,
    );
  }

  void setAmount(Kobo amount) {
    state = ContributeFlow(
      goalId: state.goalId,
      amount: amount,
      idempotencyKey: state.idempotencyKey,
    );
  }

  void startAttempt() {
    if (state.idempotencyKey != null) return;
    state = ContributeFlow(
      goalId: state.goalId,
      amount: state.amount,
      idempotencyKey: const Uuid().v4(),
    );
  }

  void reset() => state = const ContributeFlow();
}

final contributeFlowProvider =
    NotifierProvider<ContributeFlowNotifier, ContributeFlow>(
      ContributeFlowNotifier.new,
    );
