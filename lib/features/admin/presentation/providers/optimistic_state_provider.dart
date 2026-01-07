import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/domain/event_models.dart';

/// Optimistic state for Events (local updates before backend confirms)
final optimisticEventsProvider = StateNotifierProvider<OptimisticEventsNotifier, List<CodingEvent>>((ref) {
  return OptimisticEventsNotifier();
});

class OptimisticEventsNotifier extends StateNotifier<List<CodingEvent>> {
  OptimisticEventsNotifier() : super([]);

  void addEvent(CodingEvent event) {
    state = [...state, event];
  }

  void updateEvent(CodingEvent event) {
    state = [
      for (final e in state)
        if (e.id == event.id) event else e
    ];
  }

  void removeEvent(String eventId) {
    state = state.where((e) => e.id != eventId).toList();
  }

  void clear() {
    state = [];
  }
}

/// Optimistic state for Speakers
final optimisticSpeakersProvider = StateNotifierProvider<OptimisticSpeakersNotifier, List<Speaker>>((ref) {
  return OptimisticSpeakersNotifier();
});

class OptimisticSpeakersNotifier extends StateNotifier<List<Speaker>> {
  OptimisticSpeakersNotifier() : super([]);

  void addSpeaker(Speaker speaker) {
    state = [...state, speaker];
  }

  void updateSpeaker(Speaker speaker) {
    state = [
      for (final s in state)
        if (s.id == speaker.id) speaker else s
    ];
  }

  void removeSpeaker(String speakerId) {
    state = state.where((s) => s.id != speakerId).toList();
  }

  void clear() {
    state = [];
  }
}

/// Optimistic state for Sponsors
final optimisticSponsorsProvider = StateNotifierProvider<OptimisticSponsorsNotifier, List<Sponsor>>((ref) {
  return OptimisticSponsorsNotifier();
});

class OptimisticSponsorsNotifier extends StateNotifier<List<Sponsor>> {
  OptimisticSponsorsNotifier() : super([]);

  void addSponsor(Sponsor sponsor) {
    state = [...state, sponsor];
  }

  void updateSponsor(Sponsor sponsor) {
    state = [
      for (final s in state)
        if (s.id == sponsor.id) sponsor else s
    ];
  }

  void removeSponsor(String sponsorId) {
    state = state.where((s) => s.id != sponsorId).toList();
  }

  void clear() {
    state = [];
  }
}
