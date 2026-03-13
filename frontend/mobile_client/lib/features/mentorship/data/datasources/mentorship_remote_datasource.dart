import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../models/mentorship_models.dart';

abstract class MentorshipRemoteDatasource {
  // ── Profile ──────────────────────────────────────────────────────────────
  Future<MentorshipProfileModel> getProfile();
  Future<MentorshipProfileModel> saveProfile(Map<String, dynamic> data);

  // ── Matches ──────────────────────────────────────────────────────────────
  Future<List<MatchModel>> getMatches();

  /// GET /api/mentorship/matches/advanced
  /// All params are optional — only sent when non-null.
  Future<List<MatchModel>> getAdvancedMatches({
    String? expertise,
    String? availability,
    String? department,
  });

  // ── Requests ─────────────────────────────────────────────────────────────
  Future<List<MentorshipRequestModel>> getRequests();
  Future<void> sendRequest(Map<String, dynamic> data);

  /// [rejectionReason] is optional — only sent when status == 'REJECTED'.
  Future<void> respondRequest(int id, String status, {String? rejectionReason});

  // ── Relationships ─────────────────────────────────────────────────────────
  Future<List<RelationshipModel>> getRelationships();

  /// GET /api/mentorship/relationships/{id}
  Future<RelationshipModel> getRelationshipDetail(int id);

  /// PUT /api/mentorship/relationships/{id}
  /// Body keys: goals, frequency, preferredChannel, status
  Future<void> updateRelationship(int id, Map<String, dynamic> data);

  /// DELETE /api/mentorship/relationships/{id}
  Future<void> endRelationship(int id);

  // ── Feedback ──────────────────────────────────────────────────────────────
  /// POST /api/mentorship/relationships/{id}/feedback
  Future<void> submitFeedback(int relationshipId, Map<String, dynamic> data);

  /// GET /api/mentorship/relationships/{id}/feedback
  Future<List<FeedbackModel>> getFeedback(int relationshipId);
}

// ─────────────────────────────────────────────────────────────────────────────

class MentorshipRemoteDatasourceImpl implements MentorshipRemoteDatasource {
  final Dio _dio;
  MentorshipRemoteDatasourceImpl(this._dio);

  // ── Profile ───────────────────────────────────────────────────────────────

  @override
  Future<MentorshipProfileModel> getProfile() async {
    try {
      final resp = await _dio.get('${ApiConstants.mentorship}/profile');
      return MentorshipProfileModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ServerException('Profile not found');
      }
      _handleError(e);
    }
  }

  @override
  Future<MentorshipProfileModel> saveProfile(Map<String, dynamic> data) async {
    try {
      final resp = await _dio.post(
        '${ApiConstants.mentorship}/profile',
        data: data,
      );
      return MentorshipProfileModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ── Matches ───────────────────────────────────────────────────────────────

  @override
  Future<List<MatchModel>> getMatches() async {
    try {
      final resp = await _dio.get('${ApiConstants.mentorship}/matches');
      final list = resp.data as List? ?? [];
      return list
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<MatchModel>> getAdvancedMatches({
    String? expertise,
    String? availability,
    String? department,
  }) async {
    try {
      final params = <String, String>{};
      if (expertise != null && expertise.isNotEmpty) {
        params['expertise'] = expertise;
      }
      if (availability != null && availability.isNotEmpty) {
        params['availability'] = availability;
      }
      if (department != null && department.isNotEmpty) {
        params['department'] = department;
      }

      final resp = await _dio.get(
        '${ApiConstants.mentorship}/matches/advanced',
        queryParameters: params.isEmpty ? null : params,
      );
      final list = resp.data as List? ?? [];
      return list
          .map((e) => MatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ── Requests ──────────────────────────────────────────────────────────────

  @override
  Future<List<MentorshipRequestModel>> getRequests() async {
    try {
      final resp = await _dio.get('${ApiConstants.mentorship}/requests');
      final list = resp.data as List? ?? [];
      return list
          .map((e) =>
              MentorshipRequestModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> sendRequest(Map<String, dynamic> data) async {
    try {
      await _dio.post('${ApiConstants.mentorship}/request', data: data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> respondRequest(
    int id,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      await _dio.put(
        '${ApiConstants.mentorship}/request/$id',
        data: {
          'status': status,
          'rejectionReason': rejectionReason,
        },
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ── Relationships ─────────────────────────────────────────────────────────

  @override
  Future<List<RelationshipModel>> getRelationships() async {
    try {
      final resp = await _dio.get('${ApiConstants.mentorship}/relationships');
      final list = resp.data as List? ?? [];
      return list
          .map((e) => RelationshipModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<RelationshipModel> getRelationshipDetail(int id) async {
    try {
      final resp =
          await _dio.get('${ApiConstants.mentorship}/relationships/$id');
      return RelationshipModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> updateRelationship(int id, Map<String, dynamic> data) async {
    try {
      await _dio.put(
        '${ApiConstants.mentorship}/relationships/$id',
        data: data,
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<void> endRelationship(int id) async {
    try {
      await _dio.delete('${ApiConstants.mentorship}/relationships/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  @override
  Future<void> submitFeedback(
    int relationshipId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dio.post(
        '${ApiConstants.mentorship}/relationships/$relationshipId/feedback',
        data: data,
      );
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  @override
  Future<List<FeedbackModel>> getFeedback(int relationshipId) async {
    try {
      final resp = await _dio.get(
        '${ApiConstants.mentorship}/relationships/$relationshipId/feedback',
      );
      final list = resp.data as List? ?? [];
      return list
          .map((e) => FeedbackModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ── Shared error handler ──────────────────────────────────────────────────

  Never _handleError(DioException e) {
    if (e.response?.statusCode == 401) throw const AuthException();
    if (e.response?.statusCode == 403) throw const ForbiddenException();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.unknown) {
      throw const NetworkException();
    }
    throw ServerException(
        e.response?.data?['message']?.toString() ?? 'Error');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

final mentorshipDatasourceProvider =
    Provider<MentorshipRemoteDatasource>((ref) {
  return MentorshipRemoteDatasourceImpl(ref.watch(dioProvider));
});