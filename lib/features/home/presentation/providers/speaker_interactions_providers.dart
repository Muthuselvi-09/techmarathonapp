
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/auth/data/auth_repository.dart';
import 'package:tech_marathon_app/features/home/data/speaker_interaction_repository.dart';

final savedSpeakerIdsProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.read(speakerInteractionRepositoryProvider).watchSavedSpeakerIds(user.uid);
});

final userSpeakerRatingProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, speakerId) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Future.value(null);
  
  return ref.read(speakerInteractionRepositoryProvider).getUserRating(user.uid, speakerId);
});
