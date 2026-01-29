
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/auth/auth_state.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/auth_services.dart';
import 'package:kudipay/services/storage_services.dart';

// ============================================================================
// SERVICE PROVIDERS
// ============================================================================

// Storage Service Provider (singleton instance for consistency)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

// Auth Service Provider (use ref.read for non-reactive dependency)
final authServiceProvider = Provider<AuthService>((ref) {
  final storageService = ref.read(storageServiceProvider);
  return AuthService(storageService);
});

// ============================================================================
// AUTH NOTIFIER
// ============================================================================

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final StorageService _storageService;

  AuthNotifier(this._authService, this._storageService) : super(AuthState()) {
    _checkAuthStatus();
  }

  // Check if user is already logged in (on app start)
  Future<void> _checkAuthStatus() async {
    state = state.loading();

    try {
      final token = await _storageService.getAuthToken();
      final user = await _storageService.getUserModel();  // Fixed: Use getUserModel() for UserModel

      if (token != null && user != null) {
        // Verify token is still valid
        final isValid = await _authService.verifyToken(token);

        if (isValid) {
          // Update last login
          final updatedUser = user.copyWith(lastLogin: DateTime.now());
          await _storageService.saveUserModel(updatedUser);  // Fixed: Use saveUserModel() for UserModel

          state = state.authenticated(updatedUser, token);
        } else {
          // Token expired, logout
          await logout();
        }
      } else {
        state = state.unauthenticated();
      }
    } catch (e) {
      // Improved error handling: log the error and provide user feedback
      print('Error during auth check: $e'); // Use a proper logger in production
      state = state.error('Failed to check authentication status. Please try again.');
    }
  }

  // Login with email and password
  Future<void> login({
    required String email,
    required String pin
  }) async {
    state = state.loading();

    try {
      final response = await _authService.login(
        email: email,
        password: pin,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response['success'] == true) {
        final token = response['token'] as String;
        final userData = response['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        // Save to storage
        await _storageService.saveAuthToken(token);
        await _storageService.saveUserModel(user);  // Fixed: Use saveUserModel() for UserModel

        state = state.authenticated(user, token);
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      state = state.error(e.toString());
      rethrow;
    }
  }

  // Signup
  Future<void> signup({
    required String email,
    required String phoneNumber,
    required String pin,
  }) async {
    state = state.loading();

    try {
      final response = await _authService.signup(
        email: email,
        phoneNumber: phoneNumber,
        pin: pin,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response['success'] == true) {
        // Save PIN securely (use flutter_secure_storage in production!)
        await _storageService.savePin(pin);

        // Don't authenticate yet - wait for email verification
        state = state.unauthenticated('Please verify your email');
      } else {
        throw Exception(response['message'] ?? 'Signup failed');
      }
    } catch (e) {
      state = state.error(e.toString());
      rethrow;
    }
  }

  // Verify email and complete signup
  Future<void> verifyEmailAndLogin({
    required String email,
    required String code,
  }) async {
    state = state.loading();

    try {
      final response = await _authService.verifyEmail(
        email: email,
        code: code,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timed out'),
      );

      if (response['success'] == true) {
        final token = response['token'] as String;
        final userData = response['user'] as Map<String, dynamic>;
        final user = UserModel.fromJson(userData);

        // Save to storage
        await _storageService.saveAuthToken(token);
        await _storageService.saveUserModel(user);  // Fixed: Use saveUserModel() for UserModel

        state = state.authenticated(user, token);
      } else {
        throw Exception(response['message'] ?? 'Verification failed');
      }
    } catch (e) {
      state = state.error(e.toString());
      rethrow;
    }
  }

  // Update user data (for KYC progress)
  Future<void> updateUser(UserModel updatedUser) async {
    if (state.user == null) return;

    try {
      // Save updated user to storage
      await _storageService.saveUserModel(updatedUser);  // Fixed: Use saveUserModel() for UserModel

      // Update state
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      // Handle error but don't change auth state
      print('Error updating user: $e');
    }
  }

  // Update KYC verification status
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

  // Logout
  Future<void> logout() async {
    await _authService.logout();
    await _storageService.clearAll();
    state = state.unauthenticated();
  }
}

// ============================================================================
// MAIN AUTH PROVIDER
// ============================================================================

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(authServiceProvider),
    ref.read(storageServiceProvider),
  );
});

// ============================================================================
// COMPUTED PROVIDERS (for easy access)
// ============================================================================

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
  final user = ref.watch(currentUserProvider);
  return user?.kycProgress ?? 0.0;
});

final isKycCompleteProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isKycComplete ?? false;
});
