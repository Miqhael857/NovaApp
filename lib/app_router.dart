import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novawallet/presentation/features/send/send_view.dart';
import 'package:novawallet/presentation/shared/app_navigation_layout.dart';

import 'package:novawallet/routes.dart';
import 'package:novawallet/presentation/features/activity/activity_detail_screen.dart';
import 'package:novawallet/presentation/features/novasave/create_goal_view.dart';
import 'package:novawallet/presentation/features/novasave/goal_detail_view.dart';
import 'package:novawallet/presentation/features/novasave/nova_save_goal_view.dart';
import 'package:novawallet/presentation/features/send/send_amount_view.dart';
import 'package:novawallet/presentation/features/send/send_confirm_view.dart';
import 'package:novawallet/presentation/features/send/send_result_view.dart';
import 'package:novawallet/presentation/features/wallethome/wallet_home_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final shellKey = GlobalKey<NavigatorState>();

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.home,
    routes: [
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) => AppNavigationLayout(child: child),
        routes: [
          GoRoute(
            parentNavigatorKey: shellKey,
            path: Routes.home,
            name: RouteNames.home,
            builder: (context, state) => const WalletHomeScreen(),
          ),
          GoRoute(
            parentNavigatorKey: shellKey,
            path: Routes.save,
            name: RouteNames.save,
            builder: (context, state) => const NovaSaveGoalView(),
            routes: [
              // 'new' is listed before ':goalId' so it is not read as a goal id.
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                path: 'new',
                name: RouteNames.newGoal,
                builder: (context, state) => const CreateGoalView(),
              ),
              GoRoute(
                parentNavigatorKey: rootNavigatorKey,
                path: ':goalId',
                name: RouteNames.goal,
                builder: (context, state) =>
                    GoalDetailiew(goalId: state.pathParameters['goalId']!),
              ),
            ],
          ),
          // GoRoute(
          //   parentNavigatorKey: shellKey,
          //   path: Routes.profile,
          //   name: RouteNames.profile,
          //   builder: (context, state) => const ProfileScreen(),
          // ),
        ],
      ),

      // Send Money sits outside the shell so the bottom bar is hidden during
      // the flow. Its data (recipient, amount, idempotency key) will live in a
      // Riverpod notifier rather than `extra`, so it survives Android
      // restarting the app and does not depend on how a page was reached.
      GoRoute(
        path: Routes.send,
        name: RouteNames.sendRecipient,
        builder: (context, state) => const SendView(),
        routes: [
          GoRoute(
            path: 'amount',
            name: RouteNames.sendAmount,
            builder: (context, state) => const SendAmountView(),
          ),
          GoRoute(
            path: 'confirm',
            name: RouteNames.sendConfirm,
            builder: (context, state) => const SendConfirmView(),
          ),

          // GoRoute(
          //   path: 'result',
          //   name: RouteNames.sendResult,
          //   builder: (context, state) => const SendResultView(),
          // ),
        ],
      ),

      GoRoute(
        path: Routes.sendResult,
        name: RouteNames.sendResult,
        builder: (context, state) => const SendResultView(),
      ),
      GoRoute(
        path: '/activity/:id',
        name: RouteNames.activity,
        builder: (context, state) =>
            ActivityDetailScreen(id: state.pathParameters['id']!),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
