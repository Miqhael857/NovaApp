class RecipientModel {
  const RecipientModel({
    required this.name,
    required this.bank,
    required this.accountNumber,
  });

  final String name;
  final String bank;
  final String accountNumber;

  String get initials => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  String get masked =>
      '••••${accountNumber.substring(accountNumber.length - 4)}';
}
