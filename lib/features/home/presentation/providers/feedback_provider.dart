import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider to manage session feedback submission and tracking

class FeedbackState {
  final Set<String> submittedSessionIds;
  final bool isSubmitting;

  FeedbackState({
    this.submittedSessionIds = const {},
    this.isSubmitting = false,
  });

  FeedbackState copyWith({
    Set<String>? submittedSessionIds,
    bool? isSubmitting,
  }) {
    return FeedbackState(
      submittedSessionIds: submittedSessionIds ?? this.submittedSessionIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class FeedbackNotifier extends StateNotifier<FeedbackState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FeedbackNotifier(this._firestore, this._auth) : super(FeedbackState()) {
    _loadSubmittedFeedback();
  }

  Future<void> _loadSubmittedFeedback() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('sessionFeedback')
          .where('userId', isEqualTo: userId)
          .get();

      final submittedIds = snapshot.docs.map((doc) {
        final data = doc.data();
        return data['sessionId'] as String;
      }).toSet();

      state = state.copyWith(submittedSessionIds: submittedIds);
    } catch (e) {
      // Silent fail
    }
  }

  bool hasSubmittedFeedback(String sessionId) {
    return state.submittedSessionIds.contains(sessionId);
  }

  Future<bool> submitFeedback({
    required String sessionId,
    required String sessionTitle,
    required String eventId,
    required int rating,
    String? comment,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    state = state.copyWith(isSubmitting: true);

    try {
      await _firestore.collection('sessionFeedback').add({
        'userId': userId,
        'sessionId': sessionId,
        'sessionTitle': sessionTitle,
        'eventId': eventId,
        'rating': rating,
        'comment': comment ?? '',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      final newSubmitted = Set<String>.from(state.submittedSessionIds)..add(sessionId);
      state = state.copyWith(
        submittedSessionIds: newSubmitted,
        isSubmitting: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return false;
    }
  }
}

final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackState>((ref) {
  return FeedbackNotifier(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

/// Provider to check and get sessions that need feedback
/// (sessions that have ended but user hasn't submitted feedback for)
final pendingFeedbackSessionsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  // This will be populated by the SessionFeedbackWatcher widget
  return [];
});
