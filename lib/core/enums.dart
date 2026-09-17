enum SendStep {
  recipient,
  amount,
  confirm;

  String get label {
    switch (this) {
      case SendStep.recipient:
        return 'Recipient';
      case SendStep.amount:
        return 'Amount';
      case SendStep.confirm:
        return 'Confirm';
    }
  }

  int get number => index + 1;
}

enum SendResult { sent, queued }
