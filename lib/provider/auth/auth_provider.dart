import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/storage_services.dart';

// =============================================================================
// auth_provider.dart
// -----------------------------------------------------------------------------
// This file manages ALL authentication state for the app using Riverpod.
//
// WHAT IS RIVERPOD?
// Riverpod is a state management library. Think of "providers" as boxes that
// hold data. When the data in a box changes, any widget watching that box
// automatically rebuilds.
//
// HOW THIS FILE IS STRUCTURED:
//   1. Service Providers   → create single instances of AuthService & StorageService
//   2. AuthNotifier        → a class that holds auth state and has methods to
//                            change it (login, signup, logout, etc.)
//   3. authProvider        → the main provider widgets use to watch auth state
//   4. Computed Providers  → convenient providers derived from authProvider
// =============================================================================

// =============================================================================
// 1. SERVICE PROVIDERS
// =============================================================================
// These providers create single shared instances of your services.
// Using `Provider` (not StateNotifierProvider) because services don't have
// changing state themselves — they're just tools.

/// Provides a single shared instance of [StorageService].
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Provides a single shared instance of [AuthService].
/// It receives [StorageService] via dependency injection (ref.read).
final authServiceProvider = Provider<AuthService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return AuthService(storageService);
});

// =============================================================================
// 2. AUTH NOTIFIER
// =============================================================================
// StateNotifier is a class that:
//   - Holds a piece of state (here: AuthState)
//   - Has methods that can change that state
//   - Notifies all listeners when state changes
//
// Think of it as a controller for your auth state.

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;

  // The constructor receives both services and sets the initial state.
  // `super(AuthState())` sets the initial state to a fresh, empty AuthState.
  AuthNotifier(this._authService, this._storageService) : super(AuthState()) {
    // As soon as this notifier is created, check if the user is already logged in.
    _checkAuthStatus();
  }

  // ---------------------------------------------------------------------------
  // CHECK AUTH STATUS (called on app start)
  // ---------------------------------------------------------------------------
  // When the app opens, we look for a saved token and user in storage.
  // If found and valid → user is still logged in, go straight to home.
  // If not found or expired → user must log in again.

  Future<void> _checkAuthStatus() async {
    state = state.loading(); // Show loading indicator

    try {
      final token = await _storageService.getAuthToken();
      final user = await _storageService.getUserModel();

      if (token != null && user != null) {
        // We have a token — but is it still valid on the server?
        final isValid = await _authService.verifyToken(token);

        if (isValid) {
          // Token is valid — update last login time and restore session.
          final updatedUser = user.copyWith(lastLogin: DateTime.now());
          await _storageService.saveUserModel(updatedUser);
          state = state.authenticated(updatedUser, token);
        } else {
          // Token has expired — force the user to log in again.
          await logout();
        }
      } else {
        // No token or user found — user needs to log in.
        state = state.unauthenticated();
      }
    } catch (e) {
      // Something went wrong reading from storage.
      // Set an error state so the UI can show a message.
      state = state.error('Failed to restore session. Please log in again.');
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  // Sends the user's email and password to the server.
  // On success → save token + user, set authenticated state.
  // On failure → set error state and rethrow so the UI can show the error.

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.loading();

    try {
      final response = await _authService
          .login(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out. Please try again.'),
          );

      if (response['success'] == true) {
        final token = response['token'] as String;
        final userData = response['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        // Persist the session so the user stays logged in after closing the app.
        await _storageService.saveAuthToken(token);
        await _storageService.saveUserModel(user);

        state = state.authenticated(user, token);
      } else {
        throw Exception(response['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      state = state.error(e.toString());
      rethrow; // Re-throw so the UI (SignUpScreen/LoginPage) can also react.
    }
  }

  // ---------------------------------------------------------------------------
  // SIGNUP
  // ---------------------------------------------------------------------------
  // Sends the user's details to the server to create an account.
  //
  // On success:
  //   - Saves the passcode locally (hashed and encrypted).
  //   - Does NOT authenticate yet — the user must verify their email first.
  //
  // On failure → set error state and rethrow.

  Future<void> signup({
    required String email,
    required String phoneNumber,
    required String password, // This is the passcode (8-12 chars with complexity)
  }) async {
    state = state.loading();

    try {
      final response = await _authService
          .signup(
            email: email,
            phoneNumber: phoneNumber,
            pin: password,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timed out. Please try again.'),
          );

      if (response['success'] == true) {
        // Save the passcode securely so the user can log in after verification.
        await _storageService.savePin(password);

        // Persist a partial UserModel right away so the LoginPage can read
        // back the user's phone number and email from local storage.
        // This is intentionally incomplete (not yet authenticated).
        final partialUser = UserModel(
          userId: (response['userId'] as String?) ?? '',
          email: email,
          phoneNumber: phoneNumber,
          isEmailVerified: false,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await _storageService.saveUserModel(partialUser);

        // Don't authenticate yet — user must verify their email first.
        state = state.unauthenticated('Please verify your email to continue.');
      } else {
        throw Exception(response['message'] ?? 'Signup failed. Please try again.');
      }
    } catch (e) {
      state = state.error(e.toString());
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // VERIFY EMAIL AND COMPLETE LOGIN
  // ---------------------------------------------------------------------------
  // After signup, the user enters a code sent to their email.
  // This method sends that code to the server.
  // On success → save token + user, set authenticated (fully logged in).

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
        final userData = response['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        await _storageService.saveAuthToken(token);
        await _storageService.saveUserModel(user);

        state = state.authenticated(user, token);
      } else {
        throw Exception(response['message'] ?? 'Verification failed. Please try again.');
      }
    } catch (e) {
      state = state.error(e.toString());
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE USER
  // ---------------------------------------------------------------------------
  // Updates the in-memory state AND persists the updated user to storage.
  // Used when KYC data or profile info changes.

  Future<void> updateUser(UserModel updatedUser) async {
    if (state.user == null) return; // Nothing to update if not logged in

    try {
      await _storageService.saveUserModel(updatedUser);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      // Don't change auth state on a profile update failure.
      // Log it and let the UI handle it separately if needed.
      print('Warning: Failed to update user data: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE KYC STATUS
  // ---------------------------------------------------------------------------
  // KYC = Know Your Customer. These are identity verification steps
  // (BVN, NIN, selfie, address, document).
  //
  // This method updates only the KYC-related fields on the user model,
  // leaving everything else unchanged (using copyWith).

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

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  // Calls the server to invalidate the token, then clears all local data.

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Even if the server call fails, we still clear local data.
      // The user should always be able to log out locally.
    }
    await _storageService.clearAll();
    state = state.unauthenticated();
  }
}

// =============================================================================
// 3. MAIN AUTH PROVIDER
// =============================================================================
// This is the provider your widgets will watch.
// It creates and manages the AuthNotifier instance.

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );
});

// =============================================================================
// 4. COMPUTED PROVIDERS
// =============================================================================
// These are convenience providers that extract specific pieces of auth state.
// Instead of writing `ref.watch(authProvider).user` everywhere, you can
// write `ref.watch(currentUserProvider)`.

/// The currently logged-in user, or null if not authenticated.
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

/// True if the user is authenticated, false otherwise.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// The current authentication token, or null if not authenticated.
final authTokenProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).token;
});

/// The user's KYC completion progress as a value between 0.0 and 1.0.
final kycProgressProvider = Provider<double>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.kycProgress ?? 0.0;
});

/// True if the user has completed all KYC verification steps.
final isKycCompleteProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isKycComplete ?? false;
});