import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart' show AppColors;
import 'package:novawallet/presentation/shared/app_balance_card_widget.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

import 'package:novawallet/presentation/features/wallethome/transaction_view.dart';

class GoalDetailiew extends StatelessWidget {
  const GoalDetailiew({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      hasAppBar: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 16.w, 14.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'NovaSave',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy900,
                    ),
                  ],
                ),
                Gap(15.h),
                AppBalanceCardWidget(
                  text: 'Total saved',
                  subtitle: 'Across 3 goals',
                  balance: Kobo.fromNaira(20000),
                  showButton: false,
                ),
                Gap(20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      'Your goals',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),

                    Container(
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
                          Icon(
                            Icons.add,
                            size: 15.sp,
                            color: AppColors.navy900,
                          ),
                          Gap(6.w),
                          AppText(
                            'New goal',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy900,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Gap(20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppText(
                      'Recent transactions',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy700,
                    ),
                    AppText(
                      'See all',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy700,
                    ),
                  ],
                ),
                Gap(20.h),
                TransactionView(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
