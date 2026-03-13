class MentorshipProfileModel {
  final int? userId;
  final String role; // MENTOR, MENTEE, BOTH
  final String department;
  final int yearsOfExperience;
  final List<String> expertise;
  final List<String> interests;
  final String bio;
  final String availability; // HIGHLY_AVAILABLE, AVAILABLE, LIMITED, NOT_AVAILABLE
  final String timezone;
  final String? linkedInUrl;

  const MentorshipProfileModel({
    this.userId,
    required this.role,
    required this.department,
    required this.yearsOfExperience,
    required this.expertise,
    required this.interests,
    required this.bio,
    required this.availability,
    required this.timezone,
    this.linkedInUrl,
  });

  factory MentorshipProfileModel.fromJson(Map<String, dynamic> json) {
    return MentorshipProfileModel(
      userId: json['userId'] as int?,
      role: json['role'] as String,
      department: json['department'] as String,
      yearsOfExperience: (json['yearsOfExperience'] as num).toInt(),
      expertise: (json['expertise'] as List?)?.map((e) => e as String).toList() ?? [],
      interests: (json['interests'] as List?)?.map((e) => e as String).toList() ?? [],
      bio: json['bio'] as String? ?? '',
      availability: json['availability'] as String,
      timezone: json['timezone'] as String,
      linkedInUrl: json['linkedInUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'department': department,
        'yearsOfExperience': yearsOfExperience,
        'expertise': expertise,
        'interests': interests,
        'bio': bio,
        'availability': availability,
        'timezone': timezone,
        'linkedInUrl': linkedInUrl,
      };
}

class MatchModel {
  final int userId;
  final String userName;
  final MentorshipProfileModel profile;
  final double compatibilityScore;
  final List<String> commonInterests;
  // Returned by /matches/advanced — defaults to 0 for basic /matches
  final double distanceScore;

  const MatchModel({
    required this.userId,
    required this.userName,
    required this.profile,
    required this.compatibilityScore,
    required this.commonInterests,
    this.distanceScore = 0.0,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      userId: (json['userId'] as num).toInt(),
      userName: json['userName'] as String,
      profile: MentorshipProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      commonInterests:
          (json['commonInterests'] as List?)?.map((e) => e as String).toList() ?? [],
      distanceScore: (json['distanceScore'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MentorshipRequestModel {
  final int id;
  final int menteeId;
  final String menteeName;
  final int mentorId;
  final String mentorName;
  final String message;
  final List<String> topics;
  final String proposedDuration; // ONE_MONTH, THREE_MONTHS, SIX_MONTHS, ONE_YEAR
  final String status;           // PENDING, ACCEPTED, REJECTED, CANCELLED
  final String? rejectionReason; // populated when status == REJECTED
  final String createdAt;

  const MentorshipRequestModel({
    required this.id,
    required this.menteeId,
    required this.menteeName,
    required this.mentorId,
    required this.mentorName,
    required this.message,
    required this.topics,
    required this.proposedDuration,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  factory MentorshipRequestModel.fromJson(Map<String, dynamic> json) {
    return MentorshipRequestModel(
      id: (json['id'] as num).toInt(),
      menteeId: (json['menteeId'] as num).toInt(),
      menteeName: json['menteeName'] as String? ?? 'Student',
      mentorId: (json['mentorId'] as num).toInt(),
      mentorName: json['mentorName'] as String? ?? 'Alum/Staff',
      message: json['message'] as String,
      topics: (json['topics'] as List?)?.map((e) => e as String).toList() ?? [],
      proposedDuration: json['proposedDuration'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }
}

class RelationshipModel {
  final int id;
  final int menteeId;
  final String menteeName;
  final int mentorId;
  final String mentorName;
  final String goals;
  final String frequency;        // WEEKLY, BIWEEKLY, MONTHLY
  final String preferredChannel; // EMAIL, PHONE, VIDEO_CALL, IN_PERSON, MESSAGING
  final String status;           // ACTIVE, PAUSED, COMPLETED
  final String createdAt;

  const RelationshipModel({
    required this.id,
    required this.menteeId,
    required this.menteeName,
    required this.mentorId,
    required this.mentorName,
    required this.goals,
    required this.frequency,
    required this.preferredChannel,
    required this.status,
    required this.createdAt,
  });

  factory RelationshipModel.fromJson(Map<String, dynamic> json) {
    return RelationshipModel(
      id: (json['id'] as num).toInt(),
      menteeId: (json['menteeId'] as num).toInt(),
      menteeName: json['menteeName'] as String? ?? 'Mentee',
      mentorId: (json['mentorId'] as num).toInt(),
      mentorName: json['mentorName'] as String? ?? 'Mentor',
      goals: json['goals'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      preferredChannel: json['preferredChannel'] as String? ?? '',
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

// ── NEW ────────────────────────────────────────────────────────────────────────
// Maps POST /api/mentorship/relationships/{id}/feedback
//      GET  /api/mentorship/relationships/{id}/feedback
class FeedbackModel {
  final int id;
  final int relationshipId;
  final int reviewerId;
  final int rating;     // 1–5
  final String comment;
  final String createdAt;

  const FeedbackModel({
    required this.id,
    required this.relationshipId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: (json['id'] as num).toInt(),
      relationshipId: (json['relationshipId'] as num).toInt(),
      reviewerId: (json['reviewerId'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] as String,
    );
  }
}