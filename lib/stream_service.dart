import 'dart:convert';
import 'package:http/http.dart' as http;

class StreamService {
  final String baseUrl = "http://172.20.10.10";  // Your Pi's IP

  Future<void> controlStream(String action) async {
    final url = Uri.parse("$baseUrl/stream");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"action": action}),
    );

    if (response.statusCode == 200) {
      print("Stream $action command sent successfully");
    } else {
      print("Failed to send command: ${response.statusCode}");
    }
  }
}
