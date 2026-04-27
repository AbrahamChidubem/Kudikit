// lib/services/api_services.dart
// FIXED: Renamed TimeoutException → KudiPayTimeoutException to avoid
//        shadowing dart:async's built-in TimeoutException.

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:kudipay/mock/mock_api_data.dart';
import 'package:kudipay/model/user/user.dart';
import 'package:kudipay/services/connectivity_service.dart';

class NoInternetException implements Exception {
  final String message;
  NoInternetException([this.message = 'No internet connection available']);
  @override String toString() => message;
}
class KudiPayTimeoutException implements Exception {
  final String message;
  KudiPayTimeoutException([this.message = 'Request timed out. Please check your internet connection.']);
  @override String toString() => message;
}

class ApiService {
  ApiService._privateConstructor();
  static final ApiService instance = ApiService._privateConstructor();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  );

  final ConnectivityService _connectivityService = ConnectivityService.instance;

  Future<void> _ensureConnected() async {
    final hasInternet = await _connectivityService.hasInternetConnection();
    if (!hasInternet) throw NoInternetException();
  }

  Future<LoginResponse> login(String email, String password) async {
    await _ensureConnected();
    try {
      final response = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      final data = response.data;
      final user = UserProfile(userId: data['user']['id'], name: data['user']['name'], email: data['user']['email']);
      return LoginResponse(user: user, token: data['token']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserProfile> verifyIdentity({required String idNumber, required String idType, required String token}) async {
    await _ensureConnected();
    try {
      final response = await _dio.post(
        '/verify-bvn-nin',
        data: {'id_number': idNumber, 'id_type': idType},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = response.data;
      return UserProfile(
        userId: data['id'],
        name: '${data['first_name']} ${data['last_name']}',
        email: data['email'],
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters, String? token}) async {
    await _ensureConnected();
    try {
      return await _dio.get(endpoint, queryParameters: queryParameters,
          options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null);
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Response> post(String endpoint, {dynamic data, String? token}) async {
    await _ensureConnected();
    try {
      return await _dio.post(endpoint, data: data,
          options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null);
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Response> put(String endpoint, {dynamic data, String? token}) async {
    await _ensureConnected();
    try {
      return await _dio.put(endpoint, data: data,
          options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null);
    } on DioException catch (e) { throw _handleError(e); }
  }

  Future<Response> delete(String endpoint, {String? token}) async {
    await _ensureConnected();
    try {
      return await _dio.delete(endpoint,
          options: token != null ? Options(headers: {'Authorization': 'Bearer $token'}) : null);
    } on DioException catch (e) { throw _handleError(e); }
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return KudiPayTimeoutException();
      case DioExceptionType.connectionError:
        return NoInternetException('Connection failed. Please check your internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'An unexpected error occurred';
        switch (statusCode) {
          case 400: return Exception('Bad request: $message');
          case 401: return Exception('Unauthorized: Please login again');
          case 403: return Exception('Forbidden: You don\'t have permission');
          case 404: return Exception('Not found: $message');
          case 500: return Exception('Server error: Please try again later');
          default:  return Exception(message);
        }
      case DioExceptionType.cancel:
        return Exception('Request was cancelled');
      default:
        return Exception('An unexpected error occurred');
    }
  }

  Future<T> retryRequest<T>(Future<T> Function() request, {int maxRetries = 3, Duration retryDelay = const Duration(seconds: 2)}) async {
    int retries = 0;
    while (retries < maxRetries) {
      try {
        return await request();
      } catch (e) {
        retries++;
        if (retries >= maxRetries) rethrow;
        await Future.delayed(retryDelay);
        final hasConnection = await _connectivityService.hasInternetConnection();
        if (!hasConnection) throw NoInternetException();
      }
    }
    throw Exception('Max retries exceeded');
  }
}

class LoginResponse {
  final UserProfile user;
  final String token;
  LoginResponse({required this.user, required this.token});
}