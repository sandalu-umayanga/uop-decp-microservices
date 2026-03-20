class JobApplicationModel {
  final int? id;
  final int jobId;
  final int userId;
  final String applicantName;

  final String? whyInterested;

  final String? resumeUrl;
  final String status;

  final String? appliedAt;

  const JobApplicationModel({
    this.id,
    required this.jobId,
    required this.userId,
    required this.applicantName,
    this.whyInterested,
    this.resumeUrl,
    required this.status,
    this.appliedAt,
  });

  factory JobApplicationModel.fromJson(Map<String, dynamic> json) {
    return JobApplicationModel(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      jobId: (json['jobId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      applicantName: json['applicantName'] as String,

      // FIX: match backend field name
      whyInterested: json['whyInterested'] as String?,

      resumeUrl: json['resumeUrl'] as String?,

      // FIX: backend default handling
      status: json['status'] as String? ?? 'PENDING',

      // Keeping as String
      appliedAt: json['appliedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'jobId': jobId,
        'userId': userId,
        'applicantName': applicantName,
        'whyInterested': whyInterested,
        'resumeUrl': resumeUrl,
        'status': status,
        'appliedAt': appliedAt,
      };
}