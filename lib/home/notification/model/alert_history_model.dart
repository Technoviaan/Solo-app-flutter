class AlertHistoryModel {

  final String id;
  final String type;
  final String status;
  final String createdAt;

  AlertHistoryModel({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory AlertHistoryModel.fromJson(Map<String, dynamic> json) {

    return AlertHistoryModel(
      id: json["_id"],
      type: json["type"] ?? "",
      status: json["status"] ?? "",
      createdAt: json["createdAt"] ?? "",
    );
  }
}