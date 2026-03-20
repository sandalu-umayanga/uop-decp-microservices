import 'package:decp_mobile_app/features/mentorship/data/models/feedback_model.dart';

class RelationshipModel {
  final int id;
  final int menteeId;
  final String menteeUserName;
  final int mentorId;
  final String mentorUserName;
  final String goals;
  final String frequency;
  final String preferredChannel;
  final String status;
  final String createdAt;

  final List<FeedbackModel> mentorFeedback;
  final List<FeedbackModel> menteeFeedback;

  const RelationshipModel({
    required this.id,
    required this.menteeId,
    required this.menteeUserName,
    required this.mentorId,
    required this.mentorUserName,
    required this.goals,
    required this.frequency,
    required this.preferredChannel,
    required this.status,
    required this.createdAt,
    required this.mentorFeedback,
    required this.menteeFeedback,
  });

  factory RelationshipModel.fromJson(Map<String, dynamic> json) {
    return RelationshipModel(
      id: (json['id'] as num).toInt(),
      menteeId: (json['menteeId'] as num).toInt(),
      menteeUserName: json['menteeUserName'] as String,
      mentorId: (json['mentorId'] as num).toInt(),
      mentorUserName: json['mentorUserName'] as String,
      goals: json['goals'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      preferredChannel: json['preferredChannel'] as String? ?? '',
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,

      mentorFeedback: (json['mentorFeedback'] as List?)
              ?.map((e) => FeedbackModel.fromJson(e))
              .toList() ??
          [],
      menteeFeedback: (json['menteeFeedback'] as List?)
              ?.map((e) => FeedbackModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}