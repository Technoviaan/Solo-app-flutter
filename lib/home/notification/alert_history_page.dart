import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/home/checkin/local_storage.dart';
import 'package:solo_app/home/notification/model/alert_history_model.dart';
import 'package:solo_app/home/notification/history_store.dart';
import 'notification_api.dart';

class AlertHistoryPage extends StatefulWidget {
  const AlertHistoryPage({super.key});

  @override
  State<AlertHistoryPage> createState() => _AlertHistoryPageState();
}

class _AlertHistoryPageState extends State<AlertHistoryPage> {
  List<AlertHistoryModel> history = [];
  List<Map<String, dynamic>> localHistory = [];
  List<String> defaultContacts = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      history = await NotificationApi.getAlertHistory();
    } catch (_) {}
    try {
      localHistory = await HistoryStore.getLocalAlerts();
    } catch (_) {}

    try {
      final saved = await LocalStorage.getContacts();
      defaultContacts = saved
          .map((e) {
            final name = (e["name"] ?? "").trim();
            final phone = (e["phone"] ?? "").trim();
            final cc = (e["countryCode"] ?? "").trim();
            final fullPhone = cc.isNotEmpty ? "$cc $phone" : phone;
            if (name.isNotEmpty && fullPhone.isNotEmpty) return "$name $fullPhone";
            return name.isNotEmpty ? name : fullPhone;
          })
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (_) {}

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  String formatDateTime(String iso) {
    try {
      final date = DateTime.parse(iso).toLocal();
      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      final day = date.day;
      final month = months[date.month - 1];
      final year = date.year;

      int hour = date.hour;
      final period = hour >= 12 ? "PM" : "AM";
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final minute = date.minute.toString().padLeft(2, '0');

      return "$day $month $year · $hour:$minute $period";
    } catch (_) {
      return iso;
    }
  }

  List<Map<String, dynamic>> _rows() {
    final apiRows = history
        .map(
          (e) => {
            "createdAt": e.createdAt,
            "type": e.type,
            "contacts": e.contacts,
          },
        )
        .toList();

    final localRows = localHistory.map((e) {
      List<String> contactsList = [];
      if (e["contacts"] != null && e["contacts"] is List) {
        contactsList =
            (e["contacts"] as List).map((x) => x.toString()).toList();
      } else if (e["contact"] != null && e["contact"].toString() != "—") {
        contactsList = e["contact"]
            .toString()
            .split("\n")
            .map((x) => x.trim())
            .where((x) => x.isNotEmpty)
            .toList();
      }
      return {
        "createdAt": (e["createdAt"] ?? "").toString(),
        "type": (e["type"] ?? "").toString(),
        "contacts": contactsList,
      };
    }).toList();

    final rows = [...localRows, ...apiRows];
    rows.sort(
      (a, b) => DateTime.parse(b["createdAt"] as String)
          .compareTo(DateTime.parse(a["createdAt"] as String)),
    );
    if (rows.isEmpty) {
      return [
        {
          "createdAt": DateTime.now().subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
          "type": "MISSED",
          "contacts": ["SP GRP- Electric (+65 9090 7856)"],
        },
        {
          "createdAt": DateTime.now().subtract(const Duration(days: 3, hours: 5)).toIso8601String(),
          "type": "SOS",
          "contacts": ["SP GRP- Electric (+65 9090 7856)"],
        },
      ];
    }
    return rows;
  }

  Widget _statusCapsule(String rawType) {
    final isSos = rawType.toUpperCase().contains("SOS");
    final label = isSos ? "SOS Alert" : "Missed";

    return Container(
      width: 90,
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFEE6A59),
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFFF5F5F5),
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SoloLogo(),
              const SizedBox(height: 24),
              const Text(
                "Sent Alerts",
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
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : rows.isEmpty
                        ? const Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "No alerts sent yet",
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Color(0xFF5A6C7D),
                                height: 1.0,
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) => const Divider(
                              color: Color(0x808A99A6),
                              height: 1,
                              thickness: 1,
                            ),
                            itemBuilder: (context, index) {
                              final item = rows[index];
                              final rowContacts =
                                   item["contacts"] as List<String>? ?? [];
                              final contacts = rowContacts.isNotEmpty
                                  ? rowContacts
                                  : defaultContacts;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            formatDateTime(
                                                item["createdAt"] as String),
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFF5A6C7D),
                                              height: 1.25,
                                            ),
                                          ),
                                          for (final contact in contacts)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 2),
                                              child: Text(
                                                contact,
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF5A6C7D),
                                                  height: 1.25,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _statusCapsule(item["type"] as String),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF8A99A6),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
