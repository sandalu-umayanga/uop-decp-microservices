import 'package:decp_mobile_app/features/research/data/models/project_member_model.dart';

class ResearchModel {
  final int? id;
  final String title;
  final String researchAbstract;
  final List<String> authors;

  final List<String> tags; // enum -> string
  final String category;   // enum -> string

  final String? documentUrl;
  final String? doi;

  final int? createdBy;
  final String? createdByName;

  final int views;
  final int downloads;
  final int citations;

  final List<ProjectMemberModel> members;

  final String? createdAt;
  final String? updatedAt;

  const ResearchModel({
    this.id,
    required this.title,
    required this.researchAbstract,
    required this.authors,
    required this.tags,
    required this.category,
    this.documentUrl,
    this.doi,
    this.createdBy,
    this.createdByName,
    this.views = 0,
    this.downloads = 0,
    this.citations = 0,
    this.members = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ResearchModel.fromJson(Map<String, dynamic> json) {
    return ResearchModel(
      id: (json['id'] as num?)?.toInt(),

      title: json['title']?.toString() ?? '',
      researchAbstract: json['researchAbstract']?.toString() ?? '',

      authors: (json['authors'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],

      // enum → string
      tags: (json['tags'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],

      category: json['category']?.toString() ?? '',

      documentUrl: json['documentUrl']?.toString(),
      doi: json['doi']?.toString(),

      createdBy: (json['createdBy'] as num?)?.toInt(),
      createdByName: json['createdByName']?.toString(),

      views: (json['views'] as num?)?.toInt() ?? 0,
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      citations: (json['citations'] as num?)?.toInt() ?? 0,

      members: (json['members'] as List?)
              ?.map((e) => ProjectMemberModel.fromJson(e))
              .toList() ??
          [],

      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'researchAbstract': researchAbstract,
      'authors': authors,
      'tags': tags, // must match enum names
      'documentUrl': documentUrl,
      'doi': doi,
      'category': category,
    };
  }
}