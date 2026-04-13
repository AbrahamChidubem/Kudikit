// ============================================================================
// lib/provider/cable_tv/cable_tv_provider.dart
// Riverpod state management for Cable TV bill payment.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/mock/mock_api_data.dart';
import 'package:kudipay/model/cable_tv/cable_tv_model.dart';
import 'package:flutter_riverpod/legacy.dart';
// ============================================================================
// CABLE TV STATE
// ============================================================================

enum CableTvStep {
  enterDetails,
  confirm,
  processing,
  success,
  failed,
}

class CableTvState {
  final CableTvStep step;
  final CableTvProviderInfo selectedProvider;
  final CableTvPlan? selectedPlan;
  final String iucNumber;
  final CableTvAccountDetail? accountDetail;
  final bool isValidatingIuc;
  final bool isIucInvalid;
  final double? amount;
  final bool autoRenew;
  final bool isProcessing;
  final String? error;

  const CableTvState({
    this.step = CableTvStep.enterDetails,
    CableTvProviderInfo? selectedProvider,
    this.selectedPlan,
    this.iucNumber = '',
    this.accountDetail,
    this.isValidatingIuc = false,
    this.isIucInvalid = false,
    this.amount,
    this.autoRenew = false,
    this.isProcessing = false,
    this.error,
  }) : selectedProvider = selectedProvider ??
            const CableTvProviderInfo(
              provider: CableTvProvider.dstv,
              name: 'DSTV',
            );

  CableTvState copyWith({
    CableTvStep? step,
    CableTvProviderInfo? selectedProvider,
    CableTvPlan? selectedPlan,
    String? iucNumber,
    CableTvAccountDetail? accountDetail,
    bool? isValidatingIuc,
    bool? isIucInvalid,
    double? amount,
    bool? autoRenew,
    bool? isProcessing,
    String? error,
    bool clearError = false,
    bool clearAccountDetail = false,
    bool clearPlan = false,
  }) {
    return CableTvState(
      step: step ?? this.step,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      selectedPlan: clearPlan ? null : (selectedPlan ?? this.selectedPlan),
      iucNumber: iucNumber ?? this.iucNumber,
      accountDetail:
          clearAccountDetail ? null : (accountDetail ?? this.accountDetail),
      isValidatingIuc: isValidatingIuc ?? this.isValidatingIuc,
      isIucInvalid: isIucInvalid ?? this.isIucInvalid,
      amount: amount ?? this.amount,
      autoRenew: autoRenew ?? this.autoRenew,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get canContinue =>
      selectedPlan != null &&
      iucNumber.isNotEmpty &&
      accountDetail != null &&
      !isIucInvalid;

  List<CableTvPlan> get availablePlans =>
      getPlansForProvider(selectedProvider.provider);
}

// ============================================================================
// CABLE TV NOTIFIER
// ============================================================================

class CableTvNotifier extends StateNotifier<CableTvState> {
  CableTvNotifier() : super(const CableTvState());

  void setProvider(CableTvProviderInfo provider) {
    state = state.copyWith(
      selectedProvider: provider,
      clearPlan: true,
      iucNumber: '',
      clearAccountDetail: true,
      isIucInvalid: false,
    );
  }

  void selectPlan(CableTvPlan plan) {
    state = state.copyWith(
      selectedPlan: plan,
      amount: plan.amount,
    );
  }

  void setIucNumber(String number) {
    state = state.copyWith(
      iucNumber: number,
      clearAccountDetail: true,
      isIucInvalid: false,
    );

    if (number.length >= 10) {
      _validateIuc(number);
    }
  }

  Future<void> _validateIuc(String iucNumber) async {
    state = state.copyWith(isValidatingIuc: true, clearAccountDetail: true);

    await Future.delayed(const Duration(milliseconds: 800));

    // Mock: 2343323441 is invalid (as shown in Image 7)
    final isInvalid = iucNumber == '2343323441';

    if (isInvalid) {
      state = state.copyWith(
        isValidatingIuc: false,
        isIucInvalid: true,
        clearAccountDetail: true,
      );
    } else {
      final isExpired = iucNumber == '2343323441x';

      // Pull the default plan name from MockBillsData so it stays in sync.
      final packages = MockBillsData.dstvPackagesResponse['packages'] as List;
      final defaultPlan = (packages.isNotEmpty)
          ? packages.first['name'] as String
          : 'DSTV Padi';

      state = state.copyWith(
        isValidatingIuc: false,
        isIucInvalid: false,
        accountDetail: CableTvAccountDetail(
          name: 'Adebayo Oluwakemi Peters',
          decoderNumber: iucNumber,
          provider: state.selectedProvider.name,
          currentPlan: state.selectedPlan?.name ?? defaultPlan,
          isExpired: isExpired,
        ),
      );
    }
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void toggleAutoRenew() {
    state = state.copyWith(autoRenew: !state.autoRenew);
  }

  void showConfirm() {
    state = state.copyWith(step: CableTvStep.confirm);
  }

  void backToDetails() {
    state =
        state.copyWith(step: CableTvStep.enterDetails, clearError: true);
  }

  Future<void> processPayment() async {
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      step: CableTvStep.processing,
    );

    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(
      isProcessing: false,
      step: CableTvStep.success,
    );
  }

  void reset() {
    state = const CableTvState();
  }
}

final cableTvProvider =
    StateNotifierProvider<CableTvNotifier, CableTvState>((ref) {
  return CableTvNotifier();
});