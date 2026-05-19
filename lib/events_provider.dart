import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class EventsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _savedEvents = [];
  List<Map<String, dynamic>> _joinedEvents = [];

  List<Map<String, dynamic>> get savedEvents => _savedEvents;
  List<Map<String, dynamic>> get joinedEvents => _joinedEvents;

  Future<void> loadEvents() async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    final doc = await FirebaseFirestore.instance.collection('user_events').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      _savedEvents = List<Map<String, dynamic>>.from(data['saved'] ?? []);
      _joinedEvents = List<Map<String, dynamic>>.from(data['joined'] ?? []);
      notifyListeners();
    }
  }

  Future<void> saveEvent(Map<String, dynamic> event) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    if (!_savedEvents.any((e) => e['name'] == event['name'])) {
      _savedEvents.add(event);
      await _updateFirestore(userId);
      notifyListeners();
    }
  }

  Future<void> joinEvent(Map<String, dynamic> event) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    if (!_joinedEvents.any((e) => e['name'] == event['name'])) {
      _joinedEvents.add(event);
      await _updateFirestore(userId);
      notifyListeners();
    }
  }

  Future<void> removeSavedEvent(String eventName) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    _savedEvents.removeWhere((e) => e['name'] == eventName);
    await _updateFirestore(userId);
    notifyListeners();
  }

  Future<void> removeJoinedEvent(String eventName) async {
    final userId = FirebaseService.instance.currentUserId;
    if (userId == null) return;

    _joinedEvents.removeWhere((e) => e['name'] == eventName);
    await _updateFirestore(userId);
    notifyListeners();
  }

  Future<void> _updateFirestore(String userId) async {
    await FirebaseFirestore.instance.collection('user_events').doc(userId).set({
      'saved': _savedEvents,
      'joined': _joinedEvents,
    }, SetOptions(merge: true));
  }
}
