import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/enums.dart';

class SendStepNotifier extends Notifier<SendStep> {
  @override
  SendStep build() => SendStep.recipient;

  void next() {
    if (state != SendStep.confirm) {
      state = SendStep.values[state.index + 1];
    }
  }

  void back() {
    if (state != SendStep.recipient) {
      state = SendStep.values[state.index - 1];
    }
  }

  void goTo(SendStep step) {
    state = step;
  }

  void reset() {
    state = SendStep.recipient;
  }
}

final sendStepProvider = NotifierProvider<SendStepNotifier, SendStep>(
  SendStepNotifier.new,
);
