import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  User? user;
  bool loading = true;
  bool isVerifiedConsultant = false;

  void bind() {
    _auth.authStateChanges().listen((u) async {
      user = u;
      if (u != null) {
        final doc = await _db.collection('users').doc(u.uid).get();
        final data = doc.data();
        final role = data?['role'];
        final verified = data?['verified'] == true;
        isVerifiedConsultant = role == 'consultant' && verified;
      } else {
        isVerifiedConsultant = false;
      }
      loading = false;
      notifyListeners();
    });
  }

  Future<String?> registerConsultant({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(displayName);
      await _db.collection('users').doc(cred.user!.uid).set({
        'displayName': displayName,
        'email': email,
        'role': 'consultant',
        'verified': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// New: includes LinkedIn + Qualifications (no file upload)
  Future<String?> registerConsultantWithApplication({
    required String email,
    required String password,
    required String displayName,
    required String linkedinUrl,
    required String qualifications,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user!.updateDisplayName(displayName);
      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'displayName': displayName,
        'email': email,
        'role': 'consultant',
        'verified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'applicationStatus': 'pending',
        'applicationSubmittedAt': FieldValue.serverTimestamp(),
        'application': {
          'linkedinUrl': linkedinUrl,
          'qualifications': qualifications, // plain text summary/bullets
        },
      }, SetOptions(merge: true));

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() => _auth.signOut();
}
