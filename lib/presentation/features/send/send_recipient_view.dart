import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/presentation/features/send/widgets/send_recipient_widget.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/presentation/shared/app_text_field.dart';

class SendRecipientView extends ConsumerStatefulWidget {
  const SendRecipientView({super.key});

  @override
  ConsumerState<SendRecipientView> createState() => _RecipientStepState();
}

class _RecipientStepState extends ConsumerState<SendRecipientView> {
  late final TextEditingController _account = TextEditingController(
    text: ref.read(sendFlowModelProvider).accountNumber,
  );

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  Future<void> _pickBank() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: AppText(
                'Choose a bank',
                fontSize: 16,
                lineHeight: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
            for (final bank in kBanks)
              ListTile(
                leading: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.navy700,
                ),
                title: AppText(bank, color: AppColors.navy900),
                onTap: () => Navigator.of(sheetContext).pop(bank),
              ),
          ],
        ),
      ),
    );

    if (chosen != null) {
      ref.read(sendFlowModelProvider.notifier).setBank(chosen);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(sendFlowModelProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      children: [
        AppText('Bank', fontWeight: FontWeight.w600, color: AppColors.navy900),
        Gap(8.h),
        Semantics(
          button: true,
          label: flow.bank == null ? 'Choose a bank' : 'Bank, ${flow.bank}',
          excludeSemantics: true,
          child: InkWell(
            onTap: _pickBank,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              constraints: BoxConstraints(minHeight: 56.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 20.r,
                    color: AppColors.navy700,
                  ),
                  Gap(12.w),
                  Expanded(
                    child: AppText(
                      flow.bank ?? 'Choose a bank',
                      fontSize: 16,
                      lineHeight: 24,
                      color: flow.bank == null
                          ? AppColors.textMuted
                          : AppColors.navy900,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20.r,
                    color: AppColors.navy700,
                  ),
                ],
              ),
            ),
          ),
        ),
        Gap(16.h),

        AppText(
          'Account number',
          fontWeight: FontWeight.w600,
          color: AppColors.navy900,
        ),

        Gap(8.h),
        AppTextField(
          controller: _account,
          keyboardType: TextInputType.number,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          hintText: '10-digit NUBAN',
          onChanged: ref.read(sendFlowModelProvider.notifier).setAccountNumber,
        ),
        Gap(4.h),
        Align(
          alignment: Alignment.centerRight,
          child: AppText(
            '${flow.accountNumber.length}/10',
            fontSize: 12,
            lineHeight: 16,
            color: AppColors.textMuted,
            tabular: true,
          ),
        ),

        if (flow.accountName != null) ...[
          Gap(12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.r,
                  height: 32.r,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 20.r,
                    color: AppColors.surface,
                  ),
                ),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Account name',
                        fontSize: 12,
                        lineHeight: 16,
                        color: AppColors.textSecondary,
                      ),
                      AppText(
                        flow.accountName!.toUpperCase(),
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy900,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        Gap(24.h),
        AppText(
          'Recent recipients',
          fontSize: 16,
          lineHeight: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.navy900,
        ),
        Gap(12.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < kRecentRecipients.length; i++) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    margin: EdgeInsets.only(left: 68.w),
                    color: AppColors.border,
                  ),
                SendRecipientWidget(
                  recipientmodel: kRecentRecipients[i],
                  onTap: () {
                    ref
                        .read(sendFlowModelProvider.notifier)
                        .chooseRecipient(kRecentRecipients[i]);
                    _account.text = kRecentRecipients[i].accountNumber;
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
