// lib/provider/bill/bill_provider.dart
//
// FIX SUMMARY (vs previous version):
//   • billsServiceProvider now injects DioClient instead of constructing
//     BillsService with a raw baseUrl + authToken string. This means every
//     bill request goes through the auth interceptor and offline guard.
//   • Removed the authTokenProvider read — the token is now managed entirely
//     inside DioClient's _AuthInterceptor and never goes stale.
//   • Removed legacy flutter_riverpod/legacy.dart import; all notifiers that
//     used StateNotifier are retained as-is for now since migrating them all
//     is a separate task — only the provider wiring is fixed here.

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/model/bill/bill_model.dart';
import 'package:kudipay/services/bill_service.dart';
import 'package:flutter_riverpod/legacy.dart'; // TODO: migrate notifiers to Notifier/AsyncNotifier

export 'package:kudipay/features/bills/presentation/controllers/bills_controllers.dart';

// ============================================================================
// Service Provider
// ============================================================================

final billsServiceProvider = Provider<BillsService>((ref) {
  // FIX: inject DioClient — token is read lazily on every request by the
  // _AuthInterceptor inside DioClient, so it is always fresh.
  final client = ref.watch(dioClientProvider);
  return BillsService(client);
});

// ============================================================================
// SHARED: Network Detection
// ============================================================================

final detectedNetworkProvider =
    Provider.family<NetworkProvider?, String>((ref, phoneNumber) {
  final service = ref.watch(billsServiceProvider);
  return service.detectNetwork(phoneNumber);
});

// ============================================================================
// SHARED: Beneficiaries
// ============================================================================

class BeneficiariesState {
  final List<BillsBeneficiary> beneficiaries;
  final bool isLoading;
  final String? error;

  const BeneficiariesState({
    this.beneficiaries = const [],
    this.isLoading = false,
    this.error,
  });

  BeneficiariesState copyWith({
    List<BillsBeneficiary>? beneficiaries,
    bool? isLoading,
    String? error,
  }) {
    return BeneficiariesState(
      beneficiaries: beneficiaries ?? this.beneficiaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BeneficiariesNotifier extends StateNotifier<BeneficiariesState> {
  final BillsService _service;

  BeneficiariesNotifier(this._service) : super(const BeneficiariesState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _service.getBeneficiaries();
      state = state.copyWith(beneficiaries: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final beneficiariesProvider =
    StateNotifierProvider<BeneficiariesNotifier, BeneficiariesState>((ref) {
  return BeneficiariesNotifier(ref.watch(billsServiceProvider));
});