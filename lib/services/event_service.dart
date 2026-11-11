import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/event.dart';

class EventService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Event>> upcomingEvents() {
    return _db.collection('events').orderBy('date').snapshots().map((snap) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      return snap.docs
          .map(Event.fromDoc)
          .where((e) => !e.date.isBefore(startOfToday))
          .toList();
    });
  }

  Stream<Event?> eventStream(String eventId) {
    return _db
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? Event.fromDoc(doc) : null);
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

  Future<void> registerForEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in first.');

    final eventRef = _db.collection('events').doc(eventId);
    final regRef = eventRef.collection('registrations').doc(user.uid);
    final userRegRef = _db
        .collection('users')
        .doc(user.uid)
        .collection('registeredEvents')
        .doc(eventId);

    final profile = await _db.collection('users').doc(user.uid).get();
    final name = profile.data()?['name']?.toString() ?? '';

    await _db.runTransaction((tx) async {
      final eventSnap = await tx.get(eventRef);
      if (!eventSnap.exists) throw Exception('This event no longer exists.');

      final regSnap = await tx.get(regRef);
      if (regSnap.exists) throw Exception('You are already registered.');

      final data = eventSnap.data()!;
      final total = (data['totalSlots'] as num?)?.toInt() ?? 0;
      final count = (data['registeredCount'] as num?)?.toInt() ?? 0;
      if (count >= total) throw Exception('Sorry, this event is fully booked.');

      tx.update(eventRef, {'registeredCount': count + 1});

      tx.set(regRef, {
        'uid': user.uid,
        'name': name,
        'email': user.email ?? '',
        'registeredAt': FieldValue.serverTimestamp(),
      });

      tx.set(userRegRef, {
        'eventId': eventId,
        'title': data['title'],
        'category': data['category'],
        'location': data['location'],
        'date': data['date'],
        'registeredAt': FieldValue.serverTimestamp(),
      });
    });
  }
}