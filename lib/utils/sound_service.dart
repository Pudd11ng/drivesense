import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FreeSoundService {
  static const String baseUrl = 'https://freesound.org/apiv2';
  static String? _apiKey;
  static final Map<String, String> previewUrlCache = {};
  final http.Client _client = http.Client();
  
  // Initialize with API key check
  FreeSoundService() {
    _apiKey = dotenv.env['FREESOUND_API_KEY'];
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('⚠️ WARNING: FreeSound API key not found in environment!');
    }
  }

  // Proper text search implementation following API docs
  Future<List<FreeSoundItem>> searchSounds(
    String query, {
    int page = 1,
    int pageSize = 15,
    String? filter,
    String sort = 'score',
    String fields = 'id,name,username,previews,duration,license,tags',
  }) async {
    try {
      if (_apiKey == null) {
        throw Exception('FreeSound API key not configured');
      }
      
      final queryParams = {
        'query': query,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'token': _apiKey!,
        'fields': fields,
      };
      
      // Add optional parameters if provided
      if (filter != null) queryParams['filter'] = filter;
      if (sort != 'score') queryParams['sort'] = sort;
      
      final uri = Uri.parse('$baseUrl/search/text/').replace(queryParameters: queryParams);
      
      debugPrint('🔍 Searching FreeSound: ${uri.toString()}');
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'];
        return results.map((item) => FreeSoundItem.fromJson(item)).toList();
      } else {
        debugPrint(
          'FreeSound API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to search sounds: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('FreeSound search error: $e');
      throw Exception('Error searching sounds: $e');
    }
  }

  // Get sound details with proper fields
  Future<FreeSoundItem> getSoundDetails(int soundId) async {
    try {
      if (_apiKey == null) {
        throw Exception('FreeSound API key not configured');
      }
      
      final uri = Uri.parse('$baseUrl/sounds/$soundId/')
          .replace(queryParameters: {'token': _apiKey!});
      
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        return FreeSoundItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to get sound details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting sound details: $e');
    }
  }
  
  // Get similar sounds
  Future<List<FreeSoundItem>> getSimilarSounds(
      int soundId, {
      int page = 1, 
      int pageSize = 15,
      String fields = 'id,name,username,previews,duration,license,tags',
  }) async {
    try {
      if (_apiKey == null) {
        throw Exception('FreeSound API key not configured');
      }
      
      final queryParams = {
        'token': _apiKey!,
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'fields': fields,
      };
      
      final uri = Uri.parse('$baseUrl/sounds/$soundId/similar/')
          .replace(queryParameters: queryParams);
      
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List results = data['results'];
        
        return results.map((item) => FreeSoundItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to get similar sounds: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting similar sounds: $e');
    }
  }
  
  // Store preview URL in memory cache
  static void cachePreviewUrl(String behavior, String url) {
    previewUrlCache[behavior] = url;
  }
  
  // Get preview URL from memory cache
  static String? getPreviewUrl(String behavior) {
    return previewUrlCache[behavior];
  }
  
  void dispose() {
    _client.close();
  }
}

class FreeSoundItem {
  final int id;
  final String name;
  final String username;
  final String license;
  final Uri previewsHqMp3;
  final Duration duration;
  final Map<String, dynamic> images;
  final List<String>? tags;
  final double? avgRating; // Added rating field

  FreeSoundItem({
    required this.id,
    required this.name,
    required this.username,
    required this.license,
    required this.previewsHqMp3,
    required this.duration,
    required this.images,
    this.tags,
    this.avgRating,
  });

  factory FreeSoundItem.fromJson(Map<String, dynamic> json) {
    // Extract previews data safely
    final previewsMap = json['previews'] as Map<String, dynamic>? ?? {};
    final previewUrl = previewsMap['preview-hq-mp3'] as String? ?? '';
    
    // Extract tags safely
    List<String>? tagList;
    if (json['tags'] != null) {
      tagList = (json['tags'] as List).map((item) => item.toString()).toList();
    }
    
    // Extract rating (may be null)
    final avgRating = json['avg_rating'] != null 
        ? (json['avg_rating'] as num).toDouble() 
        : null;
    
    return FreeSoundItem(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      license: json['license'] as String,
      previewsHqMp3: Uri.parse(previewUrl),
      duration: Duration(milliseconds: ((json['duration'] as num? ?? 0) * 1000).round()),
      images: json['images'] as Map<String, dynamic>? ?? {},
      tags: tagList,
      avgRating: avgRating,
    );
  }
}
