import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

final List<Map<String, dynamic>> alertMethods = [
  {'name': 'Alarm', 'hasExtraConfig': false, 'icon': Icons.alarm},
  {'name': 'Audio', 'hasExtraConfig': true, 'icon': Icons.volume_up},
  {
    'name': 'Self-Configured Audio',
    'hasExtraConfig': true,
    'icon': Icons.settings_voice,
  },
  {'name': 'Music', 'hasExtraConfig': true, 'icon': Icons.music_note},
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
    Future.microtask(() {
      final viewModel = Provider.of<AlertViewModel>(context, listen: false);
      if (!viewModel.hasAlert) {
        viewModel.loadAlert();
      }
    });
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
            onLeadingPressed: () => context.go('/'),
          ),
          body: _buildBody(context, viewModel, isDarkMode, textColor),
          bottomNavigationBar: const AppBottomNavBar(
            currentRoute: '/manage_alert',
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AlertViewModel viewModel,
    bool isDarkMode,
    Color textColor,
  ) {
    // Show loading state
    if (viewModel.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading alert settings...',
              style: TextStyle(color: textColor),
            ),
          ],
        ),
      );
    }

    // Show error state
    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error Loading Alerts',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.errorMessage!,
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => viewModel.loadAlert(),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? AppColors.blue : AppColors.darkBlue,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show state when no alert data is available
    if (!viewModel.hasAlert) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off,
                size: 64,
                color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No Alert Data',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No alert configuration found',
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => viewModel.loadAlert(),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? AppColors.blue : AppColors.darkBlue,
                ),
                child: Text('Load Alerts'),
              ),
            ],
          ),
        ),
      );
    }

    // Main content when alert data is available
    return SingleChildScrollView(
      // Prevent overflow
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDarkMode
                        ? AppColors.blue.withValues(alpha: 0.2)
                        : AppColors.blue.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isDarkMode
                              ? AppColors.blue.withValues(alpha: 0.2)
                              : AppColors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alert Methods',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose how you want to be alerted',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                isDarkMode
                                    ? AppColors.greyBlue
                                    : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Alert methods list
            _buildAlertMethodsList(viewModel, context, isDarkMode),
          ],
        ),
      ),
    );
  }

  // Update the onTap handler in _buildAlertMethodsList
  Widget _buildAlertMethodsList(
    AlertViewModel viewModel,
    BuildContext context,
    bool isDarkMode,
  ) {
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;
    final backgroundColor = isDarkMode ? AppColors.darkGrey : Colors.white;
    final borderColor =
        isDarkMode
            ? AppColors.greyBlue.withValues(alpha: 0.2)
            : AppColors.lightGrey;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: alertMethods.length,
          separatorBuilder:
              (context, index) =>
                  Divider(color: borderColor, height: 1, thickness: 0.5),
          itemBuilder: (context, index) {
            final alert = alertMethods[index];
            // Safe access to alert data
            final bool isSelected =
                viewModel.hasAlert &&
                alert['name'] == viewModel.alert?.alertTypeName;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                minLeadingWidth: 40,
                leading: Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? accentColor.withValues(alpha: 0.2)
                            : accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    alert['icon'] as IconData,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  alert['name'],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? AppColors.white : AppColors.black,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  if (viewModel.hasAlert) {
                    final alertName = alert['name'];

                    // Only add validation for Self-Configured Audio and Music
                    if (alertName == 'Self-Configured Audio' ||
                        alertName == 'Music') {
                      // Check if all behaviors have non-empty configurations
                      bool allConfigured = true;
                      String? missingBehavior;

                      for (String behavior in [
                        'Drowsiness',
                        'Distraction',
                        'Intoxication',
                        'Phone Usage',
                      ]) {
                        Map<String, dynamic>? behaviorData;

                        if (alertName == 'Self-Configured Audio') {
                          behaviorData =
                              viewModel.alert?.audioFilePath[behavior];
                        } else {
                          // Music
                          behaviorData =
                              viewModel.alert?.musicPlayList[behavior];
                        }

                        // Check if the data exists and has non-empty name and path
                        if (behaviorData == null ||
                            behaviorData['name'] == null ||
                            behaviorData['name'].isEmpty ||
                            behaviorData['path'] == null ||
                            behaviorData['path'].isEmpty) {
                          allConfigured = false;
                          missingBehavior = behavior;
                          break;
                        }
                      }

                      if (!allConfigured) {
                        // Show message and redirect to config
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please configure audio for $missingBehavior',
                            ),
                            backgroundColor: Colors.orange,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );

                        // Navigate to config screen
                        Future.delayed(const Duration(milliseconds: 500), () {
                          context.go('/extra_config/?alertTypeName=$alertName');
                        });
                        return;
                      }
                    }

                    // If validation passes or not needed, update the alert
                    viewModel.updateAlert(alertName);
                  }
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: 14),
                      ),
                    if (alert['hasExtraConfig'])
                      Container(
                        margin: EdgeInsets.only(left: isSelected ? 12 : 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              context.go(
                                '/extra_config/?alertTypeName=${alert['name']}',
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.settings,
                                  color: accentColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Configure',
                                  style: TextStyle(
                                    color: accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
