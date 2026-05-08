// ============================================================================
// lib/provider/cable_tv/cable_tv_provider.dart
// Riverpod state management for Cable TV bill payment.
// ============================================================================

import 'package:kudipay/config/dio_client.dart';
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
  final String? transactionId;

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
    this.transactionId,
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
    String? transactionId,
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
      transactionId: transactionId ?? this.transactionId,
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
  final DioClient _client;

  CableTvNotifier(this._client) : super(const CableTvState());

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
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/bills/cable-tv/validate-iuc',
        data: {
          'iuc_number': iucNumber,
          'provider': state.selectedProvider.name,
        },
      );
      final data = response.data!;
      state = state.copyWith(
        isValidatingIuc: false,
        isIucInvalid: false,
        accountDetail: CableTvAccountDetail(
          name: data['name'] as String,
          decoderNumber: iucNumber,
          provider: state.selectedProvider.name,
          currentPlan:
              data['current_plan'] as String? ?? state.selectedPlan?.name ?? '',
          isExpired: data['is_expired'] as bool? ?? false,
        ),
      );
    } on KudiApiException catch (e) {
      state = state.copyWith(
        isValidatingIuc: false,
        isIucInvalid: true,
        error: e.message,
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
    state = state.copyWith(step: CableTvStep.enterDetails, clearError: true);
  }

  Future<void> processPayment(String pin) async {
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      step: CableTvStep.processing,
    );
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/bills/cable-tv/pay',
        data: {
          'iuc_number': state.iucNumber,
          'provider': state.selectedProvider.name,
          'plan_id': state.selectedPlan?.id,
          'amount': state.amount,
          'auto_renew': state.autoRenew,
          'pin': pin,
        },
      );
      state = state.copyWith(
        isProcessing: false,
        step: CableTvStep.success,
        transactionId: response.data!['transaction_id'] as String?,
      );
    } on KudiApiException catch (e) {
      state = state.copyWith(
        isProcessing: false,
        step: CableTvStep.failed,
        error: e.message,
      );
    }
  }

  void reset() {
    state = const CableTvState();
  }
}

final cableTvProvider =
    StateNotifierProvider<CableTvNotifier, CableTvState>((ref) {
  return CableTvNotifier(ref.read(dioClientProvider));
});
