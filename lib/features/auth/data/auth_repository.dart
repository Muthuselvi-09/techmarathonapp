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

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        await _userRepository.syncUser(
          credential.user!.uid,
          name: credential.user!.displayName ?? email.split('@')[0],
          email: credential.user!.email,
          fcmToken: fcmToken,
          isOnline: true,
        );
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
}
