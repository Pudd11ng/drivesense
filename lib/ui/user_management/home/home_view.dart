import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:drivesense/ui/core/widgets/app_bottom_navbar.dart';

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
    return Consumer<MonitoringViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'DriveSense',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: () => _showAddDeviceDialog(context, viewModel),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: _buildFeatureButton(
                        context: context,
                        icon: Icons.car_repair,
                        label: 'Driving\nHistory',
                        onTap: () {
                          //TODO: Navigate to the driving history screen
                        },
                      ),
                    ),
                    _buildFeatureButton(
                      context: context,
                      icon: Icons.notifications_active,
                      label: 'Alert Method',
                      onTap: () {
                        //TODO: Navigate to the alert method screen
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Device',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: viewModel.devices.length,
                    itemBuilder: (context, index) {
                      final device = viewModel.devices[index];
                      return _buildDeviceItem(context, device, viewModel);
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1A237E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(
    BuildContext context,
    Device device,
    MonitoringViewModel viewModel,
  ) {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          device.deviceName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Status : Connected',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, color: Colors.white, size: 30),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDeviceDialog(context, device, viewModel);
                } else if (value == 'remove') {
                  _showRemoveDeviceDialog(context, device, viewModel);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Name'),
                    ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Remove Device'),
                    ),
                  ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDeviceDialog(
    BuildContext context,
    MonitoringViewModel viewModel,
  ) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController ssidController = TextEditingController();
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Device'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'Device ID'),
                ),
                TextField(
                  controller: ssidController,
                  decoration: const InputDecoration(labelText: 'Device SSID'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Device Name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (idController.text.isNotEmpty &&
                      ssidController.text.isNotEmpty &&
                      nameController.text.isNotEmpty) {
                    viewModel.addDevice(
                      Device(
                        deviceId: idController.text,
                        deviceName: nameController.text,
                        deviceSSID: ssidController.text,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditDeviceDialog(
    BuildContext context,
    Device device,
    MonitoringViewModel viewModel,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: device.deviceName,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Device Name'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Device Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    viewModel.updateDeviceName(
                      device.deviceId,
                      nameController.text,
                    );
                    Navigator.pop(context);
                  }
                },
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
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Device'),
            content: Text(
              'Are you sure you want to remove ${device.deviceName}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  viewModel.removeDevice(device.deviceId);
                  Navigator.pop(context);
                },
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}
