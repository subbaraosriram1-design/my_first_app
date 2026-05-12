import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseService._init();

  // Authentication
  Future<User?> registerUser(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint('Registration Error: $e');
      return null;
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint('Login Error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  // Firestore Resume Operations
  Future<void> saveResume(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('resumes').doc(userId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore Save Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getResume(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('resumes').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Firestore Get Error: $e');
      return null;
    }
  }
}
