import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

final List<Map<String, dynamic>> alertMethods = [
  {'name': 'Alarm (Default)', 'hasExtraConfig': false, 'icon': Icons.alarm},
  {'name': 'Audio', 'hasExtraConfig': true, 'icon': Icons.volume_up},
  {
    'name': 'Self-Configured Audio',
    'hasExtraConfig': true,
    'icon': Icons.settings_voice,
  },
  {'name': 'Music', 'hasExtraConfig': true, 'icon': Icons.music_note},
  {'name': 'AI Chatbot', 'hasExtraConfig': false, 'icon': Icons.smart_toy},
];

class ManageAlertView extends StatefulWidget {
  const ManageAlertView({super.key});

  @override
  State<ManageAlertView> createState() => _ManageAlertViewState();
}

class _ManageAlertViewState extends State<ManageAlertView> {
  @override
  void initState() {
    super.initState();
    Provider.of<AlertViewModel>(context, listen: false).loadAlertData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;

    return Consumer<AlertViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppHeaderBar(
            title: 'Alert Method',
            leading: Icon(Icons.arrow_back),
            onLeadingPressed: () => context.pop(),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alert Methods',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to be alerted when drowsiness is detected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                _buildAlertMethodsList(viewModel, context, isDarkMode),
              ],
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(
            currentRoute: '/manage_alert',
          ),
        );
      },
    );
  }

  Widget _buildAlertMethodsList(
    AlertViewModel viewModel,
    BuildContext context,
    bool isDarkMode,
  ) {
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkBlue.withAlpha(150) : accentColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: alertMethods.length,
        separatorBuilder:
            (context, index) => Divider(
              color: AppColors.white.withAlpha(60),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
        itemBuilder: (context, index) {
          final alert = alertMethods[index];
          final isSelected = alert['name'] == viewModel.alert.alertTypeName;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                alert['icon'] as IconData,
                color: AppColors.white,
                size: 22,
              ),
            ),
            title: Text(
              alert['name'],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            onTap: () {
              viewModel.updateAlert(alert['name']).then((success) {
                // Let the framework handle the UI update
              });
            },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: accentColor, size: 14),
                  ),
                if (alert['hasExtraConfig'])
                  Padding(
                    padding: EdgeInsets.only(left: isSelected ? 16 : 0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: AppColors.white,
                      ),
                      onPressed: () {
                        context.go(
                          '/extra_config/?alertTypeName=${alert['name']}',
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
