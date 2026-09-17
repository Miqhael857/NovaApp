import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/presentation/features/send/model/recipient_model.dart';
import 'package:novawallet/presentation/features/send/model/send_flow_model.dart';
import 'package:uuid/uuid.dart';

import 'package:novawallet/core/money/kobo.dart';

const kBanks = <String>[
  'Access Bank',
  'First Bank',
  'GTBank',
  'Kuda',
  'Opay',
  'UBA',
  'Zenith Bank',
];

const kAvailableBalance = Kobo(24835075);

final kTierLimit = Kobo.fromNaira(50000);

const kRecentRecipients = <RecipientModel>[
  RecipientModel(
    name: 'Tunde Bakare',
    bank: 'Access Bank',
    accountNumber: '1234894821',
  ),
  RecipientModel(
    name: 'Aisha Bello',
    bank: 'Kuda',
    accountNumber: '2233440937',
  ),
  RecipientModel(
    name: 'Emeka Nwosu',
    bank: 'Zenith Bank',
    accountNumber: '9988775510',
  ),
];

const _directory = <String, String>{
  '0123456789': 'Chiamaka Adaeze Obi',
  '1234894821': 'Tunde Bakare',
  '2233440937': 'Aisha Bello',
  '9988775510': 'Emeka Nwosu',
};

class SendFlowmodelNotifier extends Notifier<SendFlowModel> {
  @override
  SendFlowModel build() => const SendFlowModel();

  void setBank(String bank) {
    state = SendFlowModel(
      bank: bank,
      accountNumber: state.accountNumber,
      accountName: _resolve(bank, state.accountNumber),
      amount: state.amount,
      narration: state.narration,
      idempotencyKey: state.idempotencyKey,
    );
  }

  void setAccountNumber(String accountNumber) {
    state = SendFlowModel(
      bank: state.bank,
      accountNumber: accountNumber,
      accountName: _resolve(state.bank, accountNumber),
      amount: state.amount,
      narration: state.narration,
      idempotencyKey: state.idempotencyKey,
    );
  }

  void chooseRecipient(RecipientModel recipient) {
    state = SendFlowModel(
      bank: recipient.bank,
      accountNumber: recipient.accountNumber,
      accountName: recipient.name,
      amount: state.amount,
      narration: state.narration,
      idempotencyKey: state.idempotencyKey,
    );
  }

  void setAmountText(String text) {
    state = SendFlowModel(
      bank: state.bank,
      accountNumber: state.accountNumber,
      accountName: state.accountName,
      amount: Kobo.tryParse(text),
      narration: state.narration,
      idempotencyKey: state.idempotencyKey,
    );
  }

  void setNarration(String narration) {
    state = SendFlowModel(
      bank: state.bank,
      accountNumber: state.accountNumber,
      accountName: state.accountName,
      amount: state.amount,
      narration: narration,
      idempotencyKey: state.idempotencyKey,
    );
  }

  void startAttempt() {
    if (state.idempotencyKey != null) return;
    state = SendFlowModel(
      bank: state.bank,
      accountNumber: state.accountNumber,
      accountName: state.accountName,
      amount: state.amount,
      narration: state.narration,
      idempotencyKey: const Uuid().v4(),
    );
  }

  void reset() => state = const SendFlowModel();

  static String? _resolve(String? bank, String accountNumber) {
    if (bank == null || accountNumber.length != 10) return null;
    return _directory[accountNumber] ?? 'Folake Adeyemi';
  }
}

final sendFlowModelProvider =
    NotifierProvider<SendFlowmodelNotifier, SendFlowModel>(
      SendFlowmodelNotifier.new,
    );
