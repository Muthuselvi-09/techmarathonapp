import 'package:tech_marathon_app/data/datasources/speaker_datasource.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/domain/repositories/speaker_repository.dart';

class SpeakerRepositoryImpl implements SpeakerRepository {
  final SpeakerDataSource _dataSource;

  SpeakerRepositoryImpl(this._dataSource);

  @override
  Stream<List<Speaker>> watchSpeakers(String eventId) => _dataSource.watchSpeakers(eventId);

  @override
  Future<Speaker?> getSpeakerById(String id) => _dataSource.getSpeakerById(id);

  @override
  Future<void> addSpeaker(Speaker speaker) => _dataSource.addSpeaker(speaker);

  @override
  Future<void> updateSpeaker(Speaker speaker) => _dataSource.updateSpeaker(speaker);

  @override
  Future<void> deleteSpeaker(String eventId, String id) => _dataSource.deleteSpeaker(eventId, id);
}
