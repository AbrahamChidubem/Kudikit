import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/bill/bill_model.dart';
import 'package:kudipay/services/bill_service.dart';
import 'package:flutter_riverpod/legacy.dart';

// ============================================================================
// Service Provider
// ============================================================================

final billsServiceProvider = Provider<BillsService>((ref) {
  return BillsService(
    baseUrl: 'https://api.kudipay.com/api/v1',
    // authToken: ref.watch(authTokenProvider),
  );
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
    bool clearError = false,
  }) {
    return BeneficiariesState(
      beneficiaries: beneficiaries ?? this.beneficiaries,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BeneficiariesNotifier extends StateNotifier<BeneficiariesState> {
  final BillsService _service;

  BeneficiariesNotifier(this._service) : super(const BeneficiariesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _service.getBeneficiaries();
      state = state.copyWith(beneficiaries: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void addBeneficiary(BillsBeneficiary b) {
    state = state.copyWith(beneficiaries: [b, ...state.beneficiaries]);
  }
}

final beneficiariesProvider =
    StateNotifierProvider<BeneficiariesNotifier, BeneficiariesState>((ref) {
  return BeneficiariesNotifier(ref.watch(billsServiceProvider));
});

// ============================================================================
// AIRTIME STATE
// ============================================================================

enum AirtimeStep {
  enterPhone,
  enterAmount,
  confirm,
  processing,
  success,
  failed,
}

class AirtimeState {
  final AirtimeStep step;
  final String phoneNumber;
  final NetworkProvider? selectedNetwork;
  final double? amount;
  final bool isProcessing;
  final bool isNetworkDropdownOpen;
  final AirtimePurchaseResponse? result;
  final String? error;

  const AirtimeState({
    this.step = AirtimeStep.enterPhone,
    this.phoneNumber = '',
    this.selectedNetwork,
    this.amount,
    this.isProcessing = false,
    this.isNetworkDropdownOpen = false,
    this.result,
    this.error,
  });

  AirtimeState copyWith({
    AirtimeStep? step,
    String? phoneNumber,
    NetworkProvider? selectedNetwork,
    double? amount,
    bool? isProcessing,
    bool? isNetworkDropdownOpen,
    AirtimePurchaseResponse? result,
    String? error,
    bool clearError = false,
    bool clearNetwork = false,
  }) {
    return AirtimeState(
      step: step ?? this.step,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      selectedNetwork:
          clearNetwork ? null : (selectedNetwork ?? this.selectedNetwork),
      amount: amount ?? this.amount,
      isProcessing: isProcessing ?? this.isProcessing,
      isNetworkDropdownOpen:
          isNetworkDropdownOpen ?? this.isNetworkDropdownOpen,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get canProceedFromPhone =>
      phoneNumber.replaceAll(' ', '').length >= 11 && selectedNetwork != null;

  bool get canProceedFromAmount =>
      amount != null && (amount! >= 50) && (amount! <= 50000);
}

class AirtimeNotifier extends StateNotifier<AirtimeState> {
  final BillsService _service;

  AirtimeNotifier(this._service) : super(const AirtimeState());

  /// Called when the user types a phone number manually.
  /// Runs NCC prefix auto-detection.
  void setPhoneNumber(String phone) {
    final detected = _service.detectNetwork(phone);
    state = state.copyWith(
      phoneNumber: phone,
      selectedNetwork: detected ?? state.selectedNetwork,
      clearNetwork: detected == null && phone.length < 4,
    );
  }

  /// Called when the user picks a contact from the contact picker.
  /// The contact service has already detected the network, so we
  /// bypass re-detection and set both values in one atomic update.
  /// [network] may be null if detection failed — falls back to
  /// whatever network was previously selected.
  void setPhoneNumberWithNetwork(String phone, NetworkProvider? network) {
    state = state.copyWith(
      phoneNumber: phone,
      selectedNetwork: network ?? state.selectedNetwork,
      clearNetwork: network == null,
      isNetworkDropdownOpen: false,
    );
  }

  void setNetwork(NetworkProvider network) {
    state = state.copyWith(
      selectedNetwork: network,
      isNetworkDropdownOpen: false,
    );
  }

  void toggleNetworkDropdown() {
    state = state.copyWith(
        isNetworkDropdownOpen: !state.isNetworkDropdownOpen);
  }

  void closeNetworkDropdown() {
    state = state.copyWith(isNetworkDropdownOpen: false);
  }

  void proceedToAmount() {
    state = state.copyWith(
      step: AirtimeStep.enterAmount,
      isNetworkDropdownOpen: false,
    );
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void showConfirm() {
    state = state.copyWith(step: AirtimeStep.confirm);
  }

  void backToAmount() {
    state = state.copyWith(step: AirtimeStep.enterAmount, clearError: true);
  }

  Future<void> processAirtime() async {
    if (state.selectedNetwork == null || state.amount == null) return;

    state = state.copyWith(
        isProcessing: true, clearError: true, step: AirtimeStep.processing);

    try {
      final response = await _service.buyAirtime(
        AirtimePurchaseRequest(
          phoneNumber: state.phoneNumber.replaceAll(' ', ''),
          network: state.selectedNetwork!,
          amount: state.amount!,
        ),
      );
      state = state.copyWith(
        isProcessing: false,
        result: response,
        step: AirtimeStep.success,
      );
    } on SocketException {
      state = state.copyWith(
        isProcessing: false,
        step: AirtimeStep.failed,
        error: 'No internet connection. Please check your network.',
      );
    } on BillsException catch (e) {
      state = state.copyWith(
        isProcessing: false,
        step: AirtimeStep.failed,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        step: AirtimeStep.failed,
        error: 'Transaction failed. Please try again.',
      );
    }
  }

  void reset() {
    state = const AirtimeState();
  }
}

final airtimeProvider =
    StateNotifierProvider<AirtimeNotifier, AirtimeState>((ref) {
  return AirtimeNotifier(ref.watch(billsServiceProvider));
});

// ============================================================================
// DATA STATE
// ============================================================================

enum DataStep {
  enterPhone,
  selectPlan,
  confirm,
  processing,
  success,
  failed,
}

class DataState {
  final DataStep step;
  final String phoneNumber;
  final NetworkProvider? selectedNetwork;
  final bool isNetworkDropdownOpen;
  final List<DataPlan> plans;
  final bool isLoadingPlans;
  final DataPlan? selectedPlan;
  final bool isProcessing;
  final DataPurchaseResponse? result;
  final String? error;

  const DataState({
    this.step = DataStep.enterPhone,
    this.phoneNumber = '',
    this.selectedNetwork,
    this.isNetworkDropdownOpen = false,
    this.plans = const [],
    this.isLoadingPlans = false,
    this.selectedPlan,
    this.isProcessing = false,
    this.result,
    this.error,
  });

  DataState copyWith({
    DataStep? step,
    String? phoneNumber,
    NetworkProvider? selectedNetwork,
    bool? isNetworkDropdownOpen,
    List<DataPlan>? plans,
    bool? isLoadingPlans,
    DataPlan? selectedPlan,
    bool? isProcessing,
    DataPurchaseResponse? result,
    String? error,
    bool clearError = false,
    bool clearPlan = false,
    bool clearNetwork = false,
  }) {
    return DataState(
      step: step ?? this.step,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      selectedNetwork:
          clearNetwork ? null : (selectedNetwork ?? this.selectedNetwork),
      isNetworkDropdownOpen:
          isNetworkDropdownOpen ?? this.isNetworkDropdownOpen,
      plans: plans ?? this.plans,
      isLoadingPlans: isLoadingPlans ?? this.isLoadingPlans,
      selectedPlan:
          clearPlan ? null : (selectedPlan ?? this.selectedPlan),
      isProcessing: isProcessing ?? this.isProcessing,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get canProceedFromPhone =>
      phoneNumber.replaceAll(' ', '').length >= 11 && selectedNetwork != null;

  bool get canProceedFromPlan => selectedPlan != null;
}

class DataNotifier extends StateNotifier<DataState> {
  final BillsService _service;

  DataNotifier(this._service) : super(const DataState());

  /// Called when the user types a phone number manually.
  void setPhoneNumber(String phone) {
    final detected = _service.detectNetwork(phone);
    state = state.copyWith(
      phoneNumber: phone,
      selectedNetwork: detected ?? state.selectedNetwork,
      clearNetwork: detected == null && phone.length < 4,
      clearPlan: true,
      plans: [],
    );
  }

  /// Called when the user picks a contact from the contact picker.
  /// Network detection already done — passed directly from contact service.
  void setPhoneNumberWithNetwork(String phone, NetworkProvider? network) {
    state = state.copyWith(
      phoneNumber: phone,
      selectedNetwork: network ?? state.selectedNetwork,
      clearNetwork: network == null,
      isNetworkDropdownOpen: false,
      clearPlan: true,
      plans: [],
    );
  }

  void setNetwork(NetworkProvider network) {
    state = state.copyWith(
      selectedNetwork: network,
      isNetworkDropdownOpen: false,
      clearPlan: true,
      plans: [],
    );
  }

  void toggleNetworkDropdown() {
    state =
        state.copyWith(isNetworkDropdownOpen: !state.isNetworkDropdownOpen);
  }

  void closeNetworkDropdown() {
    state = state.copyWith(isNetworkDropdownOpen: false);
  }

  Future<void> proceedToSelectPlan() async {
    if (state.selectedNetwork == null) return;
    state = state.copyWith(
      step: DataStep.selectPlan,
      isNetworkDropdownOpen: false,
      isLoadingPlans: true,
      clearPlan: true,
    );
    try {
      final plans = await _service.getDataPlans(state.selectedNetwork!);
      state = state.copyWith(plans: plans, isLoadingPlans: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingPlans: false,
        error: 'Failed to load data plans. Please try again.',
      );
    }
  }

  void selectPlan(DataPlan plan) {
    state = state.copyWith(selectedPlan: plan);
  }

  void showConfirm() {
    state = state.copyWith(step: DataStep.confirm);
  }

  void backToSelectPlan() {
    state = state.copyWith(step: DataStep.selectPlan, clearError: true);
  }

  Future<void> processData() async {
    if (state.selectedNetwork == null || state.selectedPlan == null) return;

    state = state.copyWith(
        isProcessing: true, clearError: true, step: DataStep.processing);

    try {
      final response = await _service.buyData(
        DataPurchaseRequest(
          phoneNumber: state.phoneNumber.replaceAll(' ', ''),
          network: state.selectedNetwork!,
          plan: state.selectedPlan!,
        ),
      );
      state = state.copyWith(
        isProcessing: false,
        result: response,
        step: DataStep.success,
      );
    } on SocketException {
      state = state.copyWith(
        isProcessing: false,
        step: DataStep.failed,
        error: 'No internet connection. Please check your network.',
      );
    } on BillsException catch (e) {
      state = state.copyWith(
        isProcessing: false,
        step: DataStep.failed,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        step: DataStep.failed,
        error: 'Transaction failed. Please try again.',
      );
    }
  }

  void reset() {
    state = const DataState();
  }
}

final dataProvider =
    StateNotifierProvider<DataNotifier, DataState>((ref) {
  return DataNotifier(ref.watch(billsServiceProvider));
});