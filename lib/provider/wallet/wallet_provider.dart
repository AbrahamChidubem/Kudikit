// ============================================================================
// lib/provider/wallet/wallet_provider.dart
// Single source of truth for wallet state: balance, account number,
// account name, and recent transactions.
//
// All screens that previously had hardcoded "TODO: replace with real balance"
// should watch walletProvider instead.
// ============================================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

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

  /// Formatted balance string, e.g. "135,780.00"
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

  /// Two-letter initials from accountName for avatar widgets.
  String get initials {
    final parts = accountName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'MA';
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(const WalletState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Simulate network fetch — replace with real API call.
      await Future.delayed(const Duration(milliseconds: 900));
      state = state.copyWith(
        isLoading: false,
        balance: 135780.00,
        accountNumber: '8123456789',
        accountName: 'MICHAEL ASUQUO TOLUWALASE',
        bankName: 'KudiPay MFB',
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load wallet. Pull to refresh.',
      );
    }
  }

  Future<void> refresh() async {
    if (state.isRefreshing) return;
    state = state.copyWith(isRefreshing: true, clearError: true);
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      state = state.copyWith(
        isRefreshing: false,
        balance: 135780.00,
        accountNumber: '8123456789',
        accountName: 'MICHAEL ASUQUO TOLUWALASE',
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Refresh failed. Try again.',
      );
    }
  }

  /// Optimistically deduct after a successful payment so the balance
  /// reflects the new value immediately without waiting for a re-fetch.
  void deduct(double amount) {
    if (state.balance >= amount) {
      state = state.copyWith(balance: state.balance - amount);
    }
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier();
});
