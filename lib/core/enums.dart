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

/// How a transfer ended.
///
/// [rejected] is not a failure to *reach* NovaPay — it is NovaPay answering
/// "no": over the daily limit, or not enough money. The sync engine marks such
/// a row failed and never retries it, so it must never be shown as pending.
enum SendResult { sent, queued, rejected }
