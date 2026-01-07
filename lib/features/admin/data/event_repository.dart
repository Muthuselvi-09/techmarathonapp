import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../home/domain/event_models.dart';

class EventRepository {
  final FirebaseFirestore _firestore;

  EventRepository(this._firestore);

  Stream<List<CodingEvent>> getEventsStream() {
    return _firestore
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CodingEvent.fromFirestore(doc))
            .toList());
  }

  Future<void> createEvent(CodingEvent event) async {
    await _firestore.collection('events').add(event.toFirestore());
  }

  Future<void> updateEvent(CodingEvent event) async {
    await _firestore.collection('events').doc(event.id).update(event.toFirestore());
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(FirebaseFirestore.instance);
});

final eventsStreamProvider = StreamProvider<List<CodingEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).getEventsStream();
});
