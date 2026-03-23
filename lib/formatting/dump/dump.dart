/**
 * import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/provider/auth_provider.dart';

// ==================== IDENTITY VERIFICATION PROVIDERS ====================

// Identification Type Enum
enum IdentificationType {
  BVN,
  NIN,
}

// User Verification Data Model
class UserVerificationData {
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String? photoUrl;
  final String gender;
  final String idNumber;
  final String idType;

  UserVerificationData({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    this.photoUrl,
    required this.gender,
    required this.idNumber,
    required this.idType,
  });

  factory UserVerificationData.fromJson(Map<String, dynamic> json) {
    return UserVerificationData(
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      middleName: json['middle_name'] ?? json['middleName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      fullName: json['full_name'] ??
          json['fullName'] ??
          '${json['first_name']} ${json['middle_name']} ${json['last_name']}',
      dateOfBirth: DateTime.parse(json['date_of_birth'] ?? json['dateOfBirth']),
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      gender: json['gender'] ?? '',
      idNumber: json['bvn'] ?? json['nin'] ?? json['id_number'] ?? '',
      idType: json['id_type'] ?? 'BVN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'gender': gender,
      'id_number': idNumber,
      'id_type': idType,
    };
  }
}

// Identity Verification State
class IdentityVerificationState {
  final UserVerificationData? verificationData;
  final bool isVerifying;
  final String? error;

  const IdentityVerificationState({
    this.verificationData,
    this.isVerifying = false,
    this.error,
  });

  IdentityVerificationState copyWith({
    UserVerificationData? verificationData,
    bool? isVerifying,
    String? error,
    bool clearError = false,
  }) {
    return IdentityVerificationState(
      verificationData: verificationData ?? this.verificationData,
      isVerifying: isVerifying ?? this.isVerifying,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Verification Exception
class VerificationException implements Exception {
  final String message;
  final int? statusCode;

  VerificationException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

// Identity Verification Service
class IdentityVerificationService {
  final String baseUrl;
  final String? authToken;

  IdentityVerificationService({
    required this.baseUrl,
    this.authToken,
  });

  // Detect if input is BVN or NIN
  IdentificationType detectIdType(String input) {
    if (input.length != 11) {
      throw VerificationException('Invalid ID length. Must be 11 digits.');
    }

    if (input.startsWith('2')) {
      return IdentificationType.BVN;
    } else {
      return IdentificationType.NIN;
    }
  }

  Future<UserVerificationData> verifyIdentity({
    required String idNumber,
    String? idType,
  }) async {
    final detectedIdType = idType ?? detectIdType(idNumber).name;

    // Mock implementation for testing
    return _mockVerifyIdentity(idNumber, detectedIdType);

    // TODO: Replace with real API call
  }

  Future<UserVerificationData> _mockVerifyIdentity(
    String idNumber,
    String idType,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    if (idNumber.length != 11) {
      throw VerificationException('Invalid $idType format');
    }

    return UserVerificationData(
      firstName: 'MICHAEL',
      middleName: 'ASUQUO',
      lastName: 'TOLUWLASE',
      fullName: 'MICHAEL ASUQUO TOLUWLASE',
      dateOfBirth: DateTime(1990, 5, 15),
      phoneNumber: '08012345678',
      gender: 'Male',
      idNumber: idNumber,
      idType: idType,
    );
  }
}

// Identity Verification Notifier
class IdentityVerificationNotifier
    extends StateNotifier<IdentityVerificationState> {
  final IdentityVerificationService _service;

  IdentityVerificationNotifier(this._service)
      : super(const IdentityVerificationState());

  Future<void> verifyIdentity({
    required String idNumber,
    dynamic idType,
  }) async {
    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      String? idTypeString;
      if (idType != null) {
        idTypeString = idType.toString().contains('.')
            ? idType.toString().split('.').last
            : idType.toString();
      }

      final verificationData = await _service.verifyIdentity(
        idNumber: idNumber,
        idType: idTypeString,
      );

      state = state.copyWith(
        verificationData: verificationData,
        isVerifying: false,
      );
    } on SocketException {
      state = state.copyWith(
        isVerifying: false,
        error: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      state = state.copyWith(
        isVerifying: false,
        error: 'Request timed out. Please try again.',
      );
    } on VerificationException catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: 'Verification failed. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const IdentityVerificationState();
  }
}

// Identity Verification Service Provider
final identityVerificationServiceProvider =
    Provider<IdentityVerificationService>((ref) {
  final authToken = ref.watch(authTokenProvider);
  return IdentityVerificationService(
    baseUrl: 'https://api.kudipay.com/api/v1',
    authToken: authToken,
  );
});

// Identity Verification Provider
final identityVerificationProvider = StateNotifierProvider<
    IdentityVerificationNotifier, IdentityVerificationState>((ref) {
  final service = ref.watch(identityVerificationServiceProvider);
  return IdentityVerificationNotifier(service);
});

// ==================== REGISTRATION PROVIDER ====================

class RegistrationState {
  final String? email;
  final String? phone;
  final String? password;
  final UserVerificationData? verificationData;
  final bool isVerifying;
  final bool isRegistering;
  final String? error;

  const RegistrationState({
    this.email,
    this.phone,
    this.password,
    this.verificationData,
    this.isVerifying = false,
    this.isRegistering = false,
    this.error,
  });

  RegistrationState copyWith({
    String? email,
    String? phone,
    String? password,
    UserVerificationData? verificationData,
    bool? isVerifying,
    bool? isRegistering,
    String? error,
    bool clearError = false,
  }) {
    return RegistrationState(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      verificationData: verificationData ?? this.verificationData,
      isVerifying: isVerifying ?? this.isVerifying,
      isRegistering: isRegistering ?? this.isRegistering,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final IdentityVerificationService _verificationService;

  RegistrationNotifier(this._verificationService)
      : super(const RegistrationState());

  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  Future<void> verifyIdentity(String idNumber) async {
    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      final verificationData = await _verificationService.verifyIdentity(
        idNumber: idNumber,
      );

      state = state.copyWith(
        verificationData: verificationData,
        isVerifying: false,
      );
    } on SocketException {
      state = state.copyWith(
        isVerifying: false,
        error: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      state = state.copyWith(
        isVerifying: false,
        error: 'Request timed out. Please try again.',
      );
    } on VerificationException catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: 'Verification failed: ${e.toString()}',
      );
    }
  }

  Future<void> completeRegistration() async {
    if (state.email == null ||
        state.password == null ||
        state.verificationData == null) {
      state = state.copyWith(
        error: 'Missing required registration information',
      );
      return;
    }

    state = state.copyWith(isRegistering: true, clearError: true);

    try {
      // TODO: Replace with actual user creation logic
      // Mock delay
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(isRegistering: false);
    } catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: 'Registration failed: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const RegistrationState();
  }
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  final service = ref.watch(identityVerificationServiceProvider);
  return RegistrationNotifier(service);
});
 */