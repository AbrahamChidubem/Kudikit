import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/services/add_money_services.dart';

/// ==================== FUNDING / ADD MONEY PROVIDERS ====================
/// 
/// This file contains all wallet funding related state providers:
/// - Add money options
/// - Bank account details
/// - QR code generation
/// - Bank selection
/// - USSD transfer
/// - Card top-up
/// - Error handling

// ==================== SERVICE PROVIDER ====================

/// Provider for add money service
final addMoneyServiceProvider = Provider<AddMoneyService>((ref) {
  return MockAddMoneyService();
});

// ==================== ERROR HANDLING ====================

/// Error types for add money operations
enum AddMoneyErrorType {
  network,
  authentication,
  serverError,
  validation,
  timeout,
  unknown,
}

/// Error class for add money operations
class AddMoneyError {
  final String message;
  final AddMoneyErrorType type;
  final int? statusCode;
  final bool isRetryable;

  const AddMoneyError({
    required this.message,
    required this.type,
    this.statusCode,
    this.isRetryable = true,
  });

  @override
  String toString() => message;
}

// ==================== ADD MONEY OPTIONS ====================

/// State for add money options
class AddMoneyOptionsState {
  final List<AddMoneyOption> options;
  final bool isLoading;
  final AddMoneyError? error;

  const AddMoneyOptionsState({
    this.options = const [],
    this.isLoading = false,
    this.error,
  });

  AddMoneyOptionsState copyWith({
    List<AddMoneyOption>? options,
    bool? isLoading,
    AddMoneyError? error,
    bool clearError = false,
  }) {
    return AddMoneyOptionsState(
      options: options ?? this.options,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// State notifier for add money options
class AddMoneyOptionsNotifier extends StateNotifier<AddMoneyOptionsState> {
  final AddMoneyService _service;

  AddMoneyOptionsNotifier(this._service) : super(const AddMoneyOptionsState());

  /// Loads available add money options
  Future<void> loadOptions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final options = await _service.getAddMoneyOptions();
      state = AddMoneyOptionsState(
        options: options,
        isLoading: false,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'No internet connection. Please check your network.',
          type: AddMoneyErrorType.network,
          isRetryable: true,
        ),
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Request timed out. Please try again.',
          type: AddMoneyErrorType.timeout,
          isRetryable: true,
        ),
      );
    } on AddMoneyException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleException(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'An unexpected error occurred.',
          type: AddMoneyErrorType.unknown,
          isRetryable: true,
        ),
      );
    }
  }

  AddMoneyError _handleException(AddMoneyException e) {
    final statusCode = e.statusCode;

    if (statusCode != null) {
      if (statusCode == 401 || statusCode == 403) {
        return AddMoneyError(
          message: 'Session expired. Please log in again.',
          type: AddMoneyErrorType.authentication,
          statusCode: statusCode,
          isRetryable: false,
        );
      } else if (statusCode >= 500) {
        return AddMoneyError(
          message: 'Server error. Please try again later.',
          type: AddMoneyErrorType.serverError,
          statusCode: statusCode,
          isRetryable: true,
        );
      } else if (statusCode >= 400) {
        return AddMoneyError(
          message: e.message,
          type: AddMoneyErrorType.validation,
          statusCode: statusCode,
          isRetryable: false,
        );
      }
    }

    return AddMoneyError(
      message: e.message,
      type: AddMoneyErrorType.unknown,
      statusCode: statusCode,
      isRetryable: true,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for add money options
final addMoneyOptionsProvider =
    StateNotifierProvider<AddMoneyOptionsNotifier, AddMoneyOptionsState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return AddMoneyOptionsNotifier(service);
});

/// Selected add money option provider
final selectedAddMoneyOptionProvider =
    StateProvider<AddMoneyOption?>((ref) => null);

// ==================== ACCOUNT DETAILS ====================

/// State for virtual account details
class AccountDetailsState {
  final AccountDetails? accountDetails;
  final bool isLoading;
  final AddMoneyError? error;

  const AccountDetailsState({
    this.accountDetails,
    this.isLoading = false,
    this.error,
  });

  AccountDetailsState copyWith({
    AccountDetails? accountDetails,
    bool? isLoading,
    AddMoneyError? error,
    bool clearError = false,
  }) {
    return AccountDetailsState(
      accountDetails: accountDetails ?? this.accountDetails,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// State notifier for account details
class AccountDetailsNotifier extends StateNotifier<AccountDetailsState> {
  final AddMoneyService _service;

  AccountDetailsNotifier(this._service) : super(const AccountDetailsState());

  /// Loads virtual account details for bank transfer
  Future<void> loadAccountDetails() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final accountDetails = await _service.getAccountDetails();
      state = AccountDetailsState(
        accountDetails: accountDetails,
        isLoading: false,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'No internet connection.',
          type: AddMoneyErrorType.network,
          isRetryable: true,
        ),
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Request timed out.',
          type: AddMoneyErrorType.timeout,
          isRetryable: true,
        ),
      );
    } on AddMoneyException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _handleException(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Failed to load account details.',
          type: AddMoneyErrorType.unknown,
          isRetryable: true,
        ),
      );
    }
  }

  AddMoneyError _handleException(AddMoneyException e) {
    final statusCode = e.statusCode;

    if (statusCode != null) {
      if (statusCode == 401 || statusCode == 403) {
        return AddMoneyError(
          message: 'Session expired. Please log in again.',
          type: AddMoneyErrorType.authentication,
          statusCode: statusCode,
          isRetryable: false,
        );
      } else if (statusCode >= 500) {
        return AddMoneyError(
          message: 'Server error. Please try again later.',
          type: AddMoneyErrorType.serverError,
          statusCode: statusCode,
          isRetryable: true,
        );
      }
    }

    return AddMoneyError(
      message: e.message,
      type: AddMoneyErrorType.unknown,
      statusCode: statusCode,
      isRetryable: true,
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for account details
final accountDetailsProvider =
    StateNotifierProvider<AccountDetailsNotifier, AccountDetailsState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return AccountDetailsNotifier(service);
});

// ==================== QR CODE ====================

/// State for QR code generation
class QrCodeState {
  final String? qrCodeUrl;
  final bool isLoading;
  final AddMoneyError? error;

  const QrCodeState({
    this.qrCodeUrl,
    this.isLoading = false,
    this.error,
  });

  QrCodeState copyWith({
    String? qrCodeUrl,
    bool? isLoading,
    AddMoneyError? error,
    bool clearError = false,
  }) {
    return QrCodeState(
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// State notifier for QR code generation
class QrCodeNotifier extends StateNotifier<QrCodeState> {
  final AddMoneyService _service;

  QrCodeNotifier(this._service) : super(const QrCodeState());

  /// Generates QR code for cash deposit
  Future<void> generateQrCode() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final qrCodeUrl = await _service.generateQrCode();
      state = QrCodeState(
        qrCodeUrl: qrCodeUrl,
        isLoading: false,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'No internet connection.',
          type: AddMoneyErrorType.network,
          isRetryable: true,
        ),
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Request timed out.',
          type: AddMoneyErrorType.timeout,
          isRetryable: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Failed to generate QR code.',
          type: AddMoneyErrorType.unknown,
          isRetryable: true,
        ),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for QR code
final qrCodeProvider =
    StateNotifierProvider<QrCodeNotifier, QrCodeState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return QrCodeNotifier(service);
});

// ==================== BANK SELECTION ====================

/// State for banks list
class BanksState {
  final List<Bank> banks;
  final bool isLoading;
  final AddMoneyError? error;

  const BanksState({
    this.banks = const [],
    this.isLoading = false,
    this.error,
  });

  BanksState copyWith({
    List<Bank>? banks,
    bool? isLoading,
    AddMoneyError? error,
    bool clearError = false,
  }) {
    return BanksState(
      banks: banks ?? this.banks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// State notifier for banks
class BanksNotifier extends StateNotifier<BanksState> {
  final AddMoneyService _service;

  BanksNotifier(this._service) : super(const BanksState());

  /// Loads list of supported banks
  Future<void> loadBanks() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final banks = await _service.getBanks();
      state = BanksState(
        banks: banks,
        isLoading: false,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'No internet connection.',
          type: AddMoneyErrorType.network,
          isRetryable: true,
        ),
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Request timed out.',
          type: AddMoneyErrorType.timeout,
          isRetryable: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Failed to load banks.',
          type: AddMoneyErrorType.unknown,
          isRetryable: true,
        ),
      );
    }
  }

  /// Searches banks by name
  List<Bank> searchBanks(String query) {
    if (query.isEmpty) return state.banks;
    return state.banks
        .where((bank) => bank.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Provider for banks list
final banksProvider = StateNotifierProvider<BanksNotifier, BanksState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return BanksNotifier(service);
});

/// Selected bank provider
final selectedBankProvider = StateProvider<Bank?>((ref) => null);

/// Bank search query provider
final bankSearchQueryProvider = StateProvider<String>((ref) => '');

// ==================== USSD TRANSFER ====================

/// State for USSD transfer
class UssdTransferState {
  final UssdTransferData? data;
  final bool isLoading;
  final AddMoneyError? error;

  const UssdTransferState({
    this.data,
    this.isLoading = false,
    this.error,
  });

  UssdTransferState copyWith({
    UssdTransferData? data,
    bool? isLoading,
    AddMoneyError? error,
    bool clearError = false,
  }) {
    return UssdTransferState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// State notifier for USSD transfer
class UssdTransferNotifier extends StateNotifier<UssdTransferState> {
  final AddMoneyService _service;

  UssdTransferNotifier(this._service) : super(const UssdTransferState());

  /// Generates USSD code for bank transfer
  Future<void> generateUssdCode({
    required String bankCode,
    required double amount,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _service.generateUssdCode(
        bankCode: bankCode,
        amount: amount,
      );
      state = UssdTransferState(
        data: data,
        isLoading: false,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'No internet connection.',
          type: AddMoneyErrorType.network,
          isRetryable: true,
        ),
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Request timed out.',
          type: AddMoneyErrorType.timeout,
          isRetryable: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Failed to generate USSD code.',
          type: AddMoneyErrorType.unknown,
          isRetryable: true,
        ),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const UssdTransferState();
  }
}

/// Provider for USSD transfer
final ussdTransferProvider =
    StateNotifierProvider<UssdTransferNotifier, UssdTransferState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return UssdTransferNotifier(service);
});

// ==================== CARD TOP-UP ====================

/// Steps in card top-up flow
enum CardTopUpStep {
  enterDetails,
  verifyOtp,
  success,
}

/// State for card top-up
class CardTopUpState {
  final CardTopUpResponse? response;
  final TransactionReceipt? receipt;
  final bool isLoading;
  final AddMoneyError? error;
  final CardTopUpStep currentStep;

  const CardTopUpState({
    this.response,
    this.receipt,
    this.isLoading = false,
    this.error,
    this.currentStep = CardTopUpStep.enterDetails,
  });

  CardTopUpState copyWith({
    CardTopUpResponse? response,
    TransactionReceipt? receipt,
    bool? isLoading,
    AddMoneyError? error,
    CardTopUpStep? currentStep,
    bool clearError = false,
  }) {
    return CardTopUpState(
      response: response ?? this.response,
      receipt: receipt ?? this.receipt,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

/// State notifier for card top-up
class CardTopUpNotifier extends StateNotifier<CardTopUpState> {
  final AddMoneyService _service;

  CardTopUpNotifier(this._service) : super(const CardTopUpState());

  /// Initiates card top-up transaction
  Future<void> initiateTopUp(CardTopUpRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _service.initiateCardTopUpWithDetails(request);
      state = CardTopUpState(
        response: response,
        isLoading: false,
        currentStep: response.requiresOtp
            ? CardTopUpStep.verifyOtp
            : CardTopUpStep.success,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'No internet connection.',
          type: AddMoneyErrorType.network,
          isRetryable: true,
        ),
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Request timed out.',
          type: AddMoneyErrorType.timeout,
          isRetryable: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: AddMoneyError(
          message: e.toString(),
          type: AddMoneyErrorType.unknown,
          isRetryable: true,
        ),
      );
    }
  }

  /// Verifies OTP for card top-up
  Future<void> verifyOtp(String otp) async {
    if (state.response?.otpReference == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final receipt = await _service.verifyCardTopUpOtp(
        otpReference: state.response!.otpReference!,
        otp: otp,
      );
      state = CardTopUpState(
        response: state.response,
        receipt: receipt,
        isLoading: false,
        currentStep: CardTopUpStep.success,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'No internet connection.',
          type: AddMoneyErrorType.network,
          isRetryable: true,
        ),
      );
    } on TimeoutException {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Request timed out.',
          type: AddMoneyErrorType.timeout,
          isRetryable: true,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: const AddMoneyError(
          message: 'Invalid OTP. Please try again.',
          type: AddMoneyErrorType.validation,
          isRetryable: false,
        ),
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const CardTopUpState();
  }
}

/// Provider for card top-up
final cardTopUpProvider =
    StateNotifierProvider<CardTopUpNotifier, CardTopUpState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return CardTopUpNotifier(service);
});

// ==================== AMOUNT SELECTION ====================

/// Selected amount for top-up
final selectedAmountProvider = StateProvider<double>((ref) => 0.0);