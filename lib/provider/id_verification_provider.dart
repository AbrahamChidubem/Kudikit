// import 'dart:async';
// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// // ==================== MODELS ====================

// class UserVerificationData {
//   final String firstName;
//   final String middleName;
//   final String lastName;
//   final String fullName;
//   final DateTime dateOfBirth;
//   final String phoneNumber;
//   final String? photoUrl;
//   final String gender;
//   final String idNumber; // BVN or NIN
//   final String idType; // 'BVN' or 'NIN'

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
//                 json['fullName'] ?? 
//                 '${json['first_name']} ${json['middle_name']} ${json['last_name']}',
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

// // ==================== STATE ====================

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

// // ==================== NOTIFIER ====================

// class IdentityVerificationNotifier extends StateNotifier<IdentityVerificationState> {
//   final IdentityVerificationService _service;

//   IdentityVerificationNotifier(this._service) 
//       : super(const IdentityVerificationState());

//   Future<void> verifyIdentity({
//     required String idNumber,
//     required dynamic idType, // Can be enum or string
//   }) async {
//     state = state.copyWith(isVerifying: true, clearError: true);

//     try {
//       final idTypeString = idType.toString().split('.').last; // Convert enum to string
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

// // ==================== SERVICE ====================

// class VerificationException implements Exception {
//   final String message;
//   final int? statusCode;

//   VerificationException(this.message, [this.statusCode]);

//   @override
//   String toString() => message;
// }

// class IdentityVerificationService {
//   final String baseUrl;
//   final String? authToken;

//   IdentityVerificationService({
//     required this.baseUrl,
//     this.authToken,
//   });

//   Future<UserVerificationData> verifyIdentity({
//     required String idNumber,
//     required String idType,
//   }) async {
//     // TODO: Replace with your actual API endpoint
//     // final response = await http.post(
//     //   Uri.parse('$baseUrl/verify-identity'),
//     //   headers: {
//     //     'Content-Type': 'application/json',
//     //     if (authToken != null) 'Authorization': 'Bearer $authToken',
//     //   },
//     //   body: jsonEncode({
//     //     'id_number': idNumber,
//     //     'id_type': idType,
//     //   }),
//     // );
//     //
//     // if (response.statusCode == 200) {
//     //   final data = jsonDecode(response.body);
//     //   return UserVerificationData.fromJson(data['user_data']);
//     // } else if (response.statusCode == 404) {
//     //   throw VerificationException('BVN/NIN not found in database', 404);
//     // } else if (response.statusCode == 400) {
//     //   throw VerificationException('Invalid BVN/NIN format', 400);
//     // } else {
//     //   throw VerificationException('Verification failed', response.statusCode);
//     // }

//     // Mock implementation for testing
//     return _mockVerifyIdentity(idNumber, idType);
//   }

//   // Mock verification for testing
//   Future<UserVerificationData> _mockVerifyIdentity(
//     String idNumber,
//     String idType,
//   ) async {
//     // Simulate API delay
//     await Future.delayed(const Duration(seconds: 2));

//     // Validate ID number
//     if (idNumber.length != 11) {
//       throw VerificationException('Invalid $idType format');
//     }

//     // Mock successful verification
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

// // Mock Service Implementation
// class MockIdentityVerificationService extends IdentityVerificationService {
//   MockIdentityVerificationService() : super(baseUrl: 'mock://api');

//   @override
//   Future<UserVerificationData> verifyIdentity({
//     required String idNumber,
//     required String idType,
//   }) async {
//     // Simulate network delay
//     await Future.delayed(const Duration(milliseconds: 1500));

//     // Validate
//     if (idNumber.length != 11) {
//       throw VerificationException('$idType must be 11 digits');
//     }

//     // Return mock data
//     return UserVerificationData(
//       firstName: 'MICHAEL',
//       middleName: 'ASUQUO',
//       lastName: 'TOLUWLASE',
//       fullName: 'MICHAEL ASUQUO TOLUWLASE',
//       dateOfBirth: DateTime(1990, 5, 15),
//       phoneNumber: '08012345678',
//       photoUrl: null,
//       gender: 'Male',
//       idNumber: idNumber,
//       idType: idType,
//     );
//   }
// }

// // ==================== PROVIDER ====================

// final identityVerificationServiceProvider = Provider<IdentityVerificationService>((ref) {
//   // Use mock service for testing
//   return MockIdentityVerificationService();

//   // Use real service in production
//   // return IdentityVerificationService(
//   //   baseUrl: 'https://api.kudipay.com/api/v1',
//   //   authToken: ref.watch(authTokenProvider),
//   // );
// });

// final identityVerificationProvider = StateNotifierProvider<
//     IdentityVerificationNotifier, IdentityVerificationState>((ref) {
//   final service = ref.watch(identityVerificationServiceProvider);
//   return IdentityVerificationNotifier(service);
// });