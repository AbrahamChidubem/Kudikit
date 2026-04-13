// ============================================================================
// lib/provider/electricity/electricity_provider.dart
// Riverpod state management for Electricity bill payment.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/mock/mock_api_data.dart';
import 'package:kudipay/model/electricity/electricity_model.dart';
import 'package:flutter_riverpod/legacy.dart';
// ============================================================================
// ELECTRICITY STATE
// ============================================================================

enum ElectricityStep {
  enterDetails,
  confirm,
  processing,
  success,
  failed,
}

class ElectricityState {
  final ElectricityStep step;
  final ElectricityProviderInfo selectedProvider;
  final MeterType meterType;
  final String meterNumber;
  final ElectricityAccountDetail? accountDetail;
  final bool isValidatingMeter;
  final bool isMeterInvalid;
  final double? amount;
  final bool isProcessing;
  final ElectricityPaymentResponse? result;
  final String? error;

  const ElectricityState({
    this.step = ElectricityStep.enterDetails,
    ElectricityProviderInfo? selectedProvider,
    this.meterType = MeterType.prepaid,
    this.meterNumber = '',
    this.accountDetail,
    this.isValidatingMeter = false,
    this.isMeterInvalid = false,
    this.amount,
    this.isProcessing = false,
    this.result,
    this.error,
  }) : selectedProvider = selectedProvider ??
            const ElectricityProviderInfo(
              provider: ElectricityProvider.ibadan,
              name: 'Ibadan Electricity',
              shortCode: 'IBEDC',
            );

  ElectricityState copyWith({
    ElectricityStep? step,
    ElectricityProviderInfo? selectedProvider,
    MeterType? meterType,
    String? meterNumber,
    ElectricityAccountDetail? accountDetail,
    bool? isValidatingMeter,
    bool? isMeterInvalid,
    double? amount,
    bool? isProcessing,
    ElectricityPaymentResponse? result,
    String? error,
    bool clearError = false,
    bool clearAccountDetail = false,
  }) {
    return ElectricityState(
      step: step ?? this.step,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      meterType: meterType ?? this.meterType,
      meterNumber: meterNumber ?? this.meterNumber,
      accountDetail:
          clearAccountDetail ? null : (accountDetail ?? this.accountDetail),
      isValidatingMeter: isValidatingMeter ?? this.isValidatingMeter,
      isMeterInvalid: isMeterInvalid ?? this.isMeterInvalid,
      amount: amount ?? this.amount,
      isProcessing: isProcessing ?? this.isProcessing,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get canContinue =>
      meterNumber.length >= 10 &&
      accountDetail != null &&
      amount != null &&
      amount! > 0;
}

// ============================================================================
// ELECTRICITY NOTIFIER
// ============================================================================

class ElectricityNotifier extends StateNotifier<ElectricityState> {
  ElectricityNotifier() : super(const ElectricityState());

  void setProvider(ElectricityProviderInfo provider) {
    state = state.copyWith(
      selectedProvider: provider,
      clearAccountDetail: true,
      meterNumber: '',
      isMeterInvalid: false,
    );
  }

  void setMeterType(MeterType type) {
    state = state.copyWith(
      meterType: type,
      clearAccountDetail: true,
      isMeterInvalid: false,
    );
  }

  void setMeterNumber(String number) {
    state = state.copyWith(
      meterNumber: number,
      clearAccountDetail: true,
      isMeterInvalid: false,
    );

    // Auto-validate when 11 digits entered
    if (number.length >= 11) {
      _validateMeter(number);
    }
  }

  Future<void> _validateMeter(String meterNumber) async {
    state = state.copyWith(isValidatingMeter: true, clearAccountDetail: true);

    await Future.delayed(const Duration(milliseconds: 800));

    // Mock: specific numbers are "invalid"
    final isInvalid = meterNumber == '2343323441';

    if (isInvalid) {
      state = state.copyWith(
        isValidatingMeter: false,
        isMeterInvalid: true,
        clearAccountDetail: true,
      );
    } else {
      final mock = MockBillsData.validateMeterSuccess(
        meterNumber: meterNumber,
      );
      state = state.copyWith(
        isValidatingMeter: false,
        isMeterInvalid: false,
        accountDetail: ElectricityAccountDetail(
          name: mock['name'] as String,
          meterNumber: mock['meter_number'] as String,
          meterType: state.meterType,
          provider: state.selectedProvider.name,
          location: mock['location'] as String,
        ),
      );
    }
  }

  void setAmount(double amount) {
    state = state.copyWith(amount: amount);
  }

  void showConfirm() {
    state = state.copyWith(step: ElectricityStep.confirm);
  }

  void backToDetails() {
    state = state.copyWith(step: ElectricityStep.enterDetails, clearError: true);
  }

  Future<void> processPayment() async {
    state = state.copyWith(
      isProcessing: true,
      clearError: true,
      step: ElectricityStep.processing,
    );

    await Future.delayed(const Duration(seconds: 2));

    state = state.copyWith(
      isProcessing: false,
      step: ElectricityStep.success,
      result: ElectricityPaymentResponse(
        success: true,
        transactionId: 'TXN${DateTime.now().millisecondsSinceEpoch}',
        message: 'Payment successful',
        token: '1234-5678-9012-3456',
        amount: state.amount ?? 0,
        meterNumber: state.meterNumber,
        createdAt: DateTime.now(),
      ),
    );
  }

  void reset() {
    state = const ElectricityState();
  }
}

final electricityProvider =
    StateNotifierProvider<ElectricityNotifier, ElectricityState>((ref) {
  return ElectricityNotifier();
});