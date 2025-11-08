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
  late WebViewController _controller;
  final String streamUrl = 'http://172.20.10.10:5000/video_feed';
  final String controlUrl = 'http://172.20.10.10:5000/stream';
  bool isStopping = false;

  /// Function to stop the stream on Raspberry Pi and return to Dashboard
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
        // ✅ Dispose WebView before leaving
        await _controller.clearCache();
        _controller.loadHtmlString("<html><body><h3>Stream stopped.</h3></body></html>");

        // Wait a moment to make sure stream stops fully on Pi
        await Future.delayed(const Duration(seconds: 1));

        if (mounted) {
          Navigator.pop(context); // ✅ Return to Dashboard
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Failed to stop stream (${response.statusCode})")),
        );
        setState(() => isStopping = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: $e")),
      );
      setState(() => isStopping = false);
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
            onPressed: () => _controller.loadUrl(streamUrl),
          ),
          IconButton(
            icon: Icon(
              isStopping ? Icons.hourglass_top : Icons.stop,
              color: Colors.red,
            ),
            onPressed: isStopping ? null : stopStream,
          ),
        ],
      ),
      body: WebView(
        initialUrl: streamUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (controller) {
          _controller = controller;
        },
      ),
    );
  }
}
