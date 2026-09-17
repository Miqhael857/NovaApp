import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:novawallet/app.dart';
import 'package:novawallet/app_router.dart';
import 'package:novawallet/presentation/features/send/provider/send_flow_provider.dart';
import 'package:novawallet/routes.dart';

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: NovaWalletApp()));
  await tester.pumpAndSettle();
}

/// Pumps the app and returns its container, so a test can drive the router
/// straight to a route instead of tapping through screens that are still
/// being built.
Future<ProviderContainer> pumpAppWithContainer(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const NovaWalletApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on Home and switches tabs from the bottom bar', (
    tester,
  ) async {
    await pumpApp(tester);

    // The tab screens no longer differ by an AppBar title - NovaSave is being
    // rebuilt and currently looks like Home - so this asserts on what the shell
    // itself believes, which is the thing the route is supposed to drive.
    int selectedTab() =>
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

    expect(selectedTab(), 0);

    await tapAndSettle(
      tester,
      find.widgetWithText(NavigationDestination, 'Save'),
    );
    expect(selectedTab(), 1);

    // The Profile destination is commented out in the shell for now. Restore
    // the third tab here once it is back.
  });

  testWidgets('send flow walks all three steps in one view and ends on a '
      'result screen that cannot go back to Confirm', (tester) async {
    final container = await pumpAppWithContainer(tester);
    container.read(appRouterProvider).go(Routes.send);
    await tester.pumpAndSettle();

    expect(find.text('Step 1 of 3 \u00b7 Recipient'), findsOneWidget);
    // The flow sits outside the shell, so the bottom bar is hidden.
    expect(find.byType(NavigationBar), findsNothing);

    // Picking a recent recipient fills bank, number and name at once.
    await tapAndSettle(tester, find.text('Tunde Bakare'));
    await tapAndSettle(tester, find.text('Continue'));
    expect(find.text('Step 2 of 3 \u00b7 Amount'), findsOneWidget);

    await tapAndSettle(tester, find.text('\u20a65,000.00'));
    await tapAndSettle(tester, find.text('Continue'));
    expect(find.text('Step 3 of 3 \u00b7 Confirm'), findsOneWidget);

    // Stepping back and forward must not mint a second idempotency key: one
    // attempt keeps one key, or a retry would become a second transfer.
    final reference = container.read(sendFlowModelProvider).reference;
    expect(reference, isNotNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3 \u00b7 Amount'), findsOneWidget);
    await tapAndSettle(tester, find.text('Continue'));
    expect(container.read(sendFlowModelProvider).reference, reference);

    await tapAndSettle(tester, find.text('Confirm and send \u20a65,000.00'));
    expect(find.text('Transfer sent'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);

    // System Back from the result goes home, never back to Confirm.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Folake'), findsOneWidget);
    expect(find.text('Step 3 of 3 \u00b7 Confirm'), findsNothing);
  });

  testWidgets(
    'goal detail reads the goal id from the path and covers the tabs',
    (tester) async {
      final container = await pumpAppWithContainer(tester);

      // Driven through the router rather than tapped: the NovaSave screen is
      // being rebuilt and has no goal tile to tap yet, but the route contract -
      // the id comes from the path, and the page covers the tabs - still holds.
      container.read(appRouterProvider).go(Routes.goal('rent-2027'));
      await tester.pumpAndSettle();

      expect(find.text('Goal id: rent-2027'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );
}
