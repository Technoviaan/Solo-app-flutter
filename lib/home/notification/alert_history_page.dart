import 'package:flutter/material.dart';
import 'package:solo_app/core/widgets/solo_logo.dart';
import 'package:solo_app/core/utils/app_size.dart';
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
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future load() async {
    history = await NotificationApi.getAlertHistory();
    localHistory = await HistoryStore.getLocalAlerts();

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
    final period = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return "$hour:${date.minute.toString().padLeft(2, '0')}$period";
  }

  List<Map<String, String>> _rows() {
    final apiRows = history
        .map((e) => {
              "createdAt": e.createdAt,
              "type": e.type,
              "contact": "—",
            })
        .toList();

    final localRows = localHistory
        .map((e) => {
              "createdAt": (e["createdAt"] ?? "").toString(),
              "type": (e["type"] ?? "").toString(),
              "contact": (e["contact"] ?? "—").toString(),
            })
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
                "Sent Alerts",
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
                                color: Colors.white,
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
                                        "No missed check-in or SOS alerts yet",
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
                              color: Colors.white,
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
                                    child: ListView.separated(
                                      physics: const BouncingScrollPhysics(),
                                      itemCount: rows.length,
                                      separatorBuilder: (context, index) =>
                                          const Divider(
                                        height: 1,
                                        color: Color(0xFFE5E7EB),
                                      ),
                                      itemBuilder: (_, i) {
                                        final item = rows[i];
                                        return dataRow(
                                          item["type"]!,
                                          item["createdAt"]!,
                                          item["contact"]!,
                                        );
                                      },
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
      color: const Color(0xFFEC6A52),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(
            flex: 20,
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
            flex: 22,
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
            flex: 38,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                "Contact",
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
            flex: 20,
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                "Type",
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

  Widget dataRow(String type, String created, String contact) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 20,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                getDate(created),
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
            flex: 22,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                getTime(created),
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
            flex: 38,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                contact,
                overflow: TextOverflow.ellipsis,
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
            flex: 20,
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                type == "SOS" ? "SOS" : "Missed",
                style: const TextStyle(
                  color: Color(0xFF5A6C7D),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}