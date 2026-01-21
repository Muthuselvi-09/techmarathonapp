import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class SponsorRepository {
  /// Watch sponsors for a specific event as a stream.
  Stream<List<Sponsor>> watchSponsors(String eventId);

  /// Get a single sponsor by its document ID.
  Future<Sponsor?> getSponsorById(String id);

  /// Add a new sponsor.
  Future<void> addSponsor(Sponsor sponsor);

  /// Update an existing sponsor.
  Future<void> updateSponsor(Sponsor sponsor);

  /// Delete a sponsor.
  Future<void> deleteSponsor(String eventId, String id);
}
