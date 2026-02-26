import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tech_marathon_app/features/auth/data/auth_repository.dart';
export 'package:tech_marathon_app/features/auth/data/auth_repository.dart' show authStateProvider;

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.signInWithEmailAndPassword(email, password));
  }

  Future<void> signUp(String email, String password, String name, String mobile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.createUserWithEmailAndPassword(email, password, name, mobile));
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.signOut());
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.sendPasswordResetEmail(email));
  }
}


/// Simple session-level provider to track if the current user has authenticated as an admin.
/// This resets when the app restarts or the user logs out.
final isAdminLoggedInProvider = StateProvider<bool>((ref) => false);
