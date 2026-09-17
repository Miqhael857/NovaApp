import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:sqflite/sqflite.dart';

import 'package:novawallet/core/enums.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/features/send/provider/send_result_provider.dart';
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

  /// Queues the transfer, then tries to send it.
  ///
  /// The order matters more than anything else on this screen: the outbox row
  /// is written to disk **before** any network call. If the app dies between
  /// the tap and the server answering, the row is still there and gets replayed
  /// with the same idempotency key, so the transfer is never lost and never
  /// sent twice.
  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    SendFlowModel flow,
  ) async {
    final key = flow.idempotencyKey;
    final amount = flow.amount;
    if (key == null || amount == null) return;

    final services = await ref.read(novaPayServicesProvider.future);

    try {
      await services.outbox.enqueue(
        idempotencyKey: key,
        type: AppDatabase.typeTransfer,
        // These keys are the contract SyncEngine._send reads back.
        payload: {
          'accountNumber': flow.accountNumber,
          'bankName': flow.bank,
          'amountKobo': amount.value,
          'narration': flow.narration.isEmpty ? null : flow.narration,
        },
      );
    } on DatabaseException {
      // The idempotency key is UNIQUE, so this means the row is already
      // queued: a double tap, not a second transfer. Let sync handle it.
    }

    // Run a pass, then ask the ROW what happened instead of trusting this
    // pass's report. SyncEngine is single-flight: if a pass was already running
    // when we enqueued, run() hands back that pass, which read the queue before
    // our row existed and would report nothing sent - so a transfer that
    // actually went through would be shown as still pending.
    await services.sync.run();

    final rows = await services.outbox.all();
    final sent = rows.any(
      (item) =>
          item.idempotencyKey == key &&
          item.status == AppDatabase.statusSucceeded,
    );

    ref
        .read(sendResultProvider.notifier)
        .setResult(sent ? SendResult.sent : SendResult.queued);

    if (context.mounted) context.go(Routes.sendResult);
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
            onTap: () => _submit(context, ref, flow),
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
