import 'package:flutter/material.dart';
import '../core/storage/token_storage.dart';
import 'subscription_api.dart';
import 'subscription_page.dart';

class PlanDetailsPage extends StatefulWidget {
  const PlanDetailsPage({super.key});

  @override
  State<PlanDetailsPage> createState() => _PlanDetailsPageState();
}

class _PlanDetailsPageState extends State<PlanDetailsPage> {
  bool _isLoading = true;

  int status = 0;
  int credits = 0;
  int contacts = 0;
  int checkins = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Always hit the backend first so any change made server-side (e.g. an
    // admin adjusting this user's credits) shows up immediately instead of
    // an old value cached on the device.
    await SubscriptionApi.getSubscriptionStatus();

    final results = await Future.wait([
      TokenStorage.getSubscriptionStatus(),
      TokenStorage.getCredits(),
      TokenStorage.getMaxContacts(),
      TokenStorage.getMaxCheckins(),
    ]);

    if (!mounted) return;

    setState(() {
      status = results[0];
      credits = results[1];
      contacts = results[2];
      checkins = results[3];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Plan")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    "Plan: ${_planName(status)}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text("Credits: $credits"),
                  Text("Max Contacts: $contacts"),
                  Text("Max Check-ins: $checkins"),

                  const SizedBox(height: 30),

                  /// TOP-UP (ONLY monthly/yearly)
                  if (status == 2 || status == 3)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionPage(),
                          ),
                        );
                      },
                      child: const Text("Buy Top-up Credits"),
                    ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SubscriptionPage(),
                        ),
                      );
                    },
                    child: const Text("Upgrade Plan"),
                  ),
                ],
              ),
            ),
    );
  }

  String _planName(int status) {
    if (status == 1) return "Free Trial";
    if (status == 2) return "Monthly";
    if (status == 3) return "Yearly";
    return "";
  }
}
