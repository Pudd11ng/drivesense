import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:drivesense/domain/models/driving_history/driving_history.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:drivesense/utils/auth_service.dart';

class AnalysisViewModel extends ChangeNotifier {
  List<DrivingHistory> _allDrivingHistory = [];
  List<DrivingHistory> _filteredDrivingHistory = [];
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;

  List<DrivingHistory> get drivingHistory => _filteredDrivingHistory;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalDrivingSessions => _filteredDrivingHistory.length;

  int get totalDrivingMinutes =>
      _filteredDrivingHistory.fold(0, (total, session) {
        return total + session.endTime.difference(session.startTime).inMinutes;
      });

  int get totalAccidents => _filteredDrivingHistory.fold(0, (total, session) {
    return total + session.accident.length;
  });

  int get totalRiskyBehaviors =>
      _filteredDrivingHistory.fold(0, (total, session) {
        return total + session.riskyBehaviour.length;
      });

  AnalysisViewModel() {
    loadDrivingHistory();
  }

  final AuthService _authService = AuthService();

  // Helper method for API headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> loadDrivingHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = '${dotenv.env['BACKEND_URL']}/api/driving';
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Parse response - we know it has a "data" field containing the records
        final jsonResponse = json.decode(response.body);
        final List<dynamic> historyList = jsonResponse['data'] ?? [];
        print(jsonResponse);
        _allDrivingHistory = [];
        
        for (var item in historyList) {
          try {
            // Map accidents with proper field mappings
            final List<dynamic> rawAccidents = item['accidents'] ?? [];
            final accidents = rawAccidents.map((accident) {
              return {
                'accidentId': accident['_id'] ?? 'unknown',
                'detectedTime': accident['detectedTime'] ?? DateTime.now().toIso8601String(),
                'location': accident['location'] ?? 'unknown',
                'contactNum': accident['contactNum'] ?? 'unknown',
                'contactTime': accident['contactTime'] ?? DateTime.now().toIso8601String(),
              };
            }).toList();
            print(accidents);

            // Map risky behaviors with proper field mappings
            final List<dynamic> rawBehaviors = item['riskyBehaviours'] ?? [];
            final behaviors = rawBehaviors.map((behavior) {
              return {
                'behaviourId': behavior['_id'] ?? 'unknown',
                'detectedTime': behavior['detectedTime'] ?? DateTime.now().toIso8601String(),
                'behaviourType': behavior['behaviourType'] ?? 'unknown',
                'alertTypeName': behavior['alertTypeName'] ?? 'unknown',
              };
            }).toList();
            print(behaviors);

            // Create the model with mapped fields
            final history = DrivingHistory.fromJson({
              'drivingHistoryId': item['_id'] ?? 'unknown',
              'startTime': item['startTime'] ?? DateTime.now().toIso8601String(),
              'endTime': item['endTime'] ?? DateTime.now().toIso8601String(),
              'accident': accidents,
              'riskyBehaviour': behaviors,
            });
            
            _allDrivingHistory.add(history);
          } catch (e) {
            debugPrint('Error parsing history item: $e');
          }
        }
        
        debugPrint('Loaded ${_allDrivingHistory.length} driving history records');
        
        // Filter records by selected month
        filterByMonth(_selectedMonth);
        _isLoading = false;
      } else {
        _isLoading = false;
        _errorMessage = 'Server returned ${response.statusCode}';
        _filteredDrivingHistory = [];
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Connection error';
      _filteredDrivingHistory = [];
    }
    
    notifyListeners();
  }

  // Filter history by month
  void filterByMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);

    _filteredDrivingHistory =
        _allDrivingHistory.where((history) {
          return history.startTime.year == _selectedMonth.year &&
              history.startTime.month == _selectedMonth.month;
        }).toList();

    // Sort by date descending (newest first)
    _filteredDrivingHistory.sort((a, b) => b.startTime.compareTo(a.startTime));

    debugPrint('After filtering by month ${DateFormat("yyyy-MM").format(_selectedMonth)}: ${_filteredDrivingHistory.length} items');

    notifyListeners();
  }

  // Change to previous month
  void previousMonth() {
    final prevMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
      1,
    );
    filterByMonth(prevMonth);
  }

  // Change to next month
  void nextMonth() {
    final nextMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      1,
    );
    filterByMonth(nextMonth);
  }

  // Get formatted duration between start and end time
  String getFormattedDuration(DrivingHistory history) {
    final duration = history.endTime.difference(history.startTime);

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return '$minutes min';
    }
  }

  // Format date for display
  String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  // Format time for display
  String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  // Add these methods to your existing AnalysisViewModel class

  DrivingHistory? getDrivingHistoryById(String id) {
    try {
      return _filteredDrivingHistory.firstWhere(
        (history) => history.drivingHistoryId == id,
      );
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getDrivingTips() async {
    try {
      // Set date filter for past 3 months
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      
      final startDate = DateFormat('yyyy-MM-dd').format(threeMonthsAgo);
      final endDate = DateFormat('yyyy-MM-dd').format(now);
      
      final url = '${dotenv.env['BACKEND_URL']}/api/driving/tips?startDate=$startDate&endDate=$endDate';
      
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse);
        return jsonResponse;
      } else {
        return {
          'drivingSummary': {},
          'drivingTips': 'Unable to fetch driving tips at this time.'
        };
      }
    } catch (e) {
      debugPrint('Error fetching driving tips: $e');
      return {
        'drivingSummary': {},
        'drivingTips': 'Connection error while retrieving driving tips.'
      };
    }
  }
}
