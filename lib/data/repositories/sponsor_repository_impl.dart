import 'package:tech_marathon_app/data/datasources/sponsor_datasource.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/domain/repositories/sponsor_repository.dart';

class SponsorRepositoryImpl implements SponsorRepository {
  final SponsorDataSource _dataSource;

  SponsorRepositoryImpl(this._dataSource);

  @override
  Stream<List<Sponsor>> watchSponsors(String eventId) => _dataSource.watchSponsors(eventId);

  @override
  Future<Sponsor?> getSponsorById(String id) => _dataSource.getSponsorById(id);

  @override
  Future<void> addSponsor(Sponsor sponsor) => _dataSource.addSponsor(sponsor);

  @override
  Future<void> updateSponsor(Sponsor sponsor) => _dataSource.updateSponsor(sponsor);

  @override
  Future<void> deleteSponsor(String eventId, String id) => _dataSource.deleteSponsor(eventId, id);
}
