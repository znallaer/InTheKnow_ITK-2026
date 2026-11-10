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
      'phoneNumber': '+63${phoneNumber.trim()}',
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
}