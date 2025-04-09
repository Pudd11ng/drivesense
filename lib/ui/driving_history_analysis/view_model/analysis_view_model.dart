import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:drivesense/domain/models/driving_history/driving_history.dart';

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

  // Load driving history data from source (JSON file for demo)
  Future<void> loadDrivingHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Load from local JSON file (in real app, this would be an API call)
      final String response = await rootBundle.loadString(
        'assets/data/driving_history_data.json',
      );
      final List<dynamic> jsonData = json.decode(response);

      _allDrivingHistory =
          jsonData.map((data) => DrivingHistory.fromJson(data)).toList();

      // Apply initial month filter
      filterByMonth(_selectedMonth);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading driving history: $e');
      _isLoading = false;
      _errorMessage = 'Failed to load driving history. Please try again.';

      // Initialize with empty list on error
      _filteredDrivingHistory = [];

      notifyListeners();
    }
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

  int calculateRiskScore(DrivingHistory history) {
    // Calculate a risk score from 0-100 based on alerts and accidents
    int baseScore = 100;

    // Deduct points for each risky behavior
    baseScore -= history.riskyBehaviour.length * 5;

    // Deduct more points for accidents
    baseScore -= history.accident.length * 20;

    // Ensure score stays within 0-100 range
    return baseScore.clamp(0, 100);
  }

  String getRiskAnalysis(DrivingHistory history) {
    final score = calculateRiskScore(history);
    final duration = history.endTime.difference(history.startTime).inMinutes;

    if (score >= 90) {
      return 'Excellent driving session with minimal risk behaviors detected. Keep up the good work!';
    } else if (score >= 70) {
      return 'Good driving session with some risk behaviors. Consider taking breaks during drives longer than ${duration ~/ 2} minutes.';
    } else if (score >= 50) {
      return 'Average driving session with several risk behaviors detected. Try to minimize distractions and stay alert.';
    } else {
      return 'High-risk driving session. Multiple safety concerns were detected. Consider driver coaching or shorter trips in the future.';
    }
  }
}
