import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';

class SendFlowModel {
  const SendFlowModel({
    this.bank,
    this.accountNumber = '',
    this.accountName,
    this.amount,
    this.narration = '',
    this.idempotencyKey,
  });

  final String? bank;
  final String accountNumber;

  final String? accountName;

  final Kobo? amount;

  final String narration;

  final String? idempotencyKey;

  String? get reference {
    final key = idempotencyKey;
    if (key == null) return null;
    final hex = key.replaceAll('-', '').toUpperCase();
    return 'NP-${hex.substring(0, 4)}-${hex.substring(4, 8)}';
  }

  bool get recipientIsComplete =>
      bank != null && accountNumber.length == 10 && accountName != null;

  bool get amountIsOverLimit => amount != null && amount! > kTierLimit;

  bool amountExceeds(Kobo available) => amount != null && amount! > available;

  bool canContinueFromAmount(Kobo available) =>
      amount != null &&
      !amount!.isZero &&
      !amountIsOverLimit &&
      !amountExceeds(available);
}
