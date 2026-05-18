// lib/provider/identity_verify/identity_verify_provider.dart

import 'package:kudipay/config/dio_client.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/providers/core_providers.dart';

// ── Enum ──────────────────────────────────────────────────────────────────────
enum IdentificationType {
  BVN,
  NIN;

  String get displayLabel => name;
  String get apiValue => name;
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
  final IdentificationType idType;

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
        'id_type': idType.apiValue,
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

// ── Notifier ──────────────────────────────────────────────────────────────────
class IdentityVerificationNotifier
    extends StateNotifier<IdentityVerificationState> {
  final DioClient _client;

  IdentityVerificationNotifier(this._client)
      : super(const IdentityVerificationState());

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

  Future<void> verifyIdentity({
    required String idNumber,
    required IdentificationType idType,
  }) async {
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      _validateIdNumber(idNumber, idType);

      final response = await _client.post<Map<String, dynamic>>(
        '/kyc/verify-identity',
        data: {
          'id_number': idNumber,
          'id_type': idType.apiValue,
        },
      );

      final data = UserVerificationData.fromJson(response.data!);
      state = state.copyWith(isVerifying: false, verificationData: data);
    } on KudiApiException catch (e) {
      state = state.copyWith(isVerifying: false, error: e.message);
    } on VerificationException catch (e) {
      state = state.copyWith(isVerifying: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: 'Verification failed. Please try again.',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const IdentityVerificationState();
}

// ── Providers ─────────────────────────────────────────────────────────────────
final identityVerificationProvider = StateNotifierProvider<
    IdentityVerificationNotifier, IdentityVerificationState>((ref) {
  return IdentityVerificationNotifier(ref.read(dioClientProvider));
});