class TransactionDetailsModel {
  const TransactionDetailsModel({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;
}
