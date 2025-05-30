import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drivesense/utils/auth_service.dart';
import 'package:drivesense/domain/models/risky_behaviour/risky_behaviour.dart';
import 'package:drivesense/domain/models/driving_history/driving_history.dart';
import 'package:drivesense/utils/network_binder.dart';

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

  final List<RiskyBehaviour> _detectedBehaviors = [];
  List<RiskyBehaviour> get detectedBehaviors =>
      List.unmodifiable(_detectedBehaviors);

  List<DateTime> _scanTimes = [];
  bool _isThrottled = false;
  DateTime? _nextAvailableScanTime;

  List<DateTime> get scanTimes => _scanTimes ;
  bool get isWifiScanThrottled => _isThrottled;
  DateTime? get nextAvailableScanTime => _nextAvailableScanTime;

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
              removedDevice?.deviceSSID == _currentWifiSSID) {
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

      // Rebind to WiFi after API call
      await NetworkBinder.bindWifi();

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Store the history with backend-generated ID
        _currentDrivingHistory = newDrivingHistory.copyWith(
          drivingHistoryId: responseData['_id'],
        );

        debugPrint(
          'Driving history created with ID: ${_currentDrivingHistory!.drivingHistoryId}',
        );
      } else {
        debugPrint('Failed to create driving history: ${response.statusCode}');
        // Still track locally even if backend fails
        _currentDrivingHistory = newDrivingHistory;
      }
    } catch (e) {
      debugPrint('Exception creating driving history: $e');
      // Make sure we rebind even if there's an error
      await NetworkBinder.bindWifi();
      // Still track locally even if backend fails
      _currentDrivingHistory = newDrivingHistory;
    }

    notifyListeners();
  }

  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _isMonitoring = false;

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

  // Add the behavior reporting function
  Future<RiskyBehaviour?> addBehaviour({
    required String behaviourType,
    required String alertTypeName,
    required DateTime detectedTime,
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

      if (behaviorResponse.statusCode == 201) {
        final data = json.decode(behaviorResponse.body);
        final riskyBehavior = RiskyBehaviour.fromJson(data);

        // Rebind to WiFi after API calls
        await NetworkBinder.bindWifi();

        // Add to our list of detected behaviors
        _detectedBehaviors.add(riskyBehavior);
        notifyListeners();

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

  // Helper method to send complete driving history
  Future<bool> _sendDrivingHistory(DrivingHistory drivingHistory) async {
    try {
      // Unbind from WiFi before API call
      await NetworkBinder.unbind();
      final url = '${dotenv.env['BACKEND_URL']}/api/driving';

      // Extract accident IDs and risky behaviour IDs
      final List<String> accidentIds =
          drivingHistory.accident
              .map((accident) => accident.accidentId)
              .where((id) => id.isNotEmpty)
              .toList();

      final List<String> riskyBehaviourIds =
          drivingHistory.riskyBehaviour
              .map((behaviour) => behaviour.behaviourId)
              .where((id) => id.isNotEmpty)
              .toList();

      // Create payload with format backend expects
      final payload = {
        'startTime': drivingHistory.startTime.toIso8601String(),
        'endTime': drivingHistory.endTime.toIso8601String(),
        'accidents': accidentIds,
        'riskyBehaviours': riskyBehaviourIds,
      };

      // For debug purposes
      debugPrint('Sending payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: json.encode(payload),
      );

      // Rebind to WiFi after API call
      await NetworkBinder.bindWifi();

      if (response.statusCode == 201) {
        // Update the driving history with the ID from the backend
        final responseData = json.decode(response.body);

        // Update the current driving history with the backend-generated ID
        _currentDrivingHistory = _currentDrivingHistory!.copyWith(
          drivingHistoryId:
              responseData['_id'], // or whatever field name your backend uses
        );

        debugPrint('Driving history saved successfully');
        return true;
      } else {
        debugPrint(
          'Failed to save driving history: ${response.statusCode}, ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('Exception sending driving history: $e');
      // Make sure we rebind even if there's an error
      await NetworkBinder.bindWifi();
      return false;
    }
  }

  @override
  void dispose() {
    _wifiCheckTimer?.cancel();
    super.dispose();
  }
}
