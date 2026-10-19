import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/core/widgets/solo_toast.dart';
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

  // Stored values for Cancel reversion
  String _savedName = '';
  String _savedEmail = '';
  String _savedPhone = '';
  String _savedAge = '';
  String? _savedGender;

  bool loading = true;
  bool saving = false;
  bool isEditing = false;

  // ── Palette ──
  static const Color _bg = Color(0xFFF7F8F3);
  static const Color _navy = Color(0xFF002C3E);
  static const Color _teal = Color(0xFF78BCC4);
  static const Color _label = Color(0xFF8A99A6);
  static const Color _text = Color(0xFF002C3E);
  static const Color _divider = Color(0x338A99A6);

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
    // 1. Check local saved profile image
    final localPath = await TokenStorage.getLocalProfileImagePath();
    if (localPath != null && localPath.isNotEmpty) {
      final localFile = File(localPath);
      if (localFile.existsSync()) {
        selectedImage = localFile;
      }
    }

    final data = await ProfileApi.getProfile();
    final userMap = data != null ? (data['user'] ?? data) : null;
    
    if (userMap != null && userMap['name'] != null && userMap['name'].toString().isNotEmpty) {
      final name = userMap['name'].toString();
      nameController.text = name;
      _savedName = name;
      await TokenStorage.saveUserName(name);
      final email = userMap['email'] ?? '';
      emailController.text = email;
      _savedEmail = email;
      String phone = userMap['phone'] ?? '';
      if (phone.isNotEmpty && !phone.startsWith('+')) {
        phone = '+65 $phone';
      }
      phoneController.text = phone;
      _savedPhone = phone;
      final age = userMap['age'] != null ? userMap['age'].toString() : '';
      ageController.text = age;
      _savedAge = age;
      gender = userMap['gender'];
      _savedGender = gender;
      if (userMap['profileImage'] != null && userMap['profileImage'] != '') {
        profileImageUrl =
            'https://api.hello-solo.com${userMap["profileImage"]}?t=${DateTime.now().millisecondsSinceEpoch}';
      }
    } else {
      // Fallback to local storage if API fails or name is empty
      final localName = await TokenStorage.getUserName();
      if (localName != "User") {
        nameController.text = localName;
        _savedName = localName;
      }
    }
    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final localFile = File(picked.path);
      if (localFile.existsSync()) {
        setState(() => selectedImage = localFile);
        await TokenStorage.saveLocalProfileImagePath(picked.path);
      }
    }
  }

  void cancelEditing() {
    setState(() {
      nameController.text = _savedName;
      emailController.text = _savedEmail;
      phoneController.text = _savedPhone;
      ageController.text = _savedAge;
      gender = _savedGender;
      isEditing = false;
    });
  }

  Future<void> saveProfile() async {
    final email = emailController.text.trim();
    if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      SoloToast.show(context, 'Enter a valid email');
      return;
    }
    setState(() => saving = true);
    final trimmedName = nameController.text.trim();
    final success = await ProfileApi.updateProfile(
      name: trimmedName,
      email: email,
      phone: phoneController.text,
      gender: gender,
      age: ageController.text,
      image: selectedImage,
    );
    setState(() => saving = false);
    if (success) {
      _savedName = trimmedName;
      _savedEmail = email;
      _savedPhone = phoneController.text;
      _savedAge = ageController.text;
      _savedGender = gender;
      setState(() {
        isEditing = false;
      });
      if (selectedImage != null) {
        await TokenStorage.saveLocalProfileImagePath(selectedImage!.path);
      }
      await TokenStorage.saveUserName(trimmedName);
      await loadProfile(); // Reload fresh data from API
      if (mounted) {
        SoloToast.show(context, 'Profile updated');
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // ── SOLO logo ──
            const SoloLogo(),
            const SizedBox(height: 24),

            // ── Header (My Profile) ──
            const Text(
              "My Profile",
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF002C3E),
                height: 1.0,
                letterSpacing: 0,
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
                        ),
                        child: ClipOval(
                          child: (selectedImage != null && selectedImage!.existsSync())
                              ? Image.file(selectedImage!, fit: BoxFit.cover)
                              : (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                                  ? Image.network(
                                      profileImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey,
                                      ),
                                    ),
                        ),
                      ),
                      // Camera badge
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _navy, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: _navy,
                          ),
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
                final double screenWidth = MediaQuery.of(context).size.width;
                final double titleFontSize = screenWidth < 360 ? 36 : 44;

                return Text(
                  '$_greeting,\n$displayName',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: _navy,
                    height: 1.1,
                    letterSpacing: 0,
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
                style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w400),
                decoration: _inputDec(),
              ),
            ),

            // ── Gender field ──
            _fieldRow(
              label: 'Gender (Optional)',
              child: Row(
                children: ['Male', 'Female', 'Others'].map((g) {
                  final selected = gender == g;
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
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
                                color: selected ? _teal : _label.withValues(alpha: 0.6),
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
                          const SizedBox(width: 8),
                          Text(
                            g,
                            style: TextStyle(
                              color: selected ? _text : _label,
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w500
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
                style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w400),
                decoration: _inputDec(),
              ),
            ),

            // ── Phone field ──
            _fieldRow(
              label: 'Phone',
              child: TextField(
                controller: phoneController,
                readOnly: !isEditing,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w400),
                decoration: _inputDec(),
              ),
            ),

            // ── Age field ──
            _fieldRow(
              label: 'Age',
              child: TextField(
                controller: ageController,
                readOnly: !isEditing,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w400),
                decoration: _inputDec(),
              ),
            ),

            const SizedBox(height: 10),

            // ── Edit / Cancel / Confirm Action Row (Figma Design) ──
            Row(
              children: [
                // Circular Pencil Edit Button
                GestureDetector(
                  onTap: () {
                    setState(() => isEditing = true);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: _navy,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.edit, size: 20, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Cancel Button
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: (isEditing || selectedImage != null) ? cancelEditing : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _navy,
                        disabledForegroundColor: _label.withValues(alpha: 0.5),
                        side: BorderSide(
                          color: (isEditing || selectedImage != null) ? _navy : _label.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm Button
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: (isEditing || selectedImage != null)
                          ? (saving ? null : saveProfile)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _navy.withValues(alpha: 0.5),
                        disabledForegroundColor: Colors.white70,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
 
            // ── Back arrow ──
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Color(0xFF8A99A6), size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Field row with label ──
  Widget _fieldRow({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _label,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        child,
        const SizedBox(height: 8),
        const Divider(color: _divider, height: 1, thickness: 1),
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _inputDec({String? hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8A99A6), fontSize: 15),
      prefixText: prefix,
      prefixStyle: const TextStyle(color: _text, fontSize: 15),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }
}