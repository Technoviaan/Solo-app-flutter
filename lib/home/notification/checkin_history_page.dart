import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/core/utils/app_size.dart';
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

  // 🛠️ FIX: Scrollbar needs an explicit ScrollController to know which
  // scrollable to attach the visible thumb to.
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future load() async {
    history = await NotificationApi.getCheckinHistory();
    localHistory = await HistoryStore.getLocalCheckins();

    setState(() {
      loading = false;
    });
  }

  String getDate(String iso) {
    final date = DateTime.parse(iso);
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
    return "${date.day} ${months[date.month - 1]}";
  }

  String getTime(String iso) {
    final date = DateTime.parse(iso);

    int hour = date.hour;
    String period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return "$hour:${date.minute.toString().padLeft(2, '0')}$period";
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
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
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
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF002C3E),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : rows.isEmpty
                    ? Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F8F3),
                      border: Border.all(
                        color: const Color(0x338A99A6),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          headerRow(),
                          Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: const Text(
                              "No past check-ins yet",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A99A6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8F3),
                    border: Border.all(
                      color: const Color(0x338A99A6),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        headerRow(),
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollController,
                            child: ListView.builder(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: rows.length,
                              itemBuilder: (_, i) {
                                final item = rows[i];
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    dataRow(
                                      getDate(item["createdAt"]!),
                                      getTime(item["createdAt"]!),
                                      item["status"]!,
                                    ),
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      indent: 14,
                                      endIndent: 14,
                                      color: Color(0x2B8A99A6),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 10),
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

  Widget headerRow() {
    return Container(
      color: const Color(0xFF78BCC4),
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          const Expanded(
            flex: 26,
            child: Padding(
              padding: EdgeInsets.only(left: 14),
              child: Text(
                "Date",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 18,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const Expanded(
            flex: 28,
            child: Padding(
              padding: EdgeInsets.only(left: 14),
              child: Text(
                "Time",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 18,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const Expanded(
            flex: 46,
            child: Padding(
              padding: EdgeInsets.only(left: 14),
              child: Text(
                "Check-in Status",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget dataRow(String date, String time, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 26,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                date,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF5A6C7D),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 28,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text(
                time,
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF5A6C7D),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 46,
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Row(
                children: [
                  Icon(
                    status == "CHECKED_IN" ? Icons.check_circle : Icons.cancel,
                    color: status == "CHECKED_IN"
                        ? const Color(0xFF26A69A)
                        : const Color(0xFFEF5350),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status == "CHECKED_IN" ? "Checked in" : "Missed",
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFF5A6C7D),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}