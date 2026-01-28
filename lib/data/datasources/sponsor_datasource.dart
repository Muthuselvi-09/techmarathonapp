import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class SponsorDataSource {
  Stream<List<Sponsor>> watchSponsors(String eventId);
  Stream<List<Sponsor>> watchAllSponsors();
  Future<Sponsor?> getSponsorById(String id);
  Future<void> addSponsor(Sponsor sponsor);
  Future<void> updateSponsor(Sponsor sponsor);
  Future<void> deleteSponsor(String id);
  Future<void> addSponsorToEvent(String eventId, String sponsorId);
  Future<void> removeSponsorFromEvent(String eventId, String sponsorId);
}

class SponsorDataSourceImpl implements SponsorDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Sponsor>> watchSponsors(String eventId) {
    return _firestore
        .collection('event_sponsor_links')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .asyncMap((snapshot) async {
      final sponsorIds = snapshot.docs
          .map((doc) => doc.data()['sponsorId'] as String)
          .toList();

      if (sponsorIds.isEmpty) {
        return [];
      }

      List<Sponsor> sponsors = [];
      
      // Batching for whereIn limit (10)
      for (var i = 0; i < sponsorIds.length; i += 10) {
        var end = (i + 10 < sponsorIds.length) ? i + 10 : sponsorIds.length;
        var chunk = sponsorIds.sublist(i, end);
        
        final chunkSnapshot = await _firestore
            .collection('sponsors')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        sponsors.addAll(chunkSnapshot.docs
            .map((doc) => Sponsor.fromMap(doc.data(), doc.id))
            .where((s) => s.isActive)
            .toList());
      }
      return sponsors;
    });
  }

  @override
  Stream<List<Sponsor>> watchAllSponsors() {
    return _firestore
        .collection('sponsors')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final sponsors = snapshot.docs
          .map((doc) => Sponsor.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort in memory to avoid Firestore index requirement
      sponsors.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return sponsors;
    });
  }

  @override
  Future<Sponsor?> getSponsorById(String id) async {
    final doc = await _firestore.collection('sponsors').doc(id).get();
    if (!doc.exists) return null;
    return Sponsor.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> addSponsor(Sponsor sponsor) async {
    String docId = sponsor.id;
    if (docId.isEmpty) {
        docId = _firestore.collection('sponsors').doc().id;
    }

    await _firestore
      .collection('sponsors')
      .doc(docId)
      .set(sponsor.toMap());
  }

  @override
  Future<void> updateSponsor(Sponsor sponsor) async {
    await _firestore
        .collection('sponsors')
        .doc(sponsor.id)
        .update(sponsor.toMap());
  }

  @override
  Future<void> deleteSponsor(String id) async {
    await _firestore
        .collection('sponsors')
        .doc(id)
        .update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addSponsorToEvent(String eventId, String sponsorId) async {
    final existing = await _firestore
        .collection('event_sponsor_links')
        .where('eventId', isEqualTo: eventId)
        .where('sponsorId', isEqualTo: sponsorId)
        .get();

    if (existing.docs.isNotEmpty) return;

    await _firestore.collection('event_sponsor_links').add({
      'eventId': eventId,
      'sponsorId': sponsorId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeSponsorFromEvent(String eventId, String sponsorId) async {
    final snapshot = await _firestore
        .collection('event_sponsor_links')
        .where('eventId', isEqualTo: eventId)
        .where('sponsorId', isEqualTo: sponsorId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
