import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novawallet/core/money/kobo.dart';

class CreateGoalFlow {
  const CreateGoalFlow({this.name = '', this.targetText = '', this.targetDate});

  static const maxNameLength = 40;

  final String name;
  final String targetText;
  final DateTime? targetDate;

  String get trimmedName => name.trim();

  bool get hasName => trimmedName.isNotEmpty;

  Kobo? get target => Kobo.tryParse(targetText);

  bool get hasTarget => target != null && !target!.isZero;

  bool get canSubmit => hasName && hasTarget && targetDate != null;

  int monthsUntil(DateTime from) {
    final date = targetDate;
    if (date == null) return 0;
    final months = (date.year - from.year) * 12 + (date.month - from.month);
    return months < 1 ? 1 : months;
  }

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
