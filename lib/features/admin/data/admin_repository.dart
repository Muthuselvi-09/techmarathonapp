import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/foundation.dart';
import 'package:tech_marathon_app/data/models/schedule.dart' as new_schedule;
import 'package:tech_marathon_app/core/providers.dart';

final adminRepositoryProvider = Provider((ref) => AdminRepository(ref));

class AdminRepository {
  final Ref ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminRepository(this.ref);

  // --- CLOUDINARY INTEGRATION ---
  final String _cloudName = 'dzn6tkc2v';
  final String _uploadPreset = 'event_upload';

  /// STRICT implementation for Cloudinary Upload
  Future<String> uploadToCloudinary(Uint8List data, {String folder = 'events'}) async {
    try {
      debugPrint('☁️ Uploading to Cloudinary (${(data.lengthInBytes/1024).toStringAsFixed(1)} KB) to folder "$folder"...');

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          data,
          filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));

      final response = await request.send().timeout(const Duration(seconds: 60));
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(responseData);
        final secureUrl = json['secure_url'] as String;
        debugPrint('✅ Cloudinary Success: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('❌ Cloudinary Error Body: $responseData');
        throw 'Cloudinary upload failed: ${response.statusCode} - $responseData';
      }
    } catch (e) {
      debugPrint('❌ Cloudinary Exception: $e');
      throw 'Upload failed: $e';
    }
  }

  // --- BRANDING METHODS ---

  Stream<BrandingInfo> watchBranding() {
    return _firestore
        .collection('branding')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return BrandingInfo(companyName: 'Event App');
      }
      return BrandingInfo.fromMap(snapshot.data()!);
    });
  }

  Future<void> saveBranding(BrandingInfo info) async {
    await _firestore
        .collection('branding')
        .doc('current')
        .set(info.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteBranding() async {
    await _firestore.collection('branding').doc('current').delete();
  }


  Stream<List<CodingEvent>> watchEvents() {
    return _firestore
        .collection('events')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CodingEvent.fromMap(doc.data(), doc.id))
          .where((e) => e.isActive) // Removed name/imageUrl empty checks to ensure it shows immediately
          .toList();
    });
  }

  // ========================================
  // SAVE METHODS (Synchronous & Fast)
  // ========================================

  /// Save event specifically (renamed from optimistically to reflect behavior)
  Future<void> saveEvent(CodingEvent event, {bool isNew = true}) async {
    try {
      final docId = event.id.isEmpty ? _firestore.collection('events').doc().id : event.id;
      
      final eventData = event.toMap();
      
      // Update with server timestamps
      eventData['updatedAt'] = FieldValue.serverTimestamp();
      if (isNew) {
        eventData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('events').doc(docId).set(eventData);
        debugPrint('✅ Event Saved: $docId');
      } else {
        await _firestore.collection('events').doc(docId).update(eventData);
        debugPrint('✅ Event Updated: $docId');
      }
    } catch (e) {
      debugPrint('❌ Event save failed: $e');
      rethrow;
    }
  }

  /// Save speaker with fast synchronous write
  Future<void> saveSpeaker(Speaker speaker, {bool isNew = true}) async {
    try {
      final String docId = speaker.id.isEmpty
          ? _firestore.collection('events').doc(speaker.eventId).collection('speakers').doc().id
          : speaker.id;

      final speakerData = speaker.toMap();
      if (isNew) {
         if (speaker.createdAt == null) {
           speakerData['createdAt'] = Timestamp.fromDate(DateTime.now());
         }
        await _firestore
            .collection('events')
            .doc(speaker.eventId)
            .collection('speakers')
            .doc(docId)
            .set(speakerData);
        debugPrint('✅ Speaker Saved: $docId');
      } else {
        await _firestore
            .collection('events')
            .doc(speaker.eventId)
            .collection('speakers')
            .doc(docId)
            .update(speakerData);
        debugPrint('✅ Speaker Updated: $docId');
      }
    } catch (e) {
      debugPrint('❌ Speaker save failed: $e');
      rethrow;
    }
  }

  /// Save sponsor with fast synchronous write
  Future<void> saveSponsor(Sponsor sponsor, {bool isNew = true}) async {
    try {
      final String docId = sponsor.id.isEmpty
          ? _firestore.collection('events').doc(sponsor.eventId).collection('sponsors').doc().id
          : sponsor.id;

      final sponsorData = sponsor.toMap();
      
      if (isNew) {
        await _firestore
            .collection('events')
            .doc(sponsor.eventId)
            .collection('sponsors')
            .doc(docId)
            .set(sponsorData);
        debugPrint('✅ Sponsor Saved: $docId');
      } else {
        await _firestore
            .collection('events')
            .doc(sponsor.eventId)
            .collection('sponsors')
            .doc(docId)
            .update(sponsorData);
        debugPrint('✅ Sponsor Updated: $docId');
      }
    } catch (e) {
      debugPrint('❌ Sponsor save failed: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  // --- REPLACED BY DOMAIN REPOSITORIES ---
  // Speaker, Sponsor, and Schedule methods removed to ensure single source of truth.

  /// Save schedule optimistically
  /// Save schedule synchronously
  Future<void> saveSchedule(new_schedule.Schedule schedule, {bool isNew = true}) async {
    try {
      final repo = ref.read(scheduleRepositoryProvider);
      if (isNew) {
        await repo.addSchedule(schedule);
      } else {
        await repo.updateSchedule(schedule);
      }
    } catch (e) {
      debugPrint('Schedule save error: $e');
      rethrow;
    }
  }

  // ========================================
  // FAST SAVE METHODS (Optimized for Speed)
  // ========================================




}
