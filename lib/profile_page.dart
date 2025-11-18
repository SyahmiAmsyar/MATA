import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'reset_password_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  String email = "";
  String? _profileImageUrl;
  File? _selectedImage;

  bool _isEditing = false;
  bool _isUploadingPhoto = false;
  bool _isUpdatingProfile = false;
  bool _isDeleting = false;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() => email = user.email ?? "");

        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data["name"] ?? "";
            _usernameController.text =
                data["username"] ?? data["Username"] ?? "";
            _profileImageUrl = data["profileImageUrl"];
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error loading user data: $e");
    }
  }

  Future<void> _pickImage() async {
    if (_isUploadingPhoto || _isUpdatingProfile || _isDeleting) return;

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isUploadingPhoto = true;
      });

      final uploadedUrl = await _uploadProfileImage(_selectedImage!);

      if (uploadedUrl != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({"profileImageUrl": uploadedUrl}, SetOptions(merge: true));

          setState(() {
            _profileImageUrl = uploadedUrl;
            _selectedImage = null;
            _isUploadingPhoto = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Profile photo updated successfully!"),
            ),
          );
        }
      } else {
        setState(() {
          _selectedImage = null;
          _isUploadingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to upload profile photo.")),
        );
      }
    }
  }

  Future<String?> _uploadProfileImage(File image) async {
    try {
      final cloudName = 'dxfiwjj1p'; // Replace with your Cloudinary Cloud Name
      final uploadPreset =
          'flutter_unsigned'; // Replace with your unsigned preset

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'];
      } else {
        debugPrint("❌ Cloudinary upload error: $resBody");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Cloudinary upload exception: $e");
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdatingProfile = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          "name": _nameController.text.trim(),
          "username": _usernameController.text.trim(),
          "email": email,
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _usernameController.text.trim());

        setState(() => _isEditing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Profile updated successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error updating profile: $e")));
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _isDeleting) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      await user.delete();

      if (mounted) {
        Navigator.of(context).pop(); // close loader
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error deleting account: $e")));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0073B1),
        title: const Text("Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0073B1), Color(0xFF004C75)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  // Profile Avatar
                  Stack(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _isUploadingPhoto
                                ? _pulseAnimation.value
                                : 1.0,
                            child: child,
                          );
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null,
                          child: (_profileImageUrl == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.blueAccent,
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.orange,
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isUploadingPhoto)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  const SizedBox(height: 15),
                  // User Name
                  Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text
                        : "Loading...",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Profile Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildTextFormField(
                            Icons.person,
                            "Name",
                            _nameController,
                            _isEditing,
                          ),
                          const SizedBox(height: 15),
                          _buildTextFormField(
                            Icons.alternate_email,
                            "Username",
                            _usernameController,
                            _isEditing,
                          ),
                          const SizedBox(height: 15),
                          _buildReadOnlyField(Icons.email, "Email", email),
                          const SizedBox(height: 15),
                          _buildReadOnlyField(
                            Icons.lock,
                            "Password",
                            "********",
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  _buildActionButton(
                    text: _isEditing ? "Save Profile" : "Edit Profile",
                    icon: _isEditing ? Icons.save : Icons.edit,
                    color: Colors.orange,
                    onPressed:
                        _isUpdatingProfile || _isUploadingPhoto || _isDeleting
                        ? null
                        : () {
                            if (_isEditing) {
                              _updateProfile();
                            } else {
                              setState(() => _isEditing = true);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    text: "Reset Password",
                    icon: Icons.lock_reset,
                    color: Colors.blueGrey,
                    onPressed:
                        _isUpdatingProfile || _isUploadingPhoto || _isDeleting
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ResetPasswordPage(),
                              ),
                            );
                          },
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    text: "Delete Account",
                    icon: Icons.delete_forever,
                    color: Colors.red,
                    onPressed: _isDeleting ? null : _deleteAccount,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
    IconData icon,
    String label,
    TextEditingController controller,
    bool enabled,
  ) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: (value) {
        if (enabled && (value == null || value.trim().isEmpty)) {
          return "$label cannot be empty";
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildReadOnlyField(IconData icon, String label, String value) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        labelText: label,
        hintText: value.isNotEmpty ? value : "-",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
