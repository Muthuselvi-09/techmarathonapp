import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/event_models.dart';
import 'package:firebase_auth/firebase_auth.dart';

final searchRepositoryProvider = Provider((ref) => SearchRepository(FirebaseFirestore.instance));

class SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepository(this._firestore);

  Stream<List<SearchResult>> searchAll(String query) {
    if (query.isEmpty) return Stream.value([]);
    
    final lowercaseQuery = query.toLowerCase();

    // Create streams for each collection
    final eventsStream = _firestore.collection('events')
        .where('searchName', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('searchName', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .snapshots()
        .map((s) => s.docs.map((doc) => SearchResult(
              id: doc.id,
              title: doc.data()['title'] ?? doc.data()['name'] ?? '',
              type: 'Event',
              data: doc.data(),
            )).toList());

    final speakersStream = _firestore.collection('speakers')
        .where('searchName', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('searchName', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .snapshots()
        .map((s) => s.docs.map((doc) => SearchResult(
              id: doc.id,
              title: doc.data()['name'] ?? '',
              type: 'Speaker',
              data: doc.data(),
            )).toList());

    final sponsorsStream = _firestore.collection('sponsors')
        .where('searchName', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('searchName', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .snapshots()
        .map((s) => s.docs.map((doc) => SearchResult(
              id: doc.id,
              title: doc.data()['name'] ?? '',
              type: 'Sponsor',
              data: doc.data(),
            )).toList());

    final membersStream = _firestore.collection('users')
        .where('searchName', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('searchName', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .snapshots()
        .map((s) => s.docs.map((doc) => SearchResult(
              id: doc.id,
              title: doc.data()['name'] ?? '',
              type: 'Member',
              data: doc.data(),
            )).toList());

    final schedulesStream = _firestore.collectionGroup('schedules')
        .where('searchName', isGreaterThanOrEqualTo: lowercaseQuery)
        .where('searchName', isLessThanOrEqualTo: '$lowercaseQuery\uf8ff')
        .snapshots()
        .map((s) => s.docs.map((doc) => SearchResult(
              id: doc.id,
              title: doc.data()['title'] ?? '',
              type: 'Schedule',
              data: doc.data(),
            )).toList());

    // Combine all streams
    return Stream.periodic(const Duration(milliseconds: 500)).asyncMap((_) async {
      final futures = await Future.wait([
        eventsStream.first,
        speakersStream.first,
        sponsorsStream.first,
        membersStream.first,
        schedulesStream.first,
      ]);
      return futures.expand((x) => x).toList();
    });
  }
}

class SearchResult {
  final String id;
  final String title;
  final String type;
  final Map<String, dynamic> data;

  SearchResult({
    required this.id,
    required this.title,
    required this.type,
    required this.data,
  });
}
