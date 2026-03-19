import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kudipay/model/transaction/transaction_model.dart';

class TransactionService {
  final String baseUrl;
  final http.Client client;

  TransactionService({
    required this.baseUrl,
    http.Client? client, String? authToken,
  }) : client = client ?? http.Client();

  /// Fetch all transactions
  Future<List<Transaction>> getTransactions({
    int? limit,
    int? offset,
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      if (status != null) queryParams['status'] = status.value;
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/transactions').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authorization header when available
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw TransactionException(
          'Failed to load transactions: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TransactionException) rethrow;
      throw TransactionException('Network error: ${e.toString()}');
    }
  }

  /// Fetch a single transaction by ID
  Future<Transaction> getTransactionById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Transaction.fromJson(jsonData as Map<String, dynamic>);
      } else {
        throw TransactionException(
          'Failed to load transaction: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TransactionException) rethrow;
      throw TransactionException('Network error: ${e.toString()}');
    }
  }

  /// Search transactions
  Future<List<Transaction>> searchTransactions(String query) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/transactions/search').replace(
          queryParameters: {'q': query},
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw TransactionException(
          'Failed to search transactions: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TransactionException) rethrow;
      throw TransactionException('Network error: ${e.toString()}');
    }
  }

  /// Download transactions (returns file path or download URL)
  Future<String> downloadTransactions({
    String format = 'pdf', // pdf, csv, excel
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, String>{
        'format': format,
      };
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String();
      }

      final response = await client.get(
        Uri.parse('$baseUrl/transactions/download').replace(
          queryParameters: queryParams,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['download_url'] as String;
      } else {
        throw TransactionException(
          'Failed to download transactions: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is TransactionException) rethrow;
      throw TransactionException('Network error: ${e.toString()}');
    }
  }

  void dispose() {
    client.close();
  }
}

class TransactionException implements Exception {
  final String message;
  final int? statusCode;

  TransactionException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
