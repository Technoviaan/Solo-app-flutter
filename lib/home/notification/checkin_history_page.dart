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
                      // 🛠️ FIX: image sample shows row fill is the
                      // same off-white as the page background
                      // (#F7F8F3), not pure white.
                      color: const Color(0xFFF7F8F3),
                      border: Border.all(
                        color: const Color(0x808A99A6),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          headerRow(),
                          Container(
                            height: 48,
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
                    // 🛠️ FIX: image sample shows row fill is the
                    // same off-white as the page background
                    // (#F7F8F3), not pure white.
                    color: const Color(0xFFF7F8F3),
                    border: Border.all(
                      color: const Color(0x808A99A6),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      children: [
                        headerRow(),
                        Expanded(
                          // 🛠️ FIX: RawScrollbar (not plain
                          // Scrollbar, which has no color param)
                          // adds the visible right-side scroll
                          // thumb seen in the design, in the same
                          // teal as the header (#78BCC4).
                          child: RawScrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            thickness: 4,
                            radius: const Radius.circular(8),
                            thumbColor: const Color(0xFF78BCC4),
                            child: ListView.builder(
                              controller: _scrollController,
                              physics:
                              const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: rows.length,
                              itemBuilder: (_, i) {
                                final item = rows[i];
                                // 🛠️ FIX: was ListView.separated,
                                // which only draws a divider
                                // BETWEEN items — the last row
                                // never got a divider under it.
                                // Now every row (including the
                                // last) draws its own divider
                                // directly beneath it.
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    dataRow(
                                      getDate(item["createdAt"]!),
                                      getTime(item["createdAt"]!),
                                      item["status"]!,
                                    ),
                                    // 🛠️ FIX: sampled exact grey
                                    // from the design image
                                    // (#CED5D6, was #E5E7EB), and
                                    // it's inset from the left/
                                    // right edges (not edge-to-
                                    // edge) — indent matches the
                                    // row text's left padding.
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      indent: 16,
                                      endIndent: 16,
                                      color: Color(0xFFCED5D6),
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
                    size: 28,
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
      // 🛠️ FIX: sampled exact teal from the design image (#78BCC4), was
      // slightly off (#7CBBC9).
      color: const Color(0xFF78BCC4),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(
            flex: 25,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                "Date",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Container(
            width: 2,
            height: 26,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const Expanded(
            flex: 30,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                "Time",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Container(
            width: 2,
            height: 26,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const Expanded(
            flex: 45,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                "Check-in Status",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 25,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                date,
                style: const TextStyle(
                  color: Color(0xFF5A6C7D),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            flex: 30,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF5A6C7D),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Row(
                children: [
                  Icon(
                    status == "CHECKED_IN" ? Icons.check_circle : Icons.cancel,
                    color: status == "CHECKED_IN"
                        ? const Color(0xFF26A69A)
                        : const Color(0xFFEF5350),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status == "CHECKED_IN" ? "Checked in" : "Missed",
                    style: const TextStyle(
                      color: Color(0xFF5A6C7D),
                      fontSize: 14,
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