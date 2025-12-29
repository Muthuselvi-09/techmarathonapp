import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/events/domain/event_models.dart';
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
        final profile = await _repository.getProfile(user.uid);
        if (profile != null) {
          state = state.copyWith(user: profile, isComplete: profile.profileCompletion >= 1.0);
        } else {
          // Initialize with basic auth info if no profile exists
          final initialParticipant = Participant(
            id: user.uid,
            name: user.displayName ?? '',
            email: user.email ?? '',
            mobile: '',
            profileCompletion: 0.0,
          );
          state = state.copyWith(user: initialParticipant, isComplete: false);
          // Don't save yet, wait for user to fill details
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

