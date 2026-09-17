import 'package:flutter/material.dart';

import 'package:novawallet/presentation/widgets/placeholder_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Profile',
      automaticallyImplyLeading: false,
      description: 'Account details and the debug "Simulate offline" switch go here.',
    );
  }
}
