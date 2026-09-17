import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/model/send_flow_model.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/presentation/features/send/provider/send_step_provider.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/presentation/shared/app_text_field.dart';

class SendAmountView extends ConsumerStatefulWidget {
  const SendAmountView({super.key});

  @override
  ConsumerState<SendAmountView> createState() => _AmountStepState();
}

class _AmountStepState extends ConsumerState<SendAmountView> {
  static const _quickAmounts = [1000, 5000, 10000];

  late final TextEditingController _amount = TextEditingController(
    text: ref.read(sendFlowModelProvider).amount?.format(symbol: false) ?? '',
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _setAmount(String text) {
    _amount.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    ref.read(sendFlowModelProvider.notifier).setAmountText(text);
  }

  String? _errorFor(SendFlowModel flow) {
    if (_amount.text.isEmpty) return null;
    if (flow.amount == null) return 'Enter an amount like 5,000 or 5000.50';
    if (flow.amount!.isZero) return 'Enter an amount above zero';
    if (flow.amountIsOverLimit) {
      return 'Tier 1 accounts can send up to ${kTierLimit.format()} per transfer';
    }
    if (flow.amountExceeds(kAvailableBalance)) {
      return 'That is more than your available balance';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(sendFlowModelProvider);
    final error = _errorFor(flow);

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40.r,
                height: 40.r,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.navyTint,
                  shape: BoxShape.circle,
                ),
                child: AppText(
                  _initialsOf(flow.accountName),
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy700,
                ),
              ),
              Gap(12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      flow.accountName ?? 'No recipient chosen',
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy900,
                    ),
                    AppText(
                      '${flow.bank ?? ''} \u00b7 ${flow.accountNumber}',
                      fontSize: 12,
                      lineHeight: 16,
                      color: AppColors.textSecondary,
                      tabular: true,
                    ),
                  ],
                ),
              ),
              Gap(8.w),
              Semantics(
                button: true,
                label: 'Change recipient',
                excludeSemantics: true,
                child: InkWell(
                  onTap: ref.read(sendStepProvider.notifier).back,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 12.h,
                    ),
                    child: AppText(
                      'Change',
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Gap(20.h),

        AppText(
          'Amount',
          fontWeight: FontWeight.w600,
          color: AppColors.navy900,
        ),
        Gap(8.h),
        AppTextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          fontSize: 20,
          hintSize: 20,
          hintText: '0.00',
          hintWeight: FontWeight.w800,
          fontWeight: FontWeight.w800,
          onChanged: ref.read(sendFlowModelProvider.notifier).setAccountNumber,
          borderSide: BorderSide(
            color: error == null ? AppColors.navy900 : AppColors.error,
            width: 2,
          ),
          prefixText: '\u20a6',
        ),
        Gap(10.h),
        AppText(
          error ?? 'Available balance: ${kAvailableBalance.format()}',
          fontSize: 12,
          lineHeight: 16,
          color: error == null ? AppColors.textSecondary : AppColors.error,
        ),
        Gap(15.h),
        Row(
          children: [
            for (var i = 0; i < _quickAmounts.length; i++) ...[
              if (i > 0) Gap(8.w),
              Semantics(
                button: true,
                child: InkWell(
                  onTap: () => _setAmount('${_quickAmounts[i]}'),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    constraints: BoxConstraints(minHeight: 40.h),
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: AppText(
                      Kobo.fromNaira(_quickAmounts[i]).format(),
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy900,
                      tabular: true,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        Gap(20.h),
        AppText(
          'Narration (optional)',
          fontWeight: FontWeight.w600,
          color: AppColors.navy900,
        ),
        Gap(8.h),
        AppTextField(
          maxLength: 50,
          fontSize: 16,
          hintText: 'What is it for?',
          hintSize: 16,
          fontWeight: FontWeight.w800,
          hintWeight: FontWeight.w400,
          onChanged: ref.read(sendFlowModelProvider.notifier).setNarration,
        ),
        Gap(12.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 20.r, color: AppColors.textMuted),
            Gap(8.w),
            Expanded(
              child: AppText(
                'Tier 1 accounts can send up to ${kTierLimit.format()} per transfer.',
                fontSize: 12,
                lineHeight: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _initialsOf(String? name) {
    if (name == null || name.isEmpty) return '?';
    return name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
  }
}
