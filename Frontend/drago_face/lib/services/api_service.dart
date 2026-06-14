import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // static const String _baseUrl = "http://127.0.0.1:8000";
    static const String _baseUrl = "http://localhost:8000";

  static Future<String> sendMessage(String userMessage) async {
    final url = Uri.parse("$_baseUrl/chat");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMessage}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["response"] ?? "No response from Drago AI.";
      } else {
        return "Error: Server returned ${response.statusCode}";
      }
    } catch (e) {
      return "Error: Unable to connect to Drago AI server.";
    }
  }
}