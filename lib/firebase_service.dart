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
      debugPrint('Saving resume for user: $userId');
      await _firestore.collection('resumes').doc(userId).set(data, SetOptions(merge: true));
      debugPrint('Resume saved successfully');
    } catch (e) {
      debugPrint('Firestore Save Error: $e');
      if (e.toString().contains('permission-denied')) {
        debugPrint('CHECK YOUR FIRESTORE RULES: Security rules might be blocking this write.');
      }
    }
  }

  Future<Map<String, dynamic>?> getResume(String userId) async {
    try {
      debugPrint('Fetching resume for user: $userId');
      DocumentSnapshot doc = await _firestore.collection('resumes').doc(userId).get();
      if (doc.exists) {
        debugPrint('Resume found');
        return doc.data() as Map<String, dynamic>;
      }
      debugPrint('No resume found for user: $userId');
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

  // Skill Resources Caching
  Future<void> saveSkillResources(String skill, Map<String, dynamic> resources) async {
    try {
      await _firestore.collection('skill_resources').doc(skill.toLowerCase()).set({
        'resources': resources,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore SaveSkillResources Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getSkillResources(String skill) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('skill_resources').doc(skill.toLowerCase()).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['resources'];
      }
      return null;
    } catch (e) {
      debugPrint('Firestore GetSkillResources Error: $e');
      return null;
    }
  }

  // Personal Roadmaps
  Future<void> savePersonalRoadmap(String userId, Map<String, dynamic> roadmap) async {
    try {
      final docRef = _firestore.collection('resumes').doc(userId);
      final doc = await docRef.get();
      Map<String, dynamic> personalRoadmaps = {};
      if (doc.exists) {
        personalRoadmaps = Map<String, dynamic>.from(doc.data()?['personalRoadmaps'] ?? {});
      }
      
      final String id = roadmap['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      roadmap['id'] = id;
      personalRoadmaps[id] = roadmap;
      
      await docRef.update({'personalRoadmaps': personalRoadmaps});
    } catch (e) {
      debugPrint('Firestore SavePersonalRoadmap Error: $e');
    }
  }

  Future<void> deletePersonalRoadmap(String userId, String roadmapId) async {
    try {
      final docRef = _firestore.collection('resumes').doc(userId);
      final doc = await docRef.get();
      if (doc.exists) {
        Map<String, dynamic> personalRoadmaps = Map<String, dynamic>.from(doc.data()?['personalRoadmaps'] ?? {});
        personalRoadmaps.remove(roadmapId);
        await docRef.update({'personalRoadmaps': personalRoadmaps});
      }
    } catch (e) {
      debugPrint('Firestore DeletePersonalRoadmap Error: $e');
    }
  }

  // Saved Colleges
  Future<void> saveCollege(String userId, Map<String, dynamic> college) async {
    try {
      final docRef = _firestore.collection('resumes').doc(userId);
      final doc = await docRef.get();
      List<dynamic> savedColleges = [];
      if (doc.exists) {
        savedColleges = List<dynamic>.from(doc.data()?['savedColleges'] ?? []);
      }
      
      // Prevent duplicates by name
      savedColleges.removeWhere((c) => c['name'] == college['name']);
      savedColleges.add(college);
      
      await docRef.update({'savedColleges': savedColleges});
    } catch (e) {
      debugPrint('Firestore SaveCollege Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSavedColleges(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('resumes').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['savedColleges'] ?? []);
      }
      return [];
    } catch (e) {
      debugPrint('Firestore GetSavedColleges Error: $e');
      return [];
    }
  }

  Future<void> removeSavedCollege(String userId, String collegeName) async {
    try {
      final docRef = _firestore.collection('resumes').doc(userId);
      final doc = await docRef.get();
      if (doc.exists) {
        List<dynamic> savedColleges = List<dynamic>.from(doc.data()?['savedColleges'] ?? []);
        savedColleges.removeWhere((c) => c['name'] == collegeName);
        await docRef.update({'savedColleges': savedColleges});
      }
    } catch (e) {
      debugPrint('Firestore RemoveSavedCollege Error: $e');
    }
  }

  // Save/Get College Preferences
  Future<void> saveCollegePreferences(String userId, Map<String, dynamic> prefs) async {
    try {
      await _firestore.collection('resumes').doc(userId).update({'collegePreferences': prefs});
    } catch (e) {
      debugPrint('Firestore SaveCollegePreferences Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getCollegePreferences(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('resumes').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['collegePreferences'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Firestore GetCollegePreferences Error: $e');
      return null;
    }
  }

  // Add/Update specific roadmap action for a college
  Future<void> updateCollegeRoadmapAction(String userId, String collegeName, String actionTitle, bool isAdded, {bool isCompleted = false, Map<String, dynamic>? actionData}) async {
    try {
      final docRef = _firestore.collection('resumes').doc(userId);
      final doc = await docRef.get();
      if (doc.exists) {
        List<dynamic> savedColleges = List<dynamic>.from(doc.data()?['savedColleges'] ?? []);
        int index = savedColleges.indexWhere((c) => c['name'] == collegeName);
        if (index != -1) {
          Map<String, dynamic> college = Map<String, dynamic>.from(savedColleges[index]);
          Map<String, dynamic> roadmapActions = Map<String, dynamic>.from(college['roadmapActions'] ?? {});
          
          if (isAdded) {
            roadmapActions[actionTitle] = {
              'title': actionTitle,
              'isCompleted': isCompleted,
              'addedAt': DateTime.now().toIso8601String(),
              ...?actionData,
            };
          } else {
            roadmapActions.remove(actionTitle);
          }
          
          college['roadmapActions'] = roadmapActions;
          savedColleges[index] = college;
          await docRef.update({'savedColleges': savedColleges});
        }
      }
    } catch (e) {
      debugPrint('Firestore UpdateCollegeRoadmapAction Error: $e');
    }
  }

  // Connectivity Check
  Future<bool> checkConnection() async {
    try {
      debugPrint('Checking Firestore connectivity...');
      // Try a lightweight operation
      await _firestore.collection('config').limit(1).get(const GetOptions(source: Source.server));
      debugPrint('Firestore connection verified');
      return true;
    } catch (e) {
      debugPrint('Firestore Connection Check Failed: $e');
      return false;
    }
  }
}
