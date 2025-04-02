import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drivesense/domain/models/user/user.dart';

class UserManagementViewModel extends ChangeNotifier {
  // This view model handles user authentication and management
  late User _user;
  bool _isLoading = false;
  String? _errorMessage;

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Email/Password Login
  Future<bool> loginWithEmailPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual login logic with backend
      // Simulating network call
      await Future.delayed(const Duration(seconds: 2));

      // Successful login
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement Google Sign-In
      // This is a placeholder for actual Google Sign-In implementation
      await Future.delayed(const Duration(seconds: 2));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google Sign-In failed.';
      notifyListeners();
      return false;
    }
  }

  // Email/Password Registration
  Future<bool> registerWithEmailPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO: Implement actual registration logic with backend
      await Future.delayed(const Duration(seconds: 2));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> loadUserData() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/user_data.json',
      );
      final Map<String, dynamic> userData = json.decode(response);
      _user = User.fromJson(userData);
      notifyListeners();
    } catch (e) {
      // Debug the error
      debugPrint('Error loading user data: $e');

      // For more detailed stack trace info
      debugPrint('Stack trace: ${StackTrace.current}');

      _user = User(
        userId: 'u000',
        firstName: 'Default',
        lastName: 'User',
        email: 'default@example.com',
        password: 'password123',
        dateOfBirth: '01/01/2000',
        country: 'Unknown',
      );
      notifyListeners();
    }
  }

  void updateUserProfile({
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? dateOfBirth,
    String? country,
  }) {
    _user = User(
      userId: userId ?? _user.userId,
      firstName: firstName ?? _user.firstName,
      lastName: lastName ?? _user.lastName,
      email: email ?? _user.email,
      password: password ?? _user.password,
      dateOfBirth: dateOfBirth ?? _user.dateOfBirth,
      country: country ?? _user.country,
    );
    notifyListeners();
  }
}
