import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:kudipay/config/api_config.dart';



class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      debugPrint('GET: $url');

      final response = await _client
          .get(url, headers: ApiConfig.getHeaders(_authToken))
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timeout. Please try again.');
    } catch (e) {
      debugPrint('GET Error: $e');
      throw ApiException('An error occurred: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      debugPrint('POST: $url');

      final response = await _client
          .post(
            url,
            headers: ApiConfig.getHeaders(_authToken),
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No internet connection');
    } on TimeoutException {
      throw ApiException('Request timeout. Please try again.');
    } catch (e) {
      debugPrint('POST Error: $e');
      throw ApiException('An error occurred: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    debugPrint('Response Status: ${response.statusCode}');

    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);

      case 400:
        throw ApiException(
          _getErrorMessage(response.body, 'Bad request'),
          400,
        );

      case 401:
        throw ApiException(
          _getErrorMessage(response.body, 'Unauthorized. Please login again.'),
          401,
        );

      case 404:
        throw ApiException(
          _getErrorMessage(response.body, 'Resource not found'),
          404,
        );

      case 500:
        throw ApiException('Server error. Please try again later.', 500);

      default:
        throw ApiException(
          'Something went wrong. Status code: ${response.statusCode}',
          response.statusCode,
        );
    }
  }

  String _getErrorMessage(String responseBody, String defaultMessage) {
    try {
      final data = jsonDecode(responseBody);
      return data['message'] ?? data['error'] ?? defaultMessage;
    } catch (e) {
      return defaultMessage;
    }
  }
}
