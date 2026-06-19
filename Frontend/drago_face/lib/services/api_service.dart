import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiService {
  static const String _baseUrl = 'http://10.171.150.228:8000';

  static Future<String> sendMessage({
    required String message,
    String? memoryContext,
    List<Map<String, String>>? history,
  }) async {
    try {
      print('[Chat] Sending to backend...');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message':        message,
          'memory_context': memoryContext,
          'history':        history ?? [],
        }),
      ).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          print('[Chat] TIMED OUT after 60s');
          return http.Response(
            '{"response": "Request timed out. Please try again."}',
            200,
          );
        },
      );

      print('[Chat] Status: ${response.statusCode}');
      print('[Chat] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String;
      }
      return 'Server error: ${response.statusCode}';

    } on TimeoutException {
      print('[Chat] TimeoutException caught');
      return 'Request timed out. Please try again.';
    } catch (e) {
      print('[Chat] ERROR: $e');
      return 'Network error: $e';
    }
  }

  static Future<Map<String, String>> extractMemory(String message) async {
    // Skip short messages — they never contain personal info
    if (message.trim().split(' ').length < 4) {
      print('[Memory] Skipped: message too short');
      return {};
    }

    try {
      print('[Memory] Extracting from: $message');

      final response = await http.post(
        Uri.parse('$_baseUrl/extract-memory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 15));

      print('[Memory] Status: ${response.statusCode}');
      print('[Memory] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['memory'] as Map<String, dynamic>? ?? {};
        return raw.map((k, v) => MapEntry(k, v.toString()));
      }
    } on TimeoutException {
      print('[Memory] Timed out — skipping silently');
    } catch (e) {
      print('[Memory] ERROR: $e');
    }
    return {};
  }
}