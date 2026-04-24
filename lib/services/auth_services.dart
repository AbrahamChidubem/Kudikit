// lib/services/auth_services.dart
// INTEGRATED against real Postman-confirmed endpoints.
//
// Registration flow (3 steps):
//   1. POST /api/v1/auth/send-otp       → { phoneNumber, email, channel }
//   2. POST /api/v1/auth/verify-otp     → { otpId, otp, action: "registration" }
//   3. POST /api/v1/auth/register       → { phone, email, passcode, deviceFingerprint }
//
// Login flow:
//   POST /api/v1/auth/login             → { identifier, passcode, deviceInfo }
//
// Session:
//   POST /api/v1/auth/refresh-token     → { refreshToken }
//   POST /api/v1/auth/logout/:userId/:sessionId
//
// Profile (used for token verification + profile fetch):
//   GET  /api/v1/profile
//   POST /api/v1/profile/update-profile → { firstName, lastName, email, dateOfBirth }
//
// Onboarding:
//   POST /api/v1/auth/onboarding/complete → { bvn }

import 'package:flutter/foundation.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/device_info_services.dart';
import 'package:kudipay/services/storage_services.dart';

class AuthService {
  final DioClient _client;
  final StorageService _storage;

  AuthService(this._storage, this._client);

  // ── Step 1: Send OTP ───────────────────────────────────────────────────────
  // POST /api/v1/auth/send-otp
  // Body: { phoneNumber, email, channel: "sms"|"email"|"whatsapp" }
  // Response: { otpId, message, ... }
  Future<Map<String, dynamic>> sendOtp({
    required String phoneNumber,
    required String email,
    String channel = 'sms',
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/send-otp',
        data: {
          'phoneNumber': phoneNumber,
          'email': email,
          'channel': channel,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Failed to send OTP: ${e.toString()}');
    }

    // ── Mock fallback ─────────────────────────────────────────────────────────
    // await Future.delayed(const Duration(seconds: 1));
    // return {'success': true, 'otpId': 'mock-otp-id-123', 'message': 'OTP sent'};
  }

  // ── Step 2: Verify OTP ─────────────────────────────────────────────────────
  // POST /api/v1/auth/verify-otp
  // Body: { otpId, otp, action: "registration"|"login"|"reset" }
  // Response: { success, verificationToken, ... }
  Future<Map<String, dynamic>> verifyOtp({
    required String otpId,
    required String otp,
    String action = 'registration',
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/verify-otp',
        data: {
          'otpId': otpId,
          'otp': otp,
          'action': action,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('OTP verification failed: ${e.toString()}');
    }

    // ── Mock fallback ─────────────────────────────────────────────────────────
    // await Future.delayed(const Duration(seconds: 1));
    // if (otp.length == 6) return {'success': true, 'verificationToken': 'mock-verify-token'};
    // throw KudiApiException('Invalid OTP');
  }

  // ── Step 3: Register ───────────────────────────────────────────────────────
  // POST /api/v1/auth/register
  // Body: { phone, email, passcode, deviceFingerprint }
  // Response: { success, userId, accessToken, refreshToken, user: {...} }
  Future<Map<String, dynamic>> signup({
    required String email,
    required String phoneNumber,
    required String passcode,
    String? deviceFingerprint,
  }) async {
    final meta = await DeviceInfoService.collect();
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/register',
        data: {
          'phone': phoneNumber,
          'email': email,
          'passcode': passcode,
          // 'deviceFingerprint': deviceFingerprint ?? meta.deviceName,
        },
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Registration failed: ${e.toString()}');
    }

    // ── Mock fallback ─────────────────────────────────────────────────────────
    // await Future.delayed(const Duration(seconds: 2));
    // return MockAuthData.registerSuccess(email: email, phoneNumber: phoneNumber, deviceMetadata: meta);
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  // POST /api/v1/auth/login
  // Body: { identifier (phone or email), passcode, deviceInfo: { deviceName, osVersion } }
  // Response: { success, accessToken, refreshToken, sessionId, user: {...} }
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String passcode,
  }) async {
    final meta = await DeviceInfoService.collect();
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/login',
        data: {
          'identifier': identifier,
          'passcode': passcode,
          // 'deviceInfo': {
          //   'deviceName': meta.deviceName,
          //   'osVersion': meta.osVersion,
          // },
        },
      );
      return response.data!;
    } on KudiUnauthorizedException {
      throw KudiApiException('Invalid credentials. Please try again.');
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Login failed: ${e.toString()}');
    }

    // ── Mock fallback ─────────────────────────────────────────────────────────
    // await Future.delayed(const Duration(seconds: 2));
    // return MockAuthData.loginSuccess(email: identifier, deviceMetadata: meta);
  }

  // ── Refresh Token ──────────────────────────────────────────────────────────
  // POST /api/v1/auth/refresh-token
  // Body: { refreshToken }
  // Response: { accessToken, refreshToken }
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );
      return response.data!;
    } catch (e) {
      throw KudiApiException('Token refresh failed: ${e.toString()}');
    }
  }

  // ── Verify Token (by fetching profile) ────────────────────────────────────
  // GET /api/v1/profile
  // Returns true if server accepts the token; false on 401.
  // On network error: returns true to avoid logging users out offline.
  Future<bool> verifyToken(String token) async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/api/v1/profile');
      return response.data != null;
    } on KudiUnauthorizedException {
      return false;
    } catch (e) {
      debugPrint('[AuthService] verifyToken network error — keeping session: $e');
      return true;
    }

    // ── Mock fallback ─────────────────────────────────────────────────────────
    // await Future.delayed(const Duration(milliseconds: 500));
    // return token.isNotEmpty;
  }

  // ── Update Profile ─────────────────────────────────────────────────────────
  // POST /api/v1/profile/update-profile
  // Body: { firstName?, lastName?, email?, dateOfBirth? }
  // Response: { success, user: {...} }
  Future<UserModel> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
    String? bvn,
    String? nin,
    bool? isBvnVerified,
    bool? isAddressVerified,
    bool? isSelfieVerified,
    bool? isDocumentVerified,
  }) async {
    final existing = await _storage.getUserModel();
    if (existing == null) throw KudiApiException('No user session found.');

    try {
      final body = <String, dynamic>{
        if (firstName != null) 'firstName': firstName,
        if (lastName != null) 'lastName': lastName,
        if (email != null) 'email': email,
        if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/profile/update-profile',
        data: body,
      );

      final data = response.data!;
      if (data['user'] != null) {
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      }
      // Optimistic fallback if server doesn't return user object
      return existing.copyWith(
        name: (firstName != null && lastName != null)
            ? '$firstName $lastName'
            : existing.name,
        isBvnVerified: isBvnVerified ?? existing.isBvnVerified,
        isAddressVerified: isAddressVerified ?? existing.isAddressVerified,
        isSelfieVerified: isSelfieVerified ?? existing.isSelfieVerified,
        isDocumentVerified: isDocumentVerified ?? existing.isDocumentVerified,
        bvn: bvn ?? existing.bvn,
        nin: nin ?? existing.nin,
      );
    } catch (e) {
      debugPrint('[AuthService] updateProfile error: $e');
      // Return optimistic local update on failure
      return existing.copyWith(
        isBvnVerified: isBvnVerified ?? existing.isBvnVerified,
        isAddressVerified: isAddressVerified ?? existing.isAddressVerified,
        isSelfieVerified: isSelfieVerified ?? existing.isSelfieVerified,
        isDocumentVerified: isDocumentVerified ?? existing.isDocumentVerified,
        bvn: bvn ?? existing.bvn,
        nin: nin ?? existing.nin,
      );
    }
  }

  // ── Complete Onboarding ────────────────────────────────────────────────────
  // POST /api/v1/auth/onboarding/complete
  // Body: { bvn }
  Future<Map<String, dynamic>> completeOnboarding({required String bvn}) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/v1/auth/onboarding/complete',
        data: {'bvn': bvn},
      );
      return response.data!;
    } on KudiApiException {
      rethrow;
    } catch (e) {
      throw KudiApiException('Onboarding failed: ${e.toString()}');
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  // POST /api/v1/auth/logout/:userId/:sessionId
  // sessionId is not stored locally — pass empty string; server will invalidate all sessions.
  Future<void> logout({String? userId, String? sessionId}) async {
    try {
      final uid = userId ?? (await _storage.getUserModel())?.userId ?? '';
      final sid = sessionId ?? '';
      await _client.post('/api/v1/auth/logout/$uid/$sid', data: {});
    } catch (e) {
      debugPrint('[AuthService] logout server call failed (session still cleared): $e');
    }
    await _storage.clearAuth();
  }

  // ── Submit User Info (onboarding helper) ───────────────────────────────────
  Future<bool> submitUserInfo(UserInfo userInfo) async {
    try {
      await _storage.saveUserInfo(userInfo);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> checkAuthStatus() async => _storage.isAuthenticated();
}