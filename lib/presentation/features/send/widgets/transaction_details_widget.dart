import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:novawallet/core/date_utils.dart';
import 'package:novawallet/core/enums.dart';
import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/model/send_flow_model.dart';
import 'package:novawallet/presentation/features/send/model/send_result_model.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

/// Colour, icon and word for each outcome, in one place so the chip, the big
/// icon and any future surface cannot drift apart.
///
/// Status is never carried by colour alone — every use pairs this icon with
/// this word.
({Color fg, Color bg, IconData icon, String label}) _styleFor(
  SendResult result,
) => switch (result) {
  SendResult.sent => (
    fg: AppColors.success,
    bg: AppColors.successBg,
    icon: Icons.check,
    label: 'Sent',
  ),
  SendResult.queued => (
    fg: AppColors.pending,
    bg: AppColors.pendingBg,
    icon: Icons.schedule,
    label: 'Pending',
  ),
  SendResult.rejected => (
    fg: AppColors.error,
    bg: AppColors.errorBg,
    icon: Icons.error_outline,
    label: 'Not sent',
  ),
};

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
  const StatusRow({super.key, required this.result});

  final SendResult result;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(result);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          AppText('Status', color: AppColors.textSecondary),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 14.r, color: style.fg),
                Gap(4.w),
                AppText(
                  style.label,
                  fontSize: 12,
                  lineHeight: 16,
                  fontWeight: FontWeight.w700,
                  color: style.fg,
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
  const StatusIcon({super.key, required this.result});

  final SendResult result;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(result);

    return Center(
      child: Container(
        width: 72.r,
        height: 72.r,
        decoration: BoxDecoration(color: style.bg, shape: BoxShape.circle),
        child: Icon(style.icon, size: 36.r, color: style.fg),
      ),
    );
  }
}

class TransferDetails extends StatelessWidget {
  const TransferDetails({
    super.key,
    required this.amount,
    required this.result,
    required this.flow,
  });

  final Kobo amount;
  final SendResultState result;
  final SendFlowModel flow;

  @override
  Widget build(BuildContext context) {
    final outcome = result.result;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          StatusRow(result: outcome),

          // On the success screen the recipient and amount are already in the
          // sentence above; when the transfer has not gone through they are
          // what the user needs to check.
          if (outcome != SendResult.sent) ...[
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
            label: switch (outcome) {
              SendResult.sent => 'Date',
              SendResult.queued => 'Saved',
              SendResult.rejected => 'Attempted',
            },
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
