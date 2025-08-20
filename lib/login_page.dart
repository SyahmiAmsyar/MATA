import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? errorText;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      setState(() => errorText = null);

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = e.message);
    } catch (e) {
      setState(() => errorText = "Something went wrong. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0073B1),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'M.A.T.A',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'VISION MOBILE\nAPPLICATION',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Image.asset('assets/logo_mata1.png', width: 200, height: 200),
              const SizedBox(height: 20),
              const Text(
                'Guiding You,\nEvery Step of the Way',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 30),
              _buildInputField('Email:', _emailController),
              const SizedBox(height: 15),
              _buildInputField('Password:', _passwordController, obscure: true),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 25),
              _buildButton('LOGIN', _login),
              const SizedBox(height: 10),
              _buildButton('BACK', () {
                Navigator.pop(context);
              }),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  // Implement Forgot Password if needed
                },
                child: const Text('Forgot Password?', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 5),
              RichText(
                text: TextSpan(
                  text: "Don’t have an account? ",
                  style: const TextStyle(color: Colors.white),
                  children: [
                    TextSpan(
                      text: "Sign up",
                      style: const TextStyle(color: Colors.orange),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool obscure = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(border: InputBorder.none, labelText: label),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Center(
      child: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[300],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(text, style: const TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}
