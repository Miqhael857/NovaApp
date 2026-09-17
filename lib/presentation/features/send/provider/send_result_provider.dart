import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/enums.dart';
import 'package:novawallet/presentation/features/send/model/send_result_model.dart';

class SendResultNotifier extends Notifier<SendResultState> {
  @override
  SendResultState build() {
    return SendResultState(result: SendResult.sent, createdAt: DateTime.now());
  }

  void setResult(SendResult result) {
    state = SendResultState(result: result, createdAt: DateTime.now());
  }

  void reset() {
    state = SendResultState(result: SendResult.sent, createdAt: DateTime.now());
  }

  void markSent() {
    setResult(SendResult.sent);
  }
}

final sendResultProvider =
    NotifierProvider<SendResultNotifier, SendResultState>(
      SendResultNotifier.new,
    );
