class SendRecipientModel {
  final bool isSent;
  final DateTime createdAt;

  const SendRecipientModel({this.isSent = false, required this.createdAt});

  SendRecipientModel copyWith({bool? isSent, DateTime? createdAt}) {
    return SendRecipientModel(
      isSent: isSent ?? this.isSent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
