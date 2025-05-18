import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class AppBottomNavBar extends StatelessWidget {
  final String currentRoute;

  const AppBottomNavBar({super.key, this.currentRoute = '/'});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 54.0,
      padding: EdgeInsets.zero,
      elevation: 8.0,
      notchMargin: 8.0,
      color: AppColors.lightPurple,
      surfaceTintColor: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            route: '/',
            isActive: currentRoute == '/',
          ),
          _buildNavItem(
            context: context,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            route: '/settings',
            isActive: currentRoute == 'settings'
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String route,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        if (!isActive) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.white : AppColors.white.withValues(alpha:0.7),
          size: 36,
        ),
      ),
    );
  }
}
