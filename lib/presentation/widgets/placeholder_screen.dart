import 'package:flutter/material.dart';

/// Temporary screen used while the routes are wired up. Each feature replaces
/// its placeholder with the real screen from the design.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
    this.automaticallyImplyLeading = true,
  });

  final String title;
  final String? description;
  final List<PlaceholderAction> actions;
  final bool automaticallyImplyLeading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: automaticallyImplyLeading,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (description != null) Text(description!),
          for (final action in actions) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: action.onPressed, child: Text(action.label)),
          ],
        ],
      ),
    );
  }
}

class PlaceholderAction {
  const PlaceholderAction(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}
