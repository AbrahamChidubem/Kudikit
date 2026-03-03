// ============================================================================
// lib/services/bills_service.dart
//
// Handles all Airtime & Data purchase API calls for KudiPay.
//
// ─── BACKEND INTEGRATION GUIDE ─────────────────────────────────────────────
// Recommended Nigerian VTU (Virtual Top-Up) providers:
//
//  1. VTpass       → https://vtpass.com/documentation
//     Most widely used. Supports all 4 networks.
//     Auth: API key in header. Service IDs: "mtn", "airtel", "glo", "etisalat"
//
//  2. Flutterwave Bills API → https://developer.flutterwave.com/docs
//     POST https://api.flutterwave.com/v3/bills
//     { country:"NG", customer:"0803...", amount:500, type:"AIRTIME",
//       recurrence:"ONCE", reference:"KD123..." }
//
//  3. Paystack → https://paystack.com/docs/bills-payments
//     Similar structure to Flutterwave.
//
//  4. Nellobytes / Clubkonnect / SmileRecharge (cheaper wholesale VTU rates)
//
// Replace _mock* methods with real HTTP calls when your backend is ready.
// All mock implementations below are production-ready in structure.
// ============================================================================

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:kudipay/model/bill/bill_model.dart';


// ============================================================================
// BillsException
// ============================================================================

class BillsException implements Exception {
  final String message;
  final int? statusCode;

  BillsException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

// ============================================================================
// BillsService
// ============================================================================

class BillsService {
  final String baseUrl;
  final String? authToken;

  BillsService({
    required this.baseUrl,
    this.authToken,
  });

  // ---------------------------------------------------------------------------
  // HEADERS
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // ---------------------------------------------------------------------------
  // NETWORK DETECTION
  //
  // Detects the Nigerian mobile network from a phone number.
  // Handles: +234xxx, 234xxx, 0xxx formats.
  // Checks 5-char prefixes before 4-char to avoid false matches.
  // ---------------------------------------------------------------------------

  NetworkProvider? detectNetwork(String phoneNumber) {
    String normalized = phoneNumber.replaceAll(' ', '').replaceAll('-', '');

    // Normalize to local 0xxx format
    if (normalized.startsWith('+234') && normalized.length >= 4) {
      normalized = '0${normalized.substring(4)}';
    } else if (normalized.startsWith('234') && normalized.length >= 4) {
      normalized = '0${normalized.substring(3)}';
    }

    if (normalized.length < 4) return null;

    // Check longer prefixes first (avoids e.g. 0703 matching before 07031)
    for (final network in nigeriaMobileNetworks) {
      for (final prefix in network.prefixes.where((p) => p.length == 5)) {
        if (normalized.startsWith(prefix)) return network.provider;
      }
    }
    for (final network in nigeriaMobileNetworks) {
      for (final prefix in network.prefixes.where((p) => p.length == 4)) {
        if (normalized.startsWith(prefix)) return network.provider;
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // AIRTIME PURCHASE
  //
  // POST $baseUrl/bills/airtime
  // Body: { phone_number, network, amount, request_id }
  //
  // VTpass equivalent:
  //   POST https://vtpass.com/api/pay
  //   { serviceID, phone, amount, request_id }
  // ---------------------------------------------------------------------------

  Future<AirtimePurchaseResponse> buyAirtime(AirtimePurchaseRequest request) async {
    return _mockBuyAirtime(request);

    // ── Real implementation ──────────────────────────────────────────────
    // try {
    //   final response = await http.post(
    //     Uri.parse('$baseUrl/bills/airtime'),
    //     headers: _headers,
    //     body: jsonEncode({
    //       ...request.toJson(),
    //       'request_id': _generateRequestId(),
    //     }),
    //   ).timeout(const Duration(seconds: 30));
    //
    //   final data = jsonDecode(response.body) as Map<String, dynamic>;
    //
    //   if (response.statusCode == 200 || response.statusCode == 201) {
    //     return AirtimePurchaseResponse.fromJson(data);
    //   } else {
    //     throw BillsException(
    //       data['message'] ?? 'Airtime purchase failed',
    //       response.statusCode,
    //     );
    //   }
    // } on SocketException {
    //   throw BillsException('No internet connection. Please check your network.');
    // } on TimeoutException {
    //   throw BillsException('Request timed out. Please try again.');
    // } catch (e) {
    //   if (e is BillsException) rethrow;
    //   throw BillsException('Airtime purchase failed. Please try again.');
    // }
  }

  Future<AirtimePurchaseResponse> _mockBuyAirtime(AirtimePurchaseRequest request) async {
    await Future.delayed(const Duration(seconds: 2));
    return AirtimePurchaseResponse(
      success: true,
      transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      message: 'Airtime purchase successful',
      amount: request.amount,
      phoneNumber: request.phoneNumber,
      network: request.network.name.toUpperCase(),
      createdAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // DATA PLANS
  //
  // GET $baseUrl/bills/data/plans?network=MTN
  // Response: { "plans": [ { id, name, price, validity, ... }, ... ] }
  //
  // NOTE: Plans are loaded fresh when the user selects a network on DataPhoneScreen.
  // The mock below contains realistic 2024 Nigerian carrier plan catalogues.
  // ---------------------------------------------------------------------------

  Future<List<DataPlan>> getDataPlans(NetworkProvider network) async {
    return _mockGetDataPlans(network);

    // ── Real implementation ──────────────────────────────────────────────
    // try {
    //   final response = await http.get(
    //     Uri.parse('$baseUrl/bills/data/plans?network=${network.name.toUpperCase()}'),
    //     headers: _headers,
    //   ).timeout(const Duration(seconds: 30));
    //
    //   final data = jsonDecode(response.body) as Map<String, dynamic>;
    //   if (response.statusCode == 200) {
    //     final list = data['plans'] as List<dynamic>;
    //     return list.map((p) => DataPlan.fromJson(p as Map<String, dynamic>)).toList();
    //   } else {
    //     throw BillsException(
    //       data['message'] ?? 'Failed to load data plans',
    //       response.statusCode,
    //     );
    //   }
    // } on SocketException {
    //   throw BillsException('No internet connection.');
    // } catch (e) {
    //   if (e is BillsException) rethrow;
    //   throw BillsException('Failed to load data plans. Please try again.');
    // }
  }

  Future<List<DataPlan>> _mockGetDataPlans(NetworkProvider network) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final Map<NetworkProvider, List<DataPlan>> catalogue = {
      // ── MTN Nigeria ────────────────────────────────────────────────────
      NetworkProvider.mtn: [
        // Daily
        DataPlan(id: 'mtn_100mb_1d',   name: '100MB',  price: 100,  validity: DataValidity.daily,   validityLabel: '1 Day',   description: '100MB • Valid for 1 Day',    network: NetworkProvider.mtn),
        DataPlan(id: 'mtn_200mb_3d',   name: '200MB',  price: 200,  validity: DataValidity.daily,   validityLabel: '3 Days',  description: '200MB • Valid for 3 Days',   network: NetworkProvider.mtn),
        // Weekly
        DataPlan(id: 'mtn_500mb_7d',   name: '500MB',  price: 300,  validity: DataValidity.weekly,  validityLabel: '7 Days',  description: '500MB • Valid for 7 Days',   network: NetworkProvider.mtn),
        DataPlan(id: 'mtn_1gb_7d',     name: '1GB',    price: 500,  validity: DataValidity.weekly,  validityLabel: '7 Days',  description: '1GB • Valid for 7 Days',     network: NetworkProvider.mtn),
        // Monthly
        DataPlan(id: 'mtn_1gb_30d',    name: '1GB',    price: 1000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '1GB • Valid for 30 Days',    network: NetworkProvider.mtn),
        DataPlan(id: 'mtn_2gb_30d',    name: '2GB',    price: 1500, validity: DataValidity.monthly, validityLabel: '30 Days', description: '2GB • Valid for 30 Days',    network: NetworkProvider.mtn),
        DataPlan(id: 'mtn_3gb_30d',    name: '3GB',    price: 2000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '3GB • Valid for 30 Days',    network: NetworkProvider.mtn),
        DataPlan(id: 'mtn_5gb_30d',    name: '5GB',    price: 3000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '5GB • Valid for 30 Days',    network: NetworkProvider.mtn),
        DataPlan(id: 'mtn_10gb_30d',   name: '10GB',   price: 5000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '10GB • Valid for 30 Days',   network: NetworkProvider.mtn),
        DataPlan(id: 'mtn_20gb_30d',   name: '20GB',   price: 8000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '20GB • Valid for 30 Days',   network: NetworkProvider.mtn),
      ],

      // ── Airtel Nigeria ─────────────────────────────────────────────────
      NetworkProvider.airtel: [
        // Daily
        DataPlan(id: 'airtl_100mb_1d',  name: '100MB',  price: 100,  validity: DataValidity.daily,   validityLabel: '1 Day',   description: '100MB • Valid for 1 Day',    network: NetworkProvider.airtel),
        DataPlan(id: 'airtl_200mb_3d',  name: '200MB',  price: 200,  validity: DataValidity.daily,   validityLabel: '3 Days',  description: '200MB • Valid for 3 Days',   network: NetworkProvider.airtel),
        // Weekly
        DataPlan(id: 'airtl_300mb_7d',  name: '300MB',  price: 300,  validity: DataValidity.weekly,  validityLabel: '7 Days',  description: '300MB • Valid for 7 Days',   network: NetworkProvider.airtel),
        DataPlan(id: 'airtl_750mb_14d', name: '750MB',  price: 500,  validity: DataValidity.weekly,  validityLabel: '14 Days', description: '750MB • Valid for 14 Days',  network: NetworkProvider.airtel),
        // Monthly
        DataPlan(id: 'airtl_1_5gb_30d', name: '1.5GB',  price: 1000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '1.5GB • Valid for 30 Days',  network: NetworkProvider.airtel),
        DataPlan(id: 'airtl_3gb_30d',   name: '3GB',    price: 1500, validity: DataValidity.monthly, validityLabel: '30 Days', description: '3GB • Valid for 30 Days',    network: NetworkProvider.airtel),
        DataPlan(id: 'airtl_6gb_30d',   name: '6GB',    price: 2500, validity: DataValidity.monthly, validityLabel: '30 Days', description: '6GB • Valid for 30 Days',    network: NetworkProvider.airtel),
        DataPlan(id: 'airtl_10gb_30d',  name: '10GB',   price: 3500, validity: DataValidity.monthly, validityLabel: '30 Days', description: '10GB • Valid for 30 Days',   network: NetworkProvider.airtel),
        DataPlan(id: 'airtl_15gb_30d',  name: '15GB',   price: 4000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '15GB • Valid for 30 Days',   network: NetworkProvider.airtel),
      ],

      // ── Glo Nigeria ────────────────────────────────────────────────────
      NetworkProvider.glo: [
        // Daily
        DataPlan(id: 'glo_50mb_1d',    name: '50MB',   price: 50,   validity: DataValidity.daily,   validityLabel: '1 Day',   description: '50MB • Valid for 1 Day',     network: NetworkProvider.glo),
        DataPlan(id: 'glo_200mb_3d',   name: '200MB',  price: 200,  validity: DataValidity.daily,   validityLabel: '3 Days',  description: '200MB • Valid for 3 Days',   network: NetworkProvider.glo),
        // Weekly
        DataPlan(id: 'glo_500mb_7d',   name: '500MB',  price: 350,  validity: DataValidity.weekly,  validityLabel: '7 Days',  description: '500MB • Valid for 7 Days',   network: NetworkProvider.glo),
        DataPlan(id: 'glo_1gb_7d',     name: '1GB',    price: 500,  validity: DataValidity.weekly,  validityLabel: '7 Days',  description: '1GB • Valid for 7 Days',     network: NetworkProvider.glo),
        // Monthly
        DataPlan(id: 'glo_1gb_30d',    name: '1GB',    price: 1000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '1GB • Valid for 30 Days',    network: NetworkProvider.glo),
        DataPlan(id: 'glo_2gb_30d',    name: '2GB',    price: 1500, validity: DataValidity.monthly, validityLabel: '30 Days', description: '2GB • Valid for 30 Days',    network: NetworkProvider.glo),
        DataPlan(id: 'glo_4gb_30d',    name: '4GB',    price: 2000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '4GB • Valid for 30 Days',    network: NetworkProvider.glo),
        DataPlan(id: 'glo_7_5gb_30d',  name: '7.5GB',  price: 3000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '7.5GB • Valid for 30 Days',  network: NetworkProvider.glo),
        DataPlan(id: 'glo_10gb_30d',   name: '10GB',   price: 4000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '10GB • Valid for 30 Days',   network: NetworkProvider.glo),
      ],

      // ── 9mobile Nigeria ────────────────────────────────────────────────
      NetworkProvider.nineMobile: [
        // Weekly
        DataPlan(id: '9mob_150mb_7d',   name: '150MB',  price: 200,  validity: DataValidity.weekly,  validityLabel: '7 Days',  description: '150MB • Valid for 7 Days',   network: NetworkProvider.nineMobile),
        DataPlan(id: '9mob_400mb_14d',  name: '400MB',  price: 400,  validity: DataValidity.weekly,  validityLabel: '14 Days', description: '400MB • Valid for 14 Days',  network: NetworkProvider.nineMobile),
        // Monthly
        DataPlan(id: '9mob_500mb_30d',  name: '500MB',  price: 500,  validity: DataValidity.monthly, validityLabel: '30 Days', description: '500MB • Valid for 30 Days',  network: NetworkProvider.nineMobile),
        DataPlan(id: '9mob_1gb_30d',    name: '1GB',    price: 1000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '1GB • Valid for 30 Days',    network: NetworkProvider.nineMobile),
        DataPlan(id: '9mob_1_5gb_30d',  name: '1.5GB',  price: 1200, validity: DataValidity.monthly, validityLabel: '30 Days', description: '1.5GB • Valid for 30 Days',  network: NetworkProvider.nineMobile),
        DataPlan(id: '9mob_2_5gb_30d',  name: '2.5GB',  price: 2000, validity: DataValidity.monthly, validityLabel: '30 Days', description: '2.5GB • Valid for 30 Days',  network: NetworkProvider.nineMobile),
        DataPlan(id: '9mob_5gb_30d',    name: '5GB',    price: 3500, validity: DataValidity.monthly, validityLabel: '30 Days', description: '5GB • Valid for 30 Days',    network: NetworkProvider.nineMobile),
      ],
    };

    return catalogue[network] ?? [];
  }

  // ---------------------------------------------------------------------------
  // DATA PURCHASE
  //
  // POST $baseUrl/bills/data
  // Body: { phone_number, network, plan_id, amount, request_id }
  // ---------------------------------------------------------------------------

  Future<DataPurchaseResponse> buyData(DataPurchaseRequest request) async {
    return _mockBuyData(request);

    // ── Real implementation ──────────────────────────────────────────────
    // try {
    //   final response = await http.post(
    //     Uri.parse('$baseUrl/bills/data'),
    //     headers: _headers,
    //     body: jsonEncode({
    //       ...request.toJson(),
    //       'request_id': _generateRequestId(),
    //     }),
    //   ).timeout(const Duration(seconds: 30));
    //
    //   final data = jsonDecode(response.body) as Map<String, dynamic>;
    //   if (response.statusCode == 200 || response.statusCode == 201) {
    //     return DataPurchaseResponse.fromJson(data);
    //   } else {
    //     throw BillsException(data['message'] ?? 'Data purchase failed', response.statusCode);
    //   }
    // } on SocketException {
    //   throw BillsException('No internet connection.');
    // } catch (e) {
    //   if (e is BillsException) rethrow;
    //   throw BillsException('Data purchase failed. Please try again.');
    // }
  }

  Future<DataPurchaseResponse> _mockBuyData(DataPurchaseRequest request) async {
    await Future.delayed(const Duration(seconds: 2));
    return DataPurchaseResponse(
      success: true,
      transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
      message: 'Data purchase successful',
      plan: request.plan,
      phoneNumber: request.phoneNumber,
      network: request.network.name.toUpperCase(),
      createdAt: DateTime.now(),
    );
  }

  // ---------------------------------------------------------------------------
  // BENEFICIARIES
  //
  // GET  $baseUrl/bills/beneficiaries
  // POST $baseUrl/bills/beneficiaries
  // ---------------------------------------------------------------------------

  Future<List<BillsBeneficiary>> getBeneficiaries() async {
    return _mockGetBeneficiaries();
  }

  Future<List<BillsBeneficiary>> _mockGetBeneficiaries() async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Empty by default — real beneficiaries are persisted after each transaction.
    return [];
  }

  Future<bool> saveBeneficiary({
    required String name,
    required String phoneNumber,
    required NetworkProvider network,
    required BillsType type,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  /// Maps NetworkProvider to the service ID string expected by your VTU provider.
  /// Update this map to match your chosen provider's documentation.
  String getNetworkServiceId(NetworkProvider network) {
    switch (network) {
      case NetworkProvider.mtn:        return 'mtn';
      case NetworkProvider.airtel:     return 'airtel';
      case NetworkProvider.glo:        return 'glo';
      case NetworkProvider.nineMobile: return '9mobile';
    }
  }

  /// Generates a unique idempotency key for each transaction request.
  /// Format: KD + timestamp. Replace with UUID if needed.
  String _generateRequestId() =>
      'KD${DateTime.now().millisecondsSinceEpoch}';
}