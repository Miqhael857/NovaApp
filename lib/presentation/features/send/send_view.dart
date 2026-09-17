import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:novawallet/core/enums.dart';
import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/presentation/features/send/model/send_flow_model.dart';
import 'package:novawallet/presentation/features/send/provider/send_step_provider.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/presentation/features/send/send_amount_view.dart';
import 'package:novawallet/presentation/features/send/send_confirm_view.dart';
import 'package:novawallet/presentation/features/send/send_recipient_view.dart';
import 'package:novawallet/presentation/features/send/widgets/send_step_header.dart';
import 'package:novawallet/presentation/shared/app_button.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/routes.dart';

class SendView extends ConsumerWidget {
  const SendView({super.key});

  void _leaveFlow(BuildContext context, WidgetRef ref) {
    ref.read(sendFlowModelProvider.notifier).reset();
    ref.read(sendStepProvider.notifier).reset();

    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(sendStepProvider);
    final flow = ref.watch(sendFlowModelProvider);

    return PopScope(
      canPop: step == SendStep.recipient,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ref.read(sendStepProvider.notifier).back();
        }
      },
      child: AppScaffold(
        hasAppBar: false,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(0.w, 4.h, 16.w, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (step != SendStep.recipient) {
                        ref.read(sendStepProvider.notifier).back();
                      } else {
                        _leaveFlow(context, ref);
                      }
                    },
                    icon: const Icon(Icons.chevron_left),
                    iconSize: 24.r,
                    color: AppColors.navy900,
                    tooltip: 'Back',
                  ),
                  AppText(
                    'Send money',
                    fontSize: 20,
                    lineHeight: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
              child: const SendStepHeader(),
            ),

            Expanded(child: _bodyFor(step)),

            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
              child: _footerFor(context, ref, step, flow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyFor(SendStep step) {
    return switch (step) {
      SendStep.recipient => const SendRecipientView(),
      SendStep.amount => const SendAmountView(),
      SendStep.confirm => const SendConfirmView(),
    };
  }

  Widget _footerFor(
    BuildContext context,
    WidgetRef ref,
    SendStep step,
    SendFlowModel flow,
  ) {
    if (step == SendStep.confirm) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppButton(
            text: 'Confirm and send ${(flow.amount ?? Kobo.zero).format()}',
            bgColor: AppColors.gold500,
            tColor: AppColors.navy900,
            fontWeight: FontWeight.w700,
            onTap: () {
              context.go(Routes.sendResult);
            },
          ),

          Gap(4.h),

          Semantics(
            button: true,
            child: InkWell(
              onTap: () => _leaveFlow(context, ref),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: AppText(
                  'Cancel',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final canContinue = step == SendStep.recipient
        ? flow.recipientIsComplete
        : flow.canContinueFromAmount(kAvailableBalance);

    return AppButton(
      text: 'Continue',
      bgColor: canContinue ? AppColors.gold500 : AppColors.border,
      tColor: canContinue ? AppColors.navy900 : AppColors.textMuted,
      fontWeight: FontWeight.w700,
      onTap: canContinue
          ? () {
              if (step == SendStep.amount) {
                ref.read(sendFlowModelProvider.notifier).startAttempt();
              }

              ref.read(sendStepProvider.notifier).next();
            }
          : null,
    );
  }
}
