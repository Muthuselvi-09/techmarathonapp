import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/event_models.dart';
import 'package:tech_marathon_app/core/providers.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_speaker;
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_sponsor;
import 'package:tech_marathon_app/data/models/schedule.dart' as new_schedule;

final currentEventStreamProvider = StreamProvider<CodingEvent?>((ref) {
  final eventRepo = ref.watch(eventRepositoryProvider);
  return eventRepo.watchEvents().map((events) {
    if (events.isEmpty) return null;
    return events.first; // Default to first active event
  });
});

final mergedSpeakersProvider = StreamProvider<List<new_speaker.Speaker>>((ref) {
  return ref.watch(speakerRepositoryProvider).watchAllSpeakers();
});

final mergedSponsorsProvider = StreamProvider<List<new_sponsor.Sponsor>>((ref) {
  return ref.watch(sponsorRepositoryProvider).watchAllSponsors();
});


final schedulesStreamProvider = StreamProvider<List<new_schedule.Schedule>>((ref) {
  return ref.watch(currentEventStreamProvider).when(
    data: (event) {
      if (event == null) return Stream.value([]);
      return ref.watch(scheduleRepositoryProvider).watchSchedules(event.id);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value([]),
  );
});

final allEventsStreamProvider = StreamProvider<List<CodingEvent>>((ref) {
  final eventRepo = ref.watch(eventRepositoryProvider);
  return eventRepo.watchEvents();
});
