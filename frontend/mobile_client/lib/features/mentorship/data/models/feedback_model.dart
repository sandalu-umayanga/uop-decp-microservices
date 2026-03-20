class FeedbackModel {
  final int id;
  final int relationshipId;
  final int givenByUserId;
  final String givenByUserName;
  final String givenByRole;
  final int rating;
  final String comment;
  final String createdAt;

  const FeedbackModel({
    required this.id,
    required this.relationshipId,
    required this.givenByUserId,
    required this.givenByUserName,
    required this.givenByRole,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: (json['id'] as num).toInt(),
      relationshipId: (json['relationshipId'] as num).toInt(),
      givenByUserId: (json['givenByUserId'] as num).toInt(),
      givenByUserName: json['givenByUserName'] as String,
      givenByRole: json['givenByRole'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] as String,
    );
  }
}