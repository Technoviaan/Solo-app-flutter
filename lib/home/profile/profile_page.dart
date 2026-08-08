import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'profile_api.dart';
import 'package:solo_app/core/storage/token_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final ageController = TextEditingController();

  String? gender;
  File? selectedImage;
  String? profileImageUrl;

  bool loading = true;
  bool saving = false;
  bool isEditing = false;

  // ── Palette ──
  static const Color _bg = Color(0xFFF7F8F3);
  static const Color _navy = Color(0xFF002C3E);
  static const Color _teal = Color(0xFF78BCC4);
  static const Color _green = Color(0xFFB5D43C);
  static const Color _label = Color(0xFF8A99A6);
  static const Color _text = Color(0xFF002C3E);
  static const Color _divider = Color(0xFFDDDDDD);

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  void initState() {
    super.initState();
    nameController.addListener(() {
      if (mounted) setState(() {});
    });
    loadProfile();
  }

  Future<void> loadProfile() async {
    final data = await ProfileApi.getProfile();
    final userMap = data != null ? (data['user'] ?? data) : null;
    
    if (userMap != null && userMap['name'] != null && userMap['name'].toString().isNotEmpty) {
      final name = userMap['name'].toString();
      nameController.text = name;
      await TokenStorage.saveUserName(name);
      emailController.text = userMap['email'] ?? '';
      String phone = userMap['phone'] ?? '';
      if (phone.isNotEmpty && !phone.startsWith('+')) {
        phone = '+65 $phone';
      }
      phoneController.text = phone;
      if (userMap['age'] != null) ageController.text = userMap['age'].toString();
      gender = userMap['gender'];
      if (userMap['profileImage'] != null && userMap['profileImage'] != '') {
        profileImageUrl =
            'https://mvp-backend-3rq1.onrender.com${userMap["profileImage"]}?t=${DateTime.now().millisecondsSinceEpoch}';
      }
    } else {
      // Fallback to local storage if API fails or name is empty
      final localName = await TokenStorage.getUserName();
      if (localName != "User") {
        nameController.text = localName;
      }
    }
    setState(() => loading = false);
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> saveProfile() async {
    final email = emailController.text.trim();
    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }
    setState(() => saving = true);
    final success = await ProfileApi.updateProfile(
      name: nameController.text,
      email: email,
      phone: phoneController.text,
      gender: gender,
      age: ageController.text,
      image: selectedImage,
    );
    setState(() => saving = false);
    if (success) {
      setState(() {
        isEditing = false;
        selectedImage = null; // Reset local image so server image shows
      });
      await TokenStorage.saveUserName(nameController.text);
      await loadProfile(); // Reload fresh data from API
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F8F3),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          children: [
            // ── SOLO logo ──
            Padding(
              padding: const EdgeInsets.only(right: 245),
              child: const Align(
                alignment: Alignment.topLeft,
                child: SoloLogo(height: 28, width: 101),
              ),
            ),
            const SizedBox(height: 20),

            // ── My Profile label ──
            const Text(
              'My Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
            ),
            const SizedBox(height: 20),

            // ── Avatar with camera badge ──
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: pickImage,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _teal, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: selectedImage != null
                              ? Image.file(selectedImage!, fit: BoxFit.cover)
                              : profileImageUrl != null
                                  ? Image.network(profileImageUrl!,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.person,
                                          size: 40, color: Colors.grey),
                                    ),
                        ),
                      ),
                      // Camera badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _divider, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_outlined,
                              size: 16, color: _navy),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Greeting + name ──
            ListenableBuilder(
              listenable: nameController,
              builder: (context, child) {
                final displayName = nameController.text.trim().isEmpty ? 'User' : nameController.text.trim();
                return Text(
                  '$_greeting,\n$displayName',
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Name field ──
            _fieldRow(
              label: 'Name',
              child: TextField(
                controller: nameController,
                readOnly: !isEditing,
                style: const TextStyle(color: _text, fontSize: 12),
                decoration: _inputDec(),
              ),
            ),

            // ── Gender field ──
            _fieldRow(
              label: 'Gender (Optional)',

              showEditIcon: true,
              child: Row(
                children: ['Male', 'Female', 'Others'].map((g) {
                  final selected = gender == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 17),
                    child: GestureDetector(
                      onTap: isEditing
                          ? () => setState(() => gender = g)
                          : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? _teal : _label,
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? Center(
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: _teal,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            g,
                            style: TextStyle(
                              color: selected ? _text : _label,
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Email field ──
            _fieldRow(
              label: 'Email',
              child: TextField(
                controller: emailController,
                readOnly: !isEditing,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: _text, fontSize: 15),
                decoration: _inputDec(),
              ),
            ),

            // ── Phone field ──
            _fieldRow(
              label: 'Phone',
              showEditIcon: true,
              child: TextField(
                controller: phoneController,
                readOnly: !isEditing,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: _text, fontSize: 15),
                decoration: _inputDec(),
              ),
            ),

            // ── Age field ──
            _fieldRow(
              label: 'Age',
              showEditIcon: true,
              child: TextField(
                controller: ageController,
                readOnly: !isEditing,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: _text, fontSize: 15),
                decoration: _inputDec(),
              ),
            ),

            const SizedBox(height: 6),

            // ── Save / Edit button ──
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 175,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (isEditing) {
                      saveProfile();
                    } else {
                      setState(() => isEditing = true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF002C3E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Save Changes' : 'Edit Profile',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
 
            // ── Back arrow ──
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: _label, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Field row with label + edit icon ──
  Widget _fieldRow({
    required String label,
    required Widget child,
    bool showEditIcon = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _label,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: child),
            if (showEditIcon)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: GestureDetector(
                  onTap: () => setState(() => isEditing = true),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: _navy,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.edit, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: _divider, height: 1, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _inputDec({String? hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF5A6C7D), fontSize: 16),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: _text, fontSize: 15),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 0),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }
}