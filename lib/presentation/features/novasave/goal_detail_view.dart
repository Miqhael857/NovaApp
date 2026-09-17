import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:sqflite/sqflite.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/goal_store.dart';
import 'package:novawallet/data/local/outbox_store.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/features/novasave/provider/contribute_provider.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart'
    show kAvailableBalance;
import 'package:novawallet/presentation/shared/app_button.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

/// One goal, its progress, and the way to add to it.
class GoalDetailiew extends ConsumerWidget {
  const GoalDetailiew({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    // Contributions for this goal that have not reached the server yet.
    final queued = ref
        .watch(outboxItemsProvider)
        .maybeWhen(
          data: (items) => items
              .where(
                (i) =>
                    i.needsSending &&
                    i.type == AppDatabase.typeContribution &&
                    i.payload['goalId'] == goalId,
              )
              .length,
          orElse: () => 0,
        );

    return AppScaffold(
      hasLeading: true,
      leadingText: 'Back',
      automaticallyImplyLeading: true,
      body: goals.when(
        loading: () => const SizedBox.shrink(),
        error: (error, _) => Center(
          child: AppText(
            'Could not load this goal: $error',
            color: AppColors.error,
          ),
        ),
        data: (list) {
          final matches = list.where((g) => g.id == goalId).toList();
          if (matches.isEmpty) {
            return Center(
              child: AppText(
                'That goal no longer exists.',
                color: AppColors.textSecondary,
              ),
            );
          }
          return _GoalBody(goal: matches.first, queued: queued);
        },
      ),
    );
  }
}

class _GoalBody extends ConsumerWidget {
  const _GoalBody({required this.goal, required this.queued});

  final Goal goal;
  final int queued;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        AppText(
          goal.name,
          fontSize: 24,
          lineHeight: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.navy900,
        ),
        Gap(12.h),

        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.navy900,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                goal.saved.format(),
                fontSize: 32,
                lineHeight: 40,
                fontWeight: FontWeight.w800,
                color: AppColors.surface,
                tabular: true,
              ),
              AppText(
                'saved of ${goal.target.format()}',
                color: AppColors.onNavySecondary,
                tabular: true,
              ),
              Gap(16.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: goal.percent / 100,
                  minHeight: 8.h,
                  backgroundColor: AppColors.navy700,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold500),
                ),
              ),
              Gap(8.h),
              AppText(
                '${goal.percent}% saved · ${goal.remaining.format()} to go',
                fontSize: 12,
                lineHeight: 16,
                color: AppColors.onNavySecondary,
                tabular: true,
              ),
            ],
          ),
        ),

        if (queued > 0) ...[
          Gap(12.h),
          MergeSemantics(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.pendingBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 20.r, color: AppColors.pending),
                  Gap(8.w),
                  Expanded(
                    child: AppText(
                      queued == 1
                          ? 'Pending — will send when back online'
                          : '$queued contributions pending — will send '
                                'when back online',
                      fontSize: 12,
                      lineHeight: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pending,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        Gap(20.h),
        AppButton(
          text: 'Add to ${goal.name}',
          bgColor: AppColors.gold500,
          tColor: AppColors.navy900,
          fontWeight: FontWeight.w700,
          onTap: () => _openSheet(context, ref, goal),
        ),
      ],
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref, Goal goal) {
    ref.read(contributeFlowProvider.notifier).start(goal.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => ContributeSheet(goal: goal),
    );
  }
}

/// "Add to Rent 2027" — the contribution goes through the same outbox and the
/// same sync engine as a transfer, so it inherits the same guarantee.
class ContributeSheet extends ConsumerStatefulWidget {
  const ContributeSheet({super.key, required this.goal});

  final Goal goal;

  @override
  ConsumerState<ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends ConsumerState<ContributeSheet> {
  static const _quickAmounts = [2000, 5000, 10000];

  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setAmount(int naira) {
    final text = '$naira';
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    ref.read(contributeFlowProvider.notifier).setAmountText(text);
  }

  /// Writes the outbox row **before** any network call, credits the goal
  /// locally so the user sees it immediately, then tries to send.
  Future<void> _submit(Kobo amount) async {
    setState(() => _busy = true);

    ref.read(contributeFlowProvider.notifier).startAttempt();
    final key = ref.read(contributeFlowProvider).idempotencyKey!;

    final services = await ref.read(novaPayServicesProvider.future);

    try {
      await services.outbox.enqueue(
        idempotencyKey: key,
        type: AppDatabase.typeContribution,
        // The keys SyncEngine._send reads back for a contribution.
        payload: {'goalId': widget.goal.id, 'amountKobo': amount.value},
      );
      // Durable in the outbox, so showing it on the goal now is honest even
      // while offline. If the server refuses it, the credit is reversed below.
      await services.goals.credit(widget.goal.id, amount);
    } on DatabaseException {
      // Same key already queued: a double tap, not a second contribution.
    }

    await services.sync.run();

    final rows = await services.outbox.all();
    final mine = rows.where((i) => i.idempotencyKey == key).toList();
    final OutboxItem? row = mine.isEmpty ? null : mine.first;
    final rejected = row != null && row.status == AppDatabase.statusFailed;
    final sent = row != null && row.status == AppDatabase.statusSucceeded;

    if (rejected) {
      await services.goals.debit(widget.goal.id, amount);
    }

    ref
      ..invalidate(goalsProvider)
      ..invalidate(totalSavedProvider)
      ..invalidate(outboxItemsProvider);
    ref.read(contributeFlowProvider.notifier).reset();

    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          rejected
              ? 'Not added — ${row.lastError ?? 'the contribution was refused'}'
              : sent
              ? 'Added ${amount.format()} to ${widget.goal.name}.'
              : 'Pending — will send when back online.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(contributeFlowProvider);
    final amount = flow.amount ?? Kobo.zero;
    final after = widget.goal.saved + amount;
    final afterPercent = after.percentOf(widget.goal.target);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        MediaQuery.viewInsetsOf(context).bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            'Add to ${widget.goal.name}',
            fontSize: 20,
            lineHeight: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.navy900,
          ),
          AppText(
            'From NovaWallet · Available ${kAvailableBalance.format()}',
            fontSize: 12,
            lineHeight: 16,
            color: AppColors.textSecondary,
            tabular: true,
          ),
          Gap(16.h),

          AppText(
            'Amount',
            fontWeight: FontWeight.w600,
            color: AppColors.navy900,
          ),
          Gap(8.h),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
              fontFamily: 'PlusJakartaSans',
            ),
            decoration: InputDecoration(
              prefixText: '₦',
              hintText: '0.00',
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: flow.exceedsWallet
                      ? AppColors.error
                      : AppColors.navy900,
                  width: 2,
                ),
              ),
            ),
            onChanged: ref.read(contributeFlowProvider.notifier).setAmountText,
          ),
          Gap(6.h),
          AppText(
            flow.exceedsWallet
                ? 'That is more than your wallet balance'
                : 'Moves from your wallet to this goal.',
            fontSize: 12,
            lineHeight: 16,
            color: flow.exceedsWallet
                ? AppColors.error
                : AppColors.textSecondary,
          ),
          Gap(12.h),

          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final naira in _quickAmounts)
                Semantics(
                  button: true,
                  child: InkWell(
                    onTap: () => _setAmount(naira),
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
                        Kobo.fromNaira(naira).format(),
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy900,
                        tabular: true,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (flow.hasAmount) ...[
            Gap(16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.navyTint,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  AppText(
                    'After this',
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  const Spacer(),
                  AppText(
                    '$afterPercent% · ${after.format()}',
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                    tabular: true,
                  ),
                ],
              ),
            ),
          ],
          Gap(16.h),

          AppButton(
            text: _busy
                ? 'Adding…'
                : 'Add ${flow.hasAmount ? amount.format() : ''}'.trim(),
            bgColor: flow.canSubmit && !_busy
                ? AppColors.gold500
                : AppColors.border,
            tColor: flow.canSubmit && !_busy
                ? AppColors.navy900
                : AppColors.textMuted,
            fontWeight: FontWeight.w700,
            onTap: flow.canSubmit && !_busy ? () => _submit(amount) : null,
          ),
        ],
      ),
    );
  }
}
