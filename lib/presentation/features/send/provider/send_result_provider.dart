import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/presentation/features/send/model/send_result_model.dart';

class SendRecipientNotifier extends Notifier<SendRecipientModel> {
  @override
  SendRecipientModel build() {
    return SendRecipientModel(createdAt: DateTime.now());
  }

  void markSent() {
    state = state.copyWith(isSent: true, createdAt: DateTime.now());
  }

  void reset() {
    state = SendRecipientModel(createdAt: DateTime.now());
  }
}

final sendRecipientProvider =
    NotifierProvider<SendRecipientNotifier, SendRecipientModel>(
      SendRecipientNotifier.new,
    );
