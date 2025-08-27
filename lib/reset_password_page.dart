import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // 👁️ state for toggling password visibility
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _updatePassword() async {
    String oldPassword = _oldPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null && user.email != null) {
        // ✅ Step 1: Re-authenticate user with old password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: oldPassword,
        );
        await user.reauthenticateWithCredential(credential);

        // ✅ Step 2: Update password in Firebase Auth
        await user.updatePassword(newPassword);

        // ⚠️ Optional (not recommended in production)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({"password": newPassword});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password Updated Successfully')),
        );

        Navigator.pop(context); // Go back to ProfilePage
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Unexpected error: $e")));
    }
  }

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
                    Navigator.pop(context); // Back to Profile Page
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
              const SizedBox(height: 30),

              // ✅ Password fields with toggle
              _buildPasswordField(
                'Old Password',
                _oldPasswordController,
                _obscureOld,
                    () => setState(() => _obscureOld = !_obscureOld),
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                'New Password',
                _newPasswordController,
                _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                'Confirm Password',
                _confirmPasswordController,
                _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'Update Password',
                  style: TextStyle(color: Colors.white, fontSize: 16),
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

  // 🔑 Reusable field with show/hide toggle
  Widget _buildPasswordField(
      String label,
      TextEditingController controller,
      bool obscureText,
      VoidCallback toggleVisibility,
      ) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: toggleVisibility,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
