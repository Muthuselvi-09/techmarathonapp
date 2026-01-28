import 'package:tech_marathon_app/data/datasources/speaker_datasource.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/domain/repositories/speaker_repository.dart';

class SpeakerRepositoryImpl implements SpeakerRepository {
  final SpeakerDataSource _dataSource;

  SpeakerRepositoryImpl(this._dataSource);

  @override
  Stream<List<Speaker>> watchSpeakers(String eventId) => _dataSource.watchSpeakers(eventId);

  @override
  Stream<List<Speaker>> watchAllSpeakers() => _dataSource.watchAllSpeakers();

  @override
  Future<Speaker?> getSpeakerById(String id) => _dataSource.getSpeakerById(id);

  @override
  Future<void> addSpeaker(Speaker speaker) => _dataSource.addSpeaker(speaker);

  @override
  Future<void> updateSpeaker(Speaker speaker) => _dataSource.updateSpeaker(speaker);

  @override
  Future<void> deleteSpeaker(String id) => _dataSource.deleteSpeaker(id);

  @override
  Future<void> addSpeakerToEvent(String eventId, String speakerId) => _dataSource.addSpeakerToEvent(eventId, speakerId);

  @override
  Future<void> removeSpeakerFromEvent(String eventId, String speakerId) => _dataSource.removeSpeakerFromEvent(eventId, speakerId);
}
