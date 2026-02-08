import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Change this to your backend URL
  static const String baseUrl = 'http://172.18.52.32:6000';

  // Get auth token from local storage
  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ==================== AUTHENTICATION ====================

  /// Login with email and password
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10)); // Timeout after 10 seconds

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'message':
              'Login failed with status code ${response.statusCode}: ${response.body}',
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'ClientException: $e'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timed out'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    } finally {}
  }

  /// Sign up with email and password
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Signup failed: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Logout (clear local token)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('username');
  }

  // ==================== HERITAGE SITES ====================

  /// Detect heritage site from image
  // static Future<Map<String, dynamic>> detectHeritage(String base64Image) async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse('$baseUrl/api/heritage/detect'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'imageBase64': base64Image}),
  //     );

  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body);
  //     } else {
  //       throw Exception('Detection failed: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     throw Exception('Detection error: $e');
  //   }
  // }

  // /// Get list of heritage sites
  // static Future<List<Map<String, dynamic>>> getHeritageList({
  //   bool wheelchairOnly = false,
  // }) async {
  //   try {
  //     final url = Uri.parse(
  //       '$baseUrl/api/heritage/list?wheelchairOnly=$wheelchairOnly',
  //     );
  //     final response = await http.get(url);

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       return List<Map<String, dynamic>>.from(data['sites'] ?? []);
  //     } else {
  //       throw Exception('Failed to load heritage sites');
  //     }
  //   } catch (e) {
  //     throw Exception('Error: $e');
  //   }
  // }

  // /// Get heritage site details
  // static Future<Map<String, dynamic>> getHeritageDetails(int siteId) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$baseUrl/api/heritage/$siteId'),
  //     );

  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body);
  //     } else {
  //       throw Exception('Failed to load heritage details');
  //     }
  //   } catch (e) {
  //     throw Exception('Error: $e');
  //   }
  // }
  static Future<Map<String, dynamic>> detectHeritage(
      String base64Image, String mimeType) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/heritage/detect'),
            headers: {'Content-Type': 'application/json'},
            body:
                jsonEncode({'imageBase64': base64Image, 'mimeType': mimeType}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Detect response status: ${response.statusCode}');
      debugPrint('Detect response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Safely parse error, fallback to raw body
        dynamic errorData;
        try {
          errorData = jsonDecode(response.body);
        } catch (_) {
          errorData = {'error': response.body};
        }
        throw Exception(
          'Failed to detect heritage (${response.statusCode}): ${errorData['error'] ?? 'Unknown error'}',
        );
      }
    } on TimeoutException {
      throw Exception('Heritage detection request timed out');
    } catch (e) {
      throw Exception('Error detecting heritage: $e');
    }
  }

  static Future<List<dynamic>> getHeritageList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/heritage/list'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['sites'] ?? [];
      } else {
        throw Exception('Failed to get heritage list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting heritage list: $e');
    }
  }

  static Future<Map<String, dynamic>> getHeritageDetails(int siteId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/heritage/$siteId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get heritage details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting heritage details: $e');
    }
  }
  // ==================== ISSUE REPORTS ====================

  /// Create a new issue report
  static Future<Map<String, dynamic>> createIssue({
    required String category,
    required String photoBase64,
    required double latitude,
    required double longitude,
    String? address,
    String? description,
  }) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/issues/create'),
        headers: headers,
        body: jsonEncode({
          'category': category,
          'photoBase64': photoBase64,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create issue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get list of issue reports
  static Future<List<Map<String, dynamic>>> getIssuesList({
    String? status,
    String? category,
  }) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
      };

      String url = '$baseUrl/api/issues/list';
      final params = <String>[];
      if (status != null) params.add('status=$status');
      if (category != null) params.add('category=$category');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['issues'] ?? []);
      } else {
        throw Exception('Failed to load issues');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get issue details
  static Future<Map<String, dynamic>> getIssueDetails(int issueId) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/issues/$issueId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load issue details');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Update issue status
  static Future<Map<String, dynamic>> updateIssueStatus({
    required int issueId,
    required String status,
  }) async {
    try {
      final token = await _getAuthToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/api/issues/$issueId/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Get user's own issue reports
  static Future<List<Map<String, dynamic>>> getUserIssues() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final headers = {
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/api/issues/user/my-issues'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['issues'] ?? []);
      } else {
        throw Exception('Failed to load your issues');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
