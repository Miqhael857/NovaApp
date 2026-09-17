import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/presentation/features/send/provider/transaction_details_provider.dart';
import 'package:novawallet/presentation/features/send/widgets/transaction_details_widget.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

class SendConfirmView extends ConsumerWidget {
  const SendConfirmView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(sendFlowModelProvider);
    final amount = flow.amount ?? Kobo.zero;
    final details = ref.watch(transactionDetailsProvider);
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      children: [
        Center(
          child: AppText(
            "You're sending",
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ),
        Gap(4.h),
        Center(
          child: AppText(
            amount.format(),
            fontSize: 32,
            lineHeight: 40,
            fontWeight: FontWeight.w800,
            color: AppColors.navy900,
            tabular: true,
            textAlign: TextAlign.center,
          ),
        ),
        Gap(4.h),
        Center(
          child: AppText(
            'to ${flow.accountName ?? ''}',
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ),
        Gap(20.h),

        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (final detail in details)
                TransactionDetailsWidget(
                  label: detail.label,
                  value: detail.value,
                  emphasised: detail.emphasised,
                ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Container(height: 1, color: AppColors.border),
              ),

              TransactionDetailsWidget(
                label: 'Reference',
                value: flow.reference ?? '',
              ),
            ],
          ),
        ),
        Gap(16.h),

        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: AppColors.navyTint,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 20.r,
                color: AppColors.navy700,
              ),
              Gap(8.w),
              Expanded(
                child: AppText(
                  'This transfer has a unique reference, so it can only go '
                  'through once \u2014 even if your connection drops and we try '
                  'again.',
                  fontSize: 12,
                  lineHeight: 16,
                  color: AppColors.navy700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
