import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/event_catalog.dart';
import '../models/event.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// All fixed events (soonest first) with a live registered count from
  /// Firestore. Events nobody has registered for yet simply count as 0.
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

  /// One event with its live count (so slots update instantly on screen).
  Stream<Event?> eventStream(String eventId) {
    final base = findEvent(eventId);
    if (base == null) return Stream.value(null);
    return _db.collection('events').doc(eventId).snapshots().map((doc) {
      final count = (doc.data()?['registeredCount'] as num?)?.toInt() ?? 0;
      return base.withRegisteredCount(count);
    });
  }

  /// True when the signed-in user already registered for this event.
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

  /// Live profile of the signed-in user (users/{uid}).
  Stream<Map<String, dynamic>?> userProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }

  /// All events registered by the signed-in user, including completed ones.
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

  /// Persists whether the user has marked a registered event as done.
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

  /// Registers the signed-in user for an event.
  /// A transaction reads the latest count first, so two students can never
  /// take the last slot at the same time (same idea as the stock check in
  /// the classroom guide).
  ///
  /// The optional values come from the 3-step registration form.
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
