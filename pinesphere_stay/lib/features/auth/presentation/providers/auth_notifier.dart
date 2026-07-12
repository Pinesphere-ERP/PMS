import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../audit/data/audit_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_model.dart';
import '../../../sync/data/sync_service.dart';

part 'auth_notifier.freezed.dart';
part 'auth_notifier.g.dart';

@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(UserModel user) = _Authenticated;
  const factory AuthState.locked(UserModel user) = _Locked;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(String message) = _Error;
}

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    _checkAuthStatus();
    return const AuthState.initial();
  }

  Future<void> _checkAuthStatus() async {
    final repository = ref.read(authRepositoryProvider);
    final cachedUser = await repository.getCachedUser();
    
    if (cachedUser != null) {
      state = AuthState.locked(cachedUser);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    final repository = ref.read(authRepositoryProvider);
    final result = await repository.login(email, password);

    result.fold(
      (failure) {
        ref.read(auditServiceProvider).log(
          moduleName: 'auth',
          actionType: 'login_failure',
          targetEntity: 'user',
          targetRecordId: email,
          newValue: {'email': email, 'reason': failure.message},
        );
        state = AuthState.error(failure.message);
      },
      (user) {
        ref.read(auditServiceProvider).log(
          moduleName: 'auth',
          actionType: 'login_success',
          targetEntity: 'user',
          targetRecordId: user.id,
          userId: user.id,
          newValue: {'email': email, 'role': user.role.name},
        );
        state = AuthState.authenticated(user);
        ref.read(syncServiceProvider).triggerSync();
      },
    );
  }

  Future<void> logout() async {
    final currentUser = state.whenOrNull(authenticated: (u) => u);
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();

    ref.read(auditServiceProvider).log(
      moduleName: 'auth',
      actionType: 'logout',
      targetEntity: 'user',
      targetRecordId: currentUser?.id ?? 'unknown',
      userId: currentUser?.id,
    );

    state = const AuthState.unauthenticated();
  }

  Future<bool> tryBiometricLogin() async {
    final repository = ref.read(authRepositoryProvider);
    final cachedUser = await repository.getCachedUser();
    
    if (cachedUser != null) {
      ref.read(auditServiceProvider).log(
        moduleName: 'auth',
        actionType: 'biometric_login_success',
        targetEntity: 'user',
        targetRecordId: cachedUser.id,
        userId: cachedUser.id,
      );
      state = AuthState.authenticated(cachedUser);
      return true;
    }
    
    return false;
  }

  void unlockPin() {
    state.maybeWhen(
      locked: (user) {
        state = AuthState.authenticated(user);
      },
      orElse: () {},
    );
  }
}
