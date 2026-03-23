

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:kudipay/mock/mock_api_data.dart';


enum IdentificationType {
  BVN,
  NIN,
}

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

class VerificationException implements Exception {
  final String message;
  final int? statusCode;

  VerificationException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class IdentityVerificationService {
  final String baseUrl;
  final String? authToken;
  
  IdentityVerificationService({
    this.baseUrl = 'https://api.kudipay.com/api/v1',
    this.authToken,
  });
  
  /// Detect if input is BVN or NIN based on pattern
  /// BVN: Always 11 digits, typically starts with 2
  /// NIN: Always 11 digits, various patterns
  IdentificationType detectIdType(String input) {
    if (input.length != 11) {
      throw VerificationException('Invalid ID length. Must be 11 digits.');
    }
    
    if (!RegExp(r'^\d+$').hasMatch(input)) {
      throw VerificationException('ID must contain only digits.');
    }
    
    // BVN typically starts with 2, but this is simplified logic
    // Adjust based on actual requirements from your backend
    if (input.startsWith('2')) {
      return IdentificationType.BVN;
    } else {
      return IdentificationType.NIN;
    }
  }
  
  /// Verify identity using BVN or NIN
  /// Automatically detects the ID type if not provided
  Future<UserVerificationData> verifyIdentity({
    required String idNumber,
    String? idType,
  }) async {
    try {
      // Auto-detect ID type if not provided
      final detectedIdType = idType ?? detectIdType(idNumber).name;
      
      // For now, using mock implementation
      // TODO: Replace with actual API call when backend is ready
      return await _mockVerifyIdentity(idNumber, detectedIdType);
      
      // Uncomment this when you have the actual backend endpoint
      /*
      final response = await http.post(
        Uri.parse('$baseUrl/verify-identity'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'id_number': idNumber,
          'id_type': detectedIdType,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserVerificationData.fromJson(data['user_data']);
      } else if (response.statusCode == 404) {
        throw VerificationException('BVN/NIN not found in database', 404);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw VerificationException(
          error['message'] ?? 'Invalid BVN/NIN format', 
          400,
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw VerificationException('Unauthorized. Please login again.', response.statusCode);
      } else {
        throw VerificationException(
          'Verification failed with status ${response.statusCode}',
          response.statusCode,
        );
      }
      */
    } on SocketException {
      throw VerificationException('No internet connection. Please check your network.');
    } on TimeoutException {
      throw VerificationException('Request timed out. Please try again.');
    } on VerificationException {
      rethrow;
    } catch (e) {
      throw VerificationException('Verification error: ${e.toString()}');
    }
  }
  
  /// Mock implementation for testing
  /// Replace this with actual API call when backend is ready
  Future<UserVerificationData> _mockVerifyIdentity(
    String idNumber,
    String idType,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Validate format
    if (idNumber.length != 11) {
      throw VerificationException('Invalid $idType format. Must be 11 digits.');
    }

    if (!RegExp(r'^\d+$').hasMatch(idNumber)) {
      throw VerificationException('$idType must contain only digits.');
    }

    // Simulate different responses based on ID number for testing
    // You can customize this for different test scenarios
    if (idNumber == '00000000000') {
      throw VerificationException('$idType not found in database', 404);
    }

    if (idNumber == '11111111111') {
      throw VerificationException('Invalid $idType format', 400);
    }

    // Return mock successful verification using centralised MockKycData
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