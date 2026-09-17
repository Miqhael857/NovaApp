import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/presentation/features/wallethome/transaction_view.dart';
import 'package:novawallet/presentation/features/wallethome/widgets/balance_card_widget.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/routes.dart';

class WalletHomeScreen extends StatelessWidget {
  const WalletHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      // The greeting below is this screen's header, so there is no app bar to
      // reserve space for.
      hasAppBar: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(14.w, 8.h, 16.w, 14.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText('Home', color: AppColors.navy900),
                    Gap(4.h),
                    AppText(
                      'Folake',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: AppColors.navy700,
                  child: AppText(
                    'FA',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                  ),
                ),
              ],
            ),
            Gap(15.h),
            BalanceCardWidget(
              text: 'NovaWallet balance',
              subtitle: 'Updated 22:04 · Pull down to refresh',
              balance: Kobo.fromNaira(20000),
              onSend: () => context.pushNamed(RouteNames.sendRecipient),
              onSave: () => context.goNamed(RouteNames.save),
            ),
            Gap(20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: AppColors.navyTint,
                    child: AppText(
                      'FA',
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy700,
                    ),
                  ),
                  Gap(12.w),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'NovaSave',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        Gap(4.h),
                        AppText(
                          '₦412,500.00 saved across 3 goals',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 15.sp,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
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
      ),
    );
  }
}
