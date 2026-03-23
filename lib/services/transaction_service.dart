import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kudipay/mock/mock_api_data.dart';
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
    // ── Mock implementation ───────────────────────────────────────────────────
    // Returns data from MockTransactionData so the Transactions screen is never
    // empty during development. Replace with the real HTTP block below when
    // the backend is ready.
    return _mockGetTransactions(status: status);

    // ── Real implementation ───────────────────────────────────────────────────
    // try {
    //   final queryParams = <String, String>{};
    //   if (limit != null) queryParams['limit'] = limit.toString();
    //   if (offset != null) queryParams['offset'] = offset.toString();
    //   if (status != null) queryParams['status'] = status.value;
    //   if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    //   if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    //
    //   final uri = Uri.parse('$baseUrl/transactions').replace(
    //     queryParameters: queryParams.isNotEmpty ? queryParams : null,
    //   );
    //   final response = await client.get(uri, headers: {
    //     'Content-Type': 'application/json',
    //     'Accept': 'application/json',
    //   });
    //   if (response.statusCode == 200) {
    //     final body = json.decode(response.body);
    //     final List<dynamic> list = body is List ? body : body['transactions'] as List;
    //     return list.map((j) => Transaction.fromJson(j as Map<String, dynamic>)).toList();
    //   } else {
    //     throw TransactionException('Failed to load transactions: ${response.statusCode}', statusCode: response.statusCode);
    //   }
    // } catch (e) {
    //   if (e is TransactionException) rethrow;
    //   throw TransactionException('Network error: ${e.toString()}');
    // }
  }

  // ---------------------------------------------------------------------------
  // Mock helper — parses MockTransactionData.transactionListResponse
  // ---------------------------------------------------------------------------
  Future<List<Transaction>> _mockGetTransactions({TransactionStatus? status}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final raw = MockTransactionData.transactionListResponse['transactions'] as List<dynamic>;
    final all = raw.map((j) => Transaction.fromJson(j as Map<String, dynamic>)).toList();
    if (status == null) return all;
    return all.where((t) => t.status.value == status.value).toList();
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
    // Search within mock data
    final all = await _mockGetTransactions();
    final q = query.toLowerCase();
    return all.where((t) =>
      t.title.toLowerCase().contains(q) ||
      t.id.toLowerCase().contains(q)
    ).toList();
  }

  /// Download transactions (returns file path or download URL)
  Future<String> downloadTransactions({
    String format = 'pdf',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Return mock download URL from MockTransactionData
    await Future.delayed(const Duration(milliseconds: 500));
    return MockTransactionData.downloadResponse['download_url'] as String;
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
