import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drivesense/domain/models/alert/alert.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drivesense/utils/auth_service.dart';

class AlertViewModel extends ChangeNotifier {
  // Change from late Alert _alert to nullable
  Alert? _alert;
  bool isLoading = false;
  String? errorMessage;
  final AuthService _authService = AuthService();

  AlertViewModel() {
    loadAlert();
  }

  // Safe getter that returns alert only when available
  Alert? get alert => _alert;
  bool get hasAlert => _alert != null;

  // Helper method for API headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> loadAlert() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = '${dotenv.env['BACKEND_URL']}/api/alerts';
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle the response based on its type
        if (data is List) {
          if (data.isNotEmpty) {
            // Take the first alert from the list
            _alert = Alert.fromJson(data[0] as Map<String, dynamic>);
            debugPrint('Alert loaded from list: ${_alert?.toJson()}');
          } else {
            throw Exception('No alerts found in the response');
          }
        } else if (data is Map<String, dynamic>) {
          // Handle single alert object
          _alert = Alert.fromJson(data);
          debugPrint('Alert loaded: ${_alert?.toJson()}');
        } else {
          throw Exception('Unexpected data format received from API');
        }
      } else {
        throw Exception('Failed to load alerts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading alert data: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      errorMessage = 'Failed to load alert settings';

      // Try to load from cache if available
      try {
        await _getAlertData();
      } catch (cacheError) {
        debugPrint('Could not load from cache: $cacheError');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAlert(String alertTypeName) async {
    if (_alert == null) {
      errorMessage = 'No alert data available to update';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      notifyListeners();

      final url = '${dotenv.env['BACKEND_URL']}/api/alerts/${_alert!.alertId}';
      final updatedAlertData = {'alertTypeName': alertTypeName};

      final response = await http.put(
        Uri.parse(url),
        body: json.encode(updatedAlertData),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _alert = Alert.fromJson(responseData);
        await _saveAlertData();
        return true;
      } else {
        throw Exception('Failed to update alert: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating alert: $e');
      errorMessage = 'Failed to update alert method';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Method for updating music playlist (for Music alert type)
  Future<bool> updatePlaylist(String behavior, String musicName, String musicPath) async {
    if (_alert == null) {
      errorMessage = 'Cannot update playlist: No alert available';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      notifyListeners();

      final updatedMusicPlayList = Map<String, dynamic>.from(
        _alert!.musicPlayList,
      );
      updatedMusicPlayList[behavior] = {"name": musicName, "path": musicPath};

      // Update via API
      final url = '${dotenv.env['BACKEND_URL']}/api/alerts/${_alert!.alertId}';
      final updateData = {'musicPlayList': updatedMusicPlayList};

      final response = await http.put(
        Uri.parse(url),
        body: json.encode(updateData),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        _alert = Alert.fromJson(json.decode(response.body));
      } else {
        // Fallback to local update if API fails
        _alert = Alert(
          alertId: _alert!.alertId,
          alertTypeName: _alert!.alertTypeName,
          musicPlayList: updatedMusicPlayList,
          audioFilePath: _alert!.audioFilePath,
        );
      }

      notifyListeners();
      await _saveAlertData();
      return true;
    } catch (e) {
      debugPrint('Error updating playlist: $e');
      return false;
    }
  }

  // Method for updating audio file path (for Self-Configured Audio alert type)
  Future<bool> updateAudioFile(
    String behavior,
    String fileName, {
    String? audioPath,
  }) async {
    if (_alert == null) {
      errorMessage = 'Cannot update audio file: No alert available';
      notifyListeners();
      return false;
    }

    try {
      isLoading = true;
      notifyListeners();

      final updatedAudioFilePath = Map<String, dynamic>.from(
        _alert!.audioFilePath,
      );
      updatedAudioFilePath[behavior] = {"name": fileName, "path": audioPath};

      // Update via API
      final url = '${dotenv.env['BACKEND_URL']}/api/alerts/${_alert!.alertId}';
      final updateData = {'audioFilePath': updatedAudioFilePath};

      final response = await http.put(
        Uri.parse(url),
        body: json.encode(updateData),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        _alert = Alert.fromJson(json.decode(response.body));
      } else {
        // Fallback to local update if API fails
        _alert = Alert(
          alertId: _alert!.alertId,
          alertTypeName: _alert!.alertTypeName,
          musicPlayList: _alert!.musicPlayList,
          audioFilePath: updatedAudioFilePath,
        );
      }

      await _saveAlertData();
      return true;
    } catch (e) {
      debugPrint('Error updating audio file: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Add these methods if they don't exist
  Future<void> _getAlertData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertJson = prefs.getString('alert_data');
      if (alertJson != null) {
        _alert = Alert.fromJson(json.decode(alertJson));
      }
    } catch (e) {
      debugPrint('Error loading cached alert data: $e');
    }
  }

  Future<void> _saveAlertData() async {
    if (_alert != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('alert_data', json.encode(_alert!.toJson()));
      } catch (e) {
        debugPrint('Error saving alert data: $e');
      }
    }
  }
}
