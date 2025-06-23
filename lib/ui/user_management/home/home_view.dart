import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:drivesense/ui/user_management/view_model/user_management_view_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<MonitoringViewModel>(
        context,
        listen: false,
      );
      viewModel.loadDeviceData();
      viewModel.refreshWifiConnection();
    });
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureButton(
                      context: context,
                      icon: Icons.history,
                      label: 'Driving\nHistory',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        context.go('/driving_history');
                      },
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
                    _buildFeatureButton(
                      context: context,
                      icon: Icons.contact_emergency,
                      label: 'Emergency\nContacts',
                      isDarkMode: isDarkMode,
                      onTap: () {
                        context.go('/emergency_contact');
                      },
                    ),

                    // Add as the last button in the row
                    Consumer<UserManagementViewModel>(
                      builder: (context, userViewModel, _) {
                        return Stack(
                          children: [
                            _buildFeatureButton(
                              context: context,
                              icon: Icons.notifications,
                              label: 'Notifi-\ncations',
                              isDarkMode: isDarkMode,
                              onTap: () {
                                context.go('/notifications');
                              },
                            ),
                            if (userViewModel.unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      userViewModel.unreadCount > 99
                                          ? '99+'
                                          : '${userViewModel.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
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
    final isConnected = viewModel.currentWifiSSID == device.deviceSSID;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isConnected
                  ? (isDarkMode
                      ? [AppColors.blue, Color(0xFF1E3A5F)]
                      : [AppColors.blue, AppColors.darkBlue])
                  : (isDarkMode
                      ? [Color(0xFF2D3748), Color(0xFF1A202C)]
                      : [Color(0xFF64748B), Color(0xFF334155)]),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isConnected ? AppColors.blue : AppColors.blackTransparent)
                .withValues(alpha: isDarkMode ? 0.2 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (isConnected) {
              context.go('/device/${device.deviceId}');
            } else {
              context.go('/connect_device');
            }
          },
          splashColor: AppColors.white.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                right: -45,
                top: -10,
                child: Opacity(
                  opacity: 0.08,
                  child: Icon(
                    Icons.directions_car_outlined,
                    size: 120,
                    color: AppColors.white,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row with connection status
                    Row(
                      children: [
                        // Status icon pulsing if connected
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? Colors.green : Colors.orange,
                            boxShadow:
                                isConnected
                                    ? [
                                      BoxShadow(
                                        color: Colors.green.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'CONNECTED' : 'DISCONNECTED',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.white,
                          ),
                          color:
                              isDarkMode ? AppColors.darkGrey : AppColors.white,
                          elevation: 3,
                          position: PopupMenuPosition.under,
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

                    const SizedBox(height: 14),

                    // Device name and model section
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.videocam,
                            color: AppColors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.deviceName,
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'DriveSense Camera',
                                style: TextStyle(
                                  color: AppColors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bottom info section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blackTransparent.withValues(
                          alpha: 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // SSID info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEVICE ID',
                                  style: TextStyle(
                                    color: AppColors.white.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  device.deviceSSID,
                                  style: TextStyle(
                                    color: AppColors.white.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Action button
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isConnected
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isConnected ? Icons.monitor : Icons.wifi,
                                  color: AppColors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isConnected ? 'MONITOR' : 'CONNECT',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
