class CheckinHistoryModel {

  final String id;
  final String scheduledTime;
  final String status;
  final String createdAt;

  CheckinHistoryModel({
    required this.id,
    required this.scheduledTime,
    required this.status,
    required this.createdAt,
  });

  factory CheckinHistoryModel.fromJson(Map<String, dynamic> json) {

    return CheckinHistoryModel(
      id: json["_id"],
      scheduledTime: json["scheduledTime"] ?? "",
      status: json["status"] ?? "",
      createdAt: json["createdAt"] ?? "",
    );
  }
}