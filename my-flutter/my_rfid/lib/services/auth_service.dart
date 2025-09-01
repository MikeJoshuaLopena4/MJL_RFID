// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart'; // ✅ for FCM token management

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Stream of authentication state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔹 Initialize notifications and save FCM token
      await NotificationService.init();

      return cred.user;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<User?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create default user doc in Firestore
      final uid = cred.user?.uid;
      if (uid != null) {
        await _db.collection('users').doc(uid).set({
          'email': email,
          'username': 'Parent', // default username
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 🔹 Also init notifications after sign-up
        await NotificationService.init();
      }

      return cred.user;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 🔹 Clear FCM token from Firestore so old device won't get notifications
        await _db.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
      }

      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      rethrow;
    }
  }

  // Get username (from Firestore or fallback to email prefix)
  Future<String> getUsername() async {
    final user = _auth.currentUser;
    if (user == null) return "Parent";

    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['username'] != null && (data['username'] as String).isNotEmpty) {
        return data['username'] as String;
      }
    }

    // fallback to email before @
    final email = user.email ?? "";
    return email.isNotEmpty ? email.split('@')[0] : "Parent";
  }

  // Update username in Firestore (merge so we don't clobber other fields)
  Future<void> updateUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).set(
      {'username': username},
      SetOptions(merge: true),
    );
  }
}
