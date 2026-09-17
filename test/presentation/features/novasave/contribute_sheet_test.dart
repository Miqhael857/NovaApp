import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novawallet/core/money/kobo.dart';
import 'package:novawallet/data/local/goal_store.dart';
import 'package:novawallet/presentation/features/novasave/widgets/contribute_sheet_widget.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart'
    show kAvailableBalance;
import 'package:novawallet/presentation/shared/app_button.dart';

/// The NovaSave contribution flow, as far as a widget test can honestly take it.
///
/// Tapping *Add* writes an outbox row and runs a sync pass, which needs real
/// sqflite I/O that a widget test's zone never completes — the same wall the
/// Send flow test hits. So this covers everything up to that tap: what the
/// sheet shows, what it works out, and when it refuses to submit. The write
/// itself is covered by the sync-engine tests and the integration test.
void main() {
  final goal = Goal(
    id: 'rent-2027',
    name: 'Rent 2027',
    target: Kobo.fromNaira(600000),
    saved: Kobo.fromNaira(285000),
    targetDate: DateTime(2027, 1, 31),
    createdAt: DateTime(2026, 6, 1),
  );

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(360, 800),
          builder: (context, child) => MaterialApp(
            home: Scaffold(body: ContributeSheetWidget(goal: goal)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppButton addButton(WidgetTester tester) =>
      tester.widget<AppButton>(find.byType(AppButton));

  testWidgets('opens on the goal, with nothing to submit yet', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Add to Rent 2027'), findsOneWidget);
    expect(
      addButton(tester).onTap,
      isNull,
      reason: 'no amount entered, so there is nothing to add',
    );
  });

  testWidgets('a quick amount fills the field and arms the button', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.text('₦5,000.00'));
    await tester.pumpAndSettle();

    expect(find.text('Add ₦5,000.00'), findsOneWidget);
    expect(addButton(tester).onTap, isNotNull);
  });

  testWidgets('works out the resulting progress in integer kobo', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.text('₦5,000.00'));
    await tester.pumpAndSettle();

    // ₦285,000 saved + ₦5,000 = ₦290,000 of ₦600,000, which is 48% floored —
    // never 48.333…, and never rounded up to 49%.
    expect(find.text('48% · ₦290,000.00'), findsOneWidget);
  });

  testWidgets('refuses an amount larger than the wallet', (tester) async {
    await pumpSheet(tester);

    final tooMuch = kAvailableBalance + Kobo.fromNaira(1);
    await tester.enterText(
      find.byType(TextField),
      tooMuch.format(symbol: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('That is more than your wallet balance'), findsOneWidget);
    expect(
      addButton(tester).onTap,
      isNull,
      reason: 'the wallet cannot fund it, so the sheet must not queue it',
    );
  });

  testWidgets('refuses zero', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), '0');
    await tester.pumpAndSettle();

    expect(addButton(tester).onTap, isNull);
  });
}
