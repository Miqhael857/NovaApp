import 'package:novawallet/core/enums.dart';

class SendResultState {
  const SendResultState({required this.result, required this.createdAt});

  final SendResult result;
  final DateTime createdAt;

  bool get isSent => result == SendResult.sent;
}
