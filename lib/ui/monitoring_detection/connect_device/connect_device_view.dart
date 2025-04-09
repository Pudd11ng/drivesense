import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';

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

      final List<WifiNetwork> networks = await WiFiForIoTPlugin.loadWifiList();

      if (!mounted) return;

      // Filter for DriveSense devices (modify this filter based on your actual device naming convention)
      final driveSenseNetworks =
          networks
              // .where(
              //   (network) =>
              //       network.ssid != null &&
              //       (network.ssid!.toLowerCase().contains('drivesense') ||
              //           network.ssid!.toLowerCase().contains('ds_') ||
              //           network.ssid!.toLowerCase().contains('iot')),
              // )
              .toList();

      // Convert to DeviceWithState objects
      final devicesList =
          driveSenseNetworks.map((network) {
            return _DeviceWithState(
              device: Device(
                deviceId: network.bssid ?? "unknown",
                deviceName: _getDeviceNameFromSSID(network.ssid ?? "unknown"),
                deviceSSID: network.ssid ?? "unknown",
              ),
              signalStrength: _calculateSignalStrength(network.level ?? -80),
              deviceType: _guessDeviceType(network.ssid ?? "unknown"),
              connected: false,
              isConnecting: false,
            );
          }).toList();

      setState(() {
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

  int _calculateSignalStrength(int level) {
    // WiFi levels are typically between -100 dBm (weak) and -30 dBm (strong)
    // Convert to percentage (0-100)
    return ((level + 100) * 2).clamp(0, 100);
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

  String _guessDeviceType(String ssid) {
    final lowerSsid = ssid.toLowerCase();
    if (lowerSsid.contains('camera') || lowerSsid.contains('cam')) {
      return 'Camera';
    } else if (lowerSsid.contains('alert') ||
        lowerSsid.contains('speaker') ||
        lowerSsid.contains('audio')) {
      return 'Speaker';
    } else if (lowerSsid.contains('sensor') || lowerSsid.contains('env')) {
      return 'Environment';
    }
    return 'Unknown';
  }

  Future<void> _connectToDevice(_DeviceWithState deviceWithState) async {
    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);

    setState(() {
      deviceWithState.isConnecting = true;
    });

    try {
      // Try to connect to the WiFi network
      final result = await WiFiForIoTPlugin.connect(
        deviceWithState.device.deviceSSID,
        password:
            "password", // Default password - you might need a way to input this
        security: NetworkSecurity.WPA, // Default security type
        joinOnce: true,
      );

      if (!mounted) return;

      if (result) {
        setState(() {
          // Mark all other devices as not connected
          for (var device in _devices) {
            device.connected = false;
          }

          deviceWithState.connected = true;
          deviceWithState.isConnecting = false;
        });

        viewModel.setConnectedDevice(deviceWithState.device);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${deviceWithState.device.deviceName}'),
            backgroundColor: Colors.green,
          ),
        );
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

        viewModel.removeConnectedDevice(deviceWithState.device);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connect Device',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isScanning)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.red),
              onPressed: _stopScan,
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
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
              ? _buildWifiDisabledView()
              : _permissionDenied
              ? _buildPermissionDeniedView()
              : _errorMessage != null
              ? _buildErrorView()
              : _buildContentView(),
    );
  }

  Widget _buildWifiDisabledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'WiFi is Disabled',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Please enable WiFi to scan for nearby DriveSense devices.',
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
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Enable WiFi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return Column(
      children: [
        if (_isScanning) _buildScanningIndicator(),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _isScanning
                ? 'Searching for nearby DriveSense devices...'
                : _devices.isEmpty
                ? 'No devices found. Tap refresh to scan again.'
                : 'Select a device to connect',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),

        Expanded(
          child:
              _devices.isEmpty && !_isScanning
                  ? _buildEmptyState()
                  : _buildDeviceList(),
        ),
      ],
    );
  }

  Widget _buildScanningIndicator() {
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
                      color: const Color(0xFF1A237E).withOpacity(0.2),
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
                            color: const Color(0xFF1A237E).withOpacity(0.4),
                            width: 2,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A237E).withOpacity(0.1),
                          border: Border.all(
                            color: const Color(0xFF1A237E).withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                      ),
                      RepaintBoundary(
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: ScannerPainter(
                            _animationController.value,
                            const Color(0xFF1A237E),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.wifi_find,
                        size: 28,
                        color: Color(0xFF1A237E),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.device_unknown, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Make sure your DriveSense device is powered on and within range',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startScan,
            icon: const Icon(Icons.refresh),
            label: const Text('Scan Again'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF1A237E),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final deviceWithState = _devices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildDeviceIcon(deviceWithState.deviceType),
            title: Text(
              deviceWithState.device.deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(deviceWithState.deviceType),
                Text(
                  deviceWithState.device.deviceSSID,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                _buildSignalIndicator(deviceWithState.signalStrength),
              ],
            ),
            trailing:
                deviceWithState.isConnecting
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : ElevatedButton(
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
                                ? Colors.white
                                : const Color(0xFF1A237E),
                        side:
                            deviceWithState.connected
                                ? const BorderSide(color: Colors.red)
                                : null,
                      ),
                      child: Text(
                        deviceWithState.connected ? 'Disconnect' : 'Connect',
                      ),
                    ),
          ),
        );
      },
    );
  }

  Widget _buildDeviceIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type.toLowerCase()) {
      case 'camera':
        iconData = Icons.videocam;
        iconColor = Colors.blue;
        break;
      case 'speaker':
        iconData = Icons.volume_up;
        iconColor = Colors.orange;
        break;
      case 'environment':
        iconData = Icons.sensors;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.devices_other;
        iconColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 28),
    );
  }

  Widget _buildSignalIndicator(int strength) {
    Color color;
    int bars;

    if (strength > 80) {
      color = Colors.green;
      bars = 4;
    } else if (strength > 60) {
      color = Colors.lime;
      bars = 3;
    } else if (strength > 40) {
      color = Colors.orange;
      bars = 2;
    } else {
      color = Colors.red;
      bars = 1;
    }

    return Row(
      children: [
        Icon(Icons.signal_wifi_4_bar, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          '$bars/4 · ${strength}%',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              'Location Permission Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Location permission is required to scan for nearby WiFi networks and devices.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermissionsAndStartScan,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 72, color: Colors.red[300]),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error occurred.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkWiFiStatus,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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
      colors: [color.withOpacity(0), color.withOpacity(0.5)],
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

// Helper class to combine the Device model with UI state
class _DeviceWithState {
  final Device device;
  final String deviceType;
  final int signalStrength;
  bool connected;
  bool isConnecting;

  _DeviceWithState({
    required this.device,
    required this.deviceType,
    required this.signalStrength,
    this.connected = false,
    this.isConnecting = false,
  });
}
