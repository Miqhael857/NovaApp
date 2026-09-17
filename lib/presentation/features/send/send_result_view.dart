import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:novawallet/core/date_utils.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/provider/send_step_provider.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/presentation/features/send/provider/send_result_provider.dart';
import 'package:novawallet/presentation/features/send/widgets/transaction_details_widget.dart';
import 'package:novawallet/presentation/shared/app_button.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/routes.dart';

class SendResultView extends ConsumerStatefulWidget {
  const SendResultView({super.key});

  @override
  ConsumerState<SendResultView> createState() => _SendResultViewState();
}

class _SendResultViewState extends ConsumerState<SendResultView> {
  /// Whether the transfer actually reached the server, as recorded when it was
  /// submitted. Read from state rather than passed in, so the screen cannot
  /// claim "Transfer sent" for something that is still sitting in the outbox.
  bool get _sent => ref.watch(sendRecipientProvider).isSent;

  DateTime get _at => ref.watch(sendRecipientProvider).createdAt;

  void _goHome() {
    ref.read(sendFlowModelProvider.notifier).reset();
    ref.read(sendStepProvider.notifier).reset();
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(sendFlowModelProvider);
    final amount = flow.amount ?? Kobo.zero;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goHome();
      },
      child: AppScaffold(
        hasAppBar: false,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 16.h),
                children: [
                  Center(
                    child: Container(
                      width: 72.r,
                      height: 72.r,
                      decoration: BoxDecoration(
                        color: _sent
                            ? AppColors.successBg
                            : AppColors.pendingBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _sent ? Icons.check : Icons.schedule,
                        size: 36.r,
                        color: _sent ? AppColors.success : AppColors.pending,
                      ),
                    ),
                  ),
                  Gap(16.h),
                  AppText(
                    _sent
                        ? 'Transfer sent'
                        : 'Pending \u2014 will send when back online',
                    fontSize: 24,
                    lineHeight: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                    textAlign: TextAlign.center,
                  ),
                  Gap(8.h),
                  AppText(
                    _sent
                        ? '${amount.format()} is on its way to '
                              '${flow.accountName ?? ''} at ${flow.bank ?? ''}.'
                        : "You're offline, so we've saved this transfer on your "
                              'phone. It will be sent once, automatically, when '
                              'you reconnect \u2014 even if you close the app.',
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),
                  Gap(24.h),

                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        StatusRow(sent: _sent),
                        if (!_sent) ...[
                          TransactionDetailsWidget(
                            label: 'To',
                            value: flow.accountName ?? '',
                          ),
                          TransactionDetailsWidget(
                            label: 'Amount',
                            value: amount.format(),
                          ),
                        ],
                        TransactionDetailsWidget(
                          label: 'Reference',
                          value: flow.reference ?? '',
                        ),
                        TransactionDetailsWidget(
                          label: _sent ? 'Date' : 'Saved',
                          value: AppDateFormatter.format(_at),
                        ),
                      ],
                    ),
                  ),

                  if (!_sent) ...[
                    Gap(16.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20.r,
                          color: AppColors.pending,
                        ),
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
                    ),
                  ],
                ],
              ),
            ),

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    text: _sent ? 'Done' : 'Back to home',
                    bgColor: AppColors.gold500,
                    tColor: AppColors.navy900,
                    fontWeight: FontWeight.w700,
                    onTap: _goHome,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
