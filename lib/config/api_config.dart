// lib/config/api_config.dart
// UPDATED: This file is kept for backward compatibility only.
// All new code should import DioClient from lib/config/dio_client.dart.
//
// The old ApiClient (http.Client wrapper) has been superseded by DioClient.
// Services that still reference ApiConfig.baseUrl / ApiConfig.getHeaders()
// continue to compile via the getters below until they are migrated.

import 'package:kudipay/mock/mock_api_data.dart';

export 'package:kudipay/mock/mock_api_data.dart' show kBaseUrl;
export 'package:kudipay/config/dio_client.dart';

class ApiConfig {
  // Deprecated: use kBaseUrl directly or inject DioClient via Riverpod.
  static String get baseUrl => kBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
