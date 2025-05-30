import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:wifi_scan/wifi_scan.dart';

class ConnectDeviceView extends StatefulWidget {
  const ConnectDeviceView({super.key});

  @override
  State<ConnectDeviceView> createState() => _ConnectDeviceViewState();
}

class _ConnectDeviceViewState extends State<ConnectDeviceView>
    with SingleTickerProviderStateMixin {
  final List<_DeviceWithState> _devices = [];
  bool _isScanning = false;
  bool _permissionDenied = false;
  String? _errorMessage;
  bool _isEnabled = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);
    viewModel.refreshWifiConnection();

    _checkWiFiStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scanTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkWiFiStatus() async {
    try {
      final isEnabled = await WiFiForIoTPlugin.isEnabled();
      setState(() {
        _isEnabled = isEnabled;
      });

      if (_isEnabled) {
        _checkPermissionsAndStartScan();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking WiFi status: $e';
      });
    }
  }

  Future<void> _checkPermissionsAndStartScan() async {
    final locationStatus = await Permission.location.request();

    if (locationStatus.isGranted) {
      _startScan();
    } else {
      setState(() {
        _permissionDenied = true;
      });
    }
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _devices.clear();
    });

    _animationController.repeat();

    _scanForDevices();

    // Set timeout for scanning
    _scanTimer = Timer(const Duration(seconds: 10), () {
      _stopScan();
    });
  }

  void _stopScan() {
    if (!mounted) return;

    setState(() {
      _isScanning = false;
    });

    _animationController.stop();
    _scanTimer?.cancel();
  }

  Future<void> _scanForDevices() async {
    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);

    if (!viewModel.canStartWifiScan()) {
      setState(() {
        _isScanning = false;
        _animationController.stop();

        final remainingSeconds =
            viewModel.nextAvailableScanTime!
                .difference(DateTime.now())
                .inSeconds;

        _errorMessage =
            'WiFi scanning limited by Android. '
            'Please wait ${remainingSeconds > 0 ? remainingSeconds : 0} seconds before scanning again.';
      });
      return;
    }

    try {
      if (!_isEnabled) {
        // Try to enable WiFi if it's not enabled
        await WiFiForIoTPlugin.setEnabled(true);
        await Future.delayed(const Duration(seconds: 1));

        final isEnabled = await WiFiForIoTPlugin.isEnabled();
        if (!isEnabled) {
          throw Exception('WiFi could not be enabled');
        }

        setState(() {
          _isEnabled = true;
        });
      }

      viewModel.scanTimes.add(DateTime.now());

      // Get a WiFiScan instance
      final wifiScan = WiFiScan.instance;

      // Check if can scan
      final canScan = await wifiScan.canStartScan();
      if (canScan != CanStartScan.yes) {
        throw Exception('Cannot scan for networks: ${canScan.toString()}');
      }

      // Start scan
      final result = await wifiScan.startScan();
      if (!result) {
        throw Exception('Failed to start scan');
      }

      // Get scan results
      final scanResults = await wifiScan.getScannedResults();

      if (!mounted) return;

      final driveSenseNetworks =
          scanResults
              .where(
                (network) =>
                    network.ssid.isNotEmpty &&
                    (network.ssid.toLowerCase().contains(
                      'drivesense_camera_ds',
                    )),
              )
              .toList();

      // Convert to DeviceWithState objects
      final devicesList =
          driveSenseNetworks.map((network) {
            return _DeviceWithState(
              device: Device(
                deviceId: network.bssid,
                deviceName: _getDeviceNameFromSSID(network.ssid),
                deviceSSID: network.ssid,
              ),
              connected: false,
              isConnecting: false,
            );
          }).toList();

      setState(() {
        _devices.clear();
        _devices.addAll(devicesList);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error scanning for devices: $e';
        _isScanning = false;
      });

      _animationController.stop();
    }
  }

  String _getDeviceNameFromSSID(String ssid) {
    // Extract a friendly name from SSID
    // Example: "DriveSense_Camera_001" -> "DriveSense Camera"
    final parts = ssid.split('_');
    if (parts.length > 1) {
      return "${parts[0]} ${parts[1]}";
    }
    return ssid;
  }

  Future<void> _connectToDevice(_DeviceWithState deviceWithState) async {
    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);

    final password = await _showPasswordDialog(
      deviceWithState.device.deviceSSID,
    );

    if (password == null) {
      return;
    }

    setState(() {
      deviceWithState.isConnecting = true;
    });

    try {
      final result = await WiFiForIoTPlugin.connect(
        deviceWithState.device.deviceSSID,
        password: password,
        security: NetworkSecurity.WPA,
        joinOnce: true,
      );

      if (!mounted) return;

      if (result) {
        setState(() {
          for (var device in _devices) {
            device.connected = false;
          }

          deviceWithState.connected = true;
          deviceWithState.isConnecting = false;
        });

        // Wait briefly for connection to establish
        await Future.delayed(const Duration(milliseconds: 1000));
        await viewModel.refreshWifiConnection();

        // Check if this device is already registered in our backend
        final existingDevice = viewModel.devices.firstWhere(
          (d) => d.deviceSSID == deviceWithState.device.deviceSSID,
          orElse: () => Device(deviceId: '', deviceSSID: '', deviceName: ''),
        );

        if (existingDevice.deviceId.isNotEmpty) {
          // Device already exists in our registry, just set as connected
          viewModel.setConnectedDevice(existingDevice);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${existingDevice.deviceName}'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to device view with existing device
          if (mounted) {
            context.go('/device/${existingDevice.deviceId}');
          }
        } else {
          // This is a new device, show dialog to get name
          final deviceName = await _showDeviceNameDialog(
            deviceWithState.device.deviceSSID,
          );

          if (!mounted) return;

          if (deviceName == null || deviceName.trim().isEmpty) {
            // User cancelled naming, but keep connected
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connected to unnamed device'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // Create new device with the given name
          final newDevice = Device(
            deviceId: "", // Backend will assign ID
            deviceSSID: deviceWithState.device.deviceSSID,
            deviceName: deviceName.trim(),
          );

          // Show loading indicator
          final loadingOverlay = _showLoadingOverlay('Adding device...');

          // Add device to backend
          final success = await viewModel.addDevice(newDevice);

          // Dismiss loading overlay
          loadingOverlay.remove();

          if (!mounted) return;

          if (success) {
            // Reload devices to get the updated list with the new device
            await viewModel.loadDeviceData();

            // Find the newly added device in the updated list
            final addedDevice = viewModel.devices.firstWhere(
              (d) => d.deviceSSID == deviceWithState.device.deviceSSID,
              orElse: () => newDevice,
            );

            // Set as connected device
            viewModel.setConnectedDevice(addedDevice);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added device "$deviceName"'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to device view with newly added device
            if (mounted) {
              context.go('/device/${addedDevice.deviceId}');
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add device: ${viewModel.error}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        throw Exception('Connection failed');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        deviceWithState.isConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showPasswordDialog(String networkName) async {
    final TextEditingController passwordController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('WiFi Password'),
            backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter password for "$networkName"',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  obscureText: true,
                  autofocus: true,
                ),
              ],
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
                onPressed:
                    () => Navigator.pop(context, passwordController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Connect'),
              ),
            ],
          ),
    );
  }

  Future<String?> _showDeviceNameDialog(String ssid) async {
    final TextEditingController nameController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    // Auto-populate with a suggested name
    final suggestedName = ssid.replaceAll(
      'DriveSense_Camera_',
      'DriveSense Camera ',
    );
    nameController.text = suggestedName;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'New Device Found',
              style: TextStyle(
                color: isDarkMode ? AppColors.white : AppColors.black,
              ),
            ),
            backgroundColor: isDarkMode ? AppColors.black : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This device is not registered yet. Please provide a name for your new DriveSense device:',
                  style: TextStyle(
                    color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Device Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                  autofocus: true,
                ),
              ],
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
                onPressed: () => Navigator.pop(context, nameController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Device'),
              ),
            ],
          ),
    );
  }

  OverlayEntry _showLoadingOverlay(String message) {
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Container(
            color: Colors.black54,
            alignment: Alignment.center,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(message),
                  ],
                ),
              ),
            ),
          ),
    );

    // Insert the overlay
    Overlay.of(context)?.insert(overlayEntry);
    return overlayEntry;
  }

  Future<void> _disconnectFromDevice(_DeviceWithState deviceWithState) async {
    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);

    setState(() {
      deviceWithState.isConnecting = true;
    });

    try {
      // Disconnect from the WiFi network
      final result = await WiFiForIoTPlugin.disconnect();

      if (!mounted) return;

      if (result) {
        setState(() {
          deviceWithState.connected = false;
          deviceWithState.isConnecting = false;
        });

        viewModel.removeConnectedDevice();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Disconnected from ${deviceWithState.device.deviceName}',
            ),
          ),
        );
      } else {
        throw Exception('Disconnection failed');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        deviceWithState.isConnecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppHeaderBar(
        title: 'Connect Device',
        leading: Icon(Icons.arrow_back),
        onLeadingPressed: () => context.go('/'),
        actions: [
          if (_isScanning)
            IconButton(
              icon: Icon(Icons.stop, color: Colors.red),
              onPressed: _stopScan,
            )
          else
            IconButton(
              icon: Icon(Icons.refresh, color: accentColor),
              onPressed:
                  _isEnabled
                      ? (_permissionDenied
                          ? _checkPermissionsAndStartScan
                          : _startScan)
                      : _checkWiFiStatus,
            ),
        ],
      ),
      body:
          !_isEnabled
              ? _buildWifiDisabledView(isDarkMode, accentColor)
              : _permissionDenied
              ? _buildPermissionDeniedView(isDarkMode, accentColor)
              : _errorMessage != null
              ? _buildErrorView(isDarkMode, accentColor)
              : _buildContentView(isDarkMode, accentColor, textColor),
    );
  }

  Widget _buildWifiDisabledView(bool isDarkMode, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 72,
              color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'WiFi is Disabled',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please enable WiFi to scan for nearby DriveSense devices.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                try {
                  await WiFiForIoTPlugin.setEnabled(true);
                  _checkWiFiStatus();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to enable WiFi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: AppColors.white,
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Enable WiFi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(
    bool isDarkMode,
    Color accentColor,
    Color textColor,
  ) {
    return Column(
      children: [
        if (_isScanning) _buildScanningIndicator(isDarkMode, accentColor),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _isScanning
                ? 'Searching for nearby DriveSense devices...'
                : _devices.isEmpty
                ? 'No devices found. Tap refresh to scan again.'
                : 'Select a device to connect',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child:
              _devices.isEmpty && !_isScanning
                  ? _buildEmptyState(isDarkMode, accentColor)
                  : _buildDeviceList(isDarkMode, accentColor),
        ),
      ],
    );
  }

  Widget _buildScanningIndicator(bool isDarkMode, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withAlpha(51),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentColor.withAlpha(102),
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withAlpha(25),
                          border: Border.all(
                            color: accentColor.withAlpha(153),
                            width: 2,
                          ),
                        ),
                      ),
                      RepaintBoundary(
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: ScannerPainter(
                            _animationController.value,
                            accentColor,
                          ),
                        ),
                      ),
                      Icon(Icons.wifi_find, size: 28, color: accentColor),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.device_unknown,
            size: 80,
            color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDarkMode ? AppColors.white : AppColors.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Make sure your DriveSense device is powered on and within range',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(bool isDarkMode, Color accentColor) {
    final cardColor =
        isDarkMode ? AppColors.darkGrey.withAlpha(77) : AppColors.white;
    final viewModel = Provider.of<MonitoringViewModel>(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final deviceWithState = _devices[index];

        // Check if this device matches the current WiFi connection
        final isCurrentlyConnected =
            deviceWithState.device.deviceSSID == viewModel.currentWifiSSID;

        // Update our local state to match actual WiFi state
        if (deviceWithState.connected != isCurrentlyConnected) {
          // This is just updating our UI state, not actually connecting/disconnecting
          deviceWithState.connected = isCurrentlyConnected;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.blackTransparent.withAlpha(
                  isDarkMode ? 51 : 25,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Icon(
              Icons.wifi,
              color:
                  deviceWithState.connected
                      ? Colors.green
                      : (isDarkMode ? AppColors.blue : AppColors.darkBlue),
              size: 28,
            ),
            title: Text(
              deviceWithState.device.deviceSSID,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.white : AppColors.black,
              ),
            ),
            subtitle: Text(
              deviceWithState.connected ? 'Connected' : 'Not connected',
              style: TextStyle(
                color:
                    deviceWithState.connected
                        ? Colors.green
                        : (isDarkMode ? AppColors.greyBlue : AppColors.grey),
                fontSize: 13,
              ),
            ),
            trailing:
                deviceWithState.isConnecting
                    ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    )
                    : SizedBox(
                      height: 32, // Smaller height
                      width: 85, // Fixed width for consistency
                      child: ElevatedButton(
                        onPressed: () {
                          if (deviceWithState.connected) {
                            _disconnectFromDevice(deviceWithState);
                          } else {
                            _connectToDevice(deviceWithState);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              deviceWithState.connected
                                  ? Colors.red
                                  : Colors.white,
                          backgroundColor:
                              deviceWithState.connected
                                  ? Colors.transparent
                                  : accentColor,
                          side:
                              deviceWithState.connected
                                  ? const BorderSide(color: Colors.red)
                                  : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          deviceWithState.connected ? 'Disconnect' : 'Connect',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionDeniedView(bool isDarkMode, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_disabled,
              size: 72,
              color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              'Location Permission Required',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Location permission is required to scan for nearby WiFi networks and devices.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermissionsAndStartScan,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(bool isDarkMode, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 72, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error occurred.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkWiFiStatus,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom scanner animation
class ScannerPainter extends CustomPainter {
  final double progress;
  final Color color;

  ScannerPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Create gradient for the scanning effect
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: progress * 2 * 3.14159,
      colors: [color.withAlpha(0), color.withAlpha(127)],
      stops: const [0.0, 1.0],
    );

    final paint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    canvas.drawArc(rect, 0, progress * 2 * 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(ScannerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Helper class
class _DeviceWithState {
  final Device device;
  bool connected;
  bool isConnecting;

  _DeviceWithState({
    required this.device,
    this.connected = false,
    this.isConnecting = false,
  });
}
