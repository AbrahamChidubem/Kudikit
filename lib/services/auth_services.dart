// lib/services/auth_services.dart
// FIXED:
//   - baseUrl now reads from kBaseUrl (consistent with all other services)
//   - updateProfile() no longer throws UnimplementedError
//   - login() mock guard updated: password.length >= 6 → >= 8 to match
//     the new alphanumeric passcode minimum length rule
//   - All print() removed

import 'package:kudipay/mock/mock_api_data.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/storage_services.dart';

class AuthService {
  // FIXED: was 'https://api.kudikit.com' — now uses the single kBaseUrl constant.
  static String get baseUrl => kBaseUrl;

  // ── Login ──────────────────────────────────────────────────────────────────
  // TODO: Replace mock body below with real HTTP call:
  //   POST $baseUrl/auth/login  { email, password }
  //
  // FIXED: Guard updated from password.length >= 6 to password.length >= 8.
  // The passcode minimum is now 8 characters (alphanumeric with complexity).
  // Using 6 here was a leftover from the old 6-digit numeric PIN era and
  // would allow passwords that the StorageService._validatePasscode() would
  // reject, creating a silent inconsistency between the login mock and signup.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // Guard: must match the minimum passcode length enforced at signup (8 chars).
    if (email.isNotEmpty && password.length >= 8) {
      return MockAuthData.loginSuccess(email: email);
    } else {
      throw Exception('Invalid credentials');
    }
  }

  // ── Signup ─────────────────────────────────────────────────────────────────
  // TODO: Replace mock body below with real HTTP call:
  //   POST $baseUrl/auth/register  { email, phone_number, passcode }
  Future<Map<String, dynamic>> signup({
    required String email,
    required String phoneNumber,
    required String pin,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    return MockAuthData.registerSuccess(
        email: email, phoneNumber: phoneNumber);
  }

  // ── Email Verification ─────────────────────────────────────────────────────
  // TODO: Replace mock body below with real HTTP call:
  //   POST $baseUrl/auth/verify-email  { email, code }
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
    String phoneNumber = '',
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    if (code.length == 6) {
      return MockAuthData.verifyEmailSuccess(email: email);
    } else {
      throw Exception('Invalid verification code');
    }
  }

  // ── Token Verification ─────────────────────────────────────────────────────
  // TODO: Replace mock body below with real HTTP call:
  //   GET $baseUrl/auth/verify-token  (Authorization: Bearer $token)
  Future<bool> verifyToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return token.isNotEmpty;
  }

  // ── Update Profile ─────────────────────────────────────────────────────────
  // FIXED: was throwing UnimplementedError.
  // TODO: Replace mock body below with real HTTP call:
  //   PUT $baseUrl/user/profile  { name, bvn, nin, ... }
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? bvn,
    String? nin,
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    final existing = await _storage.getUserModel();
    if (existing == null) throw Exception('No user model found in storage');

    return existing.copyWith(
      bvn: bvn ?? existing.bvn,
      nin: nin ?? existing.nin,
      isBvnVerified: isBvnVerified ?? existing.isBvnVerified,
      isAddressVerified: isAddressVerified ?? existing.isAddressVerified,
      isSelfieVerified: isSelfieVerified ?? existing.isSelfieVerified,
      isDocumentVerified: isDocumentVerified ?? existing.isDocumentVerified,
    );
  }

  final StorageService _storage;
  AuthService(this._storage);

  Future<bool> submitUserInfo(UserInfo userInfo) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      await _storage.saveUserInfo(userInfo);
      await _storage.saveAuthToken(
          'mock_token_${DateTime.now().millisecondsSinceEpoch}');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async => _storage.clearAuth();
  Future<bool> checkAuthStatus() async => _storage.isAuthenticated();
}