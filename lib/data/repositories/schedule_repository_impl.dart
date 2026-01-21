import 'package:tech_marathon_app/data/datasources/schedule_datasource.dart';
import 'package:tech_marathon_app/data/models/schedule.dart';
import 'package:tech_marathon_app/domain/repositories/schedule_repository.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleDataSource _dataSource;

  ScheduleRepositoryImpl(this._dataSource);

  @override
  Stream<List<Schedule>> watchSchedules(String eventId) => _dataSource.watchSchedules(eventId);

  @override
  Future<Schedule?> getScheduleById(String id) => _dataSource.getScheduleById(id);

  @override
  Future<void> addSchedule(Schedule schedule) => _dataSource.addSchedule(schedule);

  @override
  Future<void> updateSchedule(Schedule schedule) => _dataSource.updateSchedule(schedule);

  @override
  Future<void> deleteSchedule(String eventId, String id) => _dataSource.deleteSchedule(eventId, id);
}
