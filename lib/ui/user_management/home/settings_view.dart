import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.lightGrey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppHeaderBar(title: 'Settings'),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Account Section
          _buildSectionHeader(context, 'Account', isDarkMode),
          _buildSettingsGroup(context, [
            _buildSettingItem(
              context: context,
              icon: Icons.person,
              iconBackgroundColor: AppColors.grey,
              title: 'Profile',
              subtitle: 'View and edit your profile',
              isDarkMode: isDarkMode,
              showDivider: false,
              onTap: () => context.go('/profile'),
            ),
          ], isDarkMode),

          const SizedBox(height: 20),

          // Support Section
          _buildSectionHeader(context, 'Support', isDarkMode),
          _buildSettingsGroup(context, [
            _buildSettingItem(
              context: context,
              icon: Icons.logout,
              iconBackgroundColor: AppColors.grey,
              title: 'Log Out',
              subtitle: 'Sign out from your account',
              isDarkMode: isDarkMode,
              showDivider: false,
              isDestructive: true,
              onTap: () => _showLogoutConfirmation(context),
            ),
          ], isDarkMode),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/settings'),
    );
  }

  Widget _buildSettingsGroup(
    BuildContext context,
    List<Widget> items,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBackgroundColor,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required VoidCallback onTap,
    bool showDivider = true,
    bool isDestructive = false,
  }) {
    final Color textColor =
        isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconBackgroundColor, size: 20),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            color:
                isDarkMode
                    ? AppColors.greyBlue.withValues(alpha: 0.9)
                    : AppColors.whiteGrey,
            height: 1,
            indent: 68,
            endIndent: 16,
          ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.darkGrey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final viewModel = Provider.of<UserManagementViewModel>(
                    context,
                    listen: false,
                  );
                  await viewModel.logout(); // Await logout to ensure token is cleared
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}
