import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instanceFor(app: Firebase.app()),
    ref.watch(userRepositoryProvider),
  );
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  AuthRepository(this._auth, this._userRepository);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        // Check if email is verified
        if (!credential.user!.emailVerified) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email before logging in.',
          );
        }

        // Check if this is an Admin login attempt
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(credential.user!.uid)
            .get();

        if (!adminDoc.exists) {
          // Only sync if NOT an admin
          final fcmToken = await FirebaseMessaging.instance.getToken();
          await _userRepository.syncUser(
            credential.user!.uid,
            name: credential.user!.displayName ?? email.split('@')[0],
            email: credential.user!.email,
            fcmToken: fcmToken,
            isOnline: true,
          );
        }
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException [${e.code}]: ${e.message}');
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password, String name, String mobile) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        // Send verification email
        await credential.user!.sendEmailVerification();
        
        final fcmToken = await FirebaseMessaging.instance.getToken();
        await _userRepository.syncUser(
          credential.user!.uid,
          name: name,
          email: credential.user!.email,
          fcmToken: fcmToken,
          mobile: mobile,
          isOnline: false, // User is not online until verified and logged in
        );

        // Sign out immediately so they have to login after verification
        await _auth.signOut();
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException [${e.code}]: ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _userRepository.updateOnlineStatus(uid, false);
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException [${e.code}]: ${e.message}');
      rethrow;
    }
  }
}
