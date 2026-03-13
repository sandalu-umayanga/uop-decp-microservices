import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/mentorship_remote_datasource.dart';
import '../../data/models/mentorship_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ─────────────────────────────────────────────
// Data container
// ─────────────────────────────────────────────

class MentorshipData {
  final MentorshipProfileModel? profile;
  final List<MatchModel> matches;
  final List<MentorshipRequestModel> requests;
  final List<RelationshipModel> relationships;

  const MentorshipData({
    this.profile,
    required this.matches,
    required this.requests,
    required this.relationships,
  });

  MentorshipData copyWith({
    MentorshipProfileModel? profile,
    List<MatchModel>? matches,
    List<MentorshipRequestModel>? requests,
    List<RelationshipModel>? relationships,
  }) =>
      MentorshipData(
        profile: profile ?? this.profile,
        matches: matches ?? this.matches,
        requests: requests ?? this.requests,
        relationships: relationships ?? this.relationships,
      );
}

// ─────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────

class MentorshipProviderNotifier
    extends Notifier<AsyncValue<MentorshipData>> {
  @override
  AsyncValue<MentorshipData> build() {
    Future.microtask(loadAll);
    return const AsyncLoading();
  }

  MentorshipRemoteDatasource get _ds =>
      ref.read(mentorshipDatasourceProvider);

  // ── Load everything ──────────────────────────────────────────────────────

  Future<void> loadAll() async {
    state = const AsyncLoading();
    try {
      MentorshipProfileModel? profile;
      try {
        profile = await _ds.getProfile();
      } catch (_) {
        // 404 → auto-create a minimal profile so matches are available
        final user = ref.read(currentUserProvider);
        if (user != null) {
          try {
            await _ds.saveProfile({
              'role': user.role == 'STUDENT' ? 'MENTEE' : 'MENTOR',
              'department': 'Computer Science',
              'yearsOfExperience': user.role == 'STUDENT' ? 0 : 2,
              'expertise': ['General'],
              'interests': ['Technology'],
              'bio': user.bio ?? 'Looking forward to connecting!',
              'availability': 'AVAILABLE',
              'timezone': 'UTC',
            });
            profile = await _ds.getProfile();
          } catch (_) {}
        }
      }

      final matches =
          profile != null ? await _ds.getMatches() : <MatchModel>[];
      final requests = await _ds.getRequests();
      final relationships = await _ds.getRelationships();

      state = AsyncData(MentorshipData(
        profile: profile,
        matches: matches,
        requests: requests,
        relationships: relationships,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // ── Profile ──────────────────────────────────────────────────────────────

  Future<bool> saveProfile(Map<String, dynamic> data) async {
    try {
      await _ds.saveProfile(data);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Matches ───────────────────────────────────────────────────────────────

  /// Reload matches, using the advanced endpoint when any filter is provided.
  Future<void> loadMatches({
    String? expertise,
    String? availability,
    String? department,
  }) async {
    MentorshipData? current;
    state.when(
      data: (d) => current = d,
      loading: () {},
      error: (_, __) {},
    );
    final snapshot = current;
    if (snapshot == null) return;
    try {
      final matches =
          (expertise != null || availability != null || department != null)
              ? await _ds.getAdvancedMatches(
                  expertise: expertise,
                  availability: availability,
                  department: department,
                )
              : await _ds.getMatches();
      state = AsyncData(snapshot.copyWith(matches: matches));
    } catch (_) {}
  }

  // ── Requests ──────────────────────────────────────────────────────────────

  Future<bool> requestMentor({
    required int mentorId,
    required String message,
    required List<String> topics,
    String proposedDuration = 'THREE_MONTHS',
  }) async {
    try {
      await _ds.sendRequest({
        'mentorId': mentorId,
        'message': message,
        'topics': topics,
        'proposedDuration': proposedDuration,
      });
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> respondRequest(
    int requestId,
    String status, {
    String? rejectionReason,
  }) async {
    try {
      await _ds.respondRequest(requestId, status,
          rejectionReason: rejectionReason);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Relationships ─────────────────────────────────────────────────────────

  Future<RelationshipModel?> getRelationshipDetail(int relationshipId) async {
    try {
      return await _ds.getRelationshipDetail(relationshipId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateRelationship(
      int relationshipId, Map<String, dynamic> data) async {
    try {
      await _ds.updateRelationship(relationshipId, data);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> endRelationship(int relationshipId) async {
    try {
      await _ds.endRelationship(relationshipId);
      await loadAll();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Feedback ──────────────────────────────────────────────────────────────

  Future<bool> submitFeedback(
      int relationshipId, int rating, String comment) async {
    try {
      await _ds.submitFeedback(relationshipId, {
        'rating': rating,
        'comment': comment,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<FeedbackModel>> getFeedback(int relationshipId) async {
    try {
      return await _ds.getFeedback(relationshipId);
    } catch (_) {
      return [];
    }
  }
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

final mentorshipProvider =
    NotifierProvider<MentorshipProviderNotifier, AsyncValue<MentorshipData>>(
  MentorshipProviderNotifier.new,
);