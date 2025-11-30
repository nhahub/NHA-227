import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medilink_app/shared/widgets/bottom_nav_bar.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndexFromLocation(String loc) {
    if (loc.startsWith('/orders')) return 1;
    if (loc.startsWith('/cart')) return 2;
    return 0; // default home
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _currentIndexFromLocation(location);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavBar(
        currentIndex: index,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/orders');
              break;
            case 2:
              context.go('/cart');
              break;
          }
        },
      ),
    );
  }
}
