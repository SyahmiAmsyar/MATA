import 'dart:convert';
import 'package:http/http.dart' as http;

class StreamService {
  // ✅ FIX: Append the '/stream' endpoint to the control URL.
  // The server expects the command at this specific route.
  final String controlUrl = "https://matavision.ngrok.app/stream";

  /// Sends a command ('start' or 'stop') to the backend stream control endpoint.
  Future<bool> controlStream(String action) async {
    final url = Uri.parse(controlUrl);
    try {
      print("📡 Sending '$action' request to $url ...");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": action}),
      );

      print("✅ Response ${response.statusCode}: ${response.body}");

      if (response.statusCode == 200) {
        print("Stream $action command sent successfully");
        return true;
      } else {
        print("Failed to send command: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error sending stream command: $e");
      return false;
    }
  }
}
