import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;
  return ref.watch(authRepositoryProvider).getUserProfile(authState.uid);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  AuthController(this._repo) : super(const AsyncData(null));

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.login(email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repo.signUp(name: name, email: email, password: password);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await _repo.signInWithGoogle();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = const AsyncLoading();
    try {
      await _repo.forgotPassword(email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
        (ref) => AuthController(ref.watch(authRepositoryProvider)));
