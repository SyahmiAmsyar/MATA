import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class LiveStreamPage extends StatefulWidget {
  const LiveStreamPage({super.key});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late WebViewController _controller;
  final String streamUrl = 'http://172.20.10.10:5000/video_feed';
  final String controlUrl = 'http://172.20.10.10:5000/stream';

  /// Function to stop the stream on Raspberry Pi and return to Dashboard
  Future<void> stopStream() async {
    try {
      final response = await http.post(
        Uri.parse(controlUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "stop"}),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); // ✅ Close LiveStreamPage and go back
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Failed to stop stream")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Stream'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _controller.loadUrl(streamUrl); // 🔄 Reload the stream
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: stopStream, // ⏹ Stop stream & go back to Dashboard
          ),
        ],
      ),
      body: WebView(
        initialUrl: streamUrl, // Automatically load /video_feed
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (controller) {
          _controller = controller;
        },
      ),
    );
  }
}
