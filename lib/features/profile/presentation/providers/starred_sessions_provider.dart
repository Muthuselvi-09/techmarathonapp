import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tech_marathon_app/data/models/schedule.dart';
import 'package:tech_marathon_app/core/services/notification_service.dart';
import 'dart:async';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';

/// Provider to manage starred/saved sessions per user
/// Stores starred session IDs in Firestore under users/{userId} document

class StarredSessionsNotifier extends StateNotifier<Set<String>> {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _subscription;

  StarredSessionsNotifier(this._ref) : super({}) {
    _auth.authStateChanges().listen((user) {
      _subscription?.cancel();
      if (user != null) {
        _subscription = _ref.watch(profileRepositoryProvider)
            .getStarredSessionIds(user.uid)
            .listen((ids) {
          state = ids.toSet();
        });
      } else {
        state = {};
      }
    });
  }

  bool isStarred(String sessionId) => state.contains(sessionId);

  Future<void> toggleStar(String sessionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _ref.read(profileRepositoryProvider).toggleStarSession(userId, sessionId);
    
    // Handle notifications
    if (!state.contains(sessionId)) {
      // It was NOT starred, so it will be starred after repo call (optimistic or wait for stream)
      // For notifications, we can fetch once
      final sessionDoc = await FirebaseFirestore.instance.collection('schedules').doc(sessionId).get();
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final startTime = (sessionData['startTime'] as Timestamp).toDate();
        await notificationService.scheduleSessionReminder(
          sessionId: sessionId,
          sessionTitle: sessionData['title'] ?? 'Session',
          eventName: 'Tech Marathon',
          sessionStartTime: startTime,
        );
      }
    } else {
      await notificationService.cancelNotification(sessionId.hashCode);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final starredSessionsProvider = StateNotifierProvider<StarredSessionsNotifier, Set<String>>((ref) {
  return StarredSessionsNotifier(ref);
});

final starredSchedulesProvider = StreamProvider<List<Schedule>>((ref) {
  final starredIds = ref.watch(starredSessionsProvider);
  if (starredIds.isEmpty) return Stream.value([]);

  final idsList = starredIds.toList();
  // Simplified for now: just fetch all and filter locally if > 10
  if (idsList.length <= 10) {
    return FirebaseFirestore.instance
        .collection('schedules')
        .where(FieldPath.documentId, whereIn: idsList)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Schedule.fromMap(doc.data(), doc.id))
            .toList());
  } else {
    return FirebaseFirestore.instance
        .collection('schedules')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => starredIds.contains(doc.id))
            .map((doc) => Schedule.fromMap(doc.data(), doc.id))
            .toList());
  }
});
