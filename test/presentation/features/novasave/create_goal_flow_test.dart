import 'package:flutter_test/flutter_test.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/presentation/features/novasave/provider/create_goal_provider.dart';

/// The create-goal form's rules, tested without a widget tree.
///
/// The screen itself is thin: it draws fields and calls [GoalStore.create]. The
/// part worth testing is the arithmetic behind the "save about X a month" hint,
/// because that is the one number on the screen the user did not type.
void main() {
  group('validation', () {
    test('needs a name, a target above zero, and a date', () {
      const empty = CreateGoalFlow();
      expect(empty.canSubmit, isFalse);

      final noDate = CreateGoalFlow(name: 'School fees', targetText: '350000');
      expect(noDate.canSubmit, isFalse);

      final noName = CreateGoalFlow(
        targetText: '350000',
        targetDate: DateTime(2027, 1, 15),
      );
      expect(noName.canSubmit, isFalse);

      final zero = CreateGoalFlow(
        name: 'School fees',
        targetText: '0',
        targetDate: DateTime(2027, 1, 15),
      );
      expect(zero.canSubmit, isFalse, reason: 'a goal of ₦0 is not a goal');

      final complete = CreateGoalFlow(
        name: 'School fees',
        targetText: '350,000',
        targetDate: DateTime(2027, 1, 15),
      );
      expect(complete.canSubmit, isTrue);
      expect(complete.target, const Kobo(35000000));
    });

    test('a name of only spaces is not a name', () {
      final spaces = CreateGoalFlow(
        name: '   ',
        targetText: '1000',
        targetDate: DateTime(2027, 1, 15),
      );
      expect(spaces.hasName, isFalse);
      expect(spaces.canSubmit, isFalse);
    });

    test('rejects an amount that is not a plain number', () {
      const flow = CreateGoalFlow(name: 'Car', targetText: '3.5k');
      expect(flow.target, isNull);
      expect(flow.hasTarget, isFalse);
    });
  });

  group('monthly contribution', () {
    test('matches the figure in the design', () {
      // The artboard: ₦350,000.00 by 15 Jan 2027, from mid-September 2026,
      // is ₦87,500.00 a month.
      final flow = CreateGoalFlow(
        name: 'School fees',
        targetText: '350000',
        targetDate: DateTime(2027, 1, 15),
      );

      expect(flow.monthsUntil(DateTime(2026, 9, 17)), 4);
      expect(
        flow.monthlyFrom(DateTime(2026, 9, 17))!.format(),
        '₦87,500.00',
      );
    });

    test('rounds up, so the months add up to at least the target', () {
      // ₦100 over 3 months is ₦33.333…, which must not round down to ₦33.33:
      // three of those lands a kobo short on the target date.
      final flow = CreateGoalFlow(
        name: 'Books',
        targetText: '100',
        targetDate: DateTime(2026, 12, 1),
      );

      final monthly = flow.monthlyFrom(DateTime(2026, 9, 1))!;
      expect(monthly, const Kobo(3334));
      expect((monthly * flow.monthsUntil(DateTime(2026, 9, 1))).value,
          greaterThanOrEqualTo(flow.target!.value));
    });

    test('a date inside this month still counts as one month, not zero', () {
      final flow = CreateGoalFlow(
        name: 'Rent',
        targetText: '50000',
        targetDate: DateTime(2026, 9, 30),
      );

      expect(flow.monthsUntil(DateTime(2026, 9, 17)), 1);
      expect(flow.monthlyFrom(DateTime(2026, 9, 17)), const Kobo(5000000));
    });

    test('is null until there is both an amount and a date', () {
      const noDate = CreateGoalFlow(name: 'Rent', targetText: '50000');
      expect(noDate.monthlyFrom(DateTime(2026, 9, 17)), isNull);

      final noAmount = CreateGoalFlow(
        name: 'Rent',
        targetDate: DateTime(2027, 1, 1),
      );
      expect(noAmount.monthlyFrom(DateTime(2026, 9, 17)), isNull);
    });
  });
}
