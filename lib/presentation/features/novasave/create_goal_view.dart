import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/providers.dart';
import 'package:novawallet/presentation/features/novasave/provider/create_goal_provider.dart';
import 'package:novawallet/presentation/shared/app_button.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';
import 'package:novawallet/presentation/shared/app_text_field.dart';
import 'package:novawallet/presentation/shared/utils/date_format.dart';
import 'package:novawallet/routes.dart';

class CreateGoalView extends ConsumerStatefulWidget {
  const CreateGoalView({super.key});

  @override
  ConsumerState<CreateGoalView> createState() => _CreateGoalViewState();
}

class _CreateGoalViewState extends ConsumerState<CreateGoalView> {
  final _name = TextEditingController();
  final _target = TextEditingController();

  /// Errors stay hidden until the first attempt, so the screen does not open
  /// already scolding the user about fields they have not reached.
  bool _submitted = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // The flow provider outlives this screen. Clear whatever a previous,
    // abandoned visit left behind so it matches the empty controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(createGoalFlowProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = ref.read(createGoalFlowProvider).targetDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year, now.month + 6, now.day),
      // A goal in the past cannot be saved towards.
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 10, now.month, now.day),
      helpText: 'Target date',
    );

    if (picked != null) {
      ref.read(createGoalFlowProvider.notifier).setTargetDate(picked);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _busy = true;
    });

    final flow = ref.read(createGoalFlowProvider);
    if (!flow.canSubmit) {
      setState(() => _busy = false);
      return;
    }

    final services = await ref.read(novaPayServicesProvider.future);
    final goal = await services.goals.create(
      id: const Uuid().v4(),
      name: flow.trimmedName,
      target: flow.target!,
      targetDate: flow.targetDate!,
    );

    ref
      ..invalidate(goalsProvider)
      ..invalidate(totalSavedProvider);
    ref.read(createGoalFlowProvider.notifier).reset();

    if (!mounted) return;
    setState(() => _busy = false);

    // Replaces this screen rather than stacking on it: Back should return to
    // the goals list, not to a form that has already been submitted.
    context.pushReplacementNamed(
      RouteNames.goal,
      pathParameters: {'goalId': goal.id},
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${goal.name} created. Add your first amount.')),
    );
  }

  String? get _nameError {
    if (!_submitted) return null;
    final flow = ref.read(createGoalFlowProvider);
    return flow.hasName ? null : 'Give your goal a name';
  }

  String? _targetError(CreateGoalFlow flow) {
    if (_target.text.isEmpty) {
      return _submitted ? 'Enter what you are saving towards' : null;
    }
    if (flow.target == null) return 'Enter an amount like 350,000 or 350000.50';
    if (flow.target!.isZero) return 'Enter an amount above zero';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(createGoalFlowProvider);
    final targetError = _targetError(flow);
    final dateError = _submitted && flow.targetDate == null
        ? 'Choose when you want to reach it'
        : null;
    final canSubmit = flow.canSubmit && !_busy;

    return AppScaffold(
      hasAppBar: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 8.h, 16.w, 8.h),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 24.r,
                  color: AppColors.navy900,
                  tooltip: 'Back',
                ),
                AppText(
                  'Create a goal',
                  fontSize: 20,
                  lineHeight: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy900,
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              children: [
                _Field(
                  label: 'Goal name',
                  error: _nameError,
                  // The counter sits opposite the error, as in the design.
                  trailing:
                      '${flow.trimmedName.length}/'
                      '${CreateGoalFlow.maxNameLength}',
                  child: AppTextField(
                    controller: _name,
                    hintText: 'School fees',
                    maxLength: CreateGoalFlow.maxNameLength,
                    textInputAction: TextInputAction.next,
                    onChanged: ref
                        .read(createGoalFlowProvider.notifier)
                        .setName,
                    borderSide: _nameError == null
                        ? null
                        : const BorderSide(color: AppColors.error, width: 2),
                  ),
                ),
                Gap(20.h),

                _Field(
                  label: 'Target amount',
                  error: targetError,
                  child: AppTextField(
                    controller: _target,
                    hintText: '0.00',
                    prefixText: '₦',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: ref
                        .read(createGoalFlowProvider.notifier)
                        .setTargetText,
                    borderSide: targetError == null
                        ? null
                        : const BorderSide(color: AppColors.error, width: 2),
                  ),
                ),
                Gap(20.h),

                _Field(
                  label: 'Target date',
                  error: dateError,
                  child: Semantics(
                    button: true,
                    label: flow.targetDate == null
                        ? 'Target date, not chosen'
                        : 'Target date, ${formatGoalDate(flow.targetDate!)}',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        constraints: BoxConstraints(minHeight: 56.h),
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: dateError == null
                                ? AppColors.inputBorder
                                : AppColors.error,
                            width: dateError == null ? 1 : 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 20.r,
                              color: AppColors.textSecondary,
                            ),
                            Gap(12.w),
                            Expanded(
                              child: AppText(
                                flow.targetDate == null
                                    ? 'Choose a date'
                                    : formatGoalDate(flow.targetDate!),
                                fontSize: 16,
                                lineHeight: 24,
                                color: flow.targetDate == null
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                tabular: true,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 20.r,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (flow.hasTarget && flow.targetDate != null) ...[
                  Gap(20.h),
                  _MonthlyHint(flow: flow),
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
            child: AppButton(
              text: _busy ? 'Creating…' : 'Create goal',
              bgColor: canSubmit ? AppColors.gold500 : AppColors.border,
              tColor: canSubmit ? AppColors.navy900 : AppColors.textMuted,
              fontWeight: FontWeight.w700,
              // Still tappable when incomplete: tapping is how the user asks
              // what is missing, and _submit turns the errors on.
              onTap: _busy ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

/// A label, the field itself, and a line underneath for an error and a counter.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.error,
    this.trailing,
  });

  final String label;
  final Widget child;
  final String? error;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        Gap(8.h),
        child,
        if (error != null || trailing != null) ...[
          Gap(6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppText(
                  error ?? '',
                  fontSize: 12,
                  lineHeight: 16,
                  color: AppColors.error,
                ),
              ),
              if (trailing != null)
                AppText(
                  trailing,
                  fontSize: 12,
                  lineHeight: 16,
                  color: AppColors.textSecondary,
                  tabular: true,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "Save about ₦87,500.00 a month to reach ₦350,000.00 by 15 Jan 2027."
///
/// Turns the two numbers the user just typed into the one number they actually
/// care about, without either of them ever being a double.
class _MonthlyHint extends StatelessWidget {
  const _MonthlyHint({required this.flow});

  final CreateGoalFlow flow;

  @override
  Widget build(BuildContext context) {
    final monthly = flow.monthlyFrom(DateTime.now());
    if (monthly == null) return const SizedBox.shrink();

    final date = formatGoalDate(flow.targetDate!);
    const base = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      color: AppColors.textPrimary,
    );

    return MergeSemantics(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.goldTint,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.adjust, size: 20.r, color: AppColors.gold600),
            Gap(12.w),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: base,
                  children: [
                    const TextSpan(text: 'Save about '),
                    TextSpan(
                      text: '${monthly.format()} a month',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' to reach ${flow.target!.format()} by '),
                    TextSpan(text: date),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
