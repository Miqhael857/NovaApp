import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/presentation/features/novasave/widgets/goal_widget.dart';
import 'package:novawallet/core/theme/app_color.dart';
import 'package:novawallet/data/local/app_database.dart';
import 'package:novawallet/data/providers.dart';

import 'package:novawallet/presentation/shared/app_scaffold.dart';
import 'package:novawallet/presentation/shared/app_text.dart';

class GoalDetailiew extends ConsumerWidget {
  const GoalDetailiew({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

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
          return GoalWidget(goal: matches.first, queued: queued);
        },
      ),
    );
  }
}
