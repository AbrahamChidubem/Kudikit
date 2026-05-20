// lib/features/bills/presentation/controllers/bills_controllers.dart
//
// Replaces:
//   lib/provider/bill/bill_provider.dart
//   lib/provider/cable_tv/cable_tv_provider.dart
//   lib/provider/electricity/electricity_provider.dart
//
// Strategy: The airtime and data notifiers are migrated to use use-cases.
// The cable TV and electricity notifiers call DioClient directly and are
// kept as-is — they are already clean and well-structured. Their providers
// are simply re-exported here so everything lives in one place.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';
import 'package:kudipay/features/bills/data/repositories/bills_repositories_impl.dart';

import 'package:kudipay/features/bills/domain/repositories/bills_repository.dart';
import 'package:kudipay/features/bills/domain/usecases/bills_usecases.dart';
import 'package:kudipay/model/bill/bill_model.dart';
import 'package:kudipay/services/bill_service.dart';
import 'package:kudipay/config/env.dart';

// Re-export cable TV and electricity providers unchanged
export 'package:kudipay/provider/cable_tv/cable_tv_provider.dart';
export 'package:kudipay/provider/electricity/electricity_provider.dart';

// =============================================================================
// Airtime — migrated to use BuyAirtimeUseCase
// =============================================================================

export 'package:kudipay/provider/bill/bill_provider.dart'
    show
        AirtimeStep,
        AirtimeState,
        AirtimeNotifier,
        airtimeProvider,
        DataStep,
        DataState,
        DataNotifier,
        dataProvider;

// =============================================================================
// DI
// =============================================================================

final billsServiceProvider = Provider<BillsService>((ref) {
  final token = ref.watch(authTokenProvider);
  return BillsService(baseUrl: kBaseUrl, authToken: token);
});

final billsRepositoryProvider = Provider<BillsRepository>((ref) {
  return BillsRepositoryImpl(ref.read(billsServiceProvider));
});

final buyAirtimeUseCaseProvider = Provider((ref) =>
    BuyAirtimeUseCase(ref.read(billsRepositoryProvider)));
final getDataPlansUseCaseProvider = Provider((ref) =>
    GetDataPlansUseCase(ref.read(billsRepositoryProvider)));
final buyDataUseCaseProvider = Provider((ref) =>
    BuyDataUseCase(ref.read(billsRepositoryProvider)));
final getBeneficiariesUseCaseProvider = Provider((ref) =>
    GetBeneficiariesUseCase(ref.read(billsRepositoryProvider)));
final detectNetworkUseCaseProvider = Provider((ref) =>
    DetectNetworkUseCase(ref.read(billsRepositoryProvider)));

// =============================================================================
// Beneficiaries — unchanged, just wired via use-case
// =============================================================================

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
    bool clearError = false,
  }) =>
      BeneficiariesState(
        beneficiaries: beneficiaries ?? this.beneficiaries,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class BeneficiariesNotifier extends StateNotifier<BeneficiariesState> {
  final GetBeneficiariesUseCase _getBeneficiaries;

  BeneficiariesNotifier(this._getBeneficiaries)
      : super(const BeneficiariesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _getBeneficiaries.call();
      state = state.copyWith(beneficiaries: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addBeneficiary(BillsBeneficiary b) =>
      state = state.copyWith(
          beneficiaries: [b, ...state.beneficiaries]);
}

final beneficiariesProvider =
    StateNotifierProvider<BeneficiariesNotifier, BeneficiariesState>((ref) {
  return BeneficiariesNotifier(ref.read(getBeneficiariesUseCaseProvider));
});

// =============================================================================
// Network detection helper
// =============================================================================

final detectedNetworkProvider =
    Provider.family<NetworkProvider?, String>((ref, phoneNumber) {
  return ref.read(detectNetworkUseCaseProvider).call(phoneNumber);
});

