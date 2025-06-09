import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:drivesense/utils/auth_service.dart';

class CloudStorageService {
  static final AuthService _authService = AuthService();

  // Get headers for API requests
  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get signed URL from backend
  static Future<Map<String, dynamic>> getSignedUploadUrl(
    String behavior,
    String fileType,
    String contentType,
  ) async {
    try {
      final url = '${dotenv.env['BACKEND_URL']}/api/alerts/upload-url';
      final queryParams = {
        'behavior': behavior,
        'fileType': fileType,
        'contentType': contentType,
      };

      final response = await http.get(
        Uri.parse(url).replace(queryParameters: queryParams),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get upload URL: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
      throw e;
    }
  }

  // Upload file using signed URL
  static Future<String> uploadFileWithSignedUrl(
    File file,
    String signedUrl,
    String contentType,
  ) async {
    try {
      final response = await http.put(
        Uri.parse(signedUrl),
        headers: {'Content-Type': contentType},
        body: await file.readAsBytes(),
      );

      if (response.statusCode == 200) {
        return signedUrl;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw e;
    }
  }
}
