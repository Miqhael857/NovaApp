import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/presentation/features/wallethome/model/transaction_model.dart';
import 'package:novawallet/core/theme/app_color.dart';

final transactionsProvider = Provider<List<TransactionModel>>((ref) {
  return const [
    TransactionModel(
      leadingIcon: Icons.arrow_upward,
      title: 'Transfer to John',
      subtitle: 'Today, 10:30 AM',
      trailingIcon: Icons.chevron_right,
      leadingIconColor: AppColors.navy700,
      circleAvatarColor: AppColors.navyTint,
    ),
    TransactionModel(
      leadingIcon: Icons.arrow_downward,
      title: 'Received from Sarah',
      subtitle: 'Yesterday, 4:15 PM',
      trailingIcon: Icons.chevron_right,
      leadingIconColor: AppColors.gold600,
      circleAvatarColor: AppColors.goldTint,
    ),
    TransactionModel(
      leadingIcon: Icons.savings_outlined,
      title: 'Savings deposit',
      subtitle: 'Sep 14, 9:00 AM',
      trailingIcon: Icons.chevron_right,
      leadingIconColor: AppColors.success,
      circleAvatarColor: AppColors.successBg,
    ),
  ];
});
