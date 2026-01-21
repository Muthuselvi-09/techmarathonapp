import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class EventRepository {
  /// Watch all events as a stream.
  Stream<List<CodingEvent>> watchEvents();

  /// Get a single event by its document ID.
  Future<CodingEvent?> getEventById(String id);

  /// Add a new event.
  Future<void> addEvent(CodingEvent event);

  /// Update an existing event.
  Future<void> updateEvent(CodingEvent event);

  /// Delete an event.
  Future<void> deleteEvent(String id);
}
