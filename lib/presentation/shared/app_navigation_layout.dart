import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:novawallet/routes.dart';

class AppNavigationLayout extends StatelessWidget {
  const AppNavigationLayout({super.key, required this.child});

  final Widget child;

  static const _tabNames = [
    RouteNames.home,
    RouteNames.save,
    RouteNames.profile,
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.save)) return 1;
    // if (location.startsWith(Routes.profile)) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => context.goNamed(_tabNames[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings),
            label: 'Save',
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.person_outline),
          //   selectedIcon: Icon(Icons.person),
          //   label: 'Profile',
          // ),
        ],
      ),
    );
  }
}
