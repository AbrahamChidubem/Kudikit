// lib/provider/auth/auth_provider.dart
// UPDATED: AuthService now takes DioClient as a second constructor param.
// All other logic is unchanged.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/model/user/user.dart';

import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/storage_services.dart';

// =============================================================================
// 1. SERVICE PROVIDERS
// =============================================================================

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// AuthService now receives DioClient via the dioClientProvider so all HTTP
/// calls go through the unified interceptor chain (auth, logging, error mapping).
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(storageServiceProvider),
    ref.read(dioClientProvider),
  );
});

// =============================================================================
// 2. AUTH NOTIFIER
// =============================================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;

  AuthNotifier(this._authService, this._storageService) : super(AuthState()) {
    _checkAuthStatus();
  }

  // ── Check auth status on app start ────────────────────────────────────────

  Future<void> _checkAuthStatus() async {
    state = state.loading();
    try {
      final token = await _storageService.getAuthToken();
      final user = await _storageService.getUserModel();

      if (token != null && user != null) {
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          final updatedUser = user.copyWith(lastLogin: DateTime.now());
          await _storageService.saveUserModel(updatedUser);
          state = state.authenticated(updatedUser, token);
        } else {
          await logout();
        }
      } else {
        state = state.unauthenticated();
      }
    } catch (e) {
      state = state.error('Failed to restore session. Please log in again.');
    }
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.loading();
    try {
      final response = await _authService
          .login(email: email, password: password, identifier: '', passcode: '')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out. Please try again.'),
          );

      if (response['success'] == true) {
        final token = response['token'] as String;
        final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
        await _storageService.saveAuthToken(token);
        await _storageService.saveUserModel(user);
        state = state.authenticated(user, token);
      } else {
        throw Exception(response['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Signup ─────────────────────────────────────────────────────────────────

  Future<void> signup({
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = state.loading();
    try {
      final response = await _authService
          .signup(email: email, phoneNumber: phoneNumber, pin: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out. Please try again.'),
          );

      if (response['success'] == true) {
        await _storageService.savePin(password);
        final partialUser = UserModel(
          userId: (response['userId'] as String?) ?? '',
          email: email,
          phoneNumber: phoneNumber,
          isEmailVerified: false,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await _storageService.saveUserModel(partialUser);
        state = state.unauthenticated('Please verify your email to continue.');
      } else {
        throw Exception(response['message'] ?? 'Signup failed. Please try again.');
      }
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Verify Email & Complete Login ──────────────────────────────────────────

  Future<void> verifyEmailAndLogin({
    required String email,
    required String code,
  }) async {
    state = state.loading();
    try {
      final response = await _authService
          .verifyEmail(email: email, code: code)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out. Please try again.'),
          );

      if (response['success'] == true) {
        final token = response['token'] as String;
        final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
        await _storageService.saveAuthToken(token);
        await _storageService.saveUserModel(user);
        state = state.authenticated(user, token);
      } else {
        throw Exception(response['message'] ?? 'Verification failed. Please try again.');
      }
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Update User ────────────────────────────────────────────────────────────

  Future<void> updateUser(UserModel updatedUser) async {
    if (state.user == null) return;
    try {
      await _storageService.saveUserModel(updatedUser);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      // Non-fatal — don't change auth state
    }
  }

  // ── Update KYC status ─────────────────────────────────────────────────────

  Future<void> updateKycStatus({
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
    String? bvn,
    String? nin,
  }) async {
    if (state.user == null) return;
    final updatedUser = state.user!.copyWith(
      isBvnVerified: isBvnVerified ?? state.user!.isBvnVerified,
      isAddressVerified: isAddressVerified ?? state.user!.isAddressVerified,
      isSelfieVerified: isSelfieVerified ?? state.user!.isSelfieVerified,
      isDocumentVerified: isDocumentVerified ?? state.user!.isDocumentVerified,
      bvn: bvn ?? state.user!.bvn,
      nin: nin ?? state.user!.nin,
    );
    await updateUser(updatedUser);
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {}
    await _storageService.clearAll();
    state = state.unauthenticated();
  }
}

// =============================================================================
// 3. MAIN AUTH PROVIDER
// =============================================================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );
});

// =============================================================================
// 4. COMPUTED PROVIDERS
// =============================================================================

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});

final kycProgressProvider = Provider<double>((ref) {
  return ref.watch(currentUserProvider)?.kycProgress ?? 0.0;
});

final isKycCompleteProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isKycComplete ?? false;
});

// ── Simple UI state providers ─────────────────────────────────────────────────

final pinVisibilityProvider = StateProvider<bool>((ref) => false);
final confirmPinVisibilityProvider = StateProvider<bool>((ref) => false);
final userIdProvider = StateProvider<String?>((ref) => null);
final userProvider = StateProvider<String>((ref) => '');
final userEmailProvider = StateProvider<String>((ref) => '');

final userProfileProvider = Provider<UserProfile>((ref) {
  return UserProfile(
    userId: ref.watch(userIdProvider),
    name: ref.watch(userProvider),
    email: ref.watch(userEmailProvider),
  );
});
