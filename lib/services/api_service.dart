import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://172.18.52.86:6000'; // Change to your server URL

  // Heritage APIs
  static Future<Map<String, dynamic>> detectHeritage(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/heritage/detect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imageBase64': base64Image}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to detect heritage: ${response.statusCode}');
      }
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
        throw Exception('Failed to get heritage details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting heritage details: $e');
    }
  }

  // Issue APIs
  static Future<Map<String, dynamic>> createIssue({
    required String category,
    required String photoBase64,
    required double latitude,
    required double longitude,
    String? address,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/issues/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': category,
          'photoBase64': photoBase64,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'description': description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create issue: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating issue: $e');
    }
  }

  static Future<List<dynamic>> getIssuesList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/issues/list'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['issues'] ?? [];
      } else {
        throw Exception('Failed to get issues list: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting issues list: $e');
    }
  }

  static Future<Map<String, dynamic>> getIssueDetails(int issueId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/issues/$issueId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get issue details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting issue details: $e');
    }
  }

  static Future<Map<String, dynamic>> updateIssueStatus(
    int issueId,
    String status,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/issues/$issueId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update issue status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating issue status: $e');
    }
  }
}
