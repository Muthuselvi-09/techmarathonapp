import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class SpeakerRepository {
  /// Watch speakers for a specific event as a stream.
  Stream<List<Speaker>> watchSpeakers(String eventId);

  /// Watch ALL speakers across all events.
  Stream<List<Speaker>> watchAllSpeakers();

  /// Get a single speaker by its document ID.
  Future<Speaker?> getSpeakerById(String id);

  /// Add a new speaker.
  Future<void> addSpeaker(Speaker speaker);

  /// Update an existing speaker.
  Future<void> updateSpeaker(Speaker speaker);

  /// Delete a speaker globally by its ID.
  Future<void> deleteSpeaker(String id);

  /// Link a speaker to a specific event.
  Future<void> addSpeakerToEvent(String eventId, String speakerId);

  /// Unlink a speaker from a specific event.
  Future<void> removeSpeakerFromEvent(String eventId, String speakerId);
}
