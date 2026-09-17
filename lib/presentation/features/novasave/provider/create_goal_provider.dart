import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novawallet/core/money/kobo.dart';

/// A goal the user is filling in.
///
/// Unlike a transfer or a contribution, creating a goal moves no money, so it
/// does not go through the outbox: there is nothing for the server to settle
/// and nothing that could be sent twice. It is a local record, written straight
/// to the goals table, and it works identically offline.
class CreateGoalFlow {
  const CreateGoalFlow({this.name = '', this.targetText = '', this.targetDate});

  /// Long enough for "Emergency fund for the family", short enough to fit a
  /// goal card without eliding.
  static const maxNameLength = 40;

  final String name;
  final String targetText;
  final DateTime? targetDate;

  String get trimmedName => name.trim();

  bool get hasName => trimmedName.isNotEmpty;

  /// Null when what was typed is not a valid amount at all.
  Kobo? get target => Kobo.tryParse(targetText);

  bool get hasTarget => target != null && !target!.isZero;

  bool get canSubmit => hasName && hasTarget && targetDate != null;

  /// Whole months between [from] and the target date, never less than one.
  ///
  /// Counting calendar months rather than days keeps this integer arithmetic
  /// and matches how someone actually thinks about saving: "five more
  /// paydays", not "154 days".
  int monthsUntil(DateTime from) {
    final date = targetDate;
    if (date == null) return 0;
    final months = (date.year - from.year) * 12 + (date.month - from.month);
    return months < 1 ? 1 : months;
  }

  /// What the user would have to put aside each month to arrive on time.
  ///
  /// Rounded **up**: rounding down would leave the goal a few kobo short on the
  /// target date, which is the one thing this number must not do.
  Kobo? monthlyFrom(DateTime from) {
    final total = target;
    if (total == null || total.isZero || targetDate == null) return null;
    final months = monthsUntil(from);
    return Kobo((total.value + months - 1) ~/ months);
  }
}

class CreateGoalFlowNotifier extends Notifier<CreateGoalFlow> {
  @override
  CreateGoalFlow build() => const CreateGoalFlow();

  void setName(String value) => state = CreateGoalFlow(
    name: value,
    targetText: state.targetText,
    targetDate: state.targetDate,
  );

  void setTargetText(String value) => state = CreateGoalFlow(
    name: state.name,
    targetText: value,
    targetDate: state.targetDate,
  );

  void setTargetDate(DateTime value) => state = CreateGoalFlow(
    name: state.name,
    targetText: state.targetText,
    targetDate: value,
  );

  void reset() => state = const CreateGoalFlow();
}

final createGoalFlowProvider =
    NotifierProvider<CreateGoalFlowNotifier, CreateGoalFlow>(
      CreateGoalFlowNotifier.new,
    );
