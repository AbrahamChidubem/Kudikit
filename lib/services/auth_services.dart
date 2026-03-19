// lib/services/auth_services.dart
// FIXED:
//   - baseUrl now reads from kBaseUrl (consistent with all other services)
//   - updateProfile() no longer throws UnimplementedError
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
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 2));

    if (email.isNotEmpty && password.length >= 6) {
      return MockAuthData.loginSuccess(email: email);
    } else {
      throw Exception('Invalid credentials');
    }
  }

  // ── Signup ─────────────────────────────────────────────────────────────────
  // TODO: Replace mock body below with real HTTP call:
  //   POST $baseUrl/auth/register  { email, phone_number, passcode }
  Future<Map<String, dynamic>> signup({required String email, required String phoneNumber, required String pin}) async {
    await Future.delayed(const Duration(seconds: 2));

    return MockAuthData.registerSuccess(email: email, phoneNumber: phoneNumber);
  }

  // ── Email Verification ─────────────────────────────────────────────────────
  // TODO: Replace mock body below with real HTTP call:
  //   POST $baseUrl/auth/verify-email  { email, code }
  Future<Map<String, dynamic>> verifyEmail({required String email, required String code, String phoneNumber = ''}) async {
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

    // Retrieve existing model, merge updates, and return.
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
      await _storage.saveAuthToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async => _storage.clearAuth();
  Future<bool> checkAuthStatus() async => _storage.isAuthenticated();
}