// class ApiConfig {
//   // Actual backend API URL
//   static const String baseUrl = 'https://api.yourdomain.com/api/v1';
  
//   // Endpoints
//   static const String authUrl = '$baseUrl/auth';
//   static const String coursesUrl = '$baseUrl/courses';
//   static const String topicsUrl = '$baseUrl/topics';
//   static const String questionsUrl = '$baseUrl/questions';
//   static const String quizUrl = '$baseUrl/quiz';
//   static const String userUrl = '$baseUrl/user';

//   // Timeouts
//   static const Duration connectTimeout = Duration(seconds: 30);
//   static const Duration receiveTimeout = Duration(seconds: 30);

//   // Headers
//   static Map<String, String> getHeaders(String? token) {
//     return {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//   }
// }

// lib/config/api_config.dart
// Single source of truth for API configuration.
// All service files MUST import kBaseUrl from mock/mock_api_data.dart.
// This file now re-exports it so existing imports of api_config.dart still compile.



import 'package:kudipay/mock/mock_api_data.dart';

export 'package:kudipay/mock/mock_api_data.dart' show kBaseUrl;

class ApiConfig {
  // Use kBaseUrl everywhere instead of this — kept for backward compatibility.
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