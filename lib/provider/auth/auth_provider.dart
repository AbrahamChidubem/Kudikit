import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/model/user/user.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/storage_services.dart';

// =============================================================================
// 1. SERVICE PROVIDERS
// =============================================================================

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

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Extracts token from response — backend may use 'token' or 'accessToken'.
  String? _extractToken(Map<String, dynamic> response) {
    return (response['accessToken'] ?? response['token']) as String?;
  }

  /// Returns true for any successful response shape.
  bool _isSuccess(Map<String, dynamic> response) {
    return response['success'] == true ||
        response['status'] == 'success' ||
        response['statusCode'] == 201 ||
        response['statusCode'] == 200 ||
        (response['message'] as String? ?? '').toLowerCase().contains('success') ||
        (response['message'] as String? ?? '').toLowerCase().contains('created');
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
          .login(identifier: email, passcode: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out. Please try again.'),
          );

      debugPrint('[AuthNotifier] login response: $response');

      if (_isSuccess(response)) {
        final token = _extractToken(response);
        if (token == null) {
          throw Exception('Login failed: no token in response.');
        }
        final refreshToken = response['refreshToken'] as String?;
        if (refreshToken != null) {
          await _storageService.saveRefreshToken(refreshToken);
        }
        final user = response['user'] != null
            ? UserModel.fromJson(response['user'] as Map<String, dynamic>)
            : await _storageService.getUserModel();
        if (user == null) throw Exception('Login failed: no user data.');
        await _storageService.saveAuthToken(token);
        await _storageService.saveUserModel(user);
        state = state.authenticated(user, token);
      } else {
        throw Exception(
            response['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Step 1: Send Signup OTP ────────────────────────────────────────────────

  /// Sends an OTP to the user's email for signup verification.
  /// Returns the otpId so the calling screen can pass it to the verify step.
  /// Does NOT register the user yet — that happens after OTP verification.
  Future<String> sendSignupOtp({
    required String email,
    required String phoneNumber,
  }) async {
    state = state.loading();
    try {
      final reference = 'reg_${DateTime.now().millisecondsSinceEpoch}';
      final otpResponse = await _authService
          .sendOtp(
            phoneNumber: phoneNumber,
            email: email,
            reference: reference,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out. Please try again.'),
          );

      debugPrint('[AuthNotifier] sendSignupOtp response: $otpResponse');

      final otpId = (otpResponse['data']?['otpId'] ??
          otpResponse['otpId'] ??
          reference) as String;

      state = state.unauthenticated('Please verify your email to continue.');
      return otpId;
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Resend Verification OTP ────────────────────────────────────────────────

  /// Returns the new otpId so the verify screen can update its reference.
  Future<String> resendVerification({
    required String email,
    required String phoneNumber,
  }) async {
    final reference = 'resend_${DateTime.now().millisecondsSinceEpoch}';
    final otpResponse = await _authService.sendOtp(
      phoneNumber: phoneNumber,
      email: email,
      reference: reference,
    );
    return (otpResponse['data']?['otpId'] ??
        otpResponse['otpId'] ??
        reference) as String;
  }

  // ── Steps 2 & 3: Verify OTP then Register ─────────────────────────────────

  /// Verifies the OTP code, then registers the user account.
  /// This matches the backend's expected flow: verify-otp → register.
  Future<void> verifyOtpAndRegister({
    required String otpId,
    required String otp,
    required String email,
    required String phoneNumber,
    required String passcode,
  }) async {
    state = state.loading();
    try {
      // Step 2: Verify OTP
      final verifyResponse = await _authService
          .verifyOtp(otpId: otpId, otp: otp, action: 'registration')
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out. Please try again.'),
          );

      debugPrint('[AuthNotifier] verifyOtp response: $verifyResponse');

      if (!_isSuccess(verifyResponse)) {
        throw Exception(
            verifyResponse['message'] ?? 'OTP verification failed. Please try again.');
      }

      // Step 3: Register the account
      final registerResponse = await _authService
          .signup(
            email: email,
            phoneNumber: phoneNumber,
            passcode: passcode,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Request timed out. Please try again.'),
          );

      debugPrint('[AuthNotifier] register response: $registerResponse');

      if (_isSuccess(registerResponse)) {
        await _storageService.savePin(passcode);

        final token = _extractToken(registerResponse);
        final refreshToken = registerResponse['refreshToken'] as String?;

        final user = registerResponse['user'] != null
            ? UserModel.fromJson(
                registerResponse['user'] as Map<String, dynamic>)
            : UserModel(
                userId: (registerResponse['userId'] ??
                        registerResponse['data']?['userId'] ??
                        '') as String,
                email: email,
                phoneNumber: phoneNumber,
                isEmailVerified: true,
                createdAt: DateTime.now(),
                lastLogin: DateTime.now(),
              );

        await _storageService.saveUserModel(user);

        if (token != null) {
          await _storageService.saveAuthToken(token);
          if (refreshToken != null) {
            await _storageService.saveRefreshToken(refreshToken);
          }
          state = state.authenticated(user, token);
        } else {
          // Backend may not return token on register — user continues onboarding
          state = state.unauthenticated('Registration successful. Please continue.');
        }
      } else {
        throw Exception(
            registerResponse['message'] ?? 'Registration failed. Please try again.');
      }
    } catch (e) {
      state = state.error(e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  // ── Complete Onboarding ────────────────────────────────────────────────────

  Future<void> completeOnboarding({required int tierNumber}) async {
    try {
      await _authService.completeOnboarding(
        bvn: state.user?.bvn ?? '',
        tierNumber: tierNumber,
      );
      if (state.user != null) {
        final updatedUser = state.user!.copyWith(selectedTier: tierNumber);
        await _storageService.saveUserModel(updatedUser);
        state = state.copyWith(user: updatedUser);
      }
    } on KudiApiException catch (e) {
      state = state.error(e.message);
      rethrow;
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
    } catch (e) {}
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