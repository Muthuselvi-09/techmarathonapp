import 'package:tech_marathon_app/data/datasources/event_datasource.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/domain/repositories/event_repository.dart';

class EventRepositoryImpl implements EventRepository {
  final EventDataSource _dataSource;

  EventRepositoryImpl(this._dataSource);

  @override
  Stream<List<CodingEvent>> watchEvents() => _dataSource.watchEvents();

  @override
  Future<CodingEvent?> getEventById(String id) => _dataSource.getEventById(id);

  @override
  Future<void> addEvent(CodingEvent event) => _dataSource.addEvent(event);

  @override
  Future<void> updateEvent(CodingEvent event) => _dataSource.updateEvent(event);

  @override
  Future<void> deleteEvent(String id) => _dataSource.deleteEvent(id);
}
