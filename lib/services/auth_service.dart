import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String name,
    required String role,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final creds = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await _firestore.collection('users').doc(creds.user!.uid).set({
      'name': name.trim(),
      'role': role.trim(),
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return creds;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<void> updateProfile({
    required String name,
    required String role,
    required String phoneNumber,
    required String email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in first.');

    final cleanEmail = email.trim();
    if (cleanEmail.toLowerCase() != (user.email ?? '').toLowerCase()) {
      try {
        await user
            .verifyBeforeUpdateEmail(cleanEmail)
            .timeout(const Duration(seconds: 60));
      } on TimeoutException {
        throw Exception(
          'Email update timed out. Check your connection and try again.',
        );
      }
    }

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'role': role.trim(),
        'phoneNumber': phoneNumber.trim(),
        'email': cleanEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw Exception(
        'Profile update timed out. Check your connection and try again.',
      );
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Please log in first.');

    final uid = user.uid;
    try {
      final regSnap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('registeredEvents')
          .get();
      for (final doc in regSnap.docs) {
        await doc.reference.delete();
      }
    } catch (_) {}

    await _firestore.collection('users').doc(uid).delete();
    await user.delete();
  }
}
