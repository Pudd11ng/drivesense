import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drivesense/ui/monitoring_detection/device/mjpeg_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:drivesense/utils/network_binder.dart';

class DeviceView extends StatefulWidget {
  final String? deviceId;

  const DeviceView({super.key, this.deviceId});

  @override
  State<DeviceView> createState() => _DeviceViewState();
}

class _DeviceViewState extends State<DeviceView> with WidgetsBindingObserver {
  Device? _device;
  bool _isLoading = true;
  String? _errorMessage;
  String? _streamUrl;

  // Stream control
  bool _isStreaming = false;
  StreamController<void>? _streamController;
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Enable wakelock to prevent screen from turning off
    WakelockPlus.enable();

    // Initialize the connection check timer
    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnection(),
    );

    // Initialize the device and stream
    _initializeDeviceAndStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectionCheckTimer?.cancel();
    _stopStream();
    WakelockPlus.disable();
    NetworkBinder.unbind().catchError(
      (e) => debugPrint('Error unbinding network: $e'),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // Pause stream when app is in background
      _pauseStream();
    } else if (state == AppLifecycleState.resumed) {
      // Resume stream when app is back in foreground
      if (_streamUrl != null) {
        _resumeStream();
      }
    }
  }

  void _pauseStream() {
    if (_isStreaming) {
      setState(() {
        _isStreaming = false;
      });
      _stopStream();
    }
  }

  void _resumeStream() {
    if (!_isStreaming && _streamUrl != null) {
      _startStream();
      setState(() {
        _isStreaming = true;
      });
    }
  }

  void _stopStream() {
    _streamController?.close();
    _streamController = null;
  }

  void _startStream() {
    _stopStream(); // Close existing if any
    _streamController = StreamController<void>();
  }

  void _toggleStream() {
    if (_isStreaming) {
      _pauseStream();
    } else {
      _resumeStream();
    }
  }

  Future<void> _initializeDeviceAndStream() async {
    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);

    await NetworkBinder.bindWifi();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Wait for device data to load if needed
    if (viewModel.devices.isEmpty) {
      await viewModel.loadDeviceData();
    }

    // Determine which device to use
    Device? targetDevice;

    // If deviceId is provided, find device by ID
    if (widget.deviceId != null) {
      targetDevice = viewModel.devices.firstWhere(
        (d) => d.deviceId == widget.deviceId,
        orElse:
            () => Device(
              deviceId: '',
              deviceSSID: '',
              deviceName: 'Unknown Device',
            ),
      );
    }

    // If no device found by ID, use the currently connected WiFi device
    targetDevice ??= viewModel.connectedDevice;

    _device = targetDevice;

    if (_device == null || _device!.deviceId.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No connected device found. Please connect to a DriveSense device.';
      });
      return;
    }

    // Initialize video stream
    await _initializeStream();
  }

  Future<void> _initializeStream() async {
    if (_device == null) return;

    try {
      // Format for MJPEG stream
      final deviceId = _device!.deviceSSID.replaceAll("DriveSense_Camera_", "");
      _streamUrl =
          dotenv.env['DEVICE_VIDEO_URL'] ??
          'http://$deviceId.local:8080/?action=stream';

      debugPrint('Connecting to MJPEG stream at: $_streamUrl');

      _startStream();

      setState(() {
        _isLoading = false;
        _isStreaming = true;
      });
    } catch (e) {
      debugPrint('Error setting up stream: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize video stream: $e';
      });
    }
  }

  Future<void> _tryAlternativeUrl() async {
    if (_device == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceId = _device!.deviceSSID.replaceAll("DriveSense_Camera_", "");

      // Try alternative format
      _streamUrl = 'http://$deviceId.local:8081/videostream.cgi';
      debugPrint('Trying alternative URL: $_streamUrl');

      _startStream();

      setState(() {
        _isLoading = false;
        _isStreaming = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed with alternative URL: $e';
      });
    }
  }

  void _checkConnection() async {
    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);
    await viewModel.refreshWifiConnection();

    if (_device != null &&
        viewModel.currentWifiSSID != _device!.deviceSSID &&
        mounted) {
      // Connection lost to the device
      setState(() {
        _errorMessage = 'Connection to device lost. Please reconnect.';
        _pauseStream();
      });
    }
  }

  Future<void> _navigateAway(BuildContext context, String route) async {
    // First unbind network
    await NetworkBinder.unbind();

    // Then navigate if still mounted
    if (mounted) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppHeaderBar(
        title: _device?.deviceName ?? 'Device Monitor',
        leading: Icon(Icons.arrow_back),
        onLeadingPressed: () => _navigateAway(context, '/'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: accentColor),
            onPressed: () => _initializeDeviceAndStream(),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? _buildLoadingView()
                : _errorMessage != null
                ? _buildErrorView()
                : _buildStreamView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Connecting to device...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 72, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Failed to connect to device.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _initializeDeviceAndStream,
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
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _tryAlternativeUrl,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Try Alternative URL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            child: _streamUrl != null && _isStreaming
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      // Simple MJPEG view without face detection
                      MJPEGView(
                        streamUrl: _streamUrl!,
                        showLiveIcon: true,
                      ),

                      // Play/pause overlay
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.pause,
                              color: Colors.white,
                              size: 24,
                            ),
                            onPressed: _toggleStream,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.videocam_off,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _toggleStream,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: isDarkMode
                                ? AppColors.blue
                                : AppColors.darkBlue,
                          ),
                          child: const Text('Start Stream'),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        // Controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Camera Feed',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Connected to ${_device?.deviceName}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildControlButton(
                    icon: _isStreaming ? Icons.pause : Icons.play_arrow,
                    label: _isStreaming ? 'Pause' : 'Play',
                    onPressed: _toggleStream,
                    isDarkMode: isDarkMode,
                  ),
                  _buildControlButton(
                    icon: Icons.refresh,
                    label: 'Reload',
                    onPressed: _initializeDeviceAndStream,
                    isDarkMode: isDarkMode,
                  ),
                  _buildControlButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onPressed: () async {
                      await NetworkBinder.unbind();
                      if (mounted) {
                        context.go('/device_settings/${_device!.deviceId}');
                      }
                    },
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isDarkMode,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            icon,
            size: 28,
            color: isDarkMode ? AppColors.blue : AppColors.darkBlue,
          ),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
          ),
        ),
      ],
    );
  }
}
