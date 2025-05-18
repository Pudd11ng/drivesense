import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  String? _authToken;
  DateTime? _tokenExpiry;
  final _storage = const FlutterSecureStorage();

  /// Gets the authentication token, loading from secure storage if needed
  /// Returns null if token is expired
  Future<String?> getToken() async {
    // If token is not in memory, try to load from storage
    if (_authToken == null) {
      await _loadTokenFromStorage();
    }
    
    // Check if token is expired
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      debugPrint('Token expired, clearing credentials');
      await clearToken();
      return null;
    }
    
    return _authToken;
  }

  /// Sets a new authentication token and saves to secure storage
  Future<void> setToken(String token, {int expiresInSeconds = 86400}) async {
    _authToken = token;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresInSeconds));
    
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(
      key: 'token_expiry',
      value: _tokenExpiry!.toIso8601String(),
    );
  }

  /// Clears the authentication token
  Future<void> clearToken() async {
    _authToken = null;
    _tokenExpiry = null;
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'token_expiry');
  }
  
  /// Load token and expiry from secure storage
  Future<void> _loadTokenFromStorage() async {
    _authToken = await _storage.read(key: 'auth_token');
    final expiryStr = await _storage.read(key: 'token_expiry');
    
    if (expiryStr != null) {
      try {
        _tokenExpiry = DateTime.parse(expiryStr);
      } catch (e) {
        debugPrint('Error parsing token expiry: $e');
        await clearToken();
      }
    }
  }
  
  /// Check if user is authenticated with a valid token
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}
