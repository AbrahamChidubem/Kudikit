// lib/services/identity_verification_service.dart

import 'dart:convert';
import 'dart:io';

import 'package:kudipay/model/user/user_verfication.dart';
import 'package:kudipay/provider/provider.dart';

class IdentityVerificationService {
  final String baseUrl = 'https://api.yourbackend.com/v1';
  
  // Detect if input is BVN or NIN
  IdentificationType detectIdType(String input) {
    // BVN: Always 11 digits, starts with 2
    // NIN: Always 11 digits, various patterns
    
    if (input.length != 11) {
      throw Exception('Invalid ID length');
    }
    
    // This is simplified - actual logic may vary
    if (input.startsWith('2')) {
      return IdentificationType.BVN;
    } else {
      return IdentificationType.NIN;
    }
  }
  
  Future<UserVerificationData> verifyIdentity(String idNumber) async {
    try {
      final idType = detectIdType(idNumber);
      
      final response = await http.post(
        Uri.parse('$baseUrl/verify-identity'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode({
          'id_number': idNumber,
          'id_type': idType.name,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserVerificationData.fromJson(data['user_data']);
      } else if (response.statusCode == 404) {
        throw Exception('BVN/NIN not found in database');
      } else if (response.statusCode == 400) {
        throw Exception('Invalid BVN/NIN format');
      } else {
        throw Exception('Verification failed');
      }
    } on SocketException {
      throw Exception('No internet connection');
    } catch (e) {
      throw Exception('Verification error: $e');
    }
  }
}