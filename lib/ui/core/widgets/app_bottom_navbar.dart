import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends StatelessWidget {
  final String currentRoute;

  const AppBottomNavBar({super.key, this.currentRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF8C9EF0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              if (currentRoute != '/') {
                context.go('/');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              if (currentRoute != '/profile') {
                context.go('/profile');
              }
            },
          ),
        ],
      ),
    );
  }
}
