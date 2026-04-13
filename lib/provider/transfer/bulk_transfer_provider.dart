import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/mock/mock_api_data.dart';
import 'package:kudipay/model/transfer/bulk_transfer_model.dart';
import 'package:flutter_riverpod/legacy.dart';

class BulkTransferNotifier extends StateNotifier<BulkTransferState> {
  BulkTransferNotifier() : super(BulkTransferState());

  // Add recipient
  void addRecipient(BulkTransferRecipient recipient) {
    state = state.copyWith(
      recipients: [...state.recipients, recipient],
    );
  }

  // Remove recipient
  void removeRecipient(String recipientId) {
    state = state.copyWith(
      recipients: state.recipients.where((r) => r.id != recipientId).toList(),
    );
  }

  // Update recipient
  void updateRecipient(
      String recipientId, BulkTransferRecipient updatedRecipient) {
    final updatedRecipients = state.recipients.map((r) {
      return r.id == recipientId ? updatedRecipient : r;
    }).toList();

    state = state.copyWith(recipients: updatedRecipients);
  }

  // Set distribution type
  void setDistributionType(AmountDistributionType type) {
    state = state.copyWith(distributionType: type);
  }

  // Set amount per recipient (for equal split)
  void setAmountPerRecipient(double amount) {
    state = state.copyWith(amountPerRecipient: amount);
  }

  // Set total amount
  void setTotalAmount(double amount) {
    state = state.copyWith(totalAmount: amount);
  }

  // Set scheduled transfer
  void setScheduledTransfer({
    required bool isScheduled,
    DateTime? date,
    TimeOfDay? time,
  }) {
    state = state.copyWith(
      isScheduled: isScheduled,
      scheduledDate: date,
      scheduledTime: time,
    );
  }

  // Clear all recipients
  void clearRecipients() {
    state = state.copyWith(recipients: []);
  }

  // Reset entire state
  void reset() {
    state = BulkTransferState();
  }

  // Load from template
  void loadFromTemplate(BulkTransferTemplate template) {
    state = state.copyWith(
      recipients: template.recipients,
    );
  }

  // ── Execute bulk transfer ──────────────────────────────────────────────────
  // FIXED: now calls the mock API (swap for real HTTP when backend ready).
  // TODO: Add PIN verification before calling this method — use
  //       TransactionPinBottomSheet.show() from the UI layer.
  Future<void> executeBulkTransfer() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Invalid transfer data');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // ── TODO: Replace with real API call ──────────────────────────────────
      // final response = await ApiService.instance.post(
      //   '/bulk-transfer/execute',
      //   data: {
      //     'recipients': state.recipients.map((r) => r.toJson()).toList(),
      //     'total_amount': state.totalAmount,
      //     'distribution_type': state.distributionType.name,
      //   },
      //   token: authToken,
      // );
      await Future.delayed(const Duration(seconds: 2));
      final result = MockBulkTransferData.executeBulkSuccess(
        totalAmount: state.totalAmount ?? state.calculatedTotalAmount, 
      );

      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        reset();
      } else {
        throw Exception(result['message'] ?? 'Bulk transfer failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// Provider
final bulkTransferProvider =
    StateNotifierProvider<BulkTransferNotifier, BulkTransferState>((ref) {
  return BulkTransferNotifier();
});

// Templates provider (mock data for now)
final bulkTransferTemplatesProvider =
    Provider<List<BulkTransferTemplate>>((ref) {
  return [
    BulkTransferTemplate(
      id: '1',
      name: 'Monthly Staff Salary',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      useCount: 5,
      recipients: [
        BulkTransferRecipient(
          id: '1',
          name: 'John Doe',
          accountType: TransferAccountType.bank,
          accountNumber: '0123456789',
          bankName: 'GTBank',
          amount: 50000,
        ),
        BulkTransferRecipient(
          id: '2',
          name: 'Jane Smith',
          accountType: TransferAccountType.kudikit,
          accountNumber: '8001234567',
          phoneNumber: '+2348001234567',
          amount: 60000,
        ),
      ],
    ),
    BulkTransferTemplate(
      id: '2',
      name: 'Vendor Payments',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      useCount: 3,
      recipients: [
        BulkTransferRecipient(
          id: '3',
          name: 'Vendor A',
          accountType: TransferAccountType.bank,
          accountNumber: '9876543210',
          bankName: 'Access Bank',
          amount: 100000,
        ),
      ],
    ),
  ];
});


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

    // Use centralised mock data — no more hardcoded names in provider files.
    final mock = MockKycData.verifyIdentitySuccess(
      idNumber: idNumber,
      idType: idType,
    );
    return UserVerificationData(
      firstName: mock['first_name'] as String,
      middleName: mock['middle_name'] as String,
      lastName: mock['last_name'] as String,
      fullName: mock['full_name'] as String,
      dateOfBirth: DateTime.parse(mock['date_of_birth'] as String),
      phoneNumber: mock['phone_number'] as String,
      gender: mock['gender'] as String,
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