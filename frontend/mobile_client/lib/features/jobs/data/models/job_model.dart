import 'package:decp_mobile_app/features/jobs/domain/entities/job.dart';

class JobModel extends Job {
  const JobModel({
    super.id,
    required super.title,
    required super.description,
    required super.company,
    required super.location,
    required super.type,
    required super.postedBy,
    required super.posterName,
    required super.status,
    required super.applicationCount,
    super.createdAt,
    super.updatedAt,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] != null ? (json['id'] as num).toInt() : null,
      title: json['title'] as String,
      description: json['description'] as String,
      company: json['company'] as String,
      location: json['location'] as String,
      type: json['type'] as String,

      postedBy: json['postedBy'] != null
          ? (json['postedBy'] as num).toInt()
          : null,

      posterName: json['posterName'] as String? ?? '',

      status: json['status'] as String? ?? 'OPEN',

      applicationCount: json['applicationCount'] != null
          ? (json['applicationCount'] as num).toInt()
          : 0,

      // Keeping as String (as requested)
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'company': company,
        'location': location,
        'type': type,
        'postedBy': postedBy,
        'posterName': posterName,
        'status': status,
        'applicationCount': applicationCount,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}