// lib/features/wallet/presentation/controllers/wallet_controllers.dart
//
// Replaces:
//   lib/provider/wallet/wallet_provider.dart
//   lib/provider/funding/funding_provider.dart

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/core/errors/exceptions.dart';
import 'package:kudipay/core/providers/core_providers.dart';
import 'package:kudipay/features/auth/presentation/controllers/auth_controllers.dart';

import 'package:kudipay/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:kudipay/features/wallet/domain/entities/wallet_entities.dart';
import 'package:kudipay/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:kudipay/features/wallet/domain/usecases/wallet_usecases.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/services/add_money_services.dart';
import 'package:kudipay/config/env.dart';

// =============================================================================
// DI — repository + use-case providers
// =============================================================================

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.read(dioClientProvider));
});

final getWalletUseCaseProvider =
    Provider((ref) => GetWalletUseCase(ref.read(walletRepositoryProvider)));
final getAccountDetailsUseCaseProvider = Provider(
    (ref) => GetAccountDetailsUseCase(ref.read(walletRepositoryProvider)));
final generateQrCodeUseCaseProvider = Provider(
    (ref) => GenerateQrCodeUseCase(ref.read(walletRepositoryProvider)));

final addMoneyServiceProvider = Provider<AddMoneyService>((ref) {
  return AddMoneyService(
    baseUrl: kBaseUrl,
    authToken: ref.watch(authTokenProvider),
  );
});

// =============================================================================
// WalletState + WalletNotifier
// Drop-in replacement for the old WalletNotifier
// =============================================================================

class WalletState {
  final double balance;
  final String accountNumber;
  final String accountName;
  final String bankName;
  final bool isLoading;
  final bool isRefreshing;
  final DateTime? lastUpdated;
  final String? error;

  const WalletState({
    this.balance = 0.0,
    this.accountNumber = '',
    this.accountName = '',
    this.bankName = 'KudiPay MFB',
    this.isLoading = false,
    this.isRefreshing = false,
    this.lastUpdated,
    this.error,
  });

  String get formattedBalance {
    final parts = balance.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final result = StringBuffer();
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result.write(',');
      result.write(whole[i]);
      count++;
    }
    return '${result.toString().split('').reversed.join('')}.$decimal';
  }

  String get initials {
    final parts = accountName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'KK';
  }

  WalletState copyWith({
    double? balance,
    String? accountNumber,
    String? accountName,
    String? bankName,
    bool? isLoading,
    bool? isRefreshing,
    DateTime? lastUpdated,
    String? error,
    bool clearError = false,
  }) =>
      WalletState(
        balance: balance ?? this.balance,
        accountNumber: accountNumber ?? this.accountNumber,
        accountName: accountName ?? this.accountName,
        bankName: bankName ?? this.bankName,
        isLoading: isLoading ?? this.isLoading,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        error: clearError ? null : (error ?? this.error),
      );
}

class WalletNotifier extends StateNotifier<WalletState> {
  final GetWalletUseCase _getWallet;

  WalletNotifier(this._getWallet) : super(const WalletState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final wallet = await _getWallet.call();
      state = state.copyWith(
        isLoading: false,
        balance: wallet.balance,
        accountNumber: wallet.accountNumber,
        accountName: wallet.accountName,
        bankName: wallet.bankName,
        lastUpdated: wallet.lastUpdated,
      );
    } on KudiNetworkException {
      state = state.copyWith(
          isLoading: false, error: 'No internet. Pull to refresh.');
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Could not load wallet. Pull to refresh.');
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      final wallet = await _getWallet.call();
      state = state.copyWith(
        isRefreshing: false,
        balance: wallet.balance,
        accountNumber: wallet.accountNumber,
        accountName: wallet.accountName,
        bankName: wallet.bankName,
        lastUpdated: wallet.lastUpdated,
      );
    } on KudiNetworkException {
      state =
          state.copyWith(isRefreshing: false, error: 'No internet connection.');
    } catch (_) {
      state = state.copyWith(
          isRefreshing: false, error: 'Refresh failed. Try again.');
    }
  }

  /// Optimistically deduct from local balance after a confirmed payment.
  void deduct(double amount) {
    if (state.balance >= amount) {
      state = state.copyWith(balance: state.balance - amount);
    }
  }

  /// Optimistically add to local balance after a confirmed top-up.
  void credit(double amount) {
    state = state.copyWith(balance: state.balance + amount);
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.read(getWalletUseCaseProvider));
});

// =============================================================================
// Funding — Add Money Options
// =============================================================================

class AddMoneyOptionsState {
  final List<AddMoneyOption> options;
  final bool isLoading;
  final String? error;

  const AddMoneyOptionsState({
    this.options = const [],
    this.isLoading = false,
    this.error,
  });

  AddMoneyOptionsState copyWith({
    List<AddMoneyOption>? options,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AddMoneyOptionsState(
        options: options ?? this.options,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AddMoneyOptionsNotifier extends StateNotifier<AddMoneyOptionsState> {
  final AddMoneyService _service;

  AddMoneyOptionsNotifier(this._service) : super(const AddMoneyOptionsState());

  Future<void> loadOptions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final options = await _service.getAddMoneyOptions();
      state = AddMoneyOptionsState(options: options);
    } on SocketException {
      state = state.copyWith(
          isLoading: false,
          error: 'No internet connection. Please check your network.');
    } on TimeoutException {
      state = state.copyWith(
          isLoading: false, error: 'Request timed out. Please try again.');
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'An unexpected error occurred.');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final addMoneyOptionsProvider =
    StateNotifierProvider<AddMoneyOptionsNotifier, AddMoneyOptionsState>(
        (ref) => AddMoneyOptionsNotifier(ref.watch(addMoneyServiceProvider)));

final selectedAddMoneyOptionProvider =
    StateProvider<AddMoneyOption?>((ref) => null);

// =============================================================================
// Funding — Account Details
// =============================================================================

class AccountDetailsState {
  final AccountDetails? accountDetails;
  final bool isLoading;
  final String? error;

  const AccountDetailsState({
    this.accountDetails,
    this.isLoading = false,
    this.error,
  });

  AccountDetailsState copyWith({
    AccountDetails? accountDetails,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AccountDetailsState(
        accountDetails: accountDetails ?? this.accountDetails,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class AccountDetailsNotifier extends StateNotifier<AccountDetailsState> {
  final AddMoneyService _service;

  AccountDetailsNotifier(this._service) : super(const AccountDetailsState());

  Future<void> loadAccountDetails() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final details = await _service.getAccountDetails();
      state = AccountDetailsState(accountDetails: details);
    } on SocketException {
      state =
          state.copyWith(isLoading: false, error: 'No internet connection.');
    } on TimeoutException {
      state = state.copyWith(isLoading: false, error: 'Request timed out.');
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load account details.');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final accountDetailsProvider =
    StateNotifierProvider<AccountDetailsNotifier, AccountDetailsState>(
        (ref) => AccountDetailsNotifier(ref.watch(addMoneyServiceProvider)));

// =============================================================================
// Funding — QR Code
// =============================================================================

class QrCodeState {
  final String? qrCodeUrl;
  final bool isLoading;
  final String? error;

  const QrCodeState({this.qrCodeUrl, this.isLoading = false, this.error});

  QrCodeState copyWith({
    String? qrCodeUrl,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      QrCodeState(
        qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class QrCodeNotifier extends StateNotifier<QrCodeState> {
  final AddMoneyService _service;

  QrCodeNotifier(this._service) : super(const QrCodeState());

  Future<void> generateQrCode() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final url = await _service.generateQrCode();
      state = QrCodeState(qrCodeUrl: url);
    } on SocketException {
      state =
          state.copyWith(isLoading: false, error: 'No internet connection.');
    } on TimeoutException {
      state = state.copyWith(isLoading: false, error: 'Request timed out.');
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to generate QR code.');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final qrCodeProvider = StateNotifierProvider<QrCodeNotifier, QrCodeState>(
    (ref) => QrCodeNotifier(ref.watch(addMoneyServiceProvider)));

// =============================================================================
// Funding — Banks
// =============================================================================

class BanksState {
  final List<Bank> banks;
  final bool isLoading;
  final String? error;

  const BanksState({
    this.banks = const [],
    this.isLoading = false,
    this.error,
  });

  BanksState copyWith({
    List<Bank>? banks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      BanksState(
        banks: banks ?? this.banks,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class BanksNotifier extends StateNotifier<BanksState> {
  final AddMoneyService _service;

  BanksNotifier(this._service) : super(const BanksState());

  Future<void> loadBanks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final banks = await _service.getBanks();
      state = BanksState(banks: banks);
    } on SocketException {
      state =
          state.copyWith(isLoading: false, error: 'No internet connection.');
    } on TimeoutException {
      state = state.copyWith(isLoading: false, error: 'Request timed out.');
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load banks.');
    }
  }

  List<Bank> searchBanks(String query) {
    if (query.isEmpty) return state.banks;
    return state.banks
        .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final banksProvider = StateNotifierProvider<BanksNotifier, BanksState>(
    (ref) => BanksNotifier(ref.watch(addMoneyServiceProvider)));

final selectedBankProvider = StateProvider<Bank?>((ref) => null);
final bankSearchQueryProvider = StateProvider<String>((ref) => '');

// =============================================================================
// Funding — USSD Transfer
// =============================================================================

class UssdTransferState {
  final UssdTransferData? data;
  final bool isLoading;
  final String? error;

  const UssdTransferState({this.data, this.isLoading = false, this.error});

  UssdTransferState copyWith({
    UssdTransferData? data,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      UssdTransferState(
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

class UssdTransferNotifier extends StateNotifier<UssdTransferState> {
  final AddMoneyService _service;

  UssdTransferNotifier(this._service) : super(const UssdTransferState());

  Future<void> generateUssdCode({
    required String bankCode,
    required double amount,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final data =
          await _service.generateUssdCode(bankCode: bankCode, amount: amount);
      state = UssdTransferState(data: data);
    } on SocketException {
      state =
          state.copyWith(isLoading: false, error: 'No internet connection.');
    } on TimeoutException {
      state = state.copyWith(isLoading: false, error: 'Request timed out.');
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to generate USSD code.');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const UssdTransferState();
}

final ussdTransferProvider =
    StateNotifierProvider<UssdTransferNotifier, UssdTransferState>(
        (ref) => UssdTransferNotifier(ref.watch(addMoneyServiceProvider)));

// =============================================================================
// Funding — Card Top-Up
// =============================================================================

enum CardTopUpStep { enterDetails, verifyOtp, success }

class CardTopUpState {
  final CardTopUpResponse? response;
  final TransactionReceipt? receipt;
  final bool isLoading;
  final String? error;
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
    String? error,
    CardTopUpStep? currentStep,
    bool clearError = false,
  }) =>
      CardTopUpState(
        response: response ?? this.response,
        receipt: receipt ?? this.receipt,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        currentStep: currentStep ?? this.currentStep,
      );
}

class CardTopUpNotifier extends StateNotifier<CardTopUpState> {
  final AddMoneyService _service;

  CardTopUpNotifier(this._service) : super(const CardTopUpState());

  Future<void> initiateTopUp(CardTopUpRequest request) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _service.initiateCardTopUpWithDetails(request);
      state = CardTopUpState(
        response: response,
        currentStep: response.requiresOtp
            ? CardTopUpStep.verifyOtp
            : CardTopUpStep.success,
      );
    } on SocketException {
      state =
          state.copyWith(isLoading: false, error: 'No internet connection.');
    } on TimeoutException {
      state = state.copyWith(isLoading: false, error: 'Request timed out.');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

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
        currentStep: CardTopUpStep.success,
      );
    } on SocketException {
      state =
          state.copyWith(isLoading: false, error: 'No internet connection.');
    } on TimeoutException {
      state = state.copyWith(isLoading: false, error: 'Request timed out.');
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Invalid OTP. Please try again.');
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
  void reset() => state = const CardTopUpState();
}

final cardTopUpProvider =
    StateNotifierProvider<CardTopUpNotifier, CardTopUpState>(
        (ref) => CardTopUpNotifier(ref.watch(addMoneyServiceProvider)));

// =============================================================================
// Misc
// =============================================================================

final selectedAmountProvider = StateProvider<double>((ref) => 0.0);
