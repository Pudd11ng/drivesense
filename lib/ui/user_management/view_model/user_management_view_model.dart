import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:drivesense/domain/models/user/user.dart';
import 'package:drivesense/utils/auth_service.dart';

// This view model handles user authentication and management
// It includes methods for logging in, registering, and updating user profiles
class UserManagementViewModel extends ChangeNotifier {
  late User _user;
  bool _needsProfileCompletion = false;
  bool _isLoading = false;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
    serverClientId: dotenv.env['SERVER_ClIENT_ID'],
  );

  final AuthService _authService = AuthService();

  User get user => _user;
  bool get isAuthenticated => _authToken != null;
  String? get _authToken => _authService.getToken() as String?;
  String? get authToken => _authToken;
  bool get needsProfileCompletion => _needsProfileCompletion;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Email/Password Login
  Future<bool> loginWithEmailPassword(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      // Store the JWT token from backend
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Login successful: $responseData');

        if (responseData['token'] != null) {
          final int expiresIn = responseData['expiresIn'] ?? 86400; // 24 hours default
          
          // Set token in AuthService instead of local storage
          await _authService.setToken(
            responseData['token'],
            expiresInSeconds: expiresIn,
          );

          if (responseData['user'] != null) {
            _user = User.fromJson(responseData['user']);

            _needsProfileCompletion = _user.firstName.isEmpty ||
                _user.lastName.isEmpty ||
                _user.dateOfBirth.isEmpty ||
                _user.country.isEmpty;
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Login error: $errorData');

        _isLoading = false;
        _errorMessage =
            errorData['message'] ??
            'Login failed with status code ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Login exception: $e');
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        _errorMessage = 'Google Sign-In was canceled.';
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _isLoading = false;
        _errorMessage = 'Failed to get Google authentication token.';
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/auth/google/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      // Store the JWT token from backend
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Google Sign-In successful: $responseData');

        if (responseData['token'] != null) {
          final int expiresIn = responseData['expiresIn'] ?? 86400; // 24 hours default
          
          // Set token in AuthService instead of local storage
          await _authService.setToken(
            responseData['token'],
            expiresInSeconds: expiresIn,
          );

          if (responseData['user'] != null) {
            _user = User.fromJson(responseData['user']);

            _needsProfileCompletion = _user.firstName.isEmpty ||
                _user.lastName.isEmpty ||
                _user.dateOfBirth.isEmpty ||
                _user.country.isEmpty;
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Google Sign-In error: $errorData');

        _isLoading = false;
        _errorMessage =
            errorData['message'] ??
            'Google Sign-In failed with status code ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Google Sign-In exception: $e');

      _isLoading = false;
      _errorMessage = 'Google Sign-In failed. Please try again. &exception: $e';
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
      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        debugPrint('Registration successful: $responseData');

        // Store the JWT token from backend
        if (responseData['token'] != null) {
          final int expiresIn = responseData['expiresIn'] ?? 86400; // 24 hours default
          
          // Set token in AuthService instead of local storage
          await _authService.setToken(
            responseData['token'],
            expiresInSeconds: expiresIn,
          );

          if (responseData['user'] != null) {
            _user = User.fromJson(responseData['user']);

            _needsProfileCompletion = _user.firstName.isEmpty ||
                _user.lastName.isEmpty ||
                _user.dateOfBirth.isEmpty ||
                _user.country.isEmpty;
          }
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Registration error: $errorData');

        _isLoading = false;
        _errorMessage =
            errorData['message'] ??
            'Registration failed with status code ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Registration exception: $e');

      _isLoading = false;
      _errorMessage =
          'Registration failed. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  // Logout method - simplified using AuthService
  Future<void> logout() async {
    await _authService.clearToken();
    notifyListeners();
  }

  // Update user profile - sends data to backend API
  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
    String? country,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Create updated user data
      final updatedUserData = {
        'userId': _user.userId,
        'firstName': firstName ?? _user.firstName,
        'lastName': lastName ?? _user.lastName,
        'email': email ?? _user.email,
        'dateOfBirth': dateOfBirth ?? _user.dateOfBirth,
        'country': country ?? _user.country,
      };

      // Get current token
      final token = await _authService.getToken();

      // Send PUT request to update profile
      final response = await http.put(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updatedUserData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Profile update successful: $responseData');

        // Update local user object
        _user = User(
          userId: _user.userId,
          firstName: firstName ?? _user.firstName,
          lastName: lastName ?? _user.lastName,
          email: email ?? _user.email,
          dateOfBirth: dateOfBirth ?? _user.dateOfBirth,
          country: country ?? _user.country,
        );

        // Profile is now complete
        _needsProfileCompletion = false;

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Profile update error: $errorData');

        _isLoading = false;
        _errorMessage =
            errorData['message'] ??
            'Profile update failed with status code ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Profile update exception: $e');

      _isLoading = false;
      _errorMessage =
          'Profile update failed. Please check your connection and try again. $e';
      notifyListeners();
      return false;
    }
  }

  // Create a method to get an HTTP client with the auth token
  Future<http.Client> getAuthenticatedClient() async {
    final token = await _authService.getToken();
    return AuthHttpClient(authToken: token);
  }
}

// Create a custom HTTP client that adds the authorization header
class AuthHttpClient extends http.BaseClient {
  final String? authToken;
  final http.Client _inner = http.Client();

  AuthHttpClient({this.authToken});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
  }
}
