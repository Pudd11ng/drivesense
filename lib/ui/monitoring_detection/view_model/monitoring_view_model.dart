import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:drivesense/domain/models/device/device.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drivesense/utils/auth_service.dart';

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
      return _devices.firstWhere(
        (device) => device.deviceSSID == ssid,
      );
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
      return _devices.firstWhere(
        (device) => device.deviceSSID == ssid,
      );
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
              deviceId: data['_id'] ?? '', // Map _id to deviceId
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
          _error = 'Failed to add device: ${errorData['message'] ?? response.statusCode}';
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
          orElse: () => Device(
            deviceId: 'unknown',
            deviceSSID: 'unknown',
            deviceName: 'Unknown Device',
          ),
        );
        
        _devices.removeWhere((device) => device.deviceId == deviceId);

        // If removed device was the connected device, update connection status
        if (_connectedDevice?.deviceId == deviceId) {
          // If it was connected via WiFi, keep WiFi status but clear device
          if (_isConnectedViaWifi && removedDevice?.deviceSSID == _currentWifiSSID) {
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

  @override
  void dispose() {
    _wifiCheckTimer?.cancel();
    super.dispose();
  }
}
