import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';
import 'package:tech_marathon_app/features/auth/data/auth_repository.dart';
import 'dart:async';
import 'package:tech_marathon_app/features/auth/data/user_repository.dart';
import 'package:tech_marathon_app/features/events/presentation/providers/chat_provider.dart';

class ProfileState {
  final Participant? user;
  final bool isComplete;

  ProfileState({this.user, this.isComplete = false});

  ProfileState copyWith({Participant? user, bool? isComplete}) {
    return ProfileState(
      user: user ?? this.user,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final Ref _ref;
  ProviderSubscription? _authSubscription;

  ProfileNotifier(this._repository, this._ref) : super(ProfileState()) {
    _listenToAuth();
  }

  void _listenToAuth() {
    _authSubscription = _ref.listen(authStateProvider, (previous, next) async {
      final user = next.value;
      if (user != null) {
        // 1. Check if user is an Admin first
        final adminDoc = await _repository.getFirestoreInstance()
            .collection('admins')
            .doc(user.uid)
            .get();

        if (adminDoc.exists) {
          final adminData = adminDoc.data()!;
          state = state.copyWith(
            user: Participant(
              id: user.uid,
              name: adminData['name'] ?? user.displayName ?? '',
              email: user.email ?? '',
              mobile: '',
              profileCompletion: 1.0,
              role: 'admin',
            ),
            isComplete: true,
          );
          return; // Stop here for admins
        }

        // 2. Not an admin, check regular users
        final profile = await _repository.getProfile(user.uid);
        if (profile != null) {
          state = state.copyWith(user: profile, isComplete: profile.profileCompletion >= 1.0);
        } else {
          // Initialize with basic auth info if no profile exists
          String defaultName = user.displayName ?? '';
          if (defaultName.isEmpty && user.email != null) {
            defaultName = user.email!.split('@')[0];
          }

          final initialParticipant = Participant(
            id: user.uid,
            name: defaultName,
            email: user.email ?? '',
            mobile: '',
            profileCompletion: 0.0,
            role: 'user',
          );
          state = state.copyWith(user: initialParticipant, isComplete: false);
          
          // Automatically save on first login to ensure they appear in Joined Members
          _repository.saveProfile(initialParticipant);
        }
      } else {
        state = ProfileState();
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  void updateProfile({
    String? name,
    String? age,
    String? email,
    String? mobile,
    String? image,
  }) {
    final currentParticipant = state.user ?? Participant(
      id: 'current_user',
      name: '',
      email: '',
      mobile: '',
      profileCompletion: 0.0,
      role: 'user',
    );

    // Calculate completion: ONLY 0 or 100
    bool allFilled = (name?.isNotEmpty ?? currentParticipant.name.isNotEmpty) &&
                    (age?.isNotEmpty ?? false) &&
                    (email?.isNotEmpty ?? currentParticipant.email.isNotEmpty) &&
                    (mobile?.isNotEmpty ?? currentParticipant.mobile.isNotEmpty);

    double completion = allFilled ? 1.0 : 0.0;

    final updatedParticipant = Participant(
      id: currentParticipant.id,
      name: name ?? currentParticipant.name,
      email: email ?? currentParticipant.email,
      mobile: mobile ?? currentParticipant.mobile,
      profileImage: image ?? currentParticipant.profileImage,
      profileCompletion: completion,
      role: currentParticipant.role,
    );

    state = state.copyWith(
      user: updatedParticipant,
      isComplete: allFilled,
    );

    // Persist to Firestore
    _repository.saveProfile(updatedParticipant);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref.watch(profileRepositoryProvider), ref);
});

final totalParticipantsProvider = StreamProvider<int>((ref) {
  return ref.watch(profileRepositoryProvider).getTotalParticipantsCount();
});

final completedProfilesProvider = StreamProvider<int>((ref) {
  return ref.watch(profileRepositoryProvider).getCompletedProfilesCount();
});

final participantsStreamProvider = StreamProvider<List<Participant>>((ref) {
  return ref.watch(userRepositoryProvider).getRealTimeMembers();
});


final chatMessagesProvider = activeMessagesProvider;

