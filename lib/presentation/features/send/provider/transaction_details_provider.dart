import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/presentation/features/send/model/transaction_details_model.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';

final transactionDetailsProvider = Provider<List<TransactionDetailsModel>>((
  ref,
) {
  final flow = ref.watch(sendFlowModelProvider);
  final amount = flow.amount ?? Kobo.zero;

  return [
    TransactionDetailsModel(label: 'Bank', value: flow.bank ?? ''),
    TransactionDetailsModel(label: 'Account number', value: flow.accountNumber),
    if (flow.narration.isNotEmpty)
      TransactionDetailsModel(label: 'Narration', value: flow.narration),
    TransactionDetailsModel(label: 'Amount', value: amount.format()),
    TransactionDetailsModel(label: 'Transfer fee', value: Kobo.zero.format()),
    TransactionDetailsModel(
      label: 'Total',
      value: amount.format(),
      emphasised: true,
    ),
  ];
});
