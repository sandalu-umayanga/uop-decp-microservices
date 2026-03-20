class ProjectMemberModel {
  final int id;
  final int userId;
  final String userName;
  final String role;
  final String? joinedAt;

  const ProjectMemberModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    this.joinedAt,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
      userName: json['userName']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      joinedAt: json['joinedAt']?.toString(),
    );
  }
}