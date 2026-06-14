import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String _baseUrl = 'http://localhost:8000'; // iOS simulator

  /// Send a chat message with memory context and conversation history
  static Future<String> sendMessage({
    required String message,
    String? memoryContext,
    List<Map<String, String>>? history,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message':        message,
          'memory_context': memoryContext,
          'history':        history ?? [],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String;
      }
      return 'Sorry, I had trouble connecting. Please try again.';
    } catch (e) {
    print('[ApiService] sendMessage error: $e');
      return 'Network error. Please check your connection.';
    }
  }

  /// Extract memory from a message — never throws
  static Future<Map<String, String>> extractMemory(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/extract-memory'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final raw = data['memory'] as Map<String, dynamic>? ?? {};
        // Cast everything to String safely
        return raw.map((k, v) => MapEntry(k, v.toString()));
      }
    } catch (e) {
      print('[ApiService] extractMemory error: $e');
    }
    return {};
  }
}