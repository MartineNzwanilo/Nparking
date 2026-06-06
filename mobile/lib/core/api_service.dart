import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'constants.dart';
import 'database_helper.dart';

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ApiConstants.apiBaseUrl,
  );
  static final Uri _baseUri = Uri.parse(_configuredBaseUrl);
  static const Duration _timeout = Duration(seconds: 12);
  static String? _authToken;
  static void Function()? onUnauthorized;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _headers({bool json = false}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Uri _buildUri(String endpoint) {
    return Uri.parse('${_baseUri.toString()}$endpoint');
  }

  // Helper method for GET requests
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            _buildUri(endpoint),
            headers: _headers(),
          )
          .timeout(_timeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          final db = await DatabaseHelper.instance.database;
          await db.insert('api_cache', {
            'endpoint': endpoint,
            'response': response.body,
            'timestamp': DateTime.now().toIso8601String()
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } catch (e) {
          print('Failed to cache API response: $e');
        }
        return data;
      } else {
        if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
          onUnauthorized?.call();
        }
        throw Exception(
          'Failed to load data from $endpoint (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('Network request failed for $endpoint, trying offline cache. Error: $e');
      try {
        final db = await DatabaseHelper.instance.database;
        final cached = await db.query('api_cache', where: 'endpoint = ?', whereArgs: [endpoint]);
        if (cached.isNotEmpty) {
          return jsonDecode(cached.first['response'] as String);
        }
      } catch (cacheError) {
        print('Failed to read from offline cache: $cacheError');
      }
      rethrow;
    }
  }

  // Helper method for POST requests
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http
        .post(
          _buildUri(endpoint),
          headers: _headers(json: true),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
        onUnauthorized?.call();
      }
      throw Exception(
        'Failed to post data to $endpoint (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Helper method for PATCH requests
  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final response = await http
        .patch(
          _buildUri(endpoint),
          headers: _headers(json: true),
          body: jsonEncode(data),
        )
        .timeout(_timeout);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
        onUnauthorized?.call();
      }
      throw Exception(
        'Failed to update data at $endpoint (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Helper method for DELETE requests
  Future<void> delete(String endpoint) async {
    final response = await http
        .delete(
          _buildUri(endpoint),
          headers: _headers(),
        )
        .timeout(_timeout);
    if (response.statusCode != 200 && response.statusCode != 204) {
      if (response.statusCode == 401 && !endpoint.startsWith('/auth/')) {
        onUnauthorized?.call();
      }
      throw Exception(
        'Failed to delete data at $endpoint (${response.statusCode}): ${response.body}',
      );
    }
  }

  // Helper method for file uploads
  Future<String> uploadImage(String filePath) async {
    final request = http.MultipartRequest('POST', _buildUri('/upload'));
    request.headers.addAll(_headers());
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    final streamedResponse = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['url'];
    } else {
      if (response.statusCode == 401) {
        onUnauthorized?.call();
      }
      throw Exception('Failed to upload image (${response.statusCode}): ${response.body}');
    }
  }
}
