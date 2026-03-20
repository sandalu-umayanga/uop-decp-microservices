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
  final String menteeUserName;
  final int mentorId;
  final String mentorUserName;
  final String message;
  final List<String> topics;
  final String proposedDuration;
  final String status;
  final String? rejectionReason;
  final String createdAt;
  final String? respondedAt;

  const MentorshipRequestModel({
    required this.id,
    required this.menteeId,
    required this.menteeUserName,
    required this.mentorId,
    required this.mentorUserName,
    required this.message,
    required this.topics,
    required this.proposedDuration,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
    this.respondedAt,
  });

  factory MentorshipRequestModel.fromJson(Map<String, dynamic> json) {
    return MentorshipRequestModel(
      id: (json['id'] as num).toInt(),
      menteeId: (json['menteeId'] as num).toInt(),
      menteeUserName: json['menteeUserName'] as String,
      mentorId: (json['mentorId'] as num).toInt(),
      mentorUserName: json['mentorUserName'] as String,
      message: json['message'] as String? ?? '',
      topics: (json['topics'] as List?)?.map((e) => e as String).toList() ?? [],
      proposedDuration: json['proposedDuration'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: json['createdAt'] as String,
      respondedAt: json['respondedAt'] as String?,
    );
  }
}
