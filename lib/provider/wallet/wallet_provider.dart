// lib/provider/wallet/wallet_provider.dart
// FIXED:
//   - Balance, account number and account name are no longer hardcoded.
//   - _load() and refresh() call the mock API helpers from MockWalletData.
//     When the backend is ready, replace the two mock calls with:
//       GET $kBaseUrl/wallet/balance
//       GET $kBaseUrl/wallet/account-details

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/mock/mock_api_data.dart';


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
  }) {
    return WalletState(
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

  String get formattedBalance {
    final parts = balance.toStringAsFixed(2).split('.');
    final whole = parts[0];
    final decimal = parts[1];
    final buf = StringBuffer();
    int count = 0;
    for (int i = whole.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(whole[i]);
      count++;
    }
    return '${buf.toString().split('').reversed.join('')}.$decimal';
  }

  String get initials {
    final parts = accountName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'KP';
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // ── TODO: Replace with real HTTP calls when backend is ready ──────────
      // final balanceResp = await ApiService.instance.get('/wallet/balance', token: authToken);
      // final acctResp    = await ApiService.instance.get('/wallet/account-details', token: authToken);
      await Future.delayed(const Duration(milliseconds: 900));

      final balanceData = MockWalletData.balanceResponse;
      final acctData    = MockWalletData.accountDetailsResponse;

      state = state.copyWith(
        isLoading: false,
        balance: (balanceData['balance'] as num).toDouble(),
        accountNumber: acctData['account_number'] as String,
        accountName: acctData['account_name'] as String,
        bankName: acctData['bank_name'] as String,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Could not load wallet. Pull to refresh.');
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      // ── TODO: Replace with real HTTP call ─────────────────────────────────
      await Future.delayed(const Duration(milliseconds: 700));

      final balanceData = MockWalletData.balanceResponse;
      final acctData    = MockWalletData.accountDetailsResponse;

      state = state.copyWith(
        isRefreshing: false,
        balance: (balanceData['balance'] as num).toDouble(),
        accountNumber: acctData['account_number'] as String,
        accountName: acctData['account_name'] as String,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isRefreshing: false, error: 'Refresh failed. Try again.');
    }
  }

  /// Optimistically deduct after a successful payment.
  void deduct(double amount) {
    if (state.balance >= amount) {
      state = state.copyWith(balance: state.balance - amount);
    }
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});