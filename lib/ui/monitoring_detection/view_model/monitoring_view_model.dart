import 'dart:async';
import 'dart:convert';
import 'package:drivesense/routing/router.dart';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drivesense/utils/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:drivesense/domain/models/risky_behaviour/risky_behaviour.dart';
import 'package:drivesense/domain/models/driving_history/driving_history.dart';
import 'package:drivesense/utils/network_binder.dart';
import 'package:just_audio/just_audio.dart';
import 'package:drivesense/ui/core/themes/colors.dart';
import 'package:drivesense/ui/alert_notification/view_model/alert_view_model.dart';
import 'package:drivesense/utils/accident_detection_service.dart';
import 'package:drivesense/domain/models/accident/accident.dart';

class MonitoringViewModel extends ChangeNotifier {
  // This view model handles the monitoring and detection of devices
  List<Device> _devices = [];
  List<Device> get devices => _devices;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Connected DriveSense device (primary source of truth)
  Device? _connectedDevice;
  Device? get connectedDevice => _connectedDevice;

  // WiFi connection tracking
  bool _isWifiEnabled = false;
  String? _currentWifiSSID;
  String? _currentWifiBSSID;
  Timer? _wifiCheckTimer;
  bool _isInitialized = false;

  // Flag to indicate if the connected device is via WiFi
  bool _isConnectedViaWifi = false;
  bool get isConnectedViaWifi => _isConnectedViaWifi;

  // Getters for WiFi connection status
  bool get isWifiEnabled => _isWifiEnabled;
  String? get currentWifiSSID => _currentWifiSSID;
  String? get currentWifiBSSID => _currentWifiBSSID;

  bool get hasConnectedDevice => _connectedDevice != null;

  final AuthService _authService = AuthService();

  // New properties for behavior tracking
  DrivingHistory? _currentDrivingHistory;
  DrivingHistory? get currentDrivingHistory => _currentDrivingHistory;

  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  List<RiskyBehaviour> _detectedBehaviors = [];
  List<RiskyBehaviour> get detectedBehaviors => _detectedBehaviors;

  List<DateTime> _scanTimes = [];
  bool _isThrottled = false;
  DateTime? _nextAvailableScanTime;

  List<DateTime> get scanTimes => _scanTimes;
  bool get isWifiScanThrottled => _isThrottled;
  DateTime? get nextAvailableScanTime => _nextAvailableScanTime;

  // Stream controller for detected behaviors
  final _behaviorStreamController =
      StreamController<List<RiskyBehaviour>>.broadcast();

  // Getter for the stream
  Stream<List<RiskyBehaviour>> get behaviorStream =>
      _behaviorStreamController.stream;

  // Audio player for alerts
  final AudioPlayer _alertPlayer = AudioPlayer();
  Timer? _alertTimer;
  String? _currentBehaviorAlertPlaying;

  // Accident detection service
  final AccidentDetectionService _accidentService = AccidentDetectionService();
  List<Accident> _detectedAccidents = [];
  List<Accident> get detectedAccidents => _detectedAccidents;

  // Stream controller for accidents
  final _accidentStreamController =
      StreamController<List<Accident>>.broadcast();
  Stream<List<Accident>> get accidentStream => _accidentStreamController.stream;

  // Add this to the top of the class
  final List<VoidCallback> _connectionErrorListeners = [];

  MonitoringViewModel() {
    _initializeWifiMonitoring();
  }

  // Helper method for API headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _initializeWifiMonitoring() async {
    if (_isInitialized) return;

    try {
      _isWifiEnabled = await WiFiForIoTPlugin.isEnabled();

      if (_isWifiEnabled) {
        await _updateCurrentWifiConnection();
      }

      // Set up periodic checking (every 5 seconds)
      _wifiCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        refreshWifiConnection();
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing WiFi monitoring: $e');
    }
  }

  bool canStartWifiScan() {
    final now = DateTime.now();

    _scanTimes.removeWhere(
      (time) => now.difference(time) > const Duration(minutes: 2),
    );

    if (_scanTimes.length >= 4) {
      final oldestScan = _scanTimes.first;
      _nextAvailableScanTime = oldestScan.add(const Duration(minutes: 2));
      _isThrottled = true;
      notifyListeners();
      return false;
    }

    _isThrottled = false;
    return true;
  }

  Future<void> refreshWifiConnection() async {
    try {
      _isWifiEnabled = await WiFiForIoTPlugin.isEnabled();

      if (_isWifiEnabled) {
        await _updateCurrentWifiConnection();
      } else {
        _clearWifiConnection();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing WiFi connection: $e');
    }
  }

  Future<void> _updateCurrentWifiConnection() async {
    try {
      // Get current WiFi details
      _currentWifiSSID = await WiFiForIoTPlugin.getSSID();
      _currentWifiBSSID = await WiFiForIoTPlugin.getBSSID();

      // Check if the connected WiFi is one of our DriveSense devices
      _updateConnectedDevice();
    } catch (e) {
      debugPrint('Error updating WiFi connection details: $e');
    }
  }

  void _updateConnectedDevice() {
    final matchingDevice = getDeviceBySSID(_currentWifiSSID!);
    if (matchingDevice != null) {
      // Found an existing registered device
      _connectedDevice = matchingDevice;
      _isConnectedViaWifi = true;
      notifyListeners();
    } else if (_currentWifiSSID!.startsWith('DriveSense_')) {
      // Connected to a DriveSense device not in our database
      _connectedDevice = Device(
        deviceId: _currentWifiSSID!.replaceAll('DriveSense_', ''),
        deviceSSID: _currentWifiSSID!,
        deviceName: 'DriveSense Device',
      );
      _isConnectedViaWifi = true;
      notifyListeners();
    }
  }

  void _clearWifiConnection() {
    _currentWifiSSID = null;
    _currentWifiBSSID = null;

    // If we were connected via WiFi, clear the connected device
    if (_isConnectedViaWifi) {
      _connectedDevice = null;
      _isConnectedViaWifi = false;
      notifyListeners();
    }
  }

  // Find device by SSID
  Device? findDeviceBySSID(String ssid) {
    try {
      return _devices.firstWhere((device) => device.deviceSSID == ssid);
    } catch (e) {
      return Device(
        deviceId: 'unknown',
        deviceSSID: ssid,
        deviceName: 'Unknown Device',
      );
    }
  }

  // Check if a device with the given SSID exists in our list
  bool hasDeviceWithSSID(String ssid) {
    return _devices.any((device) => device.deviceSSID == ssid);
  }

  // Get device by SSID, returns null if not found
  Device? getDeviceBySSID(String ssid) {
    try {
      return _devices.firstWhere((device) => device.deviceSSID == ssid);
    } catch (e) {
      return null;
    }
  }

  // UPDATED: Load devices from backend API
  Future<void> loadDeviceData({bool autoConnectCurrentWifi = false}) async {
    _setLoading(true);

    try {
      // Check if backend URL is configured
      final backendUrl = dotenv.env['BACKEND_URL'];
      if (backendUrl == null || backendUrl.isEmpty) {
        _error = 'Backend URL not configured';
        debugPrint(_error);
        return;
      }

      final response = await http.get(
        Uri.parse('$backendUrl/api/devices'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> devicesData = json.decode(response.body);

        // Clear existing devices
        _devices.clear();

        // Manually create Device objects with only the required fields
        for (var data in devicesData) {
          try {
            final device = Device(
              deviceId: data['_id'] ?? '',
              deviceName: data['deviceName'] ?? 'Unnamed Device',
              deviceSSID: data['deviceSSID'] ?? '',
            );

            _devices.add(device);
          } catch (e) {
            debugPrint('Error parsing device: $e');
            // Skip this device and continue with others
          }
        }

        debugPrint('Loaded ${_devices.length} devices');

        // Re-check if any of these devices are currently connected by WiFi
        if (_isWifiEnabled && _currentWifiSSID != null) {
          _updateConnectedDevice();
        }
      } else {
        _error = 'Failed to load devices: ${response.statusCode}';
        debugPrint(_error);
      }
    } catch (e) {
      _error = 'Error loading device data: $e';
      debugPrint(_error);
      debugPrint('Stack trace: ${StackTrace.current}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // UPDATED: Add device to backend
  Future<bool> addDevice(Device device) async {
    _setLoading(true);
    bool success = false;

    try {
      // Debug: Log exactly what we're sending
      final requestBody = json.encode({
        'deviceName': device.deviceName,
        'deviceSSID': device.deviceSSID,
      });

      debugPrint('Sending device data: $requestBody');

      final headers = await _getHeaders();
      debugPrint('Headers: $headers');

      final url = '${dotenv.env['BACKEND_URL']}/api/devices';
      debugPrint('URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: requestBody,
      );

      // Debug: Print response details
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Add the device with the ID from the backend
        final responseData = json.decode(response.body);
        final createdDevice = Device(
          deviceId: responseData['_id'],
          deviceSSID: responseData['deviceSSID'],
          deviceName: responseData['deviceName'],
        );

        _devices.add(createdDevice);

        // If this is the currently connected WiFi device, update connection
        if (_currentWifiSSID == createdDevice.deviceSSID) {
          _connectedDevice = createdDevice;
          _isConnectedViaWifi = true;
        }

        success = true;
      } else {
        // Enhanced error handling to see validation errors
        try {
          final errorData = json.decode(response.body);
          _error =
              'Failed to add device: ${errorData['message'] ?? response.statusCode}';
        } catch (e) {
          _error = 'Failed to add device: ${response.statusCode}';
        }
        debugPrint(_error);
      }
    } catch (e) {
      _error = 'Error adding device: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
      notifyListeners();
    }

    return success;
  }

  // UPDATED: Remove device from backend
  Future<bool> removeDevice(String deviceId) async {
    _setLoading(true);
    bool success = false;

    try {
      final response = await http.delete(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/devices/$deviceId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Remove from local list
        final removedDevice = _devices.firstWhere(
          (device) => device.deviceId == deviceId,
          orElse:
              () => Device(
                deviceId: 'unknown',
                deviceSSID: 'unknown',
                deviceName: 'Unknown Device',
              ),
        );

        _devices.removeWhere((device) => device.deviceId == deviceId);

        // If removed device was the connected device, update connection status
        if (_connectedDevice?.deviceId == deviceId) {
          // If it was connected via WiFi, keep WiFi status but clear device
          if (_isConnectedViaWifi &&
              removedDevice.deviceSSID == _currentWifiSSID) {
            // Create a temporary device for the current WiFi
            _connectedDevice = Device(
              deviceId: _currentWifiSSID!.replaceAll('DriveSense_', ''),
              deviceSSID: _currentWifiSSID!,
              deviceName: 'DriveSense Device',
            );
            // _isConnectedViaWifi stays true
          } else {
            _connectedDevice = null;
            _isConnectedViaWifi = false;
          }
        }

        success = true;
      } else {
        _error = 'Failed to remove device: ${response.statusCode}';
        debugPrint(_error);
      }
    } catch (e) {
      _error = 'Error removing device: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
      notifyListeners();
    }

    return success;
  }

  // UPDATED: Update device name on backend
  Future<bool> updateDeviceName(String deviceId, String newName) async {
    _setLoading(true);
    bool success = false;

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/devices/$deviceId'),
        headers: await _getHeaders(),
        body: json.encode({'deviceName': newName}),
      );

      if (response.statusCode == 200) {
        final index = _devices.indexWhere(
          (device) => device.deviceId == deviceId,
        );
        if (index != -1) {
          final device = _devices[index];
          _devices[index] = Device(
            deviceId: device.deviceId,
            deviceSSID: device.deviceSSID,
            deviceName: newName,
          );

          // If this was the connected device, update it
          if (_connectedDevice?.deviceId == deviceId) {
            _connectedDevice = _devices[index];
            // _isConnectedViaWifi stays the same
          }
        }

        success = true;
      } else {
        _error = 'Failed to update device: ${response.statusCode}';
        debugPrint(_error);
      }
    } catch (e) {
      _error = 'Error updating device: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
      notifyListeners();
    }

    return success;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  // Add methods to manage device connections
  void setConnectedDevice(Device device) {
    _connectedDevice = device;

    // If this device matches current WiFi, mark as WiFi connection
    _isConnectedViaWifi = (_currentWifiSSID == device.deviceSSID);

    notifyListeners();
  }

  void removeConnectedDevice() {
    _connectedDevice = null;
    _isConnectedViaWifi = false;
    notifyListeners();
  }

  // Methods to manually control WiFi
  Future<bool> connectToWifi(String ssid, String password) async {
    try {
      final result = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
      );

      if (result) {
        // Wait briefly for connection to establish
        await Future.delayed(const Duration(seconds: 2));
        await refreshWifiConnection();
      }

      return result;
    } catch (e) {
      debugPrint('Error connecting to WiFi: $e');
      return false;
    }
  }

  Future<bool> disconnectFromWifi() async {
    try {
      final result = await WiFiForIoTPlugin.disconnect();
      if (result) {
        _clearWifiConnection();
        notifyListeners();
      }
      return result;
    } catch (e) {
      debugPrint('Error disconnecting from WiFi: $e');
      return false;
    }
  }

  // Monitoring session management methods

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _detectedBehaviors.clear();
    _detectedAccidents.clear();

    // Create a new driving history locally
    final newDrivingHistory = DrivingHistory(
      startTime: DateTime.now(),
      endTime: DateTime.now(), // Will update when stopping
      accident: [],
      riskyBehaviour: [],
    );

    try {
      // Unbind from WiFi before API call
      await NetworkBinder.unbind();

      final url = '${dotenv.env['BACKEND_URL']}/api/driving';

      // Send initial history to backend to get an ID
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: json.encode({
          'startTime': newDrivingHistory.startTime.toIso8601String(),
          'endTime': newDrivingHistory.endTime.toIso8601String(),
          'accidents': [],
          'riskyBehaviours': [],
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Store the history with backend-generated ID
        _currentDrivingHistory = newDrivingHistory.copyWith(
          drivingHistoryId: responseData['_id'],
        );

        debugPrint(
          'Driving history created with ID: ${_currentDrivingHistory!.drivingHistoryId}',
        );

        // Start accident detection service
        _accidentService.initialize(rootNavigatorKey.currentContext!);
        _accidentService.onAccidentDetected = _handleAccidentDetection;
        _accidentService.startMonitoring();
      } else {
        debugPrint('Failed to create driving history: ${response.statusCode}');
        _isMonitoring = false;

        // Show error and navigate back to home
        _showConnectionErrorAndNavigateHome();
        return; // Exit early
      }

      // Rebind to WiFi after API call
      await NetworkBinder.bindWifi();
    } catch (e) {
      debugPrint('Exception creating driving history: $e');
      // Cancel monitoring since we had an exception
      _isMonitoring = false;

      // Show error and navigate back to home
      _showConnectionErrorAndNavigateHome();
      return; // Exit early
    }

    notifyListeners();
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _isMonitoring = false;

    // Stop accident detection service
    _accidentService.stopMonitoring();

    // Update the end time in the backend
    if (_currentDrivingHistory?.drivingHistoryId != null) {
      try {
        // Unbind from WiFi before API call
        await NetworkBinder.unbind();

        final historyId = _currentDrivingHistory!.drivingHistoryId!;
        final url = '${dotenv.env['BACKEND_URL']}/api/driving/$historyId';

        final response = await http.put(
          Uri.parse(url),
          headers: await _getHeaders(),
          body: json.encode({'endTime': DateTime.now().toIso8601String()}),
        );

        if (response.statusCode == 200) {
          debugPrint('Driving history ended successfully');
        } else {
          debugPrint(
            'Failed to update driving history end time: ${response.statusCode}',
          );
        }

        // Rebind to WiFi after API call
        await NetworkBinder.bindWifi();
      } catch (e) {
        debugPrint('Exception ending driving history: $e');
        // Make sure we rebind even if there's an error
        await NetworkBinder.bindWifi();
      }
    }

    // Update the local object regardless of backend success
    _currentDrivingHistory = _currentDrivingHistory?.copyWith(
      endTime: DateTime.now(),
    );

    notifyListeners();
  }

  // Add this method
  void addConnectionErrorListener(VoidCallback listener) {
    _connectionErrorListeners.add(listener);
  }

  // Add this method
  void removeConnectionErrorListener(VoidCallback listener) {
    _connectionErrorListeners.remove(listener);
  }

  // Replace your existing _showConnectionErrorAndNavigateHome method with this:
  void _showConnectionErrorAndNavigateHome() {
    // Notify all registered listeners about the connection error
    for (final listener in _connectionErrorListeners) {
      listener();
    }

    // If no listeners handled it, fall back to direct navigation
    if (_connectionErrorListeners.isEmpty) {
      router.go('/');
    }
  }

  // Add the behavior reporting function
  Future<RiskyBehaviour?> addBehaviour({
    required String behaviourType,
    required String alertTypeName,
    required DateTime detectedTime,
    BuildContext? context,
  }) async {
    if (!_isMonitoring || _currentDrivingHistory?.drivingHistoryId == null) {
      debugPrint('Cannot add behavior: monitoring not active or no history ID');
      return null;
    }

    final historyId = _currentDrivingHistory!.drivingHistoryId!;

    try {
      // Unbind from WiFi before API call to use mobile data
      await NetworkBinder.unbind();

      // First, create the behavior
      final behaviorsUrl =
          '${dotenv.env['BACKEND_URL']}/api/driving/$historyId/behaviours';

      final behaviorResponse = await http.post(
        Uri.parse(behaviorsUrl),
        headers: await _getHeaders(),
        body: json.encode({
          'behaviourType': behaviourType,
          'alertTypeName': alertTypeName,
          'detectedTime': detectedTime.toIso8601String(),
        }),
      );

      debugPrint(
        'Behavior response: ${behaviorResponse.statusCode}, ${behaviorResponse.body}',
      );

      if (behaviorResponse.statusCode == 200) {
        final responseData = json.decode(behaviorResponse.body);
        RiskyBehaviour riskyBehavior = RiskyBehaviour(
          behaviourId: responseData['_id'],
          behaviourType: responseData['behaviourType'],
          alertTypeName: responseData['alertTypeName'],
          detectedTime: DateTime.parse(responseData['detectedTime']),
        );

        // Rebind to WiFi after API calls
        await NetworkBinder.bindWifi();

        // Add to our list of detected behaviors
        _detectedBehaviors.add(riskyBehavior);
        // Emit updated list to stream
        _behaviorStreamController.add(_detectedBehaviors);
        notifyListeners();

        // Play alert if context is provided
        if (context != null) {
          playAlertForBehavior(
            context,
            behaviourType,
            alertTypeName,
            detectedTime,
          );
        }

        return riskyBehavior;
      } else {
        debugPrint('Error creating behavior: ${behaviorResponse.statusCode}');
        await NetworkBinder.bindWifi();
        return null;
      }
    } catch (e) {
      debugPrint('Exception reporting behavior: $e');
      // Make sure we rebind even if there's an error
      await NetworkBinder.bindWifi();
      return null;
    }
  }

  // Method to handle alert playback
  Future<void> playAlertForBehavior(
    BuildContext context,
    String behaviourType,
    String alertTypeName,
    DateTime detectedTime,
  ) async {
    // Stop any currently playing alert
    _alertTimer?.cancel();
    await _alertPlayer.stop();

    // Get AlertViewModel to access alert configurations
    final alertViewModel = Provider.of<AlertViewModel>(context, listen: false);

    await NetworkBinder.unbind();

    // If alert isn't loaded yet, load it
    if (!alertViewModel.hasAlert) {
      await alertViewModel.loadAlert();
    }

    // Get the alert configuration
    final alert = alertViewModel.alert;
    if (alert == null) {
      debugPrint('Alert configuration not available');
      return;
    }

    // Get behavior-specific key for audio lookup
    final behaviorKey = _getBehaviorKeyFromType(behaviourType);
    if (behaviorKey == null) {
      debugPrint('Unknown behavior type: $behaviourType');
      return;
    }

    // Set current alert playing (used for tracking and UI)
    _currentBehaviorAlertPlaying = behaviourType;

    // Choose audio source based on alert type
    String? audioPath;
    String audioSource = 'asset';
    bool audioAvailable = true;

    try {
      switch (alert.alertTypeName) {
        case 'Alarm':
          // For alarm, always use the same MP3
          audioPath = 'assets/audio/audio.mp3';
          break;

        case 'Audio':
          // For audio type, use predefined assets based on behavior
          final defaultAudio = defaultAudioFiles[behaviorKey];
          audioPath = defaultAudio?['path'];
          break;

        case 'Self-Configured Audio':
          // For self-configured audio, get from audioFilePath
          final audioConfig = alert.audioFilePath[behaviorKey];
          if (audioConfig != null && audioConfig['path'] != null) {
            audioPath = audioConfig['path'];
            audioSource = 'url';
          } else {
            audioAvailable = false;
            debugPrint('No self-configured audio for $behaviorKey');
          }
          break;

        case 'Music':
          // For music, get from musicPlayList
          final musicConfig = alert.musicPlayList[behaviorKey];
          if (musicConfig != null && musicConfig['path'] != null) {
            audioPath = musicConfig['path'];
            debugPrint('audioPath: $audioPath');
            audioSource = 'url';
          } else {
            audioAvailable = false;
            debugPrint('No music for $behaviorKey');
          }
          break;

        default:
          // Unknown alert type, use fallback
          audioPath = 'assets/audio/audio.mp3';
      }

      // Show alert dialog
      if (context.mounted) {
        _showAlertDialog(
          context,
          behaviourType,
          alertTypeName,
          detectedTime,
          audioAvailable,
        );
      }

      // Play the alert audio if available
      if (audioAvailable && audioPath != null) {
        // Set audio source
        if (audioSource == 'asset') {
          await _alertPlayer.setAsset(audioPath);
        } else {
          await _alertPlayer.setUrl(audioPath);
        }

        // Play audio
        await _alertPlayer.play();

        // Set timer to stop after 30 seconds
        _alertTimer = Timer(const Duration(seconds: 30), () {
          _alertPlayer.stop();
          _currentBehaviorAlertPlaying = null;
        });
      }
      await NetworkBinder.bindWifi();
    } catch (e) {
      await NetworkBinder.bindWifi();
      debugPrint('Error playing alert audio: $e');
      // Just continue - the dialog will still show even if audio fails
    }
  }

  // Helper to get behavior key for audio lookup
  String? _getBehaviorKeyFromType(String behaviourType) {
    switch (behaviourType.toUpperCase()) {
      case 'DROWSINESS':
        return 'Drowsiness';
      case 'DISTRACTION':
        return 'Distraction';
      case 'INTOXICATION':
        return 'Intoxication';
      case 'PHONE USAGE':
        return 'Phone Usage';
      default:
        return null;
    }
  }

  // Method to stop current alert
  void stopCurrentAlert() {
    _alertTimer?.cancel();
    _alertPlayer.stop();
    _currentBehaviorAlertPlaying = null;
  }

  void _showAlertDialog(
    BuildContext context,
    String behaviourType,
    String alertTypeName,
    DateTime detectedTime,
    bool audioAvailable,
  ) {
    // Show the custom alert dialog widget
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _BehaviorAlertDialog(
          behaviourType: behaviourType,
          detectedTime: detectedTime,
          audioAvailable: audioAvailable,
          onClose: () {
            stopCurrentAlert();
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  // Define default audio files (same as in ExtraConfigView)
  final Map<String, dynamic> defaultAudioFiles = {
    'Drowsiness': {
      'name': 'drowsiness.mp3',
      'path': 'assets/audio alert/audio_alert_drowsiness.mp3',
    },
    'Distraction': {
      'name': 'distraction.mp3',
      'path': 'assets/audio alert/audio_alert_distraction.mp3',
    },
    'Intoxication': {
      'name': 'intoxication.mp3',
      'path': 'assets/audio alert/audio_alert_intoxication.mp3',
    },
    'Phone Usage': {
      'name': 'phone_usage.mp3',
      'path': 'assets/audio alert/audio_alert_phone_usage.mp3',
    },
  };

  // Accident handling methods

  // Method to handle accident detection
  void _handleAccidentDetection(
    Accident accident,
    AccidentSeverity severity,
    double force,
  ) async {
    if (!_isMonitoring || _currentDrivingHistory?.drivingHistoryId == null) {
      debugPrint(
        'Accident detected but monitoring not active or no history ID',
      );
      return;
    }

    debugPrint(
      'Handling accident detection: ${severity.name}, ${force.toStringAsFixed(2)}G',
    );

    // Add to local list for UI
    _detectedAccidents.add(accident);
    _accidentStreamController.add(_detectedAccidents);

    // Report accident to backend
    await addAccident(accident);

    // Show accident alert if context is available
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      _showAccidentAlert(context, accident, severity, force);
    }

    notifyListeners();
  }

  // Add accident reporting method
  Future<Accident?> addAccident(Accident accident) async {
    if (!_isMonitoring || _currentDrivingHistory?.drivingHistoryId == null) {
      debugPrint(
        'Cannot report accident: monitoring not active or no history ID',
      );
      return null;
    }

    final historyId = _currentDrivingHistory!.drivingHistoryId!;

    try {
      // Unbind from WiFi before API call to use mobile data
      await NetworkBinder.unbind();

      // Create the accident
      final accidentsUrl =
          '${dotenv.env['BACKEND_URL']}/api/driving/$historyId/accidents';

      final accidentResponse = await http.post(
        Uri.parse(accidentsUrl),
        headers: await _getHeaders(),
        body: json.encode({
          'detectedTime': accident.detectedTime.toIso8601String(),
          'location': accident.location,
          'contactNum': accident.contactNum,
          'contactTime': accident.contactTime.toIso8601String(),
        }),
      );

      debugPrint(
        'Accident response: ${accidentResponse.statusCode}, ${accidentResponse.body}',
      );

      if (accidentResponse.statusCode == 200 ||
          accidentResponse.statusCode == 201) {
        final responseData = json.decode(accidentResponse.body);

        // Update the accident with ID from backend
        final updatedAccident = Accident(
          accidentId: responseData['_id'] ?? accident.accidentId,
          detectedTime: DateTime.parse(responseData['detectedTime']),
          location: responseData['location'] ?? accident.location,
          contactNum: responseData['contactNum'] ?? accident.contactNum,
          contactTime: DateTime.parse(
            responseData['contactTime'] ??
                accident.contactTime.toIso8601String(),
          ),
        );

        // Rebind to WiFi after API calls
        await NetworkBinder.bindWifi();

        return updatedAccident;
      } else {
        debugPrint('Error creating accident: ${accidentResponse.statusCode}');
        await NetworkBinder.bindWifi();
        return null;
      }
    } catch (e) {
      debugPrint('Exception reporting accident: $e');
      // Make sure we rebind even if there's an error
      await NetworkBinder.bindWifi();
      return null;
    }
  }

  // Add accident alert method
  void _showAccidentAlert(
    BuildContext context,
    Accident accident,
    AccidentSeverity severity,
    double force,
  ) {
    // Show a custom alert dialog for the accident
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _AccidentAlertDialog(
          accident: accident,
          severity: severity,
          force: force,
          onDismiss: () async {
            Navigator.of(dialogContext).pop();
          },
          onEmergencyCall: () {
            _triggerEmergencyCall(accident);
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  // Method to handle emergency calls
  void _triggerEmergencyCall(Accident accident) async {
    // This would be implemented to call emergency services
    debugPrint('Emergency call triggered to: ${accident.contactNum}');
    // Typically you'd use url_launcher package to initiate a call

    // await FlutterPhoneDirectCaller.callNumber(accident.contactNum);
    final Uri launchUri = Uri(scheme: 'tel', path: accident.contactNum);
    await launchUrl(launchUri);

    // Update the contact time after an emergency call is made
    // final updatedAccident = Accident(
    //   accidentId: accident.accidentId,
    //   detectedTime: accident.detectedTime,
    //   location: accident.location,
    //   contactNum: accident.contactNum,
    //   contactTime: DateTime.now(), // Update contact time
    // );

    // Update in the backend
    // addAccident(updatedAccident);
    stopMonitoring();
  }

  @override
  void dispose() {
    _wifiCheckTimer?.cancel();
    _alertPlayer.dispose();
    _alertTimer?.cancel();
    _behaviorStreamController.close();
    _accidentStreamController.close();
    _accidentService.stopMonitoring();
    super.dispose();
  }
}

class _BehaviorAlertDialog extends StatefulWidget {
  final String behaviourType;
  final DateTime detectedTime;
  final bool audioAvailable;
  final VoidCallback onClose;

  const _BehaviorAlertDialog({
    required this.behaviourType,
    required this.detectedTime,
    required this.audioAvailable,
    required this.onClose,
  });

  @override
  _BehaviorAlertDialogState createState() => _BehaviorAlertDialogState();
}

class _BehaviorAlertDialogState extends State<_BehaviorAlertDialog> {
  Timer? _timer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    // Start the timer in initState (only runs once)
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        _timer?.cancel();
        widget.onClose();
      }
    });
  }

  @override
  void dispose() {
    // Always cancel timer when dialog is disposed
    _timer?.cancel();
    super.dispose();
  }

  String _getAlertMessage(String behaviourType) {
    switch (behaviourType.toUpperCase()) {
      case 'DROWSINESS':
        return 'You appear to be drowsy. Please consider taking a break or pulling over safely.';
      case 'DISTRACTION':
        return 'Your attention seems diverted from the road. Please focus on driving safely.';
      case 'INTOXICATION':
        return 'Warning: Signs of impairment detected. Please do not drive if you are intoxicated.';
      case 'PHONE USAGE':
        return 'Phone usage while driving is dangerous. Please focus on the road.';
      default:
        return 'Risky driving behavior detected. Please drive safely.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;

    Color alertColor;
    IconData alertIcon;

    switch (widget.behaviourType.toUpperCase()) {
      case 'DROWSINESS':
        alertColor = isDarkMode ? Colors.purple.shade300 : Colors.purple;
        alertIcon = Icons.bedtime_outlined;
        break;

      case 'DISTRACTION':
        alertColor = isDarkMode ? Colors.blue.shade300 : Colors.blue;
        alertIcon = Icons.remove_red_eye;
        break;

      case 'INTOXICATION':
        alertColor = isDarkMode ? Colors.red.shade300 : Colors.red;
        alertIcon = Icons.local_bar;
        break;

      case 'PHONE USAGE':
        alertColor = isDarkMode ? Colors.orange.shade300 : Colors.orange;
        alertIcon = Icons.smartphone;
        break;

      default:
        alertColor = isDarkMode ? Colors.amber.shade300 : Colors.amber;
        alertIcon = Icons.warning_amber;
    }

    final timeString = DateFormat('h:mm a').format(widget.detectedTime);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: alertColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(alertIcon, color: alertColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Alert: ',
                                style: TextStyle(
                                  color: alertColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                widget.behaviourType,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Detected at $timeString',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? AppColors.greyBlue
                                      : AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _getAlertMessage(widget.behaviourType),
                      style: TextStyle(color: textColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    if (widget.audioAvailable)
                      Text(
                        'Audio alert playing',
                        style: TextStyle(
                          color:
                              isDarkMode ? AppColors.greyBlue : AppColors.grey,
                          fontSize: 12,
                        ),
                      ),

                    Text(
                      'Closing in $_secondsRemaining seconds...',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.stop_circle),
                      label: const Text('Acknowledge'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
}

class _AccidentAlertDialog extends StatefulWidget {
  final Accident accident;
  final AccidentSeverity severity;
  final double force;
  final VoidCallback onDismiss;
  final VoidCallback onEmergencyCall;

  const _AccidentAlertDialog({
    required this.accident,
    required this.severity,
    required this.force,
    required this.onDismiss,
    required this.onEmergencyCall,
  });

  @override
  _AccidentAlertDialogState createState() => _AccidentAlertDialogState();
}

class _AccidentAlertDialogState extends State<_AccidentAlertDialog> {
  Timer? _timer;
  int _secondsRemaining = 60; // Longer timer for accident alerts
  bool _countdownPaused = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_countdownPaused) {
        setState(() {
          _secondsRemaining--;
        });

        if (_secondsRemaining <= 0) {
          _timer?.cancel();
          widget.onDismiss();
          final Uri launchUri = Uri(
            scheme: 'tel',
            path: widget.accident.contactNum,
          );
          await launchUrl(launchUri);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getSeverityText() {
    switch (widget.severity) {
      case AccidentSeverity.severe:
        return 'Severe';
      case AccidentSeverity.moderate:
        return 'Moderate';
      case AccidentSeverity.minor:
        return 'Minor';
      default:
        return 'Unknown';
    }
  }

  Color _getSeverityColor(bool isDarkMode) {
    switch (widget.severity) {
      case AccidentSeverity.severe:
        return isDarkMode ? Colors.red.shade300 : Colors.red;
      case AccidentSeverity.moderate:
        return isDarkMode ? Colors.orange.shade300 : Colors.orange;
      case AccidentSeverity.minor:
        return isDarkMode ? Colors.yellow.shade300 : Colors.yellow.shade800;
      default:
        return isDarkMode ? Colors.grey.shade300 : Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.white : AppColors.black;
    final backgroundColor = isDarkMode ? AppColors.black : AppColors.white;

    final alertColor = _getSeverityColor(isDarkMode);
    final severityText = _getSeverityText();

    final locationInfo =
        widget.accident.location != "Unknown location"
            ? "Location data available"
            : "No location data";

    final timeString = DateFormat(
      'h:mm:ss a',
    ).format(widget.accident.detectedTime);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: alertColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.warning_amber,
                        color: alertColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Accident Detected',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Severity: ',
                                style: TextStyle(
                                  color: alertColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                severityText,
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Detected at $timeString',
                            style: TextStyle(
                              color:
                                  isDarkMode
                                      ? AppColors.greyBlue
                                      : AppColors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'A potential vehicle accident has been detected. Impact force: ${widget.force.toStringAsFixed(1)}G.',
                      style: TextStyle(color: textColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      locationInfo,
                      style: TextStyle(
                        color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Emergency call section for moderate/severe accidents
                    if (widget.severity != AccidentSeverity.minor) ...[
                      Text(
                        'Are you okay? If you need emergency assistance, tap the button below:',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton.icon(
                        onPressed: () {
                          _countdownPaused = true;
                          widget.onEmergencyCall();
                        },
                        icon: const Icon(Icons.call),
                        label: Text(
                          'Call Emergency (${widget.accident.contactNum})',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],

                    ElevatedButton.icon(
                      onPressed: () {
                        _timer?.cancel();
                        widget.onDismiss();
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('I\'m Okay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'This alert will close in $_secondsRemaining seconds',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.greyBlue : AppColors.grey,
                        fontSize: 12,
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
}
