import 'package:flutter/material.dart';

import 'package:novawallet/presentation/widgets/placeholder_screen.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Transfer details',
      description: 'Status, reference and failure reason for $id go here.',
    );
  }
}
