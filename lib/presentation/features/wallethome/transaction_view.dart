import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/wallethome/model/transaction_model.dart';
import 'package:novawallet/presentation/features/wallethome/provider/transaction_provider.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

/// Recent transactions, as a sliver so rows are built only as they scroll into
/// view.
///
/// This is deliberately not a `ListView.builder` with `shrinkWrap: true` inside
/// the page's scroll view: shrink-wrapping lays out every child to measure
/// itself, so it would satisfy the letter of "use ListView.builder" while still
/// building the whole history eagerly. A real wallet's history is unbounded and
/// most NovaPay users are on low-end Android devices, which is why the brief
/// makes laziness a hard constraint.
class TransactionSliverList extends ConsumerWidget {
  const TransactionSliverList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // One semantics node per row: a screen reader should read "Transfer to
        // John, today 10:30 AM" as a single item, not as three fragments.
        MergeSemantics(
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
                      ),
                      Gap(4.h),
                      AppText(
                        transaction.subtitle,
                        fontSize: 12,
                        lineHeight: 16,
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

/// Box-shaped variant, for screens that are not built from slivers.
///
/// [TransactionSliverList] is the lazy one and is what Home uses for the real
/// history. This builds its rows eagerly, so it is only appropriate for the
/// short fixed previews the NovaSave screens show.
class TransactionView extends ConsumerWidget {
  const TransactionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++)
            _TransactionRow(
              transaction: transactions[i],
              showDivider: i < transactions.length - 1,
            ),
        ],
      ),
    );
  }
}
