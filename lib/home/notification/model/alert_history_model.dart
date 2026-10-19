class AlertHistoryModel {
  final String id;
  final String type;
  final String status;
  final String createdAt;
  final List<String> contacts;

  AlertHistoryModel({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.contacts = const [],
  });

  factory AlertHistoryModel.fromJson(Map<String, dynamic> json) {
    List<String> contactsList = [];
    if (json["contacts"] != null && json["contacts"] is List) {
      contactsList =
          (json["contacts"] as List).map((e) => e.toString()).toList();
    } else if (json["contact"] != null && json["contact"].toString().isNotEmpty) {
      contactsList = [json["contact"].toString()];
    }

    return AlertHistoryModel(
      id: json["_id"] ?? "",
      type: json["type"] ?? "",
      status: json["status"] ?? "",
      createdAt: json["createdAt"] ?? "",
      contacts: contactsList,
    );
  }
}