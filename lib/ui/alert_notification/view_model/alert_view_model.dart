import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drivesense/domain/models/alert/alert.dart';

class AlertViewModel extends ChangeNotifier {
  late Alert _alert;

  Alert get alert => _alert;

  Future<void> loadAlertData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/alert_data.json',
      );
      final Map<String, dynamic> alertData = json.decode(response);
      _alert = Alert.fromJson(alertData);
    } catch (e) {
      // Debug the error
      debugPrint('Error loading user data: $e');

      // For more detailed stack trace info
      debugPrint('Stack trace: ${StackTrace.current}');

      _alert = Alert(
        alertId: '0',
        alertTypeName: 'Self-Configured Audio',
        musicPlayList: {
          'Drowsiness': 'Song.mp4',
          'Distraction': null,
          'Intoxication': null,
          'Distress': null,
          'Phone Usage': null,
        },
        audioFilePath: {
          'Drowsiness': 'Song.mp4',
          'Distraction': null,
          'Intoxication': null,
          'Distress': null,
          'Phone Usage': null,
        },
      );
    }
    notifyListeners();
  }

  Future<bool> updateAlert(Alert updatedAlert) async {
    try {
      // TODO: Implement API call to update the alert in the backend
      // Example: await alertRepository.updateAlert(updatedAlert);

      // Update the local alert model
      _alert = updatedAlert;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating alert: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      throw Exception('Failed to update alert: $e');
    }
  }
}