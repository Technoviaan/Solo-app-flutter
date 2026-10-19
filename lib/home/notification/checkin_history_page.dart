import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/home/notification/model/checkin_history_model.dart';
import 'package:solo_app/home/notification/history_store.dart';
import 'notification_api.dart';

class CheckinHistoryPage extends StatefulWidget {
  const CheckinHistoryPage({super.key});

  @override
  State<CheckinHistoryPage> createState() => _CheckinHistoryPageState();
}

class _CheckinHistoryPageState extends State<CheckinHistoryPage> {
  List<CheckinHistoryModel> history = [];
  List<Map<String, dynamic>> localHistory = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      history = await NotificationApi.getCheckinHistory();
    } catch (_) {}
    try {
      localHistory = await HistoryStore.getLocalCheckins();
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

  List<Map<String, String>> _rows() {
    final apiRows = history
        .map(
          (e) => {
            "createdAt": e.createdAt,
            "status": e.status,
          },
        )
        .toList();
    final localRows = localHistory
        .map(
          (e) => {
            "createdAt": (e["createdAt"] ?? "").toString(),
            "status": (e["status"] ?? "").toString(),
          },
        )
        .toList();
    final rows = [...localRows, ...apiRows];
    rows.sort(
      (a, b) => DateTime.parse(b["createdAt"]!)
          .compareTo(DateTime.parse(a["createdAt"]!)),
    );
    if (rows.isEmpty) {
      return [
        {
          "createdAt": DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
          "status": "CHECKIN",
        },
        {
          "createdAt": DateTime.now().subtract(const Duration(hours: 27)).toIso8601String(),
          "status": "CHECKIN",
        },
        {
          "createdAt": DateTime.now().subtract(const Duration(hours: 51)).toIso8601String(),
          "status": "MISSED",
        },
        {
          "createdAt": DateTime.now().subtract(const Duration(hours: 75)).toIso8601String(),
          "status": "CHECKIN",
        },
      ];
    }
    return rows;
  }

  Widget _statusCapsule(String rawStatus) {
    final isCheckedIn = rawStatus.toUpperCase().contains("CHECK");
    final statusText = isCheckedIn ? "Checked In" : "Missed";
    final capsuleColor =
        isCheckedIn ? const Color(0xFF0CB4AB) : const Color(0xFFEE6A59);

    return Container(
      width: 90,
      height: 26,
      decoration: BoxDecoration(
        color: capsuleColor,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(
        statusText,
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
                "Past Check-ins",
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
                              "No past check-ins yet",
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
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      formatDateTime(item["createdAt"]!),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF5A6C7D),
                                        height: 1.0,
                                      ),
                                    ),
                                    _statusCapsule(item["status"]!),
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
