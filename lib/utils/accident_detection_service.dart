import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drivesense/domain/models/accident/accident.dart';

enum AccidentSeverity {
  minor, // Small impact, possibly a hard braking
  moderate, // Medium impact, could be a minor collision
  severe, // Large impact, serious collision
}

class AccidentDetectionService {
  // Singleton pattern
  static final AccidentDetectionService _instance =
      AccidentDetectionService._internal();
  factory AccidentDetectionService() => _instance;
  AccidentDetectionService._internal();

  // Stream subscriptions
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  // Callback for when accident is detected
  Function(Accident accident, AccidentSeverity severity, double force)?
  onAccidentDetected;

  // Detection configurations
  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  // Detection thresholds (in G's, where 1G = 9.8 m/s²)
  double _minorThreshold = 1.0; // ~2G force (moderate braking)
  double _moderateThreshold = 4.0; // ~4G force (hard collision)
  double _severeThreshold = 6.0; // ~6G force (severe impact)

  // Time window for peak detection (in milliseconds)
  final int _peakDetectionWindow = 200;

  // Data buffers to track recent sensor readings
  final List<AccelerometerEvent> _recentAccelReadings = [];
  final List<GyroscopeEvent> _recentGyroReadings = [];

  // Peak tracking
  double _peakAcceleration = 0;
  DateTime? _lastPeakTime;
  bool _isPotentialImpact = false;

  // Cooldown to prevent multiple detections for the same event
  bool _isInCooldown = false;
  final Duration _cooldownPeriod = Duration(seconds: 10);

  // Emergency contact information
  String _emergencyContact = "911"; // Default emergency number

  void setEmergencyContact(String contactNum) {
    _emergencyContact = contactNum;
  }

  String get emergencyContact => _emergencyContact;

  void startMonitoring() {
    if (_isMonitoring) return;

    debugPrint('Starting accident detection monitoring');
    _isMonitoring = true;
    _recentAccelReadings.clear();
    _recentGyroReadings.clear();
    _peakAcceleration = 0;
    _lastPeakTime = null;
    _isPotentialImpact = false;
    _isInCooldown = false;

    // Set up accelerometer subscription
    _accelerometerSubscription = accelerometerEvents.listen(
      _processAccelerometerEvent,
    );

    // Set up gyroscope subscription
    _gyroscopeSubscription = gyroscopeEvents.listen(_processGyroscopeEvent);
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;

    debugPrint('Stopping accident detection monitoring');
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _isMonitoring = false;
  }

  void _processAccelerometerEvent(AccelerometerEvent event) {
    if (!_isMonitoring || _isInCooldown) return;

    // Add to recent readings buffer (with max size limit)
    _recentAccelReadings.add(event);
    if (_recentAccelReadings.length > 100) {
      _recentAccelReadings.removeAt(0); // Remove oldest reading
    }

    // Calculate total acceleration magnitude (vector length)
    // gravity is ~9.8 m/s², so at rest, magnitude is ~9.8
    final magnitude = _calculateMagnitude(event);

    // Subtract gravity to get the net acceleration
    // This is a simplification, a better approach would calibrate first
    final netAcceleration = magnitude - 9.8;
    final gForce = netAcceleration / 9.8; // Convert to G-force

    // Check if this is potentially an impact
    if (gForce >= _minorThreshold) {
      debugPrint('Potential impact detected: $gForce G');
      _isPotentialImpact = true;

      // Track the peak force
      if (gForce > _peakAcceleration) {
        _peakAcceleration = gForce;
        _lastPeakTime = DateTime.now();
      }

      // After a brief window, check if we've confirmed an impact
      if (_lastPeakTime != null) {
        final timeSincePeak =
            DateTime.now().difference(_lastPeakTime!).inMilliseconds;

        if (timeSincePeak > _peakDetectionWindow && _isPotentialImpact) {
          _confirmImpact();
        }
      }
    }
  }

  void _processGyroscopeEvent(GyroscopeEvent event) {
    if (!_isMonitoring || _isInCooldown) return;

    // Add to recent readings buffer (with max size limit)
    _recentGyroReadings.add(event);
    if (_recentGyroReadings.length > 100) {
      _recentGyroReadings.removeAt(0); // Remove oldest reading
    }
  }

  double _calculateMagnitude(AccelerometerEvent event) {
    return sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
  }

  Future<void> _confirmImpact() async {
    if (!_isPotentialImpact || _isInCooldown) return;

    // Determine severity based on peak acceleration
    AccidentSeverity severity;
    if (_peakAcceleration >= _severeThreshold) {
      severity = AccidentSeverity.severe;
    } else if (_peakAcceleration >= _moderateThreshold) {
      severity = AccidentSeverity.moderate;
    } else {
      severity = AccidentSeverity.minor;
    }

    // Get current location
    String locationStr = "Unknown location";
    try {
      // Check for location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        Position position = await Geolocator.getCurrentPosition();
        locationStr = "${position.latitude},${position.longitude}";
        debugPrint('Accident location: $locationStr');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    // Create accident object
    final accident = Accident(
      accidentId:
          DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      detectedTime: DateTime.now(),
      location: locationStr,
      contactNum: _emergencyContact,
      contactTime:
          DateTime.now(), // Will be updated when contact is actually made
    );

    // Notify listeners
    if (onAccidentDetected != null) {
      onAccidentDetected!(accident, severity, _peakAcceleration);
    }

    // Enter cooldown period to avoid multiple detections
    _isInCooldown = true;
    debugPrint(
      'Accident detected! Severity: ${severity.name}, Force: ${_peakAcceleration.toStringAsFixed(2)}G',
    );

    // Reset tracking variables
    _isPotentialImpact = false;
    _peakAcceleration = 0;
    _lastPeakTime = null;

    // Clear cooldown after period
    Future.delayed(_cooldownPeriod, () {
      _isInCooldown = false;
    });
  }

  // Method to adjust thresholds if needed
  void setThresholds({double? minor, double? moderate, double? severe}) {
    if (minor != null) _minorThreshold = minor;
    if (moderate != null) _moderateThreshold = moderate;
    if (severe != null) _severeThreshold = severe;
  }
}
