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
  late final WebViewController _controller; // Updated to new API
  final String streamUrl = 'http://172.20.10.10:5000/video_feed';
  final String controlUrl = 'http://172.20.10.10:5000/stream';
  bool isStopping = false;

  @override
  void initState() {
    super.initState();

    // Initialize WebViewController with WebViewController constructor (new API)
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(streamUrl));
  }

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
        await _controller.clearCache();
        await _controller.loadHtmlString(
            "<html><body><h3>Stream stopped.</h3></body></html>");

        await Future.delayed(const Duration(seconds: 1));

        if (mounted) Navigator.pop(context);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "⚠️ Failed to stop stream (${response.statusCode})")),
          );
          setState(() => isStopping = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Error: $e")),
        );
        setState(() => isStopping = false);
      }
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
            onPressed: () => _controller.loadRequest(Uri.parse(streamUrl)),
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
      body: WebViewWidget(
        controller: _controller, // New WebViewWidget usage
      ),
    );
  }
}
