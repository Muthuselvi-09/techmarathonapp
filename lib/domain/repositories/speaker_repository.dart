import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class SpeakerRepository {
  /// Watch speakers for a specific event as a stream.
  Stream<List<Speaker>> watchSpeakers(String eventId);

  /// Get a single speaker by its document ID.
  Future<Speaker?> getSpeakerById(String id);

  /// Add a new speaker.
  Future<void> addSpeaker(Speaker speaker);

  /// Update an existing speaker.
  Future<void> updateSpeaker(Speaker speaker);

  /// Delete a speaker.
  Future<void> deleteSpeaker(String eventId, String id);
}
