import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/wallethome/model/transaction_model.dart';
import 'package:novawallet/presentation/features/wallethome/provider/transaction_provider.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

/// Transactions, as a sliver so rows are built only as they scroll into view.
///
/// This is deliberately not a `ListView.builder` with `shrinkWrap: true` inside
/// the page's scroll view: shrink-wrapping lays out every child to measure
/// itself, so it would satisfy the letter of "use ListView.builder" while still
/// building the whole history eagerly. A real wallet's history is unbounded and
/// most NovaPay users are on low-end Android devices, which is why the brief
/// makes laziness a hard constraint.
///
/// [limit] caps how many rows are shown: Home passes one to render a preview,
/// and the full history screen passes none.
class TransactionSliverList extends ConsumerWidget {
  const TransactionSliverList({super.key, this.limit});

  final int? limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(transactionFeedProvider);
    final cap = limit;
    final transactions = cap == null || cap >= all.length
        ? all
        : all.take(cap).toList();

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16.r),
      ),
      sliver: SliverList.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) => _TransactionRow(
          transaction: transactions[index],
          showDivider: index < transactions.length - 1,
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.showDivider});

  final TransactionModel transaction;
  final bool showDivider;

  Color get _amountColor => switch (transaction.status) {
    TransactionStatus.failed => AppColors.textMuted,
    _ => transaction.isCredit ? AppColors.success : AppColors.navy900,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // One node per row: a screen reader should read "Sent ₦15,000.00 to
        // Chiamaka Obi, GTBank, today 21:14" as a single item, not as four
        // fragments read in layout order.
        Semantics(
          label: transaction.semanticsLabel,
          excludeSemantics: true,
          child: Padding(
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
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy900,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Gap(4.h),
                      AppText(
                        transaction.subtitle,
                        fontSize: 12,
                        lineHeight: 16,
                        color: AppColors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Gap(12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      transaction.formattedAmount,
                      fontWeight: FontWeight.w700,
                      color: _amountColor,
                      tabular: true,
                    ),
                    if (transaction.status != TransactionStatus.completed) ...[
                      Gap(4.h),
                      _StatusChip(status: transaction.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 64.w),
            child: const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
          ),
      ],
    );
  }
}

/// Status is never colour alone: the icon and the word carry it too, so it
/// still reads on a monochrome screen and to someone who cannot distinguish
/// amber from red.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TransactionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, foreground, background) = switch (status) {
      TransactionStatus.pending => (
        'Pending',
        Icons.schedule,
        AppColors.pending,
        AppColors.pendingBg,
      ),
      TransactionStatus.failed => (
        'Failed',
        Icons.error_outline,
        AppColors.error,
        AppColors.errorBg,
      ),
      TransactionStatus.completed => (
        'Sent',
        Icons.check_circle_outline,
        AppColors.success,
        AppColors.successBg,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: foreground),
          Gap(4.w),
          AppText(
            label,
            fontSize: 12,
            lineHeight: 16,
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ],
      ),
    );
  }
}
