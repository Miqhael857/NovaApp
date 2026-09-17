import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/goal_store.dart';
import 'package:novawallet/data/local/outbox_store.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/features/wallethome/model/transaction_model.dart';

/// Settled history.
///
/// Fixed data standing in for what the server would return on a real account.
/// It is the past: everything here has already been through the ledger. What is
/// still in flight comes from the outbox, in [transactionFeedProvider].
final transactionsProvider = Provider<List<TransactionModel>>((ref) {
  return [
    _debit('Chiamaka Obi', 'GTBank · Today, 21:14', 15000),
    _contribution('Rent 2027', 'Today, 08:02', 5000),
    _credit('Tunde Bakare', 'Access Bank · Yesterday, 18:40', 50000),
    _bill('MTN Airtime', '0803 ••• 4412 · Yesterday, 12:10', 2000,
        Icons.phone_android),
    _credit('Brightpath Ltd', 'Salary · 12 Sep', 320000),
    _debit('Aisha Bello', 'Kuda · 11 Sep', 7500),
    _contribution('Emergency fund', '10 Sep', 10000),
    _bill('Ikeja Electric', 'Prepaid meter · 9 Sep', 8400, Icons.bolt),
    _debit('Chinedu Okafor', 'First Bank · 8 Sep', 25000),
    _contribution('New laptop', '6 Sep', 15000),
    _credit('Damilola Adeyemi', 'Opay · 5 Sep', 12000),
    _bill('DStv subscription', 'Compact Plus · 3 Sep', 12500, Icons.tv),
  ];
});

/// What Home and "See all" actually render.
///
/// Anything sitting in the outbox goes on top, newest first, so a transfer made
/// while offline shows up in the history immediately with a Pending chip rather
/// than vanishing until it syncs. Settled history follows underneath.
final transactionFeedProvider = Provider<List<TransactionModel>>((ref) {
  final queued = ref
      .watch(outboxItemsProvider)
      .maybeWhen(data: (items) => items, orElse: () => const <OutboxItem>[]);

  final goals = ref
      .watch(goalsProvider)
      .maybeWhen(data: (list) => list, orElse: () => const <Goal>[]);

  return [
    for (final item in queued) _fromOutbox(item, goals),
    ...ref.watch(transactionsProvider),
  ];
});

/// Turns an outbox row into a history row.
///
/// The outbox is the only place that knows about an action the server has not
/// settled, so this is what makes "queued" visible to the user rather than
/// merely true in the database.
TransactionModel _fromOutbox(OutboxItem item, List<Goal> goals) {
  final amount = Kobo((item.payload['amountKobo'] as num?)?.toInt() ?? 0);

  final status = switch (item.status) {
    AppDatabase.statusFailed => TransactionStatus.failed,
    AppDatabase.statusSucceeded => TransactionStatus.completed,
    _ => TransactionStatus.pending,
  };

  final word = switch (status) {
    TransactionStatus.completed => 'Sent',
    TransactionStatus.pending => 'Pending',
    TransactionStatus.failed => 'Not sent',
  };

  if (item.type == AppDatabase.typeContribution) {
    final goalId = item.payload['goalId'];
    final matches = goals.where((g) => g.id == goalId);
    final name = matches.isEmpty ? 'a goal' : matches.first.name;

    return TransactionModel(
      title: 'NovaSave · $name',
      subtitle: 'Contribution · $word',
      amount: amount,
      status: status,
      leadingIcon: Icons.savings_outlined,
      leadingIconColor: AppColors.success,
      circleAvatarColor: AppColors.successBg,
    );
  }

  // A transfer. The payload carries the account number and bank, but no
  // recipient name: NovaPay resolves that server-side, and the queue
  // deliberately stores as little about the person as it can.
  final account = item.payload['accountNumber'] ?? '';
  final bank = item.payload['bankName'] ?? 'Transfer';

  return TransactionModel(
    title: 'To $account',
    subtitle: '$bank · $word',
    amount: amount,
    status: status,
    leadingIcon: Icons.arrow_upward,
    leadingIconColor: AppColors.navy700,
    circleAvatarColor: AppColors.navyTint,
  );
}

TransactionModel _debit(String title, String subtitle, int naira) =>
    TransactionModel(
      title: title,
      subtitle: subtitle,
      amount: Kobo.fromNaira(naira),
      leadingIcon: Icons.arrow_upward,
      leadingIconColor: AppColors.navy700,
      circleAvatarColor: AppColors.navyTint,
    );

TransactionModel _credit(String title, String subtitle, int naira) =>
    TransactionModel(
      title: title,
      subtitle: subtitle,
      amount: Kobo.fromNaira(naira),
      isCredit: true,
      leadingIcon: Icons.arrow_downward,
      leadingIconColor: AppColors.gold600,
      circleAvatarColor: AppColors.goldTint,
    );

TransactionModel _contribution(String goal, String when, int naira) =>
    TransactionModel(
      title: 'NovaSave · $goal',
      subtitle: 'Contribution · $when',
      amount: Kobo.fromNaira(naira),
      leadingIcon: Icons.savings_outlined,
      leadingIconColor: AppColors.success,
      circleAvatarColor: AppColors.successBg,
    );

TransactionModel _bill(
  String title,
  String subtitle,
  int naira,
  IconData icon,
) => TransactionModel(
  title: title,
  subtitle: subtitle,
  amount: Kobo.fromNaira(naira),
  leadingIcon: icon,
  leadingIconColor: AppColors.navy700,
  circleAvatarColor: AppColors.navyTint,
);
