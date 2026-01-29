import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kudipay/model/user/user.dart';

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://your-api.com', // Replace with your actual production URL
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Standard Login
  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      final user = UserProfile(
        userId: data['user']['id'],
        name: data['user']['name'],
        email: data['user']['email'],
      );

      return LoginResponse(user: user, token: data['token']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// THE NEW VERIFICATION LOGIC
  /// This hits your backend, which verifies the BVN/NIN and returns 
  /// the legal name associated with the ID.
  Future<UserProfile> verifyIdentity({
    required String idNumber,
    required String idType, // 'BVN' or 'NIN'
    required String token,  // Pass the user's auth token
  }) async {
    try {
      final response = await _dio.post(
        '/verify-bvn-nin',
        data: {
          'id_number': idNumber,
          'id_type': idType,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final data = response.data;
      
      // We return a UserProfile with the name fetched from the ID provider
      return UserProfile(
        userId: data['id'], // Likely from your DB
        name: "${data['first_name']} ${data['last_name']}", // Construct full name
        email: data['email'],
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Centralized Error Handling
  Exception _handleError(DioException e) {
    final message = e.response?.data['message'] ?? 'An unexpected error occurred';
    return Exception(message);
  }
}

class LoginResponse {
  final UserProfile user;
  final String token;
  LoginResponse({required this.user, required this.token});
}