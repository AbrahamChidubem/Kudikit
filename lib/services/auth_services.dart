import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/model/user/user_model.dart';
import 'package:kudipay/services/storage_services.dart';

class AuthService {
  // TODO: Replace with your actual API base URL
  static const String baseUrl = 'https://api.kudikit.com';

  // Mock Login - Replace with actual API call
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual API call
    // final response = await http.post(
    //   Uri.parse('$baseUrl/auth/login'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'email': email, 'password': password}),
    // );

    // Mock response - Replace with actual API response
    if (email.isNotEmpty && password.length >= 6) {
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

      final user = UserModel(
        userId: userId,
        email: email,
        phoneNumber: '+2348012345678', // Mock data
        name: email.split('@')[0],
        isEmailVerified: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      return {
        'success': true,
        'token': token,
        'user': user.toJson(),
      };
    } else {
      throw Exception('Invalid credentials');
    }
  }

  // Mock Signup - Replace with actual API call
  Future<Map<String, dynamic>> signup({
    required String email,
    required String phoneNumber,
    required String pin,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // TODO: Replace with actual API call
    // final response = await http.post(
    //   Uri.parse('$baseUrl/auth/signup'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({
    //     'email': email,
    //     'phoneNumber': phoneNumber,
    //     'pin': pin,
    //   }),
    // );

    // Mock response
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    return {
      'success': true,
      'userId': userId,
      'message': 'Verification code sent to $email',
    };
  }

  // Mock Email Verification - Replace with actual API call
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String code,
    String phoneNumber = '',
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Replace with actual API call
    // final response = await http.post(
    //   Uri.parse('$baseUrl/auth/verify-email'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'email': email, 'code': code}),
    // );

    // Mock: Accept any 6-digit code
    if (code.length == 6) {
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

      final user = UserModel(
        userId: userId,
        email: email,
        phoneNumber: phoneNumber.isNotEmpty ? phoneNumber : '+234000000000',
        name: email.split('@')[0],
        isEmailVerified: true,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      return {
        'success': true,
        'token': token,
        'user': user.toJson(),
      };
    } else {
      throw Exception('Invalid verification code');
    }
  }

  // Verify token validity
  Future<bool> verifyToken(String token) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call to verify token
    // final response = await http.get(
    //   Uri.parse('$baseUrl/auth/verify-token'),
    //   headers: {'Authorization': 'Bearer $token'},
    // );

    // Mock: All tokens are valid
    return token.isNotEmpty;
  }

  // Update user profile
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

    // TODO: Replace with actual API call
    // Mock: Return updated user
    // This would normally come from your backend
    throw UnimplementedError('Update profile endpoint not implemented');
  }

  final StorageService _storage;

  AuthService(this._storage);

  Future<bool> submitUserInfo(UserInfo userInfo) async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Save user info
      await _storage.saveUserInfo(userInfo);

      // Mock auth token
      await _storage
          .saveAuthToken('mock_token_${DateTime.now().millisecondsSinceEpoch}');

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.clearAuth();
  }

  Future<bool> checkAuthStatus() async {
    return await _storage.isAuthenticated();
  }
}