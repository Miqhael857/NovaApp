import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

class TransactionDetailsWidget extends StatelessWidget {
  const TransactionDetailsWidget({
    super.key,
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(label, color: AppColors.textSecondary),
          Gap(12.w),
          Expanded(
            child: AppText(
              value,
              fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.navy900,
              tabular: true,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusRow extends StatelessWidget {
  const StatusRow({super.key, required this.sent});

  final bool sent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          AppText('Status', color: AppColors.textSecondary),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: sent ? AppColors.successBg : AppColors.pendingBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sent ? Icons.check : Icons.schedule,
                  size: 14.r,
                  color: sent ? AppColors.success : AppColors.pending,
                ),
                Gap(4.w),
                AppText(
                  sent ? 'Sent' : 'Pending',
                  fontSize: 12,
                  lineHeight: 16,
                  fontWeight: FontWeight.w700,
                  color: sent ? AppColors.success : AppColors.pending,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
