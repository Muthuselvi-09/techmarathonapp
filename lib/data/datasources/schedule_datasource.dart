import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tech_marathon_app/data/models/schedule.dart';

abstract class ScheduleDataSource {
  Stream<List<Schedule>> watchSchedules(String eventId);
  Future<Schedule?> getScheduleById(String id);
  Future<void> addSchedule(Schedule schedule);
  Future<void> updateSchedule(Schedule schedule);
  Future<void> deleteSchedule(String eventId, String id);
}

class ScheduleDataSourceImpl implements ScheduleDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Schedule>> watchSchedules(String eventId) {
    // Removed orderBy to avoid composite index requirement
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('schedules')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final schedules = snapshot.docs
          .map((doc) => Schedule.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory by startTime
      schedules.sort((a, b) => a.startTime.compareTo(b.startTime));
      return schedules;
    });
  }

  @override
  Future<Schedule?> getScheduleById(String id) async {
    final doc = await _firestore.collectionGroup('schedules').where(FieldPath.documentId, isEqualTo: id).limit(1).get();
    if (doc.docs.isEmpty) return null;
    return Schedule.fromMap(doc.docs.first.data(), doc.docs.first.id);
  }

  @override
  Future<void> addSchedule(Schedule schedule) async {
    final docRef = _firestore
        .collection('events')
        .doc(schedule.eventId)
        .collection('schedules')
        .doc(schedule.id.isEmpty ? null : schedule.id);
    
    await docRef.set(schedule.toMap());
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    await _firestore
        .collection('events')
        .doc(schedule.eventId)
        .collection('schedules')
        .doc(schedule.id)
        .update(schedule.toMap());
  }

  @override
  Future<void> deleteSchedule(String eventId, String id) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('schedules')
        .doc(id)
        .update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
