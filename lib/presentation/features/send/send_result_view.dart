import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/presentation/features/send/provider/send_result_provider.dart';
import 'package:novawallet/presentation/features/send/provider/send_step_provider.dart';
import 'package:novawallet/presentation/features/send/widgets/transaction_details_widget.dart';
import 'package:novawallet/presentation/shared/app_button.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/routes.dart';

class SendResultView extends ConsumerWidget {
  const SendResultView({super.key});

  void _goHome(BuildContext context, WidgetRef ref) {
    ref.read(sendResultProvider.notifier).reset();
    ref.read(sendFlowModelProvider.notifier).reset();
    ref.read(sendStepProvider.notifier).reset();

    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(sendResultProvider);
    final flow = ref.watch(sendFlowModelProvider);

    final amount = flow.amount ?? Kobo.zero;
    final isSent = result.isSent;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goHome(context, ref);
        }
      },
      child: AppScaffold(
        hasAppBar: false,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 16.h),
                children: [
                  StatusIcon(isSent: isSent),
                  Gap(16.h),

                  AppText(
                    isSent
                        ? 'Transfer sent'
                        : 'Pending — will send when back online',
                    fontSize: 24,
                    lineHeight: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                    textAlign: TextAlign.center,
                  ),

                  Gap(8.h),

                  AppText(
                    isSent
                        ? '${amount.format()} is on its way to '
                              '${flow.accountName ?? ''} at '
                              '${flow.bank ?? ''}.'
                        : "You're offline, so we've saved this transfer "
                              'on your phone. It will be sent once, '
                              'automatically, when you reconnect — even if '
                              'you close the app.',
                    color: AppColors.textSecondary,
                    textAlign: TextAlign.center,
                  ),

                  Gap(24.h),

                  TransferDetails(
                    isSent: isSent,
                    amount: amount,
                    result: result,
                    flow: flow,
                  ),

                  if (!isSent) ...[Gap(16.h), PendingMessage(amount: amount)],
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 32.h, 16.w, 16.h),

              child: AppButton(
                text: isSent ? 'Done' : 'Back to home',
                bgColor: AppColors.gold500,
                tColor: AppColors.navy900,
                fontWeight: FontWeight.w700,
                onTap: () => _goHome(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
