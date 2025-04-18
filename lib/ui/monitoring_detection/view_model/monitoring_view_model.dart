import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drivesense/domain/models/device/device.dart';

class MonitoringViewModel extends ChangeNotifier {
  // This view model handles the monitoring and detection of devices
  List<Device> _devices = [];

  List<Device> get devices => _devices;
   
  //check this ltr
  final List<Device> _connectedDevices = [];
  List<Device> get connectedDevices => List.unmodifiable(_connectedDevices);

  bool get hasConnectedDevice => _connectedDevices.isNotEmpty;

  Future<void> loadDeviceData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/device_data.json',
      );

      final List<dynamic> devicesData = json.decode(response);
      _devices = devicesData.map((data) => Device.fromJson(data)).toList();

      notifyListeners();
    } catch (e) {
      // Debug the error
      debugPrint('Error loading device data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // Initialize with a default device if loading fails
      _devices = [
        Device(
          deviceId: "md000",
          deviceSSID: "DriveSense_md000",
          deviceName: "DriveSense_md000",
        ),
      ];
      notifyListeners();
    }
  }

  void addDevice(Device device) {
    _devices.add(device);
    notifyListeners();
  }

  void removeDevice(String deviceId) {
    _devices.removeWhere((device) => device.deviceId == deviceId);
    notifyListeners();
  }

  void updateDeviceName(String deviceId, String newName) {
    final index = _devices.indexWhere((device) => device.deviceId == deviceId);
    if (index != -1) {
      final device = _devices[index];
      _devices[index] = Device(
        deviceId: device.deviceId,
        deviceSSID: device.deviceSSID,
        deviceName: newName,
      );
      notifyListeners();
    }
  }

  // Add methods to manage device connections
  void setConnectedDevice(Device device) {
    final existingIndex = _connectedDevices.indexWhere(
      (d) => d.deviceId == device.deviceId,
    );

    if (existingIndex >= 0) {
      _connectedDevices[existingIndex] = device;
    } else {
      _connectedDevices.add(device);
    }

    notifyListeners();
  }

  void removeConnectedDevice(Device device) {
    _connectedDevices.removeWhere((d) => d.deviceId == device.deviceId);
    notifyListeners();
  }
}
