import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/home/domain/event_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository());

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(XFile file, String path) async {
    final ref = _storage.ref().child(path);
    
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      final uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } else {
      final uploadTask = ref.putFile(File(file.path));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    }
  }

  Stream<List<CodingEvent>> watchEvents() {
    return _firestore.collection('events').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => CodingEvent.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> createEvent(CodingEvent event) async {
    await _firestore.collection('events').add(event.toMap());
  }

  Future<void> updateEvent(CodingEvent event) async {
    await _firestore.collection('events').doc(event.id).update(event.toMap());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }

  Stream<List<Participant>> watchEventMembers(String eventId) {
    // If eventId is 'all', watch all participants
    if (eventId == 'all') {
       return _firestore.collection('participants').snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => Participant.fromMap(doc.data(), doc.id))
            .toList();
      });
    }
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('participants')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Participant.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<int> watchTotalMemberCount() {
    return _firestore.collection('participants').snapshots().map((snapshot) => snapshot.size);
  }

  // --- SPEAKERS ---
  Stream<List<Speaker>> watchSpeakers() {
    return _firestore.collection('speakers').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Speaker.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addSpeaker(Speaker speaker) async {
    await _firestore.collection('speakers').add(speaker.toMap());
  }

  Future<void> updateSpeaker(Speaker speaker) async {
    await _firestore.collection('speakers').doc(speaker.id).update(speaker.toMap());
  }

  Future<void> deleteSpeaker(String speakerId) async {
    await _firestore.collection('speakers').doc(speakerId).delete();
  }

  // --- SPONSORS ---
  Stream<List<Sponsor>> watchSponsors() {
    return _firestore.collection('sponsors').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Sponsor.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> addSponsor(Sponsor sponsor) async {
    await _firestore.collection('sponsors').add(sponsor.toMap());
  }

  Future<void> deleteSponsor(String sponsorId) async {
    await _firestore.collection('sponsors').doc(sponsorId).delete();
  }

  Future<void> updateSponsor(Sponsor sponsor) async {
    await _firestore.collection('sponsors').doc(sponsor.id).update(sponsor.toMap());
  }

  // ========================================
  // OPTIMISTIC SAVE METHODS (Background Sync)
  // ========================================

  /// Save event optimistically - returns immediately, syncs in background
  void saveEventOptimistically(CodingEvent event, XFile? imageFile, {bool isNew = true}) {
    // Background execution - does not block UI
    Future.microtask(() async {
      try {
        String finalImageUrl = event.imageUrl;
        
        // Upload image if provided
        if (imageFile != null) {
          final path = 'events/${DateTime.now().millisecondsSinceEpoch}.jpg';
          finalImageUrl = await uploadImage(imageFile, path);
        }

        // Create updated event with final image URL
        final finalEvent = CodingEvent(
          id: event.id,
          name: event.name,
          location: event.location,
          category: event.category,
          description: event.description,
          date: event.date,
          speakerIds: event.speakerIds,
          imageUrl: finalImageUrl,
        );

        // Save to Firestore
        if (isNew) {
          await createEvent(finalEvent);
        } else {
          await updateEvent(finalEvent);
        }
      } catch (e) {
        // Silent error handling - could add retry logic or toast notification
        debugPrint('Background event save error: $e');
      }
    });
  }

  /// Save speaker optimistically - returns immediately, syncs in background
  void saveSpeakerOptimistically(Speaker speaker, XFile? imageFile, {bool isNew = true}) {
    Future.microtask(() async {
      try {
        String finalPhotoUrl = speaker.photoUrl;
        
        if (imageFile != null) {
          final path = 'speakers/${DateTime.now().millisecondsSinceEpoch}.jpg';
          finalPhotoUrl = await uploadImage(imageFile, path);
        }

        final finalSpeaker = Speaker(
          id: speaker.id,
          name: speaker.name,
          topic: speaker.topic,
          company: speaker.company,
          photoUrl: finalPhotoUrl,
          bio: speaker.bio,
        );

        if (isNew) {
          await addSpeaker(finalSpeaker);
        } else {
          await updateSpeaker(finalSpeaker);
        }
      } catch (e) {
        debugPrint('Background speaker save error: $e');
      }
    });
  }

  /// Save sponsor optimistically - returns immediately, syncs in background
  void saveSponsorOptimistically(Sponsor sponsor, XFile? imageFile, {bool isNew = true}) {
    Future.microtask(() async {
      try {
        String finalLogoUrl = sponsor.logoUrl;
        
        if (imageFile != null) {
          final path = 'sponsors/${DateTime.now().millisecondsSinceEpoch}.jpg';
          finalLogoUrl = await uploadImage(imageFile, path);
        }

        final finalSponsor = Sponsor(
          id: sponsor.id,
          name: sponsor.name,
          company: sponsor.company,
          jobPosition: sponsor.jobPosition,
          logoUrl: finalLogoUrl,
        );

        if (isNew) {
          await addSponsor(finalSponsor);
        } else {
          await updateSponsor(finalSponsor);
        }
      } catch (e) {
        debugPrint('Background sponsor save error: $e');
      }
    });
  }
}
