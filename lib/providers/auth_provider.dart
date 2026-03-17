// lib/providers/auth_provider.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  // ================= EMAIL REGISTER =================
  Future<String?> registerWithEmail({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await result.user?.updateDisplayName(username);

      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': username,
        'email': email,
        'phone': '',
        'photoUrl': '',
        'isAdmin': false,
        'nameSet': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? 'Registration failed';
    }
  }

  // ================= EMAIL LOGIN =================
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message ?? 'Login failed';
    }
  }

  // ================= GOOGLE LOGIN (FIXED) =================
Future<String?> loginWithGoogle() async {
  _isLoading = true;
  notifyListeners();

  try {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize();

    final GoogleSignInAccount googleUser =
        await googleSignIn.authenticate();

    // ✅ FIX: authentication async hota hai
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final OAuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await _auth.signInWithCredential(credential);

    final needsName = await _createUserIfNew();

    _isLoading = false;
    notifyListeners();

    return needsName ? 'setup_name' : null;
  } catch (e) {
    _isLoading = false;
    notifyListeners();
    return 'Google Sign-In failed: $e';
  }
}

  // ================= USER CREATE =================
  Future<bool> _createUserIfNew() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      await _firestore.collection('users').doc(uid).set({
        'name': _auth.currentUser?.displayName ?? '',
        'email': _auth.currentUser?.email ?? '',
        'phone': '',
        'photoUrl': _auth.currentUser?.photoURL ?? '',
        'isAdmin': false,
        'nameSet': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    final data = doc.data();
    final nameSet = data?['nameSet'] ?? false;
    return !nameSet;
  }

  // ================= LOGOUT =================
Future<void> logout() async {
  await GoogleSignIn.instance.signOut(); // ✅ FIXED
  await _auth.signOut();
}
}