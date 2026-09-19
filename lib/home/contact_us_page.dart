import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';

import '../core/storage/token_storage.dart';
import '../core/utils/app_size.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({super.key});

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  File? attachedFile;
  bool isSubmitting = false;

  // ============ REFUND REQUEST STATE ============
  bool isRefundRequest = false;
  String? refundReason;

  static const List<String> refundReasonOptions = [
    "Accidental purchase",
    "SMS blocked in my country",
    "I changed my mind",
  ];

  static const int maxDescriptionLength = 500;

  // 📍 Direct VPS Base URL Setup
  final String vpsBaseUrl = "https://api.hello-solo.com/api";

  @override
  void initState() {
    super.initState();
    HttpOverrides.global = MyHttpOverrides();
  }

  // ================= FILE PICK =================
  Future<void> pickAttachment() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );

      if (picked != null) {
        final file = File(picked.path);
        setState(() {
          attachedFile = file;
        });
      }
    } catch (e) {
      debugImageOwner: print("Attachment pick error: $e");
    }
  }

  // ================= REFUND CHECKBOX TAP =================
  Future<void> onRefundCheckboxTap() async {
    if (!isRefundRequest) {
      final String? selected = await _showRefundReasonSheet();

      if (selected == null) {
        setState(() {
          isRefundRequest = false;
          refundReason = null;
        });
      } else {
        setState(() {
          isRefundRequest = true;
          refundReason = selected;
        });
      }
    } else {
      setState(() {
        isRefundRequest = false;
        refundReason = null;
      });
    }
  }

  // ================= ACTION SHEET =================
  Future<String?> _showRefundReasonSheet() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSize.w(12), vertical: AppSize.h(10)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8F3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSize.h(14)),
                        child: Text(
                          "Select Refund Reason",
                          style: TextStyle(
                            fontSize: AppSize.sp(16),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF002C3E),
                          ),
                        ),
                      ),
                      const Divider(height: 1, thickness: 0.8, color: Color(0xFF8A99A6)),
                      for (int i = 0; i < refundReasonOptions.length; i++) ...[
                        InkWell(
                          onTap: () => Navigator.pop(sheetContext, refundReasonOptions[i]),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: AppSize.h(14), horizontal: AppSize.w(16)),
                            child: Text(
                              refundReasonOptions[i],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: AppSize.sp(14),
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF5A8C7D),
                              ),
                            ),
                          ),
                        ),
                        if (i < refundReasonOptions.length - 1)
                          const Divider(height: 1, thickness: 0.8, color: Color(0xFF8A99A6)),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: AppSize.h(8)),
                GestureDetector(
                  onTap: () => Navigator.pop(sheetContext, null),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: AppSize.h(14)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8F3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "Cancel",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSize.sp(15),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= SUBMIT =================
  Future<void> submitSupportTicket() async {
    final email = emailController.text.trim();
    final subject = subjectController.text.trim();
    final description = descriptionController.text.trim();

    if (email.isEmpty || subject.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email, subject and description are required."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (description.length > maxDescriptionLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Description must be under 500 characters."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (isRefundRequest && (refundReason == null || refundReason!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a refund reason."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final client = http.Client();

    try {
      final token = await TokenStorage.getToken();
      final url = Uri.parse("$vpsBaseUrl/support");
      final request = http.MultipartRequest("POST", url);

      request.headers.addAll({
        "Accept": "application/json",
        if (token != null && token.isNotEmpty)
          "Authorization": token.startsWith("Bearer ") ? token : "Bearer $token",
      });

      request.fields["email"] = email;
      request.fields["subject"] = subject;
      request.fields["description"] = description;
      request.fields["isRefundRequest"] = isRefundRequest.toString();
      request.fields["refundReason"] = isRefundRequest ? (refundReason ?? "") : "";

      if (attachedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("file", attachedFile!.path),
        );
      }

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException("VPS Server request timed out."),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String message = "Your request has been submitted.";
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded["message"] != null) {
            message = decoded["message"].toString();
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.green),
          );

          emailController.clear();
          subjectController.clear();
          descriptionController.clear();
          setState(() {
            attachedFile = null;
            isRefundRequest = false;
            refundReason = null;
          });

          Navigator.pop(context);
        }
      } else {
        String message = "Failed to submit request (${response.statusCode})";
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded["message"] != null) {
            message = decoded["message"].toString();
          }
        } catch (_) {}

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
          );
        }
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("VPS Server took too long to respond."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      client.close();
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    subjectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSize.w(20), vertical: AppSize.h(10)),
              child: const SoloLogo(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSize.w(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: AppSize.h(15)),
                    Text(
                      "Contact Us",
                      style: TextStyle(
                        fontSize: AppSize.sp(16),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                      ),
                    ),
                    SizedBox(height: AppSize.h(10)),
                    Text(
                      "How can we help\nyou today?",
                      style: TextStyle(
                        fontSize: AppSize.sp(32),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: AppSize.h(10)),
                    Text(
                      "We're here to listen. Tell us what you need below and we’ll get back to you soon.",
                      style: TextStyle(
                        fontSize: AppSize.sp(13),
                        color: const Color(0xFF8A99A6),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: AppSize.h(20)),

                    // Email Field (Added as per Figma)
                    Text.rich(
                      TextSpan(
                        text: "Email Address",
                        style: TextStyle(color: const Color(0xFF8A99A6), fontSize: AppSize.sp(12)),
                        children: const [
                          TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    TextField(
                      controller: emailController,
                      maxLines: 1,
                      enabled: !isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD1D8DD), width: 0.8)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF002C3E), width: 1.2)),
                      ),
                    ),
                    SizedBox(height: AppSize.h(15)),

                    // Subject Field
                    Text.rich(
                      TextSpan(
                        text: "Subject",
                        style: TextStyle(color: const Color(0xFF8A99A6), fontSize: AppSize.sp(12)),
                        children: const [
                          TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    TextField(
                      controller: subjectController,
                      maxLines: 1,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD1D8DD), width: 0.8)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF002C3E), width: 1.2)),
                      ),
                    ),
                    SizedBox(height: AppSize.h(15)),

                    // Description Field
                    Text.rich(
                      TextSpan(
                        text: "Description",
                        style: TextStyle(color: const Color(0xFF8A99A6), fontSize: AppSize.sp(12)),
                        children: const [
                          TextSpan(text: "*", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      maxLength: maxDescriptionLength,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD1D8DD), width: 0.8)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF002C3E), width: 1.2)),
                      ),
                    ),
                    SizedBox(height: AppSize.h(8)),
                    Text(
                      "Please include all relevant details so we can assist you better. Maximum length is 500 characters.",
                      style: TextStyle(
                        fontSize: AppSize.sp(10),
                        color: const Color(0xFF8A99A6),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: AppSize.h(20)),

                    // Attachments
                    Text(
                      "Attachments",
                      style: TextStyle(color: const Color(0xFF8A99A6), fontSize: AppSize.sp(12), fontWeight: FontWeight.w400),
                    ),
                    SizedBox(height: AppSize.h(8)),
                    GestureDetector(
                      onTap: isSubmitting ? null : pickAttachment,
                      child: Container(
                        width: double.infinity,
                        height: AppSize.h(41),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D8DD), width: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Add file",
                              style: TextStyle(
                                color: const Color(0xFF14B8A6),
                                fontSize: AppSize.sp(10),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            SizedBox(width: AppSize.w(4)),
                            Flexible(
                              child: Text(
                                attachedFile != null
                                    ? attachedFile!.path.split('/').last
                                    : "Click to add a screenshot or photo",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFF8A99A6),
                                  fontSize: AppSize.sp(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (attachedFile != null)
                      Padding(
                        padding: EdgeInsets.only(top: AppSize.h(6)),
                        child: GestureDetector(
                          onTap: isSubmitting ? null : () => setState(() => attachedFile = null),
                          child: Text(
                            "Remove attachment",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: AppSize.sp(10),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: AppSize.h(16)),

                    // ============ REFUND REQUEST CHECKBOX ============
                    GestureDetector(
                      onTap: isSubmitting ? null : onRefundCheckboxTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: AppSize.w(18),
                            height: AppSize.w(18),
                            decoration: BoxDecoration(
                              color: isRefundRequest ? const Color(0xFF78BCC4) : Colors.transparent,
                              border: Border.all(color: const Color(0xFF8A99A6), width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: isRefundRequest
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          SizedBox(width: AppSize.w(8)),
                          Expanded(
                            child: Text(
                              isRefundRequest && refundReason != null
                                  ? "Reason: $refundReason"
                                  : "This is a refund request",
                              style: TextStyle(
                                color: const Color(0xFF8A99A6),
                                fontSize: AppSize.sp(12),
                                fontWeight: isRefundRequest ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSize.h(24)),

                    // Submit Button
                    GestureDetector(
                      onTap: isSubmitting ? null : submitSupportTicket,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: AppSize.w(35), vertical: AppSize.h(13)),
                        decoration: BoxDecoration(
                          color: isSubmitting ? const Color(0xFF002C3E).withOpacity(0.6) : const Color(0xFF002C3E),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                          height: AppSize.h(20),
                          width: AppSize.h(20),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppSize.sp(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: AppSize.h(30)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Icon(Icons.arrow_back, color: Color(0xFF8A99A6), size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}