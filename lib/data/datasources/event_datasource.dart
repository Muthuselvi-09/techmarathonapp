import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class EventDataSource {
  Stream<List<CodingEvent>> watchEvents();
  Future<CodingEvent?> getEventById(String id);
  Future<void> addEvent(CodingEvent event);
  Future<void> updateEvent(CodingEvent event);
  Future<void> deleteEvent(String id);
}

class EventDataSourceImpl implements EventDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // NOTE: Hive caching for CodingEvent temporarily disabled until adapter is generated or verified.
  // Using simplified in-memory stream for now + Firestore.
  // final Box<CodingEvent> _hiveBox = Hive.box<CodingEvent>('eventsBox'); 

  @override
  Stream<List<CodingEvent>> watchEvents() {
    // Removed orderBy to avoid composite index requirement
    return _firestore
        .collection('events')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final events = snapshot.docs
          .map((doc) => CodingEvent.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory by createdAt
      events.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return events;
    });
  }

  @override
  Future<CodingEvent?> getEventById(String id) async {
    final doc = await _firestore.collection('events').doc(id).get();
    if (!doc.exists) return null;
    return CodingEvent.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> addEvent(CodingEvent event) async {
    // Ensure document ID is set if absent, though specific logic may vary
    final docRef = event.id.isEmpty 
        ? _firestore.collection('events').doc() 
        : _firestore.collection('events').doc(event.id);
        
    await docRef.set(event.toMap());
  }

  @override
  Future<void> updateEvent(CodingEvent event) async {
    await _firestore.collection('events').doc(event.id).update(event.toMap());
  }

  @override
  Future<void> deleteEvent(String id) async {
    await _firestore.collection('events').doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
