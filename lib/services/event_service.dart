import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/event_catalog.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  Stream<List<Event>> upcomingEvents() {
    return _db.collection('events').snapshots().map((snap) {
      final counts = <String, int>{
        for (final doc in snap.docs)
          doc.id: (doc.data()['registeredCount'] as num?)?.toInt() ?? 0,
      };
      final events = kEventCatalog
          .map((e) => e.withRegisteredCount(counts[e.id] ?? 0))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      return events;
    });
  }


  Stream<Event?> eventStream(String eventId) {
    final base = findEvent(eventId);
    if (base == null) return Stream.value(null);
    return _db.collection('events').doc(eventId).snapshots().map((doc) {
      final count = (doc.data()?['registeredCount'] as num?)?.toInt() ?? 0;
      return base.withRegisteredCount(count);
    });
  }


  Stream<bool> isRegistered(String eventId) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _db
        .collection('events')
        .doc(eventId)
        .collection('registrations')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists);
  }


  Stream<Map<String, dynamic>?> userProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }


  Stream<List<Map<String, dynamic>>> registeredEvents() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);

    return _db
        .collection('users')
        .doc(uid)
        .collection('registeredEvents')
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return <String, dynamic>{
                'eventId': doc.id,
                ...doc.data(),
              };
            }).toList());
  }


  Future<void> setRegisteredEventDone(String eventId, bool done) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Please log in first.');

    await _db
        .collection('users')
        .doc(uid)
        .collection('registeredEvents')
        .doc(eventId)
        .set({'done': done}, SetOptions(merge: true));
  }

  Future<void> removeRegisteredEvent(String eventId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final eventRef = _db.collection('events').doc(eventId);
    final regRef = eventRef.collection('registrations').doc(uid);
    final userRegRef = _db
        .collection('users')
        .doc(uid)
        .collection('registeredEvents')
        .doc(eventId);

    try {
      await _db.runTransaction((tx) async {
        final eventSnap = await tx.get(eventRef);
        if (eventSnap.exists) {
          final count = (eventSnap.data()?['registeredCount'] as num?)?.toInt() ?? 0;
          if (count > 0) {
            tx.update(eventRef, {'registeredCount': count - 1});
          }
        }
        tx.delete(regRef);
        tx.delete(userRegRef);
      });
    } catch (_) {
      try {
        await userRegRef.delete();
      } catch (_) {}
      try {
        await regRef.delete();
      } catch (_) {}
    }
  }


  Future<void> registerForEvent(
      String eventId, {
        String? name,
        String? department,
        String? attendanceType,
        DateTime? attendanceAt,
      }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in first.');

    final event = findEvent(eventId);
    if (event == null) throw Exception('This event no longer exists.');

    final eventRef = _db.collection('events').doc(eventId);
    final regRef = eventRef.collection('registrations').doc(user.uid);
    final userRegRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('registeredEvents')
        .doc(eventId);

    final profile = await _db.collection('users').doc(user.uid).get();
    final profileName = profile.data()?['name']?.toString() ?? '';
    final finalName =
    (name != null && name.trim().isNotEmpty) ? name.trim() : profileName;

    await _db.runTransaction((tx) async {
      final regSnap = await tx.get(regRef);
      if (regSnap.exists) throw Exception('You are already registered.');

      final eventSnap = await tx.get(eventRef);
      final count = eventSnap.exists
          ? (eventSnap.data()?['registeredCount'] as num?)?.toInt() ?? 0
          : 0;
      if (count >= event.totalSlots) {
        throw Exception('Sorry, this event is fully booked.');
      }

      if (eventSnap.exists) {
        tx.update(eventRef, {'registeredCount': count + 1});
      } else {
        tx.set(eventRef, {
          'registeredCount': 1,
          'totalSlots': event.totalSlots,
          'title': event.title,
        });
      }

      final attendance = <String, dynamic>{
        if (department != null) 'department': department,
        if (attendanceType != null) 'attendanceType': attendanceType,
        if (attendanceAt != null)
          'attendanceAt': Timestamp.fromDate(attendanceAt),
      };

      tx.set(regRef, {
        'uid': user.uid,
        'name': finalName,
        'email': user.email ?? '',
        ...attendance,
        'registeredAt': FieldValue.serverTimestamp(),
      });

      tx.set(userRegRef, {
        'eventId': eventId,
        'title': event.title,
        'category': event.category,
        'location': event.location,
        'date': Timestamp.fromDate(event.date),
        ...attendance,
        'done': false,
        'registeredAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
