import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

import 'package:solo_app/core/storage/token_storage.dart';
import 'package:solo_app/core/utils/app_size.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/contact/resume_checkin_page.dart';
import 'package:solo_app/subscription/subscription_page.dart';

import '../../core/network/api_config.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  Map<String, String>? manualContact1;
  Map<String, String>? manualContact2;

  bool isContact1Enabled = false;
  bool isContact2Enabled = false;

  static const Color _bg = Color(0xFFF7F8F3);
  static const Color _headingColor = Color(0xFF1B3A4B);
  static const Color _subtitleColor = Color(0xFF5A6C7D);
  static const Color _numCircle = Color(0xFF78BCC4);
  static const Color _plusBtn = Color(0xFF002C3E);
  static const Color _contactLabel = Color(0xFF5A6C7D);
  static const Color _contactText = Color(0xFF5A6C7D);
  static const Color _contactSubtext = Color(0xFF8A99A6);
  static const Color _divider = Color(0xFFDDD9D0);
  static const Color _nextGreen = Color(0xFFB5D43C);

  int getCurrentContacts() {
    int count = 0;
    if (isContact1Enabled) count++;
    if (isContact2Enabled) count++;
    return count;
  }

  Future<void> pickContact(int index) async {
    print("\n================= DYNAMIC GLOBAL CONTACT PICKER STARTED =================");
    print("Picking contact for Index: $index");

    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      print("[ERROR] Contacts permission denied!");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Contacts permission denied")),
        );
      }
      return;
    }

    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) {
        print("[CANCELLED] User closed contact picker.");
        return;
      }

      final full = await FlutterContacts.getContact(contact.id);
      if (full == null) return;

      String phone = "";
      String countryCode = "";

      if (full.phones.isNotEmpty) {
        String rawPhone = full.phones.first.number.trim();
        print("[DEBUG] Device raw phone string: '$rawPhone'");

        // Remove spaces, hyphens, brackets
        rawPhone = rawPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

        // Strictly extract digits
        String digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');

        if (rawPhone.startsWith('+')) {
          if (digitsOnly.startsWith('91') && digitsOnly.length == 12) {
            // Indian Number (+91XXXXXXXXXX)
            countryCode = "+91";
            phone = digitsOnly.substring(2);
          } else if (digitsOnly.startsWith('65') && digitsOnly.length == 10) {
            // Singapore Number (+65XXXXXXXX)
            countryCode = "+65";
            phone = digitsOnly.substring(2);
          } else if (digitsOnly.startsWith('1') && digitsOnly.length == 11) {
            // US/Canada Number (+1XXXXXXXXXX)
            countryCode = "+1";
            phone = digitsOnly.substring(1);
          } else {
            // Generic International Number Split
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
          // Without '+' in raw number
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

      print("[PARSED DYNAMIC DATA] Name: '${full.displayName}', CountryCode: '$countryCode', Phone: '$phone'");

      if (phone.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Selected contact has no valid phone number")),
          );
        }
        return;
      }

      final contactData = {
        "name": full.displayName ?? "Unknown",
        "countryCode": countryCode,
        "phone": phone,
      };

      // Keep a backup so we can roll back if the API call fails.
      final previousData = index == 1 ? manualContact1 : manualContact2;
      final previousEnabled = index == 1 ? isContact1Enabled : isContact2Enabled;

      setState(() {
        if (index == 1) {
          manualContact1 = contactData;
          isContact1Enabled = true;
        } else {
          manualContact2 = contactData;
          isContact2Enabled = true;
        }
      });

      final success = await sendContactsToApi();

      if (!success && mounted) {
        // Roll back so the UI doesn't lie about what's saved on the server.
        setState(() {
          if (index == 1) {
            manualContact1 = previousData;
            isContact1Enabled = previousEnabled;
          } else {
            manualContact2 = previousData;
            isContact2Enabled = previousEnabled;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't save this contact. Check the number and try again."),
          ),
        );
      }

      print("================= DYNAMIC PICKER FINISHED =================\n");
    } catch (e, stackTrace) {
      print("[EXCEPTION] Dynamic Pick Error: $e\n$stackTrace");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Something went wrong while picking the contact")),
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

    TextEditingController nameCtrl =
    TextEditingController(text: existing["name"] ?? "");
    TextEditingController phoneCtrl =
    TextEditingController(text: existing["phone"] ?? "");
    String selectedCountryCode = existing["countryCode"] ?? "+65";

    await showDialog(
      context: context,
      builder: (_) => Dialog(
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
              _dialogField(
                phoneCtrl,
                "Phone",
                Icons.phone_outlined,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final previousData = index == 1 ? manualContact1 : manualContact2;
                      final previousEnabled = index == 1 ? isContact1Enabled : isContact2Enabled;

                      setState(() {
                        if (index == 1) {
                          manualContact1 = null;
                          isContact1Enabled = false;
                        } else {
                          manualContact2 = null;
                          isContact2Enabled = false;
                        }
                      });

                      final success = await sendContactsToApi();
                      if (!success && mounted) {
                        setState(() {
                          if (index == 1) {
                            manualContact1 = previousData;
                            isContact1Enabled = previousEnabled;
                          } else {
                            manualContact2 = previousData;
                            isContact2Enabled = previousEnabled;
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Couldn't remove contact. Try again.")),
                        );
                      }

                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 17),
                    label: const Text("Remove",
                        style: TextStyle(color: Colors.redAccent)),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel",
                            style: TextStyle(color: _subtitleColor)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final previousData = index == 1 ? manualContact1 : manualContact2;

                          final rawDigits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');

                          if (rawDigits.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Enter a valid phone number")),
                            );
                            return;
                          }

                          final fullPhone = rawDigits.startsWith('91') || rawDigits.startsWith('65')
                              ? "+$rawDigits"
                              : "$selectedCountryCode$rawDigits";

                          final updated = {
                            "name": nameCtrl.text.trim(),
                            "countryCode": selectedCountryCode,
                            "phone": fullPhone,
                          };

                          setState(() {
                            if (index == 1) {
                              manualContact1 = updated;
                            } else {
                              manualContact2 = updated;
                            }
                          });

                          final success = await sendContactsToApi();

                          if (!success && mounted) {
                            setState(() {
                              if (index == 1) {
                                manualContact1 = previousData;
                              } else {
                                manualContact2 = previousData;
                              }
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Couldn't save this contact. Check the number and try again."),
                              ),
                            );
                            return; // keep dialog open so user can fix it
                          }

                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _numCircle,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 17, vertical: 12),
                        ),
                        child: const Text("Save",
                            style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _dialogField(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        TextInputType keyboard = TextInputType.text,
      }) {
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _numCircle, width: 1.5),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
  Future<bool> sendContactsToApi() async {
    print("\n---------------- API PAYLOAD PREPARATION ----------------");
    final token = await TokenStorage.getToken();

    final List<Map<String, String>> contacts = [];
    if (isContact1Enabled && manualContact1 != null) {
      contacts.add(manualContact1!);
    }
    if (isContact2Enabled && manualContact2 != null) {
      contacts.add(manualContact2!);
    }

    await LocalStorage.saveContacts(contacts);
    print("[SUCCESS] Contacts saved to LocalStorage.");

    if (contacts.isEmpty) {
      print("[INFO] No enabled contacts to send.");
      print("----------------------------------------------------------\n");
      return true;
    }

    final url = Uri.parse("${ApiConfig.baseUrl}/contacts");
    bool allSucceeded = true;

    for (final contact in contacts) {
      try {
        print("[API REQUEST] POST $url");

        // Format clean phone digits (e.g. "8540047732" instead of "+918540047732")
        String rawPhone = contact["phone"] ?? "";
        String cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
        String countryCode = contact["countryCode"] ?? "+91";

        // Remove country code from phone if accidentally prefixed
        if (countryCode == "+91" && cleanDigits.startsWith("91") && cleanDigits.length == 12) {
          cleanDigits = cleanDigits.substring(2);
        } else if (countryCode == "+65" && cleanDigits.startsWith("65") && cleanDigits.length == 10) {
          cleanDigits = cleanDigits.substring(2);
        }

        // Exact Postman Payload Match
        final body = jsonEncode({
          "name": contact["name"],
          "phone": cleanDigits,
          "countryCode": countryCode,
        });

        print("[API BODY PAYLOAD]: $body");

        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            if (token != null) "Authorization": token.startsWith("Bearer ") ? token : "Bearer $token",
          },
          body: body,
        );

        print("[API RESPONSE] Status Code: ${response.statusCode}");
        print("[API RESPONSE] Response Body: ${response.body}");

        if (response.statusCode >= 200 && response.statusCode < 300) {
          print("[SUCCESS] Emergency contact added to MongoDB!");
        } else {
          String message = "Failed to save contact (${response.statusCode})";
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map && decoded["message"] != null) {
              message = decoded["message"].toString();
            }
          } catch (_) {}

          print("[API ERROR] $message");
          allSucceeded = false;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      } catch (e) {
        print("[API ERROR] Failed to send contact to backend: $e");
        allSucceeded = false;
      }
    }

    print("----------------------------------------------------------\n");
    return allSucceeded;
  }
  Future<bool> canUseContacts(BuildContext context) async {
    int status = await TokenStorage.getSubscriptionStatus();
    int maxContacts = await TokenStorage.getMaxContacts();
    int current = getCurrentContacts();

    if (status == 0) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const SubscriptionPage()));
      return false;
    }
    if (current >= maxContacts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Max $maxContacts contacts allowed")),
      );
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Let Loved\nOnes Know\nYou're Okay",
                      style: TextStyle(
                        color: Color(0xFF002C3E),
                        fontSize: 44,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "You can add the people who care about you. If you miss a scheduled check-in, I'll alert them after 2 hours with your last known location. You can update your contacts anytime.",
                      style: TextStyle(
                        color: Color(0xFF5A6C7D),
                        fontSize: 14,
                        height: 1.55,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          children: [
                            const Divider(height: 1, color: Colors.black12),
                            _contactRow(index: 1),
                            const Divider(height: 1, color: Colors.black12),
                            _contactRow(index: 2),
                            const Divider(height: 1, color: Colors.black12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SvgPicture.asset(
                      'assets/svg/usefultip.svg',
                      width: 111.w,
                      height: 37.w,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Let your contacts know they're added as emergency contacts so they'll recognize alerts from your SOLO app.",
                      style: TextStyle(
                        color: _subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(left: 24.w, right: 24.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      color: _subtitleColor,
                      size: 24,
                    ),
                  ),
                  Builder(builder: (context) {
                    final canProceed =
                        manualContact1 != null || manualContact2 != null;
                    return GestureDetector(
                      onTap: canProceed
                          ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ResumeCheckinPage()),
                      )
                          : null,
                      child: Row(
                        children: [
                          Text(
                            "Next",
                            style: TextStyle(
                              color: canProceed
                                  ? _headingColor
                                  : _headingColor.withValues(alpha: 0.3),
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Opacity(
                            opacity: canProceed ? 1.0 : 0.3,
                            child: SvgPicture.asset(
                              'assets/svg/nextbutton.svg',
                              width: 60.w,
                              height: 60.w,
                            ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: _numCircle,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$index",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Contact",
                  style: TextStyle(
                    color: _contactLabel,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                hasContact
                    ? Text(
                  data!["name"] ?? "",
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: _contactText,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 28 / 18,
                    letterSpacing: 0,
                  ),
                )
                    : const Text(
                  "No contact added yet",
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: _contactSubtext,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 28 / 18,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (hasContact) {
                await editContact(index);
              } else {
                await pickContact(index);
              }
            },
            child: hasContact
                ? Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 4),
              decoration: const BoxDecoration(
                color: _plusBtn,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            )
                : Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SvgPicture.asset(
                'assets/svg/plus.svg',
                width: 28.w,
                height: 28.w,
              ),
            ),
          ),
          const SizedBox(width: 3),
          customSwitch(
            value: enabled,
            onChanged: (value) async {
              if (!hasContact) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Please add a contact first")),
                );
                return;
              }
              bool allowed = await canUseContacts(context);
              if (!allowed && value == true) return;

              final previousEnabled = enabled;

              setState(() {
                if (index == 1) {
                  isContact1Enabled = value;
                } else {
                  isContact2Enabled = value;
                }
              });

              final success = await sendContactsToApi();
              if (!success && mounted) {
                setState(() {
                  if (index == 1) {
                    isContact1Enabled = previousEnabled;
                  } else {
                    isContact2Enabled = previousEnabled;
                  }
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Couldn't update contact. Try again.")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> loadContacts() async {
    final data = await LocalStorage.getContacts();
    print("[LOAD CONTACTS] Saved local contacts loaded: ${data.length}");
    if (data.isNotEmpty) {
      setState(() {
        if (data.length >= 1) {
          manualContact1 = data[0];
          isContact1Enabled = true;
        }
        if (data.length >= 2) {
          manualContact2 = data[1];
          isContact2Enabled = true;
        }
      });
    }
  }

  Widget customSwitch({required bool value, required Function(bool) onChanged}) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50.w,
        height: 28.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.w),
          color: value ? _nextGreen : const Color(0xFFD1DBE0),
        ),
        padding: EdgeInsets.all(2.w),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24.w,
            height: 24.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
