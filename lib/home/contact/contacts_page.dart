import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/checkin/notification_service.dart';
import 'package:solo_app/home/contact/resume_checkin_page.dart';
import 'package:solo_app/subscription/subscription_page.dart';
import 'package:solo_app/subscription/subscription_api.dart';
import 'package:solo_app/core/widgets/solo_toast.dart';

import '../../core/network/api_config.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage>
    with WidgetsBindingObserver {
  Map<String, dynamic>? manualContact1;
  Map<String, dynamic>? manualContact2;

  bool isContact1Enabled = false;
  bool isContact2Enabled = false;

  int _subscriptionStatus = 0; // 0 = None, 1 = Trial, 2 = Monthly, 3 = Yearly, 4 = Unlimited
  StreamSubscription? _consentSub;

  static const Color _bg = Color(0xFFF7F8F3);
  static const Color _headingColor = Color(0xFF1B3A4B);
  static const Color _subtitleColor = Color(0xFF5A6C7D);
  static const Color _numCircle = Color(0xFF78BCC4);
  static const Color _divider = Color(0xFFDDD9D0);
  static const Color _nextGreen = Color(0xFFB5D43C);

  // Check whether Contact 2 is locked based on subscription tier
  bool get isContact2Locked => _subscriptionStatus <= 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadContacts();
    _checkSubStatus();
    _consentSub = NotificationService.consentStream.stream.listen((event) {
      if (mounted) {
        _applyConsentUpdate(event);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _consentSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSubStatus();
    }
  }

  Future<void> _checkSubStatus() async {
    try {
      final wasPending = await TokenStorage.getPendingCheckout();
      if (wasPending) {
        for (int i = 0; i < 3; i++) {
          await SubscriptionApi.getSubscriptionStatus();
          final status = await TokenStorage.getSubscriptionStatus();
          if (status >= 2) {
            await TokenStorage.savePendingCheckout(false);
            break;
          }
          if (i < 2) await Future.delayed(const Duration(seconds: 1));
        }
      } else {
        await SubscriptionApi.getSubscriptionStatus();
      }
    } catch (_) {}

    final status = await TokenStorage.getSubscriptionStatus();
    if (mounted) {
      setState(() {
        _subscriptionStatus = status;
      });
    }
  }

  void _sanitizeContactSlots() {
    if (manualContact1 == null && manualContact2 != null) {
      manualContact1 = manualContact2;
      isContact1Enabled = isContact2Enabled;
      manualContact2 = null;
      isContact2Enabled = false;
    }
  }

  void _showUpgradePrompt() {
    SoloToast.show(
      context,
      "Please upgrade your plan to add a second contact",
      isDark: false,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionPage(
          initialToastMessage:
              "Please upgrade your plan to add a second contact",
        ),
      ),
    ).then((_) => _checkSubStatus());
  }

  String _getConsentStatusLabel(dynamic status) {
    final s = (status ?? 'pending').toString().toLowerCase();
    if (s == 'accepted') return 'Accepted';
    if (s == 'declined') return 'Declined';
    return 'Pending';
  }

  Color _getConsentStatusColor(dynamic status) {
    final s = (status ?? 'pending').toString().toLowerCase();
    if (s == 'accepted') return const Color(0xFF0CB4AB);
    if (s == 'declined') return const Color(0xFFEE6A59);
    return const Color(0xFFF5B13E);
  }

  void _applyConsentUpdate(Map<String, dynamic> event) {
    final status = (event['status'] ?? 'pending').toString().toLowerCase();
    final contactName = (event['contactName'] ?? '').toString().toLowerCase();
    final identifier = (event['identifier'] ?? '').toString();

    setState(() {
      if (manualContact1 != null) {
        final name1 = (manualContact1?["name"] ?? "").toString().toLowerCase();
        final phone1 = (manualContact1?["phone"] ?? "").toString();
        if (name1 == contactName ||
            (phone1.isNotEmpty && identifier.contains(phone1)) ||
            (identifier.isNotEmpty && phone1.contains(identifier))) {
          manualContact1?["consentStatus"] = status;
          isContact1Enabled = (status == "accepted");
        }
      }
      if (manualContact2 != null) {
        final name2 = (manualContact2?["name"] ?? "").toString().toLowerCase();
        final phone2 = (manualContact2?["phone"] ?? "").toString();
        if (name2 == contactName ||
            (phone2.isNotEmpty && identifier.contains(phone2)) ||
            (identifier.isNotEmpty && phone2.contains(identifier))) {
          manualContact2?["consentStatus"] = status;
          isContact2Enabled = (status == "accepted");
        }
      }
    });
    sendContactsToApi();
  }

  Future<void> _sendConsentSmsRequest(Map<String, dynamic> contact) async {
    try {
      final userName = await LocalStorage.getUserName();
      final nameDisplay = userName.isNotEmpty ? userName : "User";
      final contactPhone =
          "${contact["countryCode"] ?? ""}${contact["phone"] ?? ""}";
      final contactName = contact["name"] ?? "there";

      print("\n---------------- CONSENT SMS REQUEST (PDF STEP 3) ----------------");
      print("To: $contactPhone ($contactName)");
      print("Message:\nSOLO Consent Request\n$nameDisplay has added you as an emergency contact on the SOLO safety app. If they miss a check-in or trigger an SOS, you may receive an alert with their location.\nReply YES to accept or NO to decline.");
      print("------------------------------------------------------------------\n");

      final token = await TokenStorage.getToken();
      final url = Uri.parse("${ApiConfig.baseUrl}/contacts/consent-request");
      await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          if (token != null)
            "Authorization": token.startsWith("Bearer ") ? token : "Bearer $token",
        },
        body: jsonEncode({
          "contactName": contactName,
          "phone": contact["phone"],
          "countryCode": contact["countryCode"],
          "userName": nameDisplay,
        }),
      ).timeout(const Duration(seconds: 4), onTimeout: () {
        return http.Response('{"status":"queued"}', 200);
      });
    } catch (e) {
      debugPrint("Consent SMS trigger logged: $e");
    }
  }

  Future<void> _updateConsentStatusManually(int index, String newStatus) async {
    final contact = index == 1 ? manualContact1 : manualContact2;
    if (contact == null) return;
    final name = contact["name"] ?? "Contact $index";

    setState(() {
      if (index == 1) {
        manualContact1?["consentStatus"] = newStatus;
        isContact1Enabled = (newStatus == "accepted");
      } else {
        manualContact2?["consentStatus"] = newStatus;
        isContact2Enabled = (newStatus == "accepted");
      }
    });

    await LocalStorage.updateContactConsentStatus(
        index: index, status: newStatus);
    await sendContactsToApi();

    if (newStatus == "accepted") {
      await NotificationService.showConsentUpdateNotification(
        contactName: name,
        isAccepted: true,
      );
    } else if (newStatus == "declined") {
      await NotificationService.showConsentUpdateNotification(
        contactName: name,
        isAccepted: false,
      );
    }
  }

  void _showConsentSimulationSheet(int index) {
    final contact = index == 1 ? manualContact1 : manualContact2;
    if (contact == null) return;
    final name = contact["name"] ?? "Contact $index";
    final currentStatus = _getConsentStatusLabel(contact["consentStatus"]);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Consent Status: $name",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF002C3E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Current: $currentStatus\nSelect an SMS reply to simulate the PDF flow & push notification:",
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF5A6C7D),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle, color: Color(0xFF0CB4AB)),
                title: const Text(
                  "Reply 'YES' (Accepted)",
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                    "Status becomes Accepted, toggle turns ON, push notification sent"),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateConsentStatusManually(index, "accepted");
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cancel, color: Color(0xFFEE6A59)),
                title: const Text(
                  "Reply 'NO' (Declined)",
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                    "Status becomes Declined, toggle stays inactive, push notification sent"),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateConsentStatusManually(index, "declined");
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.hourglass_empty, color: Color(0xFFF5B13E)),
                title: const Text(
                  "Reset to 'Pending'",
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                    "SMS sent, waiting for reply (no notification sent)"),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateConsentStatusManually(index, "pending");
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  int getCurrentContacts() {
    int count = 0;
    if (isContact1Enabled) count++;
    if (isContact2Enabled) count++;
    return count;
  }

  Future<void> pickContact(int index) async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      if (mounted) {
        SoloToast.show(
          context,
          "Please allow access to your contacts to continue",
          isDark: false,
        );
      }
      return;
    }

    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;

      final full = await FlutterContacts.getContact(contact.id);
      if (full == null) return;

      String phone = "";
      String countryCode = "";

      if (full.phones.isNotEmpty) {
        String rawPhone = full.phones.first.number.trim();
        rawPhone = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        String digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');

        if (rawPhone.startsWith('+')) {
          if (digitsOnly.startsWith('91') && digitsOnly.length == 12) {
            countryCode = "+91";
            phone = digitsOnly.substring(2);
          } else if (digitsOnly.startsWith('65') && digitsOnly.length == 10) {
            countryCode = "+65";
            phone = digitsOnly.substring(2);
          } else if (digitsOnly.startsWith('1') && digitsOnly.length == 11) {
            countryCode = "+1";
            phone = digitsOnly.substring(1);
          } else {
            final match = RegExp(r'^(\d{1,3})(\d{7,10})$').firstMatch(digitsOnly);
            if (match != null) {
              countryCode = "+${match.group(1)}";
              phone = match.group(2) ?? "";
            } else {
              countryCode = "+91";
              phone = digitsOnly;
            }
          }
        } else {
          final Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
          if (digitsOnly.length == 10) {
            countryCode = "+91";
            phone = digitsOnly;
          } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
            countryCode = "+91";
            phone = digitsOnly.substring(2);
          } else {
            countryCode = _getDynamicCountryCode(deviceLocale.countryCode);
            phone = digitsOnly;
          }
        }
      }

      if (phone.isEmpty) {
        if (mounted) {
          SoloToast.show(
            context,
            "Selected contact has no valid phone number",
            isDark: false,
          );
        }
        return;
      }

      final contactData = {
        "name": full.displayName.isEmpty ? "Unknown" : full.displayName,
        "countryCode": countryCode,
        "phone": phone,
        "consentStatus": "pending",
      };

      setState(() {
        if (index == 1) {
          manualContact1 = contactData;
          isContact1Enabled = false; // Pending -> toggle inactive per PDF
        } else {
          manualContact2 = contactData;
          isContact2Enabled = false; // Pending -> toggle inactive per PDF
        }
      });

      await sendContactsToApi();
      await _sendConsentSmsRequest(contactData);
    } catch (e) {
      if (mounted) {
        SoloToast.show(
          context,
          "Something went wrong while picking the contact",
          isDark: false,
        );
      }
    }
  }

  String _getDynamicCountryCode(String? regionCode) {
    final Map<String, String> countryCodes = {
      'IN': '+91',
      'SG': '+65',
      'US': '+1',
      'CA': '+1',
      'GB': '+44',
      'AE': '+971',
      'NP': '+977',
      'AU': '+61',
      'MY': '+60',
      'PK': '+92',
      'BD': '+880',
      'PH': '+63',
      'TH': '+66',
      'ID': '+62',
      'SA': '+966',
    };
    return countryCodes[regionCode?.toUpperCase()] ?? '+91';
  }

  Future<void> editContact(int index) async {
    final existing = index == 1 ? manualContact1 : manualContact2;
    if (existing == null) return;

    TextEditingController nameCtrl = TextEditingController(text: existing["name"] ?? "");
    TextEditingController phoneCtrl = TextEditingController(text: existing["phone"] ?? "");
    String selectedCountryCode = existing["countryCode"] ?? "+65";

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Contact $index",
                style: const TextStyle(
                  color: _headingColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _dialogField(nameCtrl, "Name", Icons.person_outline),
              const SizedBox(height: 12),
              _dialogField(phoneCtrl, "Phone", Icons.phone_outlined, keyboard: TextInputType.phone),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();

                        setState(() {
                          if (index == 1) {
                            if (manualContact2 != null) {
                              manualContact1 = manualContact2;
                              isContact1Enabled = isContact2Enabled;
                              manualContact2 = null;
                              isContact2Enabled = false;
                            } else {
                              manualContact1 = null;
                              isContact1Enabled = false;
                            }
                          } else {
                            manualContact2 = null;
                            isContact2Enabled = false;
                          }
                        });

                        sendContactsToApi();
                      },
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 17),
                    label: const Text("Remove", style: TextStyle(color: Colors.redAccent)),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text("Cancel", style: TextStyle(color: _subtitleColor)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final rawDigits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
                          if (rawDigits.isEmpty) {
                            SoloToast.show(
                              context,
                              "Enter a valid phone number",
                              isDark: false,
                            );
                            return;
                          }

                          final existingPhone = existing["phone"] ?? "";
                          final existingStatus = existing["consentStatus"] ?? "pending";
                          final bool phoneChanged = existingPhone != rawDigits;
                          final newStatus = phoneChanged ? "pending" : existingStatus;

                          final updated = {
                            "name": nameCtrl.text.trim(),
                            "countryCode": selectedCountryCode,
                            "phone": rawDigits,
                            "consentStatus": newStatus,
                          };

                          Navigator.of(dialogContext).pop();

                          setState(() {
                            if (index == 1) {
                              manualContact1 = updated;
                              if (phoneChanged) isContact1Enabled = false;
                            } else {
                              manualContact2 = updated;
                              if (phoneChanged) isContact2Enabled = false;
                            }
                          });

                          await sendContactsToApi();
                          if (phoneChanged) {
                            await _sendConsentSmsRequest(updated);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _numCircle,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
                        ),
                        child: const Text("Save", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: _headingColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _subtitleColor, fontSize: 13),
        prefixIcon: Icon(icon, color: _numCircle, size: 18),
        filled: true,
        fillColor: const Color(0xFFF9F8F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _numCircle, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Future<bool> sendContactsToApi() async {
    print("\n---------------- API PAYLOAD PREPARATION ----------------");
    final token = await TokenStorage.getToken();

    final locationData = await LocationService.getCurrentLocationData();

    final List<Map<String, dynamic>> allContacts = [];
    if (manualContact1 != null) {
      final c1 = Map<String, dynamic>.from(manualContact1!);
      c1["enabled"] = isContact1Enabled.toString();
      allContacts.add(c1);
    }
    if (manualContact2 != null && !isContact2Locked) {
      final c2 = Map<String, dynamic>.from(manualContact2!);
      c2["enabled"] = isContact2Enabled.toString();
      allContacts.add(c2);
    }

    await LocalStorage.saveContacts(
      allContacts.map((e) => e.map((k, v) => MapEntry(k, v.toString()))).toList(),
    );

    if (allContacts.isEmpty) return true;

    final url = Uri.parse("${ApiConfig.baseUrl}/contacts");
    bool allSucceeded = true;

    for (final contact in allContacts) {
      try {
        String rawPhone = contact["phone"] ?? "";
        String cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
        String countryCode = contact["countryCode"] ?? "+91";

        if (countryCode == "+91" && cleanDigits.startsWith("91") && cleanDigits.length == 12) {
          cleanDigits = cleanDigits.substring(2);
        } else if (countryCode == "+65" && cleanDigits.startsWith("65") && cleanDigits.length == 10) {
          cleanDigits = cleanDigits.substring(2);
        }

        final body = jsonEncode({
          "name": contact["name"],
          "phone": cleanDigits,
          "countryCode": countryCode,
          "consentStatus": contact["consentStatus"] ?? "pending",
          "isEnabled": contact["enabled"] == "true",
          if (locationData != null) ...{
            "latitude": locationData["latitude"],
            "longitude": locationData["longitude"],
            "mapsUrl": locationData["mapsUrl"],
            "timestamp": locationData["timestamp"],
          }
        });

        print("[API REQUEST] POST $url");
        print("[API BODY PAYLOAD WITH LOCATION & CONSENT]: $body");

        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            if (token != null)
              "Authorization":
                  token.startsWith("Bearer ") ? token : "Bearer $token",
          },
          body: body,
        );

        print("[API RESPONSE] Status Code: ${response.statusCode}");
        print("[API RESPONSE] Response Body: ${response.body}");

        if (response.statusCode < 200 || response.statusCode >= 300) {
          allSucceeded = false;
        }
      } catch (e) {
        print("[API ERROR] $e");
        allSucceeded = false;
      }
    }

    print("----------------------------------------------------------\n");
    return allSucceeded;
  }

  Future<void> loadContacts() async {
    final data = await LocalStorage.getContacts();
    if (data.isNotEmpty) {
      setState(() {
        if (data.length >= 1) {
          manualContact1 = Map<String, dynamic>.from(data[0]);
          final status1 = (manualContact1?["consentStatus"] ?? "pending")
              .toString()
              .toLowerCase();
          final storedEnabled1 = manualContact1?["enabled"];
          isContact1Enabled =
              (status1 == "accepted") && (storedEnabled1 != "false");
        }
        if (data.length >= 2) {
          manualContact2 = Map<String, dynamic>.from(data[1]);
          final status2 = (manualContact2?["consentStatus"] ?? "pending")
              .toString()
              .toLowerCase();
          final storedEnabled2 = manualContact2?["enabled"];
          isContact2Enabled =
              (status2 == "accepted") && (storedEnabled2 != "false");
        }
        _sanitizeContactSlots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _sanitizeContactSlots();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double screenWidth = MediaQuery.of(context).size.width;
                    double titleFontSize = screenWidth < 360 ? 36 : (screenWidth < 400 ? 40 : 44);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Let your loved\nOnes know\nYou’re Okay",
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF002C3E),
                            letterSpacing: 0,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "You can add the people who care about you. If you miss a scheduled check-in, I’ll alert them after 2 hours with your last known location. You can update your contacts anytime.",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: const Color(0xFF5A6C7D),
                            fontSize: screenWidth < 360 ? 13 : 14,
                            height: 1.45,
                            letterSpacing: 0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Contact Section
                        const Divider(height: 1, thickness: 1, color: Color(0x808A99A6)),
                        _contactRow(index: 1),
                        const Divider(height: 1, thickness: 1, color: Color(0x808A99A6)),
                        _contactRow(index: 2),
                        const Divider(height: 1, thickness: 1, color: Color(0x808A99A6)),

                        const SizedBox(height: 24),

                        // Useful Tip SVG - Aspect ratio maintain rakhne ke liye
                        SvgPicture.asset(
                          'assets/svg/usefultip.svg',
                          width: 111,
                          height: 37,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),

                        Text(
                          "Let your contacts know they’re added as emergency contacts so they’ll recognize alerts from your SOLO app.",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: _subtitleColor,
                            fontSize: screenWidth < 360 ? 13 : 14,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF5A6C7D), size: 26),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Builder(builder: (context) {
                    final canProceed = manualContact1 != null || manualContact2 != null;
                    return GestureDetector(
                      onTap: canProceed
                          ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ResumeCheckinPage()),
                      )
                          : null,
                      child: Row(
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: canProceed
                                  ? const Color(0xFF5A6C7D)
                                  : const Color(0xFF5A6C7D).withValues(alpha: 0.3),
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Opacity(
                            opacity: canProceed ? 1.0 : 0.3,
                            child: SvgPicture.asset('assets/svg/nextbutton.svg', width: 60, height: 60),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactRow({required int index}) {
    final data = index == 1 ? manualContact1 : manualContact2;
    final enabled = index == 1 ? isContact1Enabled : isContact2Enabled;
    final hasContact = data != null;
    final isTrial = isContact2Locked;

    // For monthly and yearly subscribers, both contact slots should appear active at first glance (PDF 2 page 7 item 7)
    // For trial users, only slot 1 is active (slot 2 dimmed)
    final double rowOpacity = (index == 2 && isTrial) ? 0.45 : 1.0;
    final consentStatus =
        (data?["consentStatus"] ?? "pending").toString().toLowerCase();
    final isAccepted = consentStatus == "accepted";
    final isPending = consentStatus == "pending";
    final isDeclined = consentStatus == "declined";

    return Opacity(
      opacity: rowOpacity,
      child: Padding(
        padding: EdgeInsets.only(
          top: 14,
          bottom: hasContact ? 16 : 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF76BDCB),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  "$index",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (index == 2 && isTrial) {
                    _showUpgradePrompt();
                    return;
                  }
                  if (!hasContact) {
                    if (index == 2 && manualContact1 == null) {
                      SoloToast.show(
                          context, "Please add contact 1 first", isDark: false);
                      return;
                    }
                    pickContact(index);
                  }
                },
                onLongPress:
                    hasContact ? () => _showConsentSimulationSheet(index) : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Contact",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF5A6C7D),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasContact ? (data["name"] ?? "") : "No contact added yet",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: hasContact
                            ? const Color(0xFF002C3E)
                            : const Color(0xFF8A99A6),
                        fontSize: 14,
                        fontWeight:
                            hasContact ? FontWeight.w500 : FontWeight.w400,
                        height: 20 / 14,
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasContact) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showConsentSimulationSheet(index),
                        child: Text(
                          _getConsentStatusLabel(data["consentStatus"]),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: _getConsentStatusColor(data["consentStatus"]),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                if (index == 2) {
                  if (isTrial) {
                    _showUpgradePrompt();
                    return;
                  }
                  if (manualContact1 == null) {
                    SoloToast.show(
                        context, "Please add contact 1 first", isDark: false);
                    return;
                  }
                }

                if (hasContact) {
                  setState(() {
                    if (index == 1) {
                      // If Contact 2 exists, shift it up to Contact 1 slot
                      if (manualContact2 != null) {
                        manualContact1 = manualContact2;
                        isContact1Enabled = isContact2Enabled;
                        manualContact2 = null;
                        isContact2Enabled = false;
                      } else {
                        manualContact1 = null;
                        isContact1Enabled = false;
                      }
                    } else {
                      manualContact2 = null;
                      isContact2Enabled = false;
                    }
                  });
                  await sendContactsToApi();
                } else {
                  await pickContact(index);
                }
              },
              child: (index == 2 && isTrial)
                  ? SvgPicture.asset('assets/svg/plus.svg',
                      width: 28, height: 28)
                  : hasContact
                      ? Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF002C3E),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 12,
                              height: 1.8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                        )
                      : SvgPicture.asset('assets/svg/plus.svg',
                          width: 28, height: 28),
            ),
            const SizedBox(width: 14),
            customSwitch(
              value: hasContact &&
                  enabled &&
                  isAccepted &&
                  (index == 1 || !isTrial),
              onChanged: (value) async {
                if (index == 2 && isTrial) {
                  _showUpgradePrompt();
                  return;
                }

                if (!hasContact) {
                  if (index == 2 && manualContact1 == null) {
                    SoloToast.show(
                        context, "Please add contact 1 first", isDark: false);
                  } else {
                    SoloToast.show(
                        context, "Please add a contact first", isDark: false);
                  }
                  return;
                }

                // Inactive when Pending or Declined per PDF Page 6
                if (isPending) {
                  SoloToast.show(
                      context, "Waiting for consent",
                      isDark: false);
                  return;
                }
                if (isDeclined) {
                  SoloToast.show(
                      context, "Contact has declined to receive SMS alerts",
                      isDark: false);
                  return;
                }

                setState(() {
                  if (index == 1) {
                    isContact1Enabled = value;
                  } else {
                    isContact2Enabled = value;
                  }
                });
                await sendContactsToApi();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget customSwitch({required bool value, required Function(bool) onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? _nextGreen : const Color(0xFFD1DBE0),
        ),
        padding: const EdgeInsets.all(2),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class LocationService {
  static Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("[LOCATION LOG] GPS Service is Disabled");
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("[LOCATION LOG] Permission Denied");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("[LOCATION LOG] Permission Denied Forever");
      return false;
    }

    return true;
  }

  static Future<Map<String, dynamic>?> getCurrentLocationData() async {
    try {
      final allowed = await requestLocationPermission();
      if (!allowed) return null;

      print("\n================= FETCHING LIVE GPS LOCATION =================");
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final now = DateTime.now().toLocal();
      final formattedTime =
          "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}, ${now.day}/${now.month}/${now.year}";
      final googleMapsUrl =
          "https://maps.google.com/?q=${position.latitude},${position.longitude}";

      final data = {
        "latitude": position.latitude,
        "longitude": position.longitude,
        "mapsUrl": googleMapsUrl,
        "timestamp": formattedTime,
      };

      print("[LOCATION LOG] Latitude: ${position.latitude}");
      print("[LOCATION LOG] Longitude: ${position.longitude}");
      print("[LOCATION LOG] Maps Link: $googleMapsUrl");
      print("[LOCATION LOG] Timestamp: $formattedTime");
      print("==============================================================\n");

      return data;
    } catch (e) {
      print("[LOCATION ERROR] Failed to fetch GPS: $e");
      return null;
    }
  }
}