import 'dart:async'; // Required for Timer
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Assuming these files exist in your project structure
import 'profile_page.dart';
import 'login_page.dart';
import 'LiveGpsPage.dart';
import 'reset_password_page.dart';

// =========================================================================
// CENTRALIZED UTILITY AND CONSTANTS (Simplified)
// =========================================================================

/// Displays a standardized SnackBar message across the application.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    ),
  );
}

// ❌ REMOVED: piUrlKey is no longer necessary as the URL is fixed/hardcoded.

// =========================================================================
// 2. Dashboard Page Implementation (FIXED PI URL)
// =========================================================================

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  // PI STATUS VARIABLES
  int _piBatteryLevel = 0;
  bool _isPiCharging = false;
  bool _isDeviceConnected = false;

  bool _liveFootageForced = false;
  String _username = "";

  // ✅ PI URL is now hardcoded and fixed
  final String _piUrl = "https://matavision.ngrok.app";

  Timer? _statusUpdateTimer;

  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  // ❌ REMOVED: _dialogPiUrlController

  @override
  void initState() {
    super.initState();
    // ✅ Simplified setup
    _startTimerAndInitialFetch();
    _loadUsername();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  /// Starts the timer and fetches initial status.
  Future<void> _startTimerAndInitialFetch() async {
    // ❌ REMOVED: _loadPiUrl is not needed.

    await _fetchPiStatus();

    _statusUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (Timer t) => _fetchPiStatus(),
    );
  }

  // ❌ REMOVED: _loadPiUrl method
  // ❌ REMOVED: _savePiUrl method (moved to the new dialog's logic)

  /// Fetches the Raspberry Pi's battery and connection status.
  Future<void> _fetchPiStatus() async {
    // URL check is now simpler as it is hardcoded
    if (_piUrl.isEmpty) {
      if (mounted) setState(() => _isDeviceConnected = false);
      showAppSnackBar(context, "⚠ Internal PI URL is missing (Code Error).");
      return;
    }

    try {
      final url = Uri.parse("$_piUrl/status");
      final res = await http.get(url).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (mounted) {
          setState(() {
            _isDeviceConnected = true;
            _piBatteryLevel = data['battery_level'] ?? 0;
            _isPiCharging = data['is_charging'] ?? false;
          });
        }
      } else {
        if (mounted) setState(() => _isDeviceConnected = false);
        print("API Status Error: ${res.statusCode}");
      }
    } on TimeoutException {
      if (mounted) setState(() => _isDeviceConnected = false);
      print("Connection Timeout to $_piUrl");
    } catch (e) {
      print("Failed to fetch PI status: $e");
      if (mounted) setState(() => _isDeviceConnected = false);
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(() => _username = prefs.getString('username') ?? 'User');
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedIn');
    await prefs.remove('username');

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  /// Toggle live stream start / stop safely
  Future<void> _toggleLiveFootageForce() async {
    if (!_isDeviceConnected) {
      showAppSnackBar(
        context,
        "❌ Cannot start stream, device is disconnected.",
        isError: true,
      );
      return;
    }

    final action = _liveFootageForced ? "stop" : "start";
    final url = Uri.parse("$_piUrl/stream");

    try {
      print("📡 Sending $action request to $url ...");
      final res = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"action": action}),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        if (!_liveFootageForced) {
          if (mounted) setState(() => _liveFootageForced = true);

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveStreamPage(
                streamUrl: "$_piUrl/video_feed",
                onStop: () => setState(() => _liveFootageForced = false),
              ),
            ),
          );
        } else {
          if (mounted) setState(() => _liveFootageForced = false);
          showAppSnackBar(context, "Live stream stop signal sent.");
        }
      } else {
        showAppSnackBar(
          context,
          "Failed to toggle stream: ${res.statusCode}",
          isError: true,
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      showAppSnackBar(context, "Connection Error: $e", isError: true);
    }
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("App Information"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Version: 1.0.0 (Build 20251118)"),
            const SizedBox(height: 8),
            Text("Device URL: $_piUrl (Fixed)"), // Updated text
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ❌ REMOVED: _buildEditPiUrlDialog method

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    _controller.dispose();
    // ❌ REMOVED: _dialogPiUrlController disposal
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF0073B1),
        title: const Text("Dashboard"),
        actions: [
          // ❌ REMOVED: Settings Icon
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
            // 1. Welcome Header
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots()
                  : null,
              builder: (context, snapshot) {
                final String displayUsername =
                    (snapshot.hasData && snapshot.data!.exists)
                    ? (snapshot.data!['username'] ?? _username)
                    : _username;
                return Text(
                  "👋 Welcome back, $displayUsername!",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 2. Main Connection Status
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Device Status:",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isDeviceConnected ? "CONNECTED" : "DISCONNECTED",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _isDeviceConnected
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: FaIcon(
                        _isDeviceConnected
                            ? FontAwesomeIcons.glasses
                            : FontAwesomeIcons.wifi,
                        color: _isDeviceConnected ? Colors.green : Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Action Grid (Compact 2x2 layout)
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: EdgeInsets.zero,
                children: [
                  // Live GPS
                  _buildGridActionButton(
                    icon: Icons.location_on,
                    label: "Live GPS",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LiveGpsPage(),
                      ),
                    ),
                    color: const Color(0xFF0073B1),
                  ),

                  // Start/Stop Live Footage
                  _buildGridActionButton(
                    icon: _liveFootageForced
                        ? Icons.videocam
                        : Icons.videocam_off,
                    label: _liveFootageForced ? "Stop Live" : "Start Live",
                    onTap: _toggleLiveFootageForce,
                    color: _liveFootageForced ? Colors.red : Colors.green,
                  ),

                  // Battery Status (Uses PI Battery Status)
                  _buildGridInfoTile(
                    icon: _isPiCharging ? Icons.power : Icons.battery_full,
                    label: "Battery Status",
                    value: _isDeviceConnected ? "$_piBatteryLevel%" : "--%",
                    gradient: LinearGradient(
                      colors: [
                        _isPiCharging
                            ? Colors.lightGreen
                            : (_piBatteryLevel > 20
                                  ? const Color(0xFF2979FF)
                                  : Colors.orange),
                        _isPiCharging ? Colors.green : const Color(0xFF82B1FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),

                  // App Info (Remains)
                  _buildGridActionButton(
                    icon: Icons.info_outline,
                    label: "App Info",
                    onTap: _showAppInfoDialog,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action Button for Grid
  Widget _buildGridActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = const Color(0xFF0073B1),
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info Tile for Grid (e.g., Battery)
  Widget _buildGridInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required LinearGradient gradient,
  }) {
    return Container(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: Colors.white, size: 36),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 3. Safe Live Stream Page (Uses Fixed PI URL)
// =========================================================================

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
  // ✅ Hardcoded PI URL for sending the stop command
  final String _piUrl = "https://matavision.ngrok.app";

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

    // ❌ REMOVED: SharedPreferences logic for Pi URL. Using hardcoded _piUrl.

    try {
      final res = await http
          .post(
            Uri.parse("$_piUrl/stream"), // Use the fixed Pi URL
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"action": "stop"}),
          )
          .timeout(const Duration(seconds: 5));
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
        foregroundColor: Colors.white,
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
