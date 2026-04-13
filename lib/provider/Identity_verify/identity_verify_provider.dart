// // lib/provider/identity_verify_provider.dart
// // FIXED:
// //   - IdentityVerificationState is declared ONLY here (removed from provider_pack)
// //   - baseUrl replaced with kBaseUrl
// //   - UserVerificationData declared here is canonical (id_verification_services
// //     has its own local copy for standalone use — acceptable while consolidating)

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kudipay/mock/mock_api_data.dart';
// import 'package:kudipay/provider/auth/auth_provider.dart';

// // ── Enums ─────────────────────────────────────────────────────────────────────
// enum IdentificationType { BVN, NIN }

// // ── UserVerificationData ──────────────────────────────────────────────────────
// class UserVerificationData {
//   final String firstName;
//   final String middleName;
//   final String lastName;
//   final String fullName;
//   final DateTime dateOfBirth;
//   final String phoneNumber;
//   final String? photoUrl;
//   final String gender;
//   final String idNumber;
//   final String idType;

//   UserVerificationData({
//     required this.firstName,
//     required this.middleName,
//     required this.lastName,
//     required this.fullName,
//     required this.dateOfBirth,
//     required this.phoneNumber,
//     this.photoUrl,
//     required this.gender,
//     required this.idNumber,
//     required this.idType,
//   });

//   factory UserVerificationData.fromJson(Map<String, dynamic> json) =>
//       UserVerificationData(
//         firstName:   json['first_name']   ?? json['firstName']   ?? '',
//         middleName:  json['middle_name']  ?? json['middleName']  ?? '',
//         lastName:    json['last_name']    ?? json['lastName']    ?? '',
//         fullName:    json['full_name']    ?? json['fullName']    ??
//             '${json['first_name']} ${json['middle_name']} ${json['last_name']}',
//         dateOfBirth: DateTime.parse(json['date_of_birth'] ?? json['dateOfBirth']),
//         phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
//         photoUrl:    json['photo_url']    ?? json['photoUrl'],
//         gender:      json['gender']       ?? '',
//         idNumber:    json['bvn'] ?? json['nin'] ?? json['id_number'] ?? '',
//         idType:      json['id_type']      ?? 'BVN',
//       );

//   Map<String, dynamic> toJson() => {
//     'first_name':  firstName,
//     'middle_name': middleName,
//     'last_name':   lastName,
//     'full_name':   fullName,
//     'date_of_birth': dateOfBirth.toIso8601String(),
//     'phone_number':  phoneNumber,
//     'photo_url':     photoUrl,
//     'gender':        gender,
//     'id_number':     idNumber,
//     'id_type':       idType,
//   };
// }

// // ── VerificationException ─────────────────────────────────────────────────────
// class VerificationException implements Exception {
//   final String message;
//   final int? statusCode;
//   VerificationException(this.message, [this.statusCode]);
//   @override String toString() => message;
// }

// // ── IdentityVerificationState ─────────────────────────────────────────────────
// // CANONICAL definition — provider_pack.dart re-exports this.
// class IdentityVerificationState {
//   final UserVerificationData? verificationData;
//   final bool isVerifying;
//   final String? error;

//   const IdentityVerificationState({
//     this.verificationData,
//     this.isVerifying = false,
//     this.error,
//   });

//   IdentityVerificationState copyWith({
//     UserVerificationData? verificationData,
//     bool? isVerifying,
//     String? error,
//     bool clearError = false,
//   }) => IdentityVerificationState(
//     verificationData: verificationData ?? this.verificationData,
//     isVerifying:      isVerifying      ?? this.isVerifying,
//     error:            clearError ? null : (error ?? this.error),
//   );
// }

// // ── Service ───────────────────────────────────────────────────────────────────
// class IdentityVerificationService {
//   final String baseUrl;
//   final String? authToken;

//   IdentityVerificationService({
//     this.baseUrl = kBaseUrl,   // FIXED: was hardcoded 'https://api.kudipay.com/api/v1'
//     this.authToken,
//   });

//   IdentificationType detectIdType(String input) {
//     if (input.length != 11) throw VerificationException('Invalid ID length. Must be 11 digits.');
//     if (!RegExp(r'^\d+$').hasMatch(input)) throw VerificationException('ID must contain only digits.');
//     return input.startsWith('2') ? IdentificationType.BVN : IdentificationType.NIN;
//   }

//   Future<UserVerificationData> verifyIdentity({required String idNumber, String? idType}) async {
//     try {
//       final detectedType = idType ?? detectIdType(idNumber).name;
//       // ── TODO: Replace with real HTTP call ──────────────────────────────────
//       // POST $baseUrl/kyc/verify-identity  { id_number, id_type }
//       return await _mockVerify(idNumber, detectedType);
//     } on SocketException {
//       throw VerificationException('No internet connection. Please check your network.');
//     } on TimeoutException {
//       throw VerificationException('Request timed out. Please try again.');
//     } on VerificationException {
//       rethrow;
//     } catch (e) {
//       throw VerificationException('Verification error: ${e.toString()}');
//     }
//   }

//   Future<UserVerificationData> _mockVerify(String idNumber, String idType) async {
//     await Future.delayed(const Duration(seconds: 2));
//     if (idNumber.length != 11) throw VerificationException('Invalid $idType format. Must be 11 digits.');
//     if (!RegExp(r'^\d+$').hasMatch(idNumber)) throw VerificationException('$idType must contain only digits.');
//     if (idNumber == '00000000000') throw VerificationException('$idType not found in database', 404);
//     if (idNumber == '11111111111') throw VerificationException('Invalid $idType format', 400);

//     return UserVerificationData.fromJson(
//       MockKycData.verifyIdentitySuccess(idNumber: idNumber, idType: idType),
//     );
//   }
// }

// // ── Notifier ──────────────────────────────────────────────────────────────────
// class IdentityVerificationNotifier extends StateNotifier<IdentityVerificationState> {
//   final IdentityVerificationService _service;
//   IdentityVerificationNotifier(this._service)
//       : super(const IdentityVerificationState());

//   Future<void> verifyIdentity({required String idNumber, String? idType}) async {
//     state = state.copyWith(isVerifying: true, clearError: true);
//     try {
//       final data = await _service.verifyIdentity(idNumber: idNumber, idType: idType);
//       state = state.copyWith(isVerifying: false, verificationData: data);
//     } on VerificationException catch (e) {
//       state = state.copyWith(isVerifying: false, error: e.message);
//     } catch (e) {
//       state = state.copyWith(isVerifying: false, error: e.toString());
//     }
//   }

//   void clearError() => state = state.copyWith(clearError: true);
//   void reset()      => state = const IdentityVerificationState();
// }

// // ── Providers ─────────────────────────────────────────────────────────────────
// final identityVerificationServiceProvider = Provider<IdentityVerificationService>((ref) {
//   final token = ref.watch(authTokenProvider);
//   return IdentityVerificationService(authToken: token);
// });

// final identityVerificationProvider =
//     StateNotifierProvider<IdentityVerificationNotifier, IdentityVerificationState>((ref) {
//   return IdentityVerificationNotifier(ref.watch(identityVerificationServiceProvider));
// });

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:kudipay/provider/auth/auth_provider.dart';

// // ==================== IDENTITY VERIFICATION PROVIDERS ====================

// // Identification Type Enum
// enum IdentificationType {
//   BVN,
//   NIN,
// }

// // User Verification Data Model
// class UserVerificationData {
//   final String firstName;
//   final String middleName;
//   final String lastName;
//   final String fullName;
//   final DateTime dateOfBirth;
//   final String phoneNumber;
//   final String? photoUrl;
//   final String gender;
//   final String idNumber;
//   final String idType;

//   UserVerificationData({
//     required this.firstName,
//     required this.middleName,
//     required this.lastName,
//     required this.fullName,
//     required this.dateOfBirth,
//     required this.phoneNumber,
//     this.photoUrl,
//     required this.gender,
//     required this.idNumber,
//     required this.idType,
//   });

//   factory UserVerificationData.fromJson(Map<String, dynamic> json) {
//     return UserVerificationData(
//       firstName: json['first_name'] ?? json['firstName'] ?? '',
//       middleName: json['middle_name'] ?? json['middleName'] ?? '',
//       lastName: json['last_name'] ?? json['lastName'] ?? '',
//       fullName: json['full_name'] ??
//           json['fullName'] ??
//           '${json['first_name']} ${json['middle_name']} ${json['last_name']}',
//       dateOfBirth: DateTime.parse(json['date_of_birth'] ?? json['dateOfBirth']),
//       phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
//       photoUrl: json['photo_url'] ?? json['photoUrl'],
//       gender: json['gender'] ?? '',
//       idNumber: json['bvn'] ?? json['nin'] ?? json['id_number'] ?? '',
//       idType: json['id_type'] ?? 'BVN',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'first_name': firstName,
//       'middle_name': middleName,
//       'last_name': lastName,
//       'full_name': fullName,
//       'date_of_birth': dateOfBirth.toIso8601String(),
//       'phone_number': phoneNumber,
//       'photo_url': photoUrl,
//       'gender': gender,
//       'id_number': idNumber,
//       'id_type': idType,
//     };
//   }
// }

// // Identity Verification State
// class IdentityVerificationState {
//   final UserVerificationData? verificationData;
//   final bool isVerifying;
//   final String? error;

//   const IdentityVerificationState({
//     this.verificationData,
//     this.isVerifying = false,
//     this.error,
//   });

//   IdentityVerificationState copyWith({
//     UserVerificationData? verificationData,
//     bool? isVerifying,
//     String? error,
//     bool clearError = false,
//   }) {
//     return IdentityVerificationState(
//       verificationData: verificationData ?? this.verificationData,
//       isVerifying: isVerifying ?? this.isVerifying,
//       error: clearError ? null : (error ?? this.error),
//     );
//   }
// }

// // Verification Exception
// class VerificationException implements Exception {
//   final String message;
//   final int? statusCode;

//   VerificationException(this.message, [this.statusCode]);

//   @override
//   String toString() => message;
// }

// // Identity Verification Service
// class IdentityVerificationService {
//   final String baseUrl;
//   final String? authToken;

//   IdentityVerificationService({
//     required this.baseUrl,
//     this.authToken,
//   });

//   // Detect if input is BVN or NIN
//   IdentificationType detectIdType(String input) {
//     if (input.length != 11) {
//       throw VerificationException('Invalid ID length. Must be 11 digits.');
//     }

//     if (input.startsWith('2')) {
//       return IdentificationType.BVN;
//     } else {
//       return IdentificationType.NIN;
//     }
//   }

//   Future<UserVerificationData> verifyIdentity({
//     required String idNumber,
//     String? idType,
//   }) async {
//     final detectedIdType = idType ?? detectIdType(idNumber).name;

//     // Mock implementation for testing
//     return _mockVerifyIdentity(idNumber, detectedIdType);

//     // TODO: Replace with real API call
//   }

//   Future<UserVerificationData> _mockVerifyIdentity(
//     String idNumber,
//     String idType,
//   ) async {
//     await Future.delayed(const Duration(seconds: 2));

//     if (idNumber.length != 11) {
//       throw VerificationException('Invalid $idType format');
//     }

//     return UserVerificationData(
//       firstName: 'MICHAEL',
//       middleName: 'ASUQUO',
//       lastName: 'TOLUWLASE',
//       fullName: 'MICHAEL ASUQUO TOLUWLASE',
//       dateOfBirth: DateTime(1990, 5, 15),
//       phoneNumber: '08012345678',
//       gender: 'Male',
//       idNumber: idNumber,
//       idType: idType,
//     );
//   }
// }

// // Identity Verification Notifier
// class IdentityVerificationNotifier
//     extends StateNotifier<IdentityVerificationState> {
//   final IdentityVerificationService _service;

//   IdentityVerificationNotifier(this._service)
//       : super(const IdentityVerificationState());

//   Future<void> verifyIdentity({
//     required String idNumber,
//     dynamic idType,
//   }) async {
//     state = state.copyWith(isVerifying: true, clearError: true);

//     try {
//       String? idTypeString;
//       if (idType != null) {
//         idTypeString = idType.toString().contains('.')
//             ? idType.toString().split('.').last
//             : idType.toString();
//       }

//       final verificationData = await _service.verifyIdentity(
//         idNumber: idNumber,
//         idType: idTypeString,
//       );

//       state = state.copyWith(
//         verificationData: verificationData,
//         isVerifying: false,
//       );
//     } on SocketException {
//       state = state.copyWith(
//         isVerifying: false,
//         error: 'No internet connection. Please check your network.',
//       );
//     } on TimeoutException {
//       state = state.copyWith(
//         isVerifying: false,
//         error: 'Request timed out. Please try again.',
//       );
//     } on VerificationException catch (e) {
//       state = state.copyWith(
//         isVerifying: false,
//         error: e.message,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isVerifying: false,
//         error: 'Verification failed. Please try again.',
//       );
//     }
//   }

//   void clearError() {
//     state = state.copyWith(clearError: true);
//   }

//   void reset() {
//     state = const IdentityVerificationState();
//   }
// }

// // Identity Verification Service Provider
// final identityVerificationServiceProvider =
//     Provider<IdentityVerificationService>((ref) {
//   final authToken = ref.watch(authTokenProvider);
//   return IdentityVerificationService(
//     baseUrl: 'https://api.kudipay.com/api/v1',
//     authToken: authToken,
//   );
// });

// // Identity Verification Provider
// final identityVerificationProvider = StateNotifierProvider<
//     IdentityVerificationNotifier, IdentityVerificationState>((ref) {
//   final service = ref.watch(identityVerificationServiceProvider);
//   return IdentityVerificationNotifier(service);
// });

// // ==================== REGISTRATION PROVIDER ====================

// class RegistrationState {
//   final String? email;
//   final String? phone;
//   final String? password;
//   final UserVerificationData? verificationData;
//   final bool isVerifying;
//   final bool isRegistering;
//   final String? error;

//   const RegistrationState({
//     this.email,
//     this.phone,
//     this.password,
//     this.verificationData,
//     this.isVerifying = false,
//     this.isRegistering = false,
//     this.error,
//   });

//   RegistrationState copyWith({
//     String? email,
//     String? phone,
//     String? password,
//     UserVerificationData? verificationData,
//     bool? isVerifying,
//     bool? isRegistering,
//     String? error,
//     bool clearError = false,
//   }) {
//     return RegistrationState(
//       email: email ?? this.email,
//       phone: phone ?? this.phone,
//       password: password ?? this.password,
//       verificationData: verificationData ?? this.verificationData,
//       isVerifying: isVerifying ?? this.isVerifying,
//       isRegistering: isRegistering ?? this.isRegistering,
//       error: clearError ? null : (error ?? this.error),
//     );
//   }
// }

// class RegistrationNotifier extends StateNotifier<RegistrationState> {
//   final IdentityVerificationService _verificationService;

//   RegistrationNotifier(this._verificationService)
//       : super(const RegistrationState());

//   void setEmail(String email) {
//     state = state.copyWith(email: email);
//   }

//   void setPhone(String phone) {
//     state = state.copyWith(phone: phone);
//   }

//   void setPassword(String password) {
//     state = state.copyWith(password: password);
//   }

//   Future<void> verifyIdentity(String idNumber) async {
//     state = state.copyWith(isVerifying: true, clearError: true);

//     try {
//       final verificationData = await _verificationService.verifyIdentity(
//         idNumber: idNumber,
//       );

//       state = state.copyWith(
//         verificationData: verificationData,
//         isVerifying: false,
//       );
//     } on SocketException {
//       state = state.copyWith(
//         isVerifying: false,
//         error: 'No internet connection. Please check your network.',
//       );
//     } on TimeoutException {
//       state = state.copyWith(
//         isVerifying: false,
//         error: 'Request timed out. Please try again.',
//       );
//     } on VerificationException catch (e) {
//       state = state.copyWith(
//         isVerifying: false,
//         error: e.message,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         isVerifying: false,
//         error: 'Verification failed: ${e.toString()}',
//       );
//     }
//   }

//   Future<void> completeRegistration() async {
//     if (state.email == null ||
//         state.password == null ||
//         state.verificationData == null) {
//       state = state.copyWith(
//         error: 'Missing required registration information',
//       );
//       return;
//     }

//     state = state.copyWith(isRegistering: true, clearError: true);

//     try {
//       // TODO: Replace with actual user creation logic
//       // Mock delay
//       await Future.delayed(const Duration(seconds: 2));

//       state = state.copyWith(isRegistering: false);
//     } catch (e) {
//       state = state.copyWith(
//         isRegistering: false,
//         error: 'Registration failed: ${e.toString()}',
//       );
//     }
//   }

//   void clearError() {
//     state = state.copyWith(clearError: true);
//   }

//   void reset() {
//     state = const RegistrationState();
//   }
// }

// final registrationProvider =
//     StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
//   final service = ref.watch(identityVerificationServiceProvider);
//   return RegistrationNotifier(service);
// });

// lib/provider/identity_verify/identity_verify_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/mock/mock_api_data.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:flutter_riverpod/legacy.dart';
// ── Enum ──────────────────────────────────────────────────────────────────────
// Single canonical enum for the entire app.
// Use .name to get "BVN" or "NIN" when serialising for API calls.
enum IdentificationType {
  BVN,
  NIN;

  /// Human-readable label shown in the UI
  String get displayLabel => name;

  /// Serialised value sent to the API (lowercase if your backend expects it)
  String get apiValue => name; // change to name.toLowerCase() if needed
}

// ── UserVerificationData ──────────────────────────────────────────────────────
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
  final IdentificationType idType; // ← strong-typed, not String

  const UserVerificationData({
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
    final rawType =
        (json['id_type'] ?? json['idType'] ?? 'BVN').toString().toUpperCase();
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
      idType: IdentificationType.values.firstWhere(
        (e) => e.name == rawType,
        orElse: () => IdentificationType.BVN,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'middle_name': middleName,
        'last_name': lastName,
        'full_name': fullName,
        'date_of_birth': dateOfBirth.toIso8601String(),
        'phone_number': phoneNumber,
        'photo_url': photoUrl,
        'gender': gender,
        'id_number': idNumber,
        'id_type': idType.apiValue, // serialise only at the boundary
      };
}

// ── VerificationException ─────────────────────────────────────────────────────
class VerificationException implements Exception {
  final String message;
  final int? statusCode;
  const VerificationException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

// ── IdentityVerificationState ─────────────────────────────────────────────────
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
  }) =>
      IdentityVerificationState(
        verificationData: verificationData ?? this.verificationData,
        isVerifying: isVerifying ?? this.isVerifying,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── Service ───────────────────────────────────────────────────────────────────
class IdentityVerificationService {
  final String baseUrl;
  final String? authToken;

  const IdentityVerificationService({
    this.baseUrl = kBaseUrl,
    this.authToken,
  });

  /// Verifies identity using a strongly-typed [IdentificationType].
  /// Serialisation to String happens here — the last possible moment.
  Future<UserVerificationData> verifyIdentity({
    required String idNumber,
    required IdentificationType idType, // ← strong-typed
  }) async {
    try {
      _validateIdNumber(idNumber, idType);
      // ── TODO: Replace with real HTTP call ────────────────────────────────
      // final response = await http.post(
      //   Uri.parse('$baseUrl/kyc/verify-identity'),
      //   headers: {'Authorization': 'Bearer $authToken'},
      //   body: jsonEncode({'id_number': idNumber, 'id_type': idType.apiValue}),
      // );
      return await _mockVerify(idNumber, idType);
    } on SocketException {
      throw const VerificationException(
          'No internet connection. Please check your network.');
    } on TimeoutException {
      throw const VerificationException('Request timed out. Please try again.');
    } on VerificationException {
      rethrow;
    } catch (e) {
      throw VerificationException('Verification error: $e');
    }
  }

  void _validateIdNumber(String idNumber, IdentificationType idType) {
    if (idNumber.length != 11) {
      throw VerificationException(
          '${idType.displayLabel} must be exactly 11 digits.');
    }
    if (!RegExp(r'^\d+$').hasMatch(idNumber)) {
      throw VerificationException(
          '${idType.displayLabel} must contain only digits.');
    }
  }

  Future<UserVerificationData> _mockVerify(
    String idNumber,
    IdentificationType idType,
  ) async {
    await Future.delayed(const Duration(seconds: 2));
    if (idNumber == '00000000000') {
      throw VerificationException(
          '${idType.displayLabel} not found in database.', 404);
    }
    if (idNumber == '11111111111') {
      throw VerificationException(
          'Invalid ${idType.displayLabel} format.', 400);
    }
    return UserVerificationData.fromJson(
      MockKycData.verifyIdentitySuccess(
        idNumber: idNumber,
        idType: idType.apiValue, // serialise here for mock/API layer
      ),
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class IdentityVerificationNotifier
    extends StateNotifier<IdentityVerificationState> {
  final IdentityVerificationService _service;

  IdentityVerificationNotifier(this._service)
      : super(const IdentityVerificationState());

  Future<void> verifyIdentity({
    required String idNumber,
    required IdentificationType idType, // ← strong-typed
  }) async {
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final data = await _service.verifyIdentity(
        idNumber: idNumber,
        idType: idType,
      );
      state = state.copyWith(isVerifying: false, verificationData: data);
    } on VerificationException catch (e) {
      state = state.copyWith(isVerifying: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isVerifying: false, error: e.toString());
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const IdentityVerificationState();
}

// ── Providers ─────────────────────────────────────────────────────────────────
// ── Providers ─────────────────────────────────────────────────────────────────
final identityVerificationServiceProvider =
    Provider<IdentityVerificationService>((ref) {
  final token = ref.watch(authTokenProvider);
  return IdentityVerificationService(authToken: token);
});

final identityVerificationProvider = StateNotifierProvider<
    IdentityVerificationNotifier, IdentityVerificationState>((ref) {
  return IdentityVerificationNotifier(
    ref.watch(identityVerificationServiceProvider),
  );
});
