import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:novawallet/presentation/widgets/placeholder_screen.dart';

class CreateGoalScreen extends StatelessWidget {
  const CreateGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Create a goal',
      description: 'Goal name, target amount and target date go here.',
      actions: [PlaceholderAction('Create goal', () => context.pop())],
    );
  }
}
