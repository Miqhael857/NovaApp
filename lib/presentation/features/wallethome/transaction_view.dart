import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/presentation/features/wallethome/model/transaction_model.dart';
import 'package:novawallet/presentation/features/wallethome/provider/transaction_provider.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/core/theme/app_color.dart';

class TransactionView extends ConsumerWidget {
  const TransactionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Column(
        children: List.generate(transactions.length, (index) {
          final transaction = transactions[index];

          return Column(
            children: [
              _TransactionItem(transaction: transaction),

              if (index < transactions.length - 1)
                Padding(
                  padding: EdgeInsets.only(left: 64.w),
                  child: const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({required this.transaction});

  final TransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: transaction.circleAvatarColor,
            child: Icon(
              transaction.leadingIcon,
              size: 24.r,
              color: transaction.leadingIconColor,
            ),
          ),

          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  transaction.title,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy900,
                ),
                Gap(4.h),
                AppText(
                  transaction.subtitle,
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          Gap(12.w),
          Icon(
            transaction.trailingIcon,
            size: 18.r,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
