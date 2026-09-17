import 'package:flutter/material.dart';
import 'package:novawallet/presentation/shared/app_scaffold.dart';

class ActivityDetailScreen extends StatelessWidget {
  const ActivityDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(body: Column(children: []));
  }
}
