enum RsvpStatus { GOING, NOT_GOING, MAYBE } // match backend values exactly

class RsvpModel {
  final int? id;
  final int eventId;
  final int userId;
  final String? userName;
  final RsvpStatus status;
  final DateTime? respondedAt;

  const RsvpModel({
    this.id,
    required this.eventId,
    required this.userId,
    this.userName,
    required this.status,
    this.respondedAt,
  });

  factory RsvpModel.fromJson(Map<String, dynamic> json) {
    return RsvpModel(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      eventId: (json['eventId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userName: json['userName'] as String?,
      status: RsvpStatus.values.firstWhere(
          (e) => e.toString().split('.').last == json['status']),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
        'status': status.toString().split('.').last,
      };
}