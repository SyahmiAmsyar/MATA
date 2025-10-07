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

  // ✅ Change this to your Pi IP
  final String piUrl = "http://172.20.10.10:5000";

  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _updateBatteryLevel();
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _updateBatteryLevel();
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _updateBatteryLevel() async {
    final level = await _battery.batteryLevel;
    if (mounted) setState(() => _batteryLevel = level);
  }

  // ✅ Logout with clearing login state
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn'); // Clear login flag

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _toggleLiveFootageForce() async {
    final action = _liveFootageForced ? "stop" : "start";
    try {
      print("📡 Sending $action request to $piUrl/stream ...");

      final res = await http.post(
        Uri.parse("$piUrl/stream"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"action": action}),
      );

      print("✅ Response ${res.statusCode}: ${res.body}");

      if (res.statusCode == 200) {
        setState(() => _liveFootageForced = !_liveFootageForced);

        if (!_liveFootageForced) {
          Navigator.pop(context); // Close stream page if turning OFF
        } else {
          // ✅ Open stream page — Pi usually serves video on /video_feed
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveStreamPage(
                streamUrl: "$piUrl/video_feed",
              ),
            ),
          );
        }
      } else {
        _showSnackBar("Failed to toggle stream: ${res.statusCode}");
      }
    } catch (e) {
      print("❌ Error while toggling stream: $e");
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
    final double cardHeight = 120;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0073B1),
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "👋 Welcome back, Syahmi!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Status Cards Row
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

            // Quick Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionButton(
                  icon: Icons.location_on,
                  label: "Live GPS",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LiveGpsPage()));
                  },
                ),
                _buildActionButton(
                  icon: Icons.history,
                  label: "History",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HistoryPage()));
                  },
                ),
                _buildActionButton(
                  icon: _liveFootageForced ? Icons.videocam : Icons.videocam_off,
                  label: _liveFootageForced ? "Stop Live" : "Start Live",
                  onTap: _toggleLiveFootageForce,
                  color: _liveFootageForced ? Colors.red : Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity / Placeholder
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
                      const Text(
                        "Recent Activity",
                        style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
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

  // Gradient Status Card
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
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Quick Action Button
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

// ✅ LiveStreamPage with WebViewController
class LiveStreamPage extends StatefulWidget {
  final String streamUrl;
  const LiveStreamPage({super.key, required this.streamUrl});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.streamUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Live Stream")),
      body: WebViewWidget(controller: _controller),
    );
  }
}
