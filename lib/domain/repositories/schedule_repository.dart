import 'package:tech_marathon_app/data/models/schedule.dart';

abstract class ScheduleRepository {
  /// Watch schedules for a specific event as a stream.
  Stream<List<Schedule>> watchSchedules(String eventId);

  /// Get a single schedule by its document ID.
  Future<Schedule?> getScheduleById(String id);

  /// Add a new schedule.
  Future<void> addSchedule(Schedule schedule);

  /// Update an existing schedule.
  Future<void> updateSchedule(Schedule schedule);

  /// Delete a schedule.
  Future<void> deleteSchedule(String eventId, String id);
}
