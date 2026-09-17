import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/local/goal_store.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/shared/app_balance_card_widget.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/presentation/shared/utils/date_format.dart';
import 'package:novawallet/routes.dart';

/// The Save tab: what is saved in total, and every goal with its progress.
class NovaSaveGoalView extends ConsumerWidget {
  const NovaSaveGoalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    final totalSaved = ref.watch(totalSavedProvider);

    return AppScaffold(
      hasAppBar: false,
      body: RefreshIndicator(
        onRefresh: () async {
          final services = await ref.read(novaPayServicesProvider.future);
          await services.sync.run();
          ref
            ..invalidate(goalsProvider)
            ..invalidate(totalSavedProvider)
            ..invalidate(outboxItemsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(14.w, 8.h, 16.w, 24.h),
          children: [
            AppText(
              'NovaSave',
              fontSize: 24,
              lineHeight: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
            Gap(15.h),

            AppBalanceCardWidget(
              text: 'Total saved',
              subtitle: goals.maybeWhen(
                data: (list) =>
                    'Across ${list.length} ${list.length == 1 ? 'goal' : 'goals'}',
                orElse: () => 'Across your goals',
              ),
              balance: totalSaved.maybeWhen(
                data: (total) => total,
                orElse: () => Kobo.zero,
              ),
              showButton: false,
            ),
            Gap(20.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  'Your goals',
                  fontSize: 16,
                  lineHeight: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy900,
                ),
                Semantics(
                  button: true,
                  label: 'Create a new goal',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => context.pushNamed(RouteNames.newGoal),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      constraints: BoxConstraints(minHeight: 44.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16.r, color: AppColors.navy900),
                          Gap(6.w),
                          AppText(
                            'New goal',
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy900,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Gap(16.h),

            goals.when(
              loading: () => const SizedBox.shrink(),
              error: (error, _) => AppText(
                'Could not load your goals: $error',
                fontSize: 12,
                lineHeight: 16,
                color: AppColors.error,
              ),
              data: (list) => Column(
                children: [
                  for (final goal in list) ...[
                    GoalCard(goal: goal),
                    Gap(12.h),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One goal: name, progress, and what is saved against the target.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          '${goal.name}, ${goal.percent} percent saved, '
          '${goal.saved.format()} of ${goal.target.format()}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.goal,
          pathParameters: {'goalId': goal.id},
        ),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      goal.name,
                      fontSize: 16,
                      lineHeight: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),
                  ),
                  Gap(8.w),
                  AppText(
                    '${goal.percent}%',
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy700,
                    tabular: true,
                  ),
                ],
              ),
              Gap(10.h),

              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  // The only place a double appears: built at the widget edge
                  // from two integers, and never summed.
                  value: goal.percent / 100,
                  minHeight: 8.h,
                  backgroundColor: AppColors.navyTint,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold500),
                ),
              ),
              Gap(10.h),

              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 14.r,
                    color: AppColors.textMuted,
                  ),
                  Gap(4.w),
                  Expanded(
                    child: AppText(
                      'Target: ${formatGoalDate(goal.targetDate)}',
                      fontSize: 12,
                      lineHeight: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppText(
                    '${goal.saved.format()} of ${goal.target.format()}',
                    fontSize: 12,
                    lineHeight: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    tabular: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
