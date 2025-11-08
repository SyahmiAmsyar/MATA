import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_page.dart';
import 'login_page.dart';
import 'LiveGpsPage.dart';
import 'history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  bool _isDeviceConnected = true;
  bool _liveFootageForced = false;

  String _username = "";
  final String piUrl = "http://172.20.10.10:5000"; // ✅ Pi IP or ngrok URL

  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _updateBatteryLevel();
    _battery.onBatteryStateChanged.listen((_) => _updateBatteryLevel());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? 'User');
  }

  Future<void> _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (mounted) setState(() => _batteryLevel = level);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    await prefs.remove('username');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  /// ✅ Toggle live stream start / stop safely
  Future<void> _toggleLiveFootageForce() async {
    final action = _liveFootageForced ? "stop" : "start";
    final url = Uri.parse("$piUrl/stream");

    try {
      print("📡 Sending $action request to $url ...");
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": action}),
      );

      print("✅ Response ${res.statusCode}: ${res.body}");

      if (res.statusCode == 200) {
        if (!_liveFootageForced) {
          // ✅ Starting the stream
          setState(() => _liveFootageForced = true);

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveStreamPage(
                streamUrl: "$piUrl/video_feed",
                onStop: () => setState(() => _liveFootageForced = false),
              ),
            ),
          );
        } else {
          // ✅ Stopping the stream
          setState(() => _liveFootageForced = false);
          _showSnackBar("Live stream stopped.");
        }
      } else {
        _showSnackBar("Failed to toggle stream: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Error: $e");
      _showSnackBar("Error: $e");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 120;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0073B1),
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "👋 Welcome back, $_username!",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Connection & Battery Cards
            SizedBox(
              height: cardHeight,
              child: Row(
                children: [
                  _buildGradientCard(
                    title: "Connection",
                    value: _isDeviceConnected ? "CONNECTED" : "DISCONNECTED",
                    icon: FontAwesomeIcons.glasses,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFFB9F6CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildGradientCard(
                    title: "Battery",
                    value: "$_batteryLevel%",
                    icon: Icons.battery_full,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2979FF), Color(0xFF82B1FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  icon: Icons.location_on,
                  label: "Live GPS",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LiveGpsPage()),
                  ),
                ),
                _buildActionButton(
                  icon: Icons.history,
                  label: "History",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryPage()),
                  ),
                ),
                _buildActionButton(
                  icon: _liveFootageForced
                      ? Icons.videocam
                      : Icons.videocam_off,
                  label: _liveFootageForced ? "Stop Live" : "Start Live",
                  onTap: _toggleLiveFootageForce,
                  color: _liveFootageForced ? Colors.red : Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Recent Activity",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          children: const [
                            ListTile(
                              leading: Icon(Icons.location_on),
                              title: Text("Location updated"),
                              subtitle: Text("11:30 AM"),
                            ),
                            ListTile(
                              leading: Icon(Icons.battery_charging_full),
                              title: Text("Battery charged to 85%"),
                              subtitle: Text("08:45 AM"),
                            ),
                            ListTile(
                              leading: Icon(Icons.device_hub),
                              title: Text("Device connected"),
                              subtitle: Text("09:15 AM"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Status Cards
  Widget _buildGradientCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Buttons
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF0073B1),
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

// ✅ Safe Live Stream Page
class LiveStreamPage extends StatefulWidget {
  final String streamUrl;
  final VoidCallback onStop;

  const LiveStreamPage({
    super.key,
    required this.streamUrl,
    required this.onStop,
  });

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late final WebViewController _controller;
  bool _isStopping = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.streamUrl));
  }

  Future<void> _stopStream() async {
    if (_isStopping) return;
    setState(() => _isStopping = true);

    try {
      final res = await http.post(
        Uri.parse("http://172.20.10.10:5000/stream"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": "stop"}),
      );
      print("🔴 Stream stop response: ${res.body}");
    } catch (e) {
      print("❌ Error stopping stream: $e");
    }

    widget.onStop(); // update dashboard state
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Live Stream"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.red),
            onPressed: _stopStream,
          ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
