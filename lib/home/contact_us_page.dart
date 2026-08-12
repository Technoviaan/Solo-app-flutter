import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';

import '../core/storage/token_storage.dart';
import '../core/utils/app_size.dart';

/// Self-Signed / IP HTTPS SSL Bypass Handler (VPS Direct IP testing ke liye)
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
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  File? attachedFile;
  bool isSubmitting = false;

  // ============ REFUND REQUEST STATE ============
  bool isRefundRequest = false;
  String? refundReason; // null until user picks one from the action sheet

  static const List<String> refundReasonOptions = [
    "Accidental purchase",
    "SMS blocked in my country",
    "I changed my mind",
  ];

  static const int maxDescriptionLength = 500;

  // 📍 Direct VPS Base URL Setup
  final String vpsBaseUrl = "https://187.127.122.25/api";

  @override
  void initState() {
    super.initState();
    // IP based HTTPS SSL certificate validation errors avoid karne ke liye
    HttpOverrides.global = MyHttpOverrides();
  }

  // ================= FILE PICK =================
  Future<void> pickAttachment() async {
    print("\n================= ATTACHMENT PICKER STARTED =================");
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );

      if (picked == null) {
        print("[CANCELLED] User closed attachment picker.");
      } else {
        final file = File(picked.path);
        final sizeKb = (await file.length()) / 1024;
        print("[SELECTED] File path: ${picked.path}");
        print("[SELECTED] File size: ${sizeKb.toStringAsFixed(1)} KB");
        setState(() {
          attachedFile = file;
        });
      }
    } catch (e, stackTrace) {
      print("[EXCEPTION] Attachment pick error: $e\n$stackTrace");
    }
    print("================= ATTACHMENT PICKER FINISHED =================\n");
  }

  // ================= REFUND CHECKBOX TAP =================
  Future<void> onRefundCheckboxTap() async {
    print("\n================= REFUND CHECKBOX TAPPED =================");
    print("[REFUND] Current state before tap -> isRefundRequest: $isRefundRequest, refundReason: $refundReason");

    if (!isRefundRequest) {
      // Going from unchecked -> checked: open the action sheet to pick a reason
      print("[REFUND] Opening 'Select Refund Reason' action sheet...");
      final String? selected = await _showRefundReasonSheet();

      if (selected == null) {
        // User cancelled the sheet -> keep checkbox unchecked
        print("[REFUND] User cancelled reason selection. Checkbox stays unchecked.");
        setState(() {
          isRefundRequest = false;
          refundReason = null;
        });
      } else {
        print("[REFUND] Reason selected: '$selected'");
        setState(() {
          isRefundRequest = true;
          refundReason = selected;
        });
      }
    } else {
      // Going from checked -> unchecked: clear the reason
      print("[REFUND] Unchecking. Clearing refund reason.");
      setState(() {
        isRefundRequest = false;
        refundReason = null;
      });
    }

    print("[REFUND] Final state -> isRefundRequest: $isRefundRequest, refundReason: $refundReason");
    print("================= REFUND CHECKBOX HANDLED =================\n");
  }

  // ================= ACTION SHEET (Select Refund Reason) =================
  Future<String?> _showRefundReasonSheet() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFFF7F8F3),
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSize.h(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSize.h(10)),
                  child: Text(
                    "Select Refund Reason",
                    style: TextStyle(
                      fontSize: AppSize.sp(15),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF002C3E),
                    ),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFF8A99A6)),
                for (final reason in refundReasonOptions) ...[
                  InkWell(
                    onTap: () {
                      print("[REFUND SHEET] Option tapped: '$reason'");
                      Navigator.pop(sheetContext, reason);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSize.h(14), horizontal: AppSize.w(20)),
                      child: Text(
                        reason,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: AppSize.sp(14),
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5A8C7D),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFF8A99A6)),
                ],
                SizedBox(height: AppSize.h(10)),
                GestureDetector(
                  onTap: () {
                    print("[REFUND SHEET] Cancel tapped.");
                    Navigator.pop(sheetContext, null);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: AppSize.w(20)),
                    padding: EdgeInsets.symmetric(vertical: AppSize.h(12)),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8F3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF8A99A6)),
                    ),
                    child: Text(
                      "Cancel",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: AppSize.sp(14),
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
    print("\n---------------- SUPPORT TICKET SUBMISSION (VPS TEST) ----------------");

    final subject = subjectController.text.trim();
    final description = descriptionController.text.trim();

    print("[FORM] Subject: '$subject'");
    print("[FORM] Description: '$description'");
    print("[FORM] Attachment: ${attachedFile?.path ?? 'none'}");
    print("[FORM] isRefundRequest: $isRefundRequest");
    print("[FORM] refundReason: ${refundReason ?? '(none)'}");

    if (subject.isEmpty || description.isEmpty) {
      print("[VALIDATION ERROR] Subject or Description is empty.");
      print("--------------------------------------------------------\n");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subject and description are required."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (description.length > maxDescriptionLength) {
      print("[VALIDATION ERROR] Description exceeds $maxDescriptionLength chars.");
      print("--------------------------------------------------------\n");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Description must be under $maxDescriptionLength characters."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (isRefundRequest && (refundReason == null || refundReason!.isEmpty)) {
      print("[VALIDATION ERROR] Refund request checked but no reason selected.");
      print("--------------------------------------------------------\n");
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
      print("[AUTH] Token present: ${token != null && token.isNotEmpty}");

      // 📍 New VPS URL Endpoint
      final url = Uri.parse("$vpsBaseUrl/support");
      print("[API REQUEST] POST $url");

      final request = http.MultipartRequest("POST", url);

      request.headers.addAll({
        "Accept": "application/json",
        if (token != null && token.isNotEmpty)
          "Authorization": token.startsWith("Bearer ") ? token : "Bearer $token",
      });

      request.fields["subject"] = subject;
      request.fields["description"] = description;
      request.fields["isRefundRequest"] = isRefundRequest.toString();
      request.fields["refundReason"] = isRefundRequest ? (refundReason ?? "") : "";

      print("[API FIELDS]: ${request.fields}");

      if (attachedFile != null) {
        print("[API FILE] Attaching: ${attachedFile!.path}");
        request.files.add(
          await http.MultipartFile.fromPath("file", attachedFile!.path),
        );
      } else {
        print("[API FILE] No attachment to send.");
      }

      print("[API REQUEST HEADERS]: ${request.headers}");

      final stopwatch = Stopwatch()..start();
      print("[API] Sending request to VPS host...");

      final streamedResponse = await client.send(request).timeout(
        const Duration(seconds: 30), // VPS par sleep issue nahi hota, so 30s timeout is enough
        onTimeout: () {
          print("[API TIMEOUT] No response after 30s (elapsed: ${stopwatch.elapsedMilliseconds}ms)");
          throw TimeoutException("VPS Server request timed out after 30 seconds.");
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      stopwatch.stop();
      print("[API] Response received in ${stopwatch.elapsedMilliseconds}ms");
      print("[API RESPONSE] Status Code: ${response.statusCode}");
      print("[API RESPONSE] Response Body: ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print("[SUCCESS] Support ticket submitted successfully on VPS!");

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

        print("[API ERROR] $message");

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
          );
        }
      }
    } on TimeoutException catch (e) {
      print("[API ERROR] VPS Request timed out: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("VPS Server took too long to respond."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e, stackTrace) {
      print("[API ERROR] VPS Request Failed: $e\n$stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      client.close();
      print("--------------------------------------------------------\n");
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  void dispose() {
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
                    SizedBox(height: AppSize.h(20)),
                    Text(
                      "Contact Us",
                      style: TextStyle(
                        fontSize: AppSize.sp(20),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                      ),
                    ),
                    SizedBox(height: AppSize.h(17)),
                    Text(
                      "How can we\nhelp you today?",
                      style: TextStyle(
                        fontSize: AppSize.sp(40),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002C3E),
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: AppSize.h(16)),
                    Text(
                      "We're here to listen. Tell us what you need below and we’ll get back to you soon.",
                      style: TextStyle(
                        fontSize: AppSize.sp(14),
                        color: const Color(0xFF8A99A6),
                        height: 1.4,
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
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8A99A6))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF002C3E))),
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
                      maxLines: 4,
                      maxLength: maxDescriptionLength,
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8A99A6))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF002C3E))),
                      ),
                    ),
                    SizedBox(height: AppSize.h(14)),
                    Text(
                      "Please include all relevant details so we can assist you better. Maximum length is 500 characters.",
                      style: TextStyle(
                        fontSize: AppSize.sp(10),
                        color: const Color(0xFF8A99A6),
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: AppSize.h(24)),

                    // Attachments
                    Text(
                      "Attachments",
                      style: TextStyle(color: const Color(0xFF8A99A6), fontSize: AppSize.sp(12), fontWeight: FontWeight.w400),
                    ),
                    SizedBox(height: AppSize.h(10)),
                    GestureDetector(
                      onTap: isSubmitting ? null : pickAttachment,
                      child: Container(
                        width: double.infinity,
                        height: AppSize.h(41),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8A99A6)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Add file",
                              style: TextStyle(
                                color: const Color(0xFF14B8A6),
                                fontSize: AppSize.sp(9),
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
                                  fontSize: AppSize.sp(9),
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
                              fontSize: AppSize.sp(9),
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
                              border: Border.all(color: const Color(0xFF8A99A6)),
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSize.h(27)),

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
                            fontSize: AppSize.sp(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: AppSize.h(40)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 30),
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