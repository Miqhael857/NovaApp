import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/local/goal_store.dart';
import 'package:novawallet/presentation/features/novasave/provider/contribute_provider.dart';
import 'package:novawallet/presentation/features/novasave/widgets/contribute_sheet_widget.dart';
import 'package:novawallet/presentation/shared/app_button.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

class GoalWidget extends ConsumerWidget {
  const GoalWidget({super.key, required this.goal, required this.queued});

  final Goal goal;
  final int queued;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        AppText(
          goal.name,
          fontSize: 24,
          lineHeight: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.navy900,
        ),
        Gap(12.h),

        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.navy900,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                goal.saved.format(),
                fontSize: 32,
                lineHeight: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.surface,
                tabular: true,
              ),
              AppText(
                'saved of ${goal.target.format()}',
                color: AppColors.onNavySecondary,
                tabular: true,
              ),
              Gap(16.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: goal.percent / 100,
                  minHeight: 8.h,
                  backgroundColor: AppColors.navy700,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold500),
                ),
              ),
              Gap(8.h),
              AppText(
                '${goal.percent}% saved · ${goal.remaining.format()} to go',
                fontSize: 12,
                lineHeight: 16,
                color: AppColors.onNavySecondary,
                tabular: true,
              ),
            ],
          ),
        ),

        if (queued > 0) ...[
          Gap(12.h),
          MergeSemantics(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.pendingBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20.r, color: AppColors.pending),
                  Gap(8.w),
                  Expanded(
                    child: AppText(
                      queued == 1
                          ? 'Pending — will send when back online'
                          : '$queued contributions pending — will send '
                                'when back online',
                      fontSize: 12,
                      lineHeight: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pending,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        Gap(20.h),
        AppButton(
          text: 'Add to ${goal.name}',
          bgColor: AppColors.gold500,
          tColor: AppColors.navy900,
          fontWeight: FontWeight.w700,
          onTap: () => _openSheet(context, ref, goal),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, Goal goal) {
    ref.read(contributeFlowProvider.notifier).start(goal.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => ContributeSheetWidget(goal: goal),
    );
  }
}
