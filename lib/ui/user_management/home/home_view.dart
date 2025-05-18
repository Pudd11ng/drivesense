import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    Provider.of<MonitoringViewModel>(context, listen: false).loadDeviceData();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;

    return Consumer<MonitoringViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppHeaderBar(
            title: 'DriveSense',
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
                    size: 28,
                  ),
                  onPressed: () {
                    context.go('/connect_device');
                  },
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Feature buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: _buildFeatureButton(
                        context: context,
                        icon: Icons.history,
                        label: 'Driving\nHistory',
                        isDarkMode: isDarkMode,
                        onTap: () {
                          context.go('/driving_history');
                        },
                      ),
                    ),
                    _buildFeatureButton(
                      context: context,
                      icon: Icons.notifications_active,
                      label: 'Alert\nMethod',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        context.go('/manage_alert');
                      },
                    ),
                  ],
                ),

                // Devices section header
                Padding(
                  padding: const EdgeInsets.only(top: 32, bottom: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.devices,
                        size: 20,
                        color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connected Devices',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Device list
                Expanded(
                  child:
                      viewModel.devices.isEmpty
                          ? _buildEmptyState(isDarkMode)
                          : ListView.builder(
                            itemCount: viewModel.devices.length,
                            itemBuilder: (context, index) {
                              final device = viewModel.devices[index];
                              return _buildDeviceCard(
                                context,
                                device,
                                viewModel,
                                isDarkMode,
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const AppBottomNavBar(currentRoute: '/'),
        );
      },
    );
  }

  Widget _buildFeatureButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    isDarkMode
                        ? [
                          AppColors.blue,
                          AppColors.blue.withValues(alpha: 0.7),
                        ]
                        : [AppColors.darkBlue, AppColors.blue],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackTransparent.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.white, size: 32),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.white : AppColors.darkBlue,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    Device device,
    MonitoringViewModel viewModel,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isDarkMode
                  ? [AppColors.darkBlue, AppColors.blue.withValues(alpha: 0.8)]
                  : [AppColors.darkBlue, AppColors.blue],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackTransparent.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with title and menu
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          device.deviceName,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppColors.white,
                        ),
                        color:
                            isDarkMode ? AppColors.darkGrey : AppColors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditDeviceDialog(
                              context,
                              device,
                              viewModel,
                              isDarkMode,
                            );
                          } else if (value == 'remove') {
                            _showRemoveDeviceDialog(
                              context,
                              device,
                              viewModel,
                              isDarkMode,
                            );
                          }
                        },
                        itemBuilder:
                            (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                      color:
                                          isDarkMode
                                              ? AppColors.white
                                              : AppColors.darkBlue,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Edit Name',
                                      style: TextStyle(
                                        color:
                                            isDarkMode
                                                ? AppColors.white
                                                : AppColors.darkBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remove Device',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ],
                  ),

                  // Status indicator
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            // Check if device SSID matches current WiFi
                            color:
                                viewModel.currentWifiSSID == device.deviceSSID
                                    ? Colors.green
                                    : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          viewModel.currentWifiSSID == device.deviceSSID
                              ? 'Connected'
                              : 'Not Connected',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bottom section with icon and actions
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        color: AppColors.white,
                        size: 34,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'SSID: ${device.deviceSSID}',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Connect/Disconnect Button
                      ElevatedButton(
                        onPressed: () {
                          if (viewModel.currentWifiSSID == device.deviceSSID) {
                            viewModel.disconnectFromWifi().then((success) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Disconnected from device')),
                                );
                              }
                            });
                          } else {
                            context.go('/connect_device/?deviceId=${device.deviceId}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: viewModel.currentWifiSSID == device.deviceSSID 
                              ? Colors.red.withValues(alpha: 0.8) 
                              : AppColors.white,
                          foregroundColor: viewModel.currentWifiSSID == device.deviceSSID 
                              ? AppColors.white 
                              : AppColors.darkBlue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(viewModel.currentWifiSSID == device.deviceSSID 
                            ? 'Disconnect' 
                            : 'Connect'),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Monitor Button (only shown when connected)
                      if (viewModel.currentWifiSSID == device.deviceSSID)
                        ElevatedButton(
                          onPressed: () => context.go('/device/${device.deviceId}'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text('Monitor'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices,
            size: 64,
            color:
                isDarkMode
                    ? AppColors.greyBlue.withValues(alpha: 0.5)
                    : AppColors.greyBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'No devices connected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color:
                  isDarkMode
                      ? AppColors.greyBlue.withValues(alpha: 0.5)
                      : AppColors.greyBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to connect a device',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color:
                  isDarkMode
                      ? AppColors.greyBlue.withValues(alpha: 0.3)
                      : AppColors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.go('/connect_device');
            },
            icon: Icon(Icons.add),
            label: Text('Connect Device'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? AppColors.blue : AppColors.darkBlue,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceDialog(
    BuildContext context,
    Device device,
    MonitoringViewModel viewModel,
    bool isDarkMode,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: device.deviceName,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Device Name'),
            backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Device Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
                    width: 2,
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.darkGrey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    viewModel.updateDeviceName(
                      device.deviceId,
                      nameController.text,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? AppColors.blue : AppColors.darkBlue,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _showRemoveDeviceDialog(
    BuildContext context,
    Device device,
    MonitoringViewModel viewModel,
    bool isDarkMode,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Device'),
            backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Text(
              'Are you sure you want to remove ${device.deviceName}?',
              style: TextStyle(
                color: isDarkMode ? AppColors.white : AppColors.darkGrey,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.darkGrey,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  viewModel.removeDevice(device.deviceId);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}
