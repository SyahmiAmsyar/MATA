import 'package:flutter/material.dart';
import 'reset_password_page.dart'; // Import the Reset Password Page
import 'login_page.dart'; // Correct: Import LoginPage from login_page.dart

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0073B1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    ); // Back to Dashboard or Previous Page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/profile_pic.jpg'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Profile Picture',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 20),
              buildProfileField('Name', 'Iskandar'),
              const SizedBox(height: 10),
              buildProfileField('Username', 'Iskandar64'),
              const SizedBox(height: 10),
              buildProfileField('Email', 'Iskandar64@g.com'),
              const SizedBox(height: 10),
              buildProfileField('Password', 'Iskandar_64'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to Reset Password Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Reset Password',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  // Navigate back to LoginPage and clear navigation stack
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                        (Route<dynamic> route) => false, // Remove all previous routes
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Delete Account',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.shield_outlined,
                size: 100,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildProfileField(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label :',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value, style: const TextStyle(color: Colors.black)),
          ),
        ),
      ],
    );
  }
}
