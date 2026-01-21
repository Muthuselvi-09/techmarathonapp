import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class SponsorDataSource {
  Stream<List<Sponsor>> watchSponsors(String eventId);
  Future<Sponsor?> getSponsorById(String id);
  Future<void> addSponsor(Sponsor sponsor);
  Future<void> updateSponsor(Sponsor sponsor);
  Future<void> deleteSponsor(String eventId, String id);
}

class SponsorDataSourceImpl implements SponsorDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Sponsor>> watchSponsors(String eventId) {
    // Removed orderBy to avoid composite index requirement
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('sponsors')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final sponsors = snapshot.docs
          .map((doc) => Sponsor.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory by createdAt if needed
      sponsors.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return sponsors;
    });
  }

  @override
  Future<Sponsor?> getSponsorById(String id) async {
    final doc = await _firestore.collectionGroup('sponsors').where(FieldPath.documentId, isEqualTo: id).get();
    if (doc.docs.isEmpty) return null;
    return Sponsor.fromMap(doc.docs.first.data(), doc.docs.first.id);
  }

  @override
  Future<void> addSponsor(Sponsor sponsor) async {
    String docId = sponsor.id;
    if (docId.isEmpty) {
        docId = _firestore.collection('events').doc(sponsor.eventId).collection('sponsors').doc().id;
    }

    await _firestore
      .collection('events')
      .doc(sponsor.eventId)
      .collection('sponsors')
      .doc(docId)
      .set(sponsor.toMap());
  }

  @override
  Future<void> updateSponsor(Sponsor sponsor) async {
    await _firestore
        .collection('events')
        .doc(sponsor.eventId)
        .collection('sponsors')
        .doc(sponsor.id)
        .update(sponsor.toMap());
  }

  @override
  Future<void> deleteSponsor(String eventId, String id) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('sponsors')
        .doc(id)
        .update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
