import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class SponsorRepository {
  /// Watch sponsors for a specific event as a stream.
  Stream<List<Sponsor>> watchSponsors(String eventId);

  /// Watch ALL sponsors across all events.
  Stream<List<Sponsor>> watchAllSponsors();

  /// Get a single sponsor by its document ID.
  Future<Sponsor?> getSponsorById(String id);

  /// Add a new sponsor.
  Future<void> addSponsor(Sponsor sponsor);

  /// Update an existing sponsor.
  Future<void> updateSponsor(Sponsor sponsor);

  /// Delete a sponsor globally (not just from an event).
  Future<void> deleteSponsor(String id);

  /// Link an existing sponsor to an event.
  Future<void> addSponsorToEvent(String eventId, String sponsorId);

  /// Unlink a sponsor from an event.
  Future<void> removeSponsorFromEvent(String eventId, String sponsorId);
}
