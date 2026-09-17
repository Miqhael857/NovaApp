import 'package:flutter/material.dart';

import 'package:novawallet/presentation/widgets/placeholder_screen.dart';

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Goal',
      description: 'Goal id: $goalId',
    );
  }
}
