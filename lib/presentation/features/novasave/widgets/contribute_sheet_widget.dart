import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/local/goal_store.dart';
import 'package:novawallet/data/local/outbox_store.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/features/novasave/provider/contribute_provider.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/presentation/shared/app_button.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:sqflite/sqflite.dart';

class ContributeSheetWidget extends ConsumerStatefulWidget {
  const ContributeSheetWidget({super.key, required this.goal});

  final Goal goal;

  @override
  ConsumerState<ContributeSheetWidget> createState() =>
      _ContributeSheetWidgetState();
}

class _ContributeSheetWidgetState extends ConsumerState<ContributeSheetWidget> {
  static const _quickAmounts = [2000, 5000, 10000];

  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The sheet is handed its goal, so it starts its own attempt rather than
    // trusting whoever opened it to have done so. Relying on the caller meant
    // a forgotten start() left the Add button disabled for ever, with nothing
    // on screen to explain why.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(contributeFlowProvider.notifier).start(widget.goal.id);
      }
    });
  }

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

  Future<void> _submit(Kobo amount) async {
    setState(() => _busy = true);

    ref.read(contributeFlowProvider.notifier).startAttempt();
    final key = ref.read(contributeFlowProvider).idempotencyKey!;

    final services = await ref.read(novaPayServicesProvider.future);

    try {
      await services.outbox.enqueue(
        idempotencyKey: key,
        type: AppDatabase.typeContribution,
        payload: {'goalId': widget.goal.id, 'amountKobo': amount.value},
      );
      await services.goals.credit(widget.goal.id, amount);
    } on DatabaseException {
      // The idempotency key is UNIQUE, so this is the same contribution
      // arriving twice — a double tap, not a second contribution. The row is
      // already queued; let sync deal with it.
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
