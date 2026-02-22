import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BatchProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DocumentSnapshot> _userBatches = [];
  bool _isLoading = false;

  List<DocumentSnapshot> get userBatches => _userBatches;
  bool get isLoading => _isLoading;

  Future<void> loadUserBatches() async {
    _isLoading = true;
    notifyListeners();

    try {
      String uid = _auth.currentUser!.uid;

      // Get batches where user is a student
      var snapshot = await _firestore
          .collection('batches')
          .where('students', arrayContains: uid)
          .get();

      _userBatches = snapshot.docs;
    } catch (e) {
      print('Error loading batches: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<QueryDocumentSnapshot>> getLectures(String batchId) async {
    try {
      var snapshot = await _firestore
          .collection('batches')
          .doc(batchId)
          .collection('lectures')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs;
    } catch (e) {
      print('Error loading lectures: $e');
      return [];
    }
  }

  Stream<QuerySnapshot> getLiveLectures(String batchId) {
    return _firestore
        .collection('batches')
        .doc(batchId)
        .collection('lectures')
        .where('isLive', isEqualTo: true)
        .snapshots();
  }
}
