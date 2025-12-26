import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Explicitly bind Auth to the app initialized in main() 
  // to prevent project-sync issues on Web.
  return AuthRepository(FirebaseAuth.instanceFor(app: Firebase.app()));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Attempting login for project: ${_auth.app.options.projectId}');
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Diagnostic logging for developers
      debugPrint('FirebaseAuthException [${e.code}]: ${e.message}');
      if (e.code == 'invalid-credential' && e.message?.contains('API') == true) {
        debugPrint('CRITICAL: Possible API Key mismatch or configuration sync issue.');
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected Auth Error: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('Attempting signup for project: ${_auth.app.options.projectId}');
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException [${e.code}]: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected Signup Error: ${e.toString()}');
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Google Sign In can be added here once google_sign_in package is configured
}
