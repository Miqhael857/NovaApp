import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:novawallet/core/date_utils.dart';
import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/model/send_result_model.dart';
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

class StatusIcon extends StatelessWidget {
  const StatusIcon({super.key, required this.isSent});

  final bool isSent;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 72.r,
        height: 72.r,
        decoration: BoxDecoration(
          color: isSent ? AppColors.successBg : AppColors.pendingBg,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSent ? Icons.check : Icons.schedule,
          size: 36.r,
          color: isSent ? AppColors.success : AppColors.pending,
        ),
      ),
    );
  }
}

class TransferDetails extends StatelessWidget {
  const TransferDetails({
    super.key,
    required this.isSent,
    required this.amount,
    required this.result,
    required this.flow,
  });

  final bool isSent;
  final Kobo amount;
  final SendResultState result;
  final dynamic flow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          StatusRow(sent: isSent),

          if (!isSent) ...[
            TransactionDetailsWidget(
              label: 'To',
              value: flow.accountName ?? '',
            ),
            TransactionDetailsWidget(label: 'Amount', value: amount.format()),
          ],

          TransactionDetailsWidget(
            label: 'Reference',
            value: flow.reference ?? '',
          ),

          TransactionDetailsWidget(
            label: isSent ? 'Date' : 'Saved',
            value: AppDateFormatter.format(result.createdAt),
          ),
        ],
      ),
    );
  }
}

class PendingMessage extends StatelessWidget {
  const PendingMessage({super.key, required this.amount});

  final Kobo amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 20.r, color: AppColors.pending),
        Gap(8.w),
        Expanded(
          child: AppText(
            '${amount.format()} is held from your available '
            'balance until it goes through.',
            fontSize: 12,
            lineHeight: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
