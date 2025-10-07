import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Check persistent login state
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool loggedIn = prefs.getBool('loggedIn') ?? false;

  runApp(MATAApp(initialLoggedIn: loggedIn));
}

class MATAApp extends StatelessWidget {
  final bool initialLoggedIn;
  const MATAApp({super.key, required this.initialLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MATA Vision Aid',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Open dashboard directly if logged in
      home: initialLoggedIn ? const DashboardPage() : const LoginPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}
