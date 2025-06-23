import 'dart:convert';
import 'package:drivesense/routing/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:drivesense/domain/models/user/user.dart';
import 'package:drivesense/utils/auth_service.dart';
import 'package:drivesense/domain/models/notification/notification.dart';
import 'package:provider/provider.dart';
import 'package:drivesense/utils/fcm_service.dart';

// This view model handles user authentication and management
// It includes methods for logging in, registering, and updating user profiles
class UserManagementViewModel extends ChangeNotifier {
  late User _user;
  List<User> _emergencyContacts = [];
  bool _needsProfileCompletion = false;
  bool _isLoading = false;
  String? _errorMessage;

  List<UserNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoadingNotifications = false;
  String? _notificationError;
  bool _hasMoreNotifications = true;
  int _page = 0;
  final int _notificationLimit = 20;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
    serverClientId: dotenv.env['SERVER_ClIENT_ID'],
  );

  final AuthService _authService = AuthService();

  String? _cachedToken;

  bool get isAuthenticated => _cachedToken != null;
  bool get hasValidAuth => _cachedToken != null;

  User get user => _user;
  List<User> get emergencyContacts => _emergencyContacts;
  bool get needsProfileCompletion => _needsProfileCompletion;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<UserNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoadingNotifications => _isLoadingNotifications;
  String? get notificationError => _notificationError;
  bool get hasMoreNotifications => _hasMoreNotifications;

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
          final int expiresIn =
              responseData['expiresIn'] ?? 604800; // 7 days default

          // Set token in AuthService instead of local storage
          await _authService.setToken(
            responseData['token'],
            expiresInSeconds: expiresIn,
          );

          if (responseData['user'] != null) {
            _user = User.fromJson(responseData['user']);

            _needsProfileCompletion =
                _user.firstName.isEmpty ||
                _user.lastName.isEmpty ||
                _user.dateOfBirth.isEmpty ||
                _user.country.isEmpty;
          }
        }

        _isLoading = false;
        notifyListeners();

        try {
          final fcmService = Provider.of<FcmService>(
            rootNavigatorKey.currentContext!,
            listen: false,
          );
          if (fcmService.fcmToken != null) {
            await updateFcmToken(fcmService.fcmToken!);
          }
        } catch (e) {
          debugPrint('Failed to update FCM token: $e');
        }

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
          final int expiresIn =
              responseData['expiresIn'] ?? 604800; // 24 hours default

          // Set token in AuthService instead of local storage
          await _authService.setToken(
            responseData['token'],
            expiresInSeconds: expiresIn,
          );

          if (responseData['user'] != null) {
            _user = User.fromJson(responseData['user']);

            _needsProfileCompletion =
                _user.firstName.isEmpty ||
                _user.lastName.isEmpty ||
                _user.dateOfBirth.isEmpty ||
                _user.country.isEmpty;
          }
        }

        _isLoading = false;
        notifyListeners();

        try {
          final fcmService = Provider.of<FcmService>(
            rootNavigatorKey.currentContext!,
            listen: false,
          );
          if (fcmService.fcmToken != null) {
            await updateFcmToken(fcmService.fcmToken!);
          }
        } catch (e) {
          debugPrint('Failed to update FCM token: $e');
        }

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
          final int expiresIn =
              responseData['expiresIn'] ?? 604800; // 7 days default

          // Set token in AuthService instead of local storage
          await _authService.setToken(
            responseData['token'],
            expiresInSeconds: expiresIn,
          );

          if (responseData['user'] != null) {
            _user = User.fromJson(responseData['user']);

            _needsProfileCompletion =
                _user.firstName.isEmpty ||
                _user.lastName.isEmpty ||
                _user.dateOfBirth.isEmpty ||
                _user.country.isEmpty;
          }
        }
        _isLoading = false;
        notifyListeners();

        try {
          final fcmService = Provider.of<FcmService>(
            rootNavigatorKey.currentContext!,
            listen: false,
          );
          if (fcmService.fcmToken != null) {
            await updateFcmToken(fcmService.fcmToken!);
          }
        } catch (e) {
          debugPrint('Failed to update FCM token: $e');
        }

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

  // Password reset functionality
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Password reset email sent: $responseData');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Password reset error: $errorData');

        _isLoading = false;
        _errorMessage =
            errorData['message'] ??
            'Failed to send reset link. Status code: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Password reset exception: $e');

      _isLoading = false;
      _errorMessage =
          'Failed to send reset link. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  /// Resets user's password with the provided token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': token, 'password': newPassword}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('Password reset successful: $responseData');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Password reset error: $errorData');

        _isLoading = false;
        _errorMessage =
            errorData['message'] ??
            'Failed to reset password. The link may have expired or is invalid.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Password reset exception: $e');

      _isLoading = false;
      _errorMessage =
          'Failed to reset password. Please check your connection and try again.';
      notifyListeners();
      return false;
    }
  }

  // Create a method to get an HTTP client with the auth token
  Future<http.Client> getAuthenticatedClient() async {
    final token = await _authService.getToken();
    return AuthHttpClient(authToken: token);
  }

  // Method to fetch notifications
  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _page = 0;
      _hasMoreNotifications = true;
    }

    if (!_hasMoreNotifications && !refresh) return;

    _isLoadingNotifications = true;
    _notificationError = null;
    if (refresh) {
      notifyListeners();
    }

    try {
      final skip = _page * _notificationLimit;
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse(
          '${dotenv.env['BACKEND_URL']}/api/notifications?limit=$_notificationLimit&skip=$skip',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<UserNotification> fetchedNotifications =
            (data['notifications'] as List)
                .map((json) => UserNotification.fromJson(json))
                .toList();

        if (refresh) {
          _notifications = fetchedNotifications;
        } else {
          _notifications.addAll(fetchedNotifications);
        }

        _page++;
        _hasMoreNotifications = data['hasMore'] ?? false;
        _unreadCount = data['unreadCount'] ?? 0;

        _isLoadingNotifications = false;
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        _notificationError =
            errorData['message'] ?? 'Failed to load notifications';
        _isLoadingNotifications = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      _notificationError =
          'Failed to load notifications. Please check your connection.';
      _isLoadingNotifications = false;
      notifyListeners();
    }
  }

  // Get unread count only
  Future<void> fetchUnreadNotificationCount() async {
    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse(
          '${dotenv.env['BACKEND_URL']}/api/notifications/unread-count',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _unreadCount = data['unreadCount'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  // Mark notification as read
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      debugPrint('Marking notification as read: $notificationId');
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse(
          '${dotenv.env['BACKEND_URL']}/api/notifications/$notificationId/read',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({}),
      );

      debugPrint(
        'Marking notification as read: $notificationId, status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        // Update local state
        final index = _notifications.indexWhere(
          (n) => n.notificationId == notificationId,
        );
        if (index != -1) {
          final notification = _notifications[index];
          if (!notification.isRead) {
            _notifications[index] = UserNotification(
              notificationId: notification.notificationId,
              title: notification.title,
              body: notification.body,
              type: notification.type,
              isRead: true,
              data: notification.data,
              createdAt: notification.createdAt,
            );
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
            notifyListeners();
          }
        }
        return true;
      } else {
        debugPrint('Failed to mark as read: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    try {
      final token = await _authService.getToken();
      final response = await http.put(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        // Update local state
        _notifications =
            _notifications
                .map(
                  (notification) => UserNotification(
                    notificationId: notification.notificationId,
                    title: notification.title,
                    body: notification.body,
                    type: notification.type,
                    isRead: true,
                    data: notification.data,
                    createdAt: notification.createdAt,
                  ),
                )
                .toList();
        _unreadCount = 0;
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to mark all as read: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  // Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse(
          '${dotenv.env['BACKEND_URL']}/api/notifications/$notificationId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        final notification = _notifications.firstWhere(
          (n) => n.notificationId == notificationId,
          orElse:
              () => UserNotification(
                notificationId: '',
                title: '',
                body: '',
                type: '',
                isRead: true,
                createdAt: DateTime.now(),
              ),
        );

        if (!notification.isRead) {
          _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
        }

        _notifications.removeWhere((n) => n.notificationId == notificationId);
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to delete: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  // Clear all notifications
  Future<bool> clearAllNotifications() async {
    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Update local state
        _notifications = [];
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
      return false;
    }
  }

  // Update FCM token
  Future<void> updateFcmToken(String fcmToken) async {
    if (fcmToken.isEmpty) return;

    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'token': fcmToken}),
      );
      debugPrint('Updating FCM token: $fcmToken');

      if (response.statusCode == 200) {
        debugPrint('FCM token updated successfully');
      } else {
        debugPrint('Failed to update FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  // Update checkAuthStatus to also fetch notification count
  Future<void> checkAuthStatus() async {
    try {
      _cachedToken = await _authService.getToken();
      
      if (_cachedToken != null) {
        try {
          await loadUserProfile();
          await fetchUnreadNotificationCount();
          
          // Update FCM token if available
          final fcmService = Provider.of<FcmService>(
            rootNavigatorKey.currentContext!, 
            listen: false
          );
          if (fcmService.fcmToken != null) {
            await updateFcmToken(fcmService.fcmToken!);
          }
        } catch (e) {
          debugPrint('Error loading user profile: $e');
          await logout();
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      _cachedToken = null;
      notifyListeners();
    }
  }

  Future<void> loadUserProfile() async {
    final token = await _authService.getToken();

    final response = await http.get(
      Uri.parse('${dotenv.env['BACKEND_URL']}/api/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      _user = User.fromJson(userData['user']);
      _needsProfileCompletion =
          _user.firstName.isEmpty ||
          _user.lastName.isEmpty ||
          _user.dateOfBirth.isEmpty ||
          _user.country.isEmpty;
      notifyListeners();
    } else {
      // If profile fetch fails, token might be invalid
      throw Exception('Failed to load user profile');
    }
  }

  // Generate a secure invitation link
  Future<String> generateInvitationCode() async {
    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse(
          '${dotenv.env['BACKEND_URL']}/api/users/emergency-contacts/generate-code',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final inviteCode = data['inviteCode'];
        return 'https://drivesense.my/emergency-invite?code=$inviteCode';
      } else {
        throw Exception('Failed to generate invitation code');
      }
    } catch (e) {
      debugPrint('Error generating invitation code: $e');
      throw Exception('Could not generate invitation link. Please try again.');
    }
  }

  // Accept an invitation
  Future<bool> acceptEmergencyInvitation(String inviteCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await http.post(
        Uri.parse(
          '${dotenv.env['BACKEND_URL']}/api/users/emergency-contacts/accept',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'inviteCode': inviteCode}),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        // Todo: maybe need notify the other user
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Error accepting invitation: $errorData');

        _isLoading = false;
        _errorMessage = errorData['message'] ?? 'Failed to accept invitation';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Exception accepting invitation: $e');

      _isLoading = false;
      _errorMessage =
          'Failed to accept invitation. Please check your connection.';
      notifyListeners();
      return false;
    }
  }

  // Fetch user's emergency contacts
  Future<void> fetchEmergencyContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await http.get(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/users/emergency-contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Parse emergency contact user IDs from the response
        _user = _user.copyWith(
          emergencyContactUserIds: List<String>.from(
            data['contactUserIds'] ?? [],
          ),
        );

        // Parse full emergency contact user objects
        _emergencyContacts =
            (data['contacts'] as List)
                .map((contact) => User.fromJson(contact))
                .toList();

        _isLoading = false;
        notifyListeners();
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Error fetching emergency contacts: $errorData');

        _isLoading = false;
        _errorMessage =
            errorData['message'] ?? 'Failed to load emergency contacts';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Exception fetching emergency contacts: $e');

      _isLoading = false;
      _errorMessage =
          'Failed to load emergency contacts. Please check your connection.';
      notifyListeners();
    }
  }

  // Remove an emergency contact
  Future<bool> removeEmergencyContact(String contactUserId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.getToken();
      final response = await http.delete(
        Uri.parse(
          '${dotenv.env['BACKEND_URL']}/api/users/emergency-contacts/$contactUserId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Update the local lists
        _user = _user.copyWith(
          emergencyContactUserIds:
              _user.emergencyContactUserIds
                  .where((id) => id != contactUserId)
                  .toList(),
        );

        _emergencyContacts =
            _emergencyContacts
                .where((contact) => contact.userId != contactUserId)
                .toList();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = json.decode(response.body);
        debugPrint('Error removing emergency contact: $errorData');

        _isLoading = false;
        _errorMessage =
            errorData['message'] ?? 'Failed to remove emergency contact';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Exception removing emergency contact: $e');

      _isLoading = false;
      _errorMessage =
          'Failed to remove emergency contact. Please check your connection.';
      notifyListeners();
      return false;
    }
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
