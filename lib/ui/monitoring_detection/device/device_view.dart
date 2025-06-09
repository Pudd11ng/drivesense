import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drivesense/ui/monitoring_detection/device/mjpeg_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:drivesense/ui/monitoring_detection/view_model/monitoring_view_model.dart';
import 'package:drivesense/domain/models/risky_behaviour/risky_behaviour.dart';
import 'package:drivesense/ui/core/widgets/app_header_bar.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:drivesense/utils/network_binder.dart';
import 'package:intl/intl.dart';

class DeviceView extends StatefulWidget {
  final String? deviceId;

  const DeviceView({super.key, this.deviceId});

  @override
  State<DeviceView> createState() => _DeviceViewState();
}

class _DeviceViewState extends State<DeviceView> with WidgetsBindingObserver {
  // Add the controller
  final MJPEGController _mjpegController = MJPEGController();

  Device? _device;
  bool _isLoading = true;
  String? _errorMessage;
  final _streamUrl = dotenv.env['DEVICE_VIDEO_URL'];

  // Stream control
  bool _isStreaming = false;
  Timer? _connectionCheckTimer;

  // Add this subscription property
  StreamSubscription<List<RiskyBehaviour>>? _behaviorSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WakelockPlus.enable();

    _connectionCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkConnection(),
    );
    _initializeDeviceAndStream();

    // Add subscription to behavior updates
    _subscribeToBehaviorUpdates();
  }

  @override
  void dispose() {
    // Cancel the behavior subscription
    _behaviorSubscription?.cancel();

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
      _pauseStream();
    } else if (state == AppLifecycleState.resumed) {
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
    setState(() {
      _isStreaming = false;
    });
    _mjpegController.stopStream();
  }

  void _startStream() {
    setState(() {
      _isStreaming = true;
    });
    _mjpegController.startStream();
  }

  void _toggleStream() {
    if (_isStreaming) {
      _pauseStream();
    } else {
      _resumeStream();
    }
  }

  Future<void> _initializeDeviceAndStream() async {
    _stopStream();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isStreaming = false;
    });

    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);

    await NetworkBinder.bindWifi();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (viewModel.devices.isEmpty) {
      await viewModel.loadDeviceData();
    }
    Device? targetDevice;

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
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;

    setState(() {
      _isStreaming = false;
    });

    _mjpegController.stopStream();

    await Future.delayed(const Duration(milliseconds: 300));

    try {
      await NetworkBinder.unbind();
    } catch (e) {
      debugPrint('Error unbinding network: $e');
    }

    if (mounted) {
      context.go(route);
    }
  }

  // Add this method to subscribe to behavior changes
  void _subscribeToBehaviorUpdates() {
    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);

    // Listen to the behavior stream
    _behaviorSubscription = viewModel.behaviorStream.listen((_) {
      // Force rebuild of the timeline when behaviors change
      if (mounted) {
        setState(() {
          // Just trigger a rebuild
        });
      }
    });
  }

  // In the _toggleMonitoring method, update it to reset the subscription when monitoring state changes:
  void _toggleMonitoring() {
    final viewModel = Provider.of<MonitoringViewModel>(context, listen: false);

    if (viewModel.isMonitoring) {
      viewModel.stopMonitoring();
    } else {
      // Ensure stream is running before starting monitoring
      if (!_isStreaming) {
        _resumeStream();
        setState(() {
          _isStreaming = true;
        });
      }
      viewModel.startMonitoring();
    }

    // Reset behavior subscription when monitoring state changes
    _behaviorSubscription?.cancel();
    _subscribeToBehaviorUpdates();
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final viewModel = Provider.of<MonitoringViewModel>(context);
    final isMonitoring = viewModel.isMonitoring;

    return SingleChildScrollView(
      // Add this to make content scrollable
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera card with fixed aspect ratio
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.4,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child:
                    _streamUrl != null && _isStreaming
                        ? Stack(
                          alignment: Alignment.center,
                          children: [
                            // MJPEG view with controller
                            MJPEGView(
                              streamUrl: _streamUrl,
                              showLiveIcon: true,
                              controller: _mjpegController,
                            ),

                            // Add streaming controls overlay if needed
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: InkWell(
                                onTap: _toggleStream,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.pause,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Video off icon and start button
                              Icon(
                                Icons.videocam_off,
                                size: 64,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _toggleStream,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      isDarkMode
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

            // Spacing
            const SizedBox(height: 20),

            // Monitoring info and controls
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Monitoring',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMonitoring
                          ? 'System is actively monitoring driver behavior and detecting risks.'
                          : 'Start monitoring to detect driver behaviors and potential risks.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isMonitoring
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isMonitoring ? Colors.green : Colors.orange,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isMonitoring
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isMonitoring ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isMonitoring
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Start/Stop button
                        ElevatedButton.icon(
                          onPressed: _toggleMonitoring,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                isMonitoring
                                    ? Colors.red
                                    : isDarkMode
                                    ? AppColors.blue
                                    : AppColors.darkBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Icon(
                            isMonitoring ? Icons.stop : Icons.play_arrow,
                          ),
                          label: Text(
                            isMonitoring
                                ? 'Stop Monitoring'
                                : 'Start Monitoring',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Add Event Timeline - show even if no behaviors yet but monitoring is active
            if (isMonitoring)
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                child: _buildEventTimelineCard(viewModel.detectedBehaviors),
              ),
          ],
        ),
      ),
    );
  }

  // Add this method to build the event timeline card
  Widget _buildEventTimelineCard(List<RiskyBehaviour> behaviors) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDarkMode ? AppColors.blue : AppColors.darkBlue;
    final cardColor =
        isDarkMode
            ? AppColors.darkGrey.withValues(alpha: 0.3)
            : AppColors.white;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final secondaryColor = isDarkMode ? AppColors.greyBlue : AppColors.grey;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Event Timeline', accentColor, textColor),

            behaviors.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No events detected yet',
                      style: TextStyle(color: secondaryColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: behaviors.length,
                  itemBuilder: (context, index) {
                    final behavior = behaviors[index];
                    final time = behavior.detectedTime;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _getBehaviorTypeColor(
                                  behavior.behaviourType.toLowerCase(),
                                  isDarkMode,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  _getBehaviorTypeIcon(behavior.behaviourType),
                                  color: AppColors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                            if (index != behaviors.length - 1)
                              Container(
                                width: 2,
                                height: 50,
                                color:
                                    isDarkMode
                                        ? AppColors.greyBlue.withValues(
                                          alpha: 0.3,
                                        )
                                        : AppColors.grey.withValues(alpha: 0.3),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('h:mm a').format(time),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Card(
                                elevation: isDarkMode ? 0 : 1,
                                color: cardColor,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side:
                                      isDarkMode
                                          ? BorderSide(
                                            color: AppColors.greyBlue
                                                .withValues(alpha: 0.2),
                                          )
                                          : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: _buildRiskyBehaviorTimelineItem(
                                    behavior,
                                    textColor,
                                    context,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title, Color accentColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
      ),
    );
  }

  // Helper method to get behavior icons
  IconData _getBehaviorTypeIcon(String behaviourType) {
    switch (behaviourType.toLowerCase()) {
      case 'drowsiness':
        return Icons.bedtime_outlined;
      case 'phone usage':
        return Icons.smartphone;
      case 'distraction':
        return Icons.remove_red_eye;
      case 'intoxication':
        return Icons.local_bar;
      default:
        return Icons.warning_amber;
    }
  }

  // Helper method to get behavior colors
  Color _getBehaviorTypeColor(String type, bool isDarkMode) {
    switch (type.toLowerCase()) {
      case 'drowsiness':
        return isDarkMode ? Colors.purple.shade300 : Colors.purple;
      case 'distraction':
        return isDarkMode ? Colors.blue.shade300 : Colors.blue;
      case 'intoxication':
        return isDarkMode ? Colors.red.shade300 : Colors.red;
      case 'phone usage':
        return isDarkMode ? Colors.orange.shade300 : Colors.orange;
      default:
        return isDarkMode ? Colors.amber.shade300 : Colors.amber;
    }
  }

  // Helper method to build risky behavior items
  Widget _buildRiskyBehaviorTimelineItem(
    RiskyBehaviour behavior,
    Color textColor,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getRiskyBehaviorIcon(
          behavior.behaviourType,
          Theme.of(context).brightness == Brightness.dark,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                behavior.behaviourType,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Alert Type: ${behavior.alertTypeName}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for behavior icons with styling
  Widget _getRiskyBehaviorIcon(String behaviourType, bool isDarkMode) {
    IconData iconData;
    Color iconColor;

    switch (behaviourType.toLowerCase()) {
      case 'drowsiness':
        iconData = Icons.bedtime_outlined;
        iconColor = isDarkMode ? Colors.purple.shade300 : Colors.purple;
        break;
      case 'distraction':
        iconData = Icons.remove_red_eye;
        iconColor = isDarkMode ? Colors.blue.shade300 : Colors.blue;
        break;
      case 'intoxication':
        iconData = Icons.local_bar;
        iconColor = isDarkMode ? Colors.red.shade300 : Colors.red;
        break;
      case 'phone usage':
        iconData = Icons.smartphone;
        iconColor = isDarkMode ? Colors.orange.shade300 : Colors.orange;
        break;
      default:
        iconData = Icons.warning_amber;
        iconColor = isDarkMode ? Colors.amber.shade300 : Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor),
    );
  }
}
