import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';

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
  
  // For manual login bypass (dev only)
  String? _manualUserId;
  void setManualUser(String userId) => _manualUserId = userId;
  String? get currentUserId => _manualUserId ?? _auth.currentUser?.uid;

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

  Future<Map<String, dynamic>?> getResumeByEmail(String email) async {
    try {
      final query = await _firestore.collection('resumes').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data();
      }
      return null;
    } catch (e) {
      debugPrint('Firestore GetByEmail Error: $e');
      return null;
    }
  }

  Future<bool> updatePasswordByEmail(String email, String newPassword) async {
    try {
      final query = await _firestore.collection('resumes').where('email', isEqualTo: email).limit(1).get();
      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({'password': newPassword});
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Firestore UpdatePassword Error: $e');
      return false;
    }
  }

  // Fetch API Keys for AI Services
  Future<String?> getGrokApiKey() async {
    try {
      DocumentSnapshot doc = await _firestore.collection(ApiConfig.configCollection).doc(ApiConfig.apiKeysDocument).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data[ApiConfig.grokKeyField] as String?;
      }
      debugPrint('Firestore: ${ApiConfig.configCollection}/${ApiConfig.apiKeysDocument} document does not exist');
      return null;
    } catch (e) {
      debugPrint('Firestore GetApiKey Error: $e');
      return null;
    }
  }
}
