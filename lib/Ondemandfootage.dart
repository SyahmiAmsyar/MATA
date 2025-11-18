import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;

class Ondemandfootage extends StatefulWidget {
  const Ondemandfootage({super.key});

  @override
  State<Ondemandfootage> createState() => _OndemandfootageState();
}

class _OndemandfootageState extends State<Ondemandfootage> {
  late final WebViewController _controller;

  // URL for the video feed (M-JPEG stream)
  final String streamUrl = 'https://matavision.ngrok.app/video_feed';

  // ✅ CORRECTION: URL for sending control commands ('start'/'stop').
  // This is typically the base URL + /stream, not /video_feed/stream.
  final String controlUrl = 'https://matavision.ngrok.app/stream';

  bool isStopping = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(streamUrl));
  }

  /// Sends a 'stop' command to the server's control endpoint.
  Future<void> stopStream() async {
    if (isStopping) return;
    setState(() => isStopping = true);

    try {
      final response = await http.post(
        Uri.parse(controlUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "stop"}),
      );

      if (response.statusCode == 200) {
        // Optionally clear the cache and show a "stopped" message
        await _controller.clearCache();
        await _controller.loadHtmlString(
          "<html><body><div style='display: flex; justify-content: center; align-items: center; height: 100vh; color: white; background-color: black; font-size: 20px;'>Live Stream Stopped.</div></body></html>",
        );

        // Wait briefly before closing the page
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) Navigator.pop(context);
      } else {
        // Show failure message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "⚠️ Failed to stop stream (HTTP ${response.statusCode})",
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Show connection error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("⚠️ Connection Error: $e")));
      }
    }

    if (mounted) setState(() => isStopping = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Stream"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadRequest(Uri.parse(streamUrl)),
          ),
          IconButton(
            icon: Icon(
              isStopping ? Icons.hourglass_top : Icons.stop,
              color: Colors.red,
            ),
            // Disable the button while the stop command is being sent
            onPressed: isStopping ? null : stopStream,
          ),
        ],
      ),
      // Ensure WebView fills the screen
      body: Container(
        color: Colors.black,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
