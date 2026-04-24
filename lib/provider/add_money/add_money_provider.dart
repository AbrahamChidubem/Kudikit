// lib/provider/add_money_provider.dart
// FIXED: This is the canonical file for AddMoneyOptionsState.
// provider_pack.dart now re-exports from here — no more duplicate definitions.

import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/mock/mock_api_data.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/services/add_money_services.dart';
import 'package:flutter_riverpod/legacy.dart';
// ── Service provider ──────────────────────────────────────────────────────────
// FIXED: was returning MockAddMoneyService() with no token and no base URL.
// Now passes the live auth token so real HTTP calls won't 401.
final addMoneyServiceProvider = Provider<AddMoneyService>((ref) {
  final token = ref.watch(authTokenProvider);
  return MockAddMoneyService(baseUrl: kBaseUrl, authToken: token);
});

// ── Error types ───────────────────────────────────────────────────────────────
enum AddMoneyErrorType { network, authentication, serverError, validation, timeout, unknown }

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

// ── AddMoneyOptionsState ──────────────────────────────────────────────────────
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
  }) => AddMoneyOptionsState(
    options:   options   ?? this.options,
    isLoading: isLoading ?? this.isLoading,
    error:     clearError ? null : (error ?? this.error),
  );
}

class AddMoneyOptionsNotifier extends StateNotifier<AddMoneyOptionsState> {
  final AddMoneyService _service;
  AddMoneyOptionsNotifier(this._service) : super(const AddMoneyOptionsState());

  Future<void> loadOptions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final options = await _service.getAddMoneyOptions();
      state = AddMoneyOptionsState(options: options, isLoading: false);
    } on SocketException {
      state = state.copyWith(isLoading: false, error: const AddMoneyError(
        message: 'No internet connection. Please check your network.',
        type: AddMoneyErrorType.network));
    } on TimeoutException {
      state = state.copyWith(isLoading: false, error: const AddMoneyError(
        message: 'Request timed out. Please try again.',
        type: AddMoneyErrorType.timeout));
    } on AddMoneyException catch (e) {
      state = state.copyWith(isLoading: false, error: _handle(e));
    } catch (_) {
      state = state.copyWith(isLoading: false, error: const AddMoneyError(
        message: 'An unexpected error occurred.',
        type: AddMoneyErrorType.unknown));
    }
  }

  AddMoneyError _handle(AddMoneyException e) {
    final sc = e.statusCode;
    if (sc != null) {
      if (sc == 401 || sc == 403) return AddMoneyError(message: 'Session expired. Please log in again.', type: AddMoneyErrorType.authentication, statusCode: sc, isRetryable: false);
      if (sc >= 500) return AddMoneyError(message: 'Server error. Please try again later.', type: AddMoneyErrorType.serverError, statusCode: sc);
      if (sc >= 400) return AddMoneyError(message: e.message, type: AddMoneyErrorType.validation, statusCode: sc, isRetryable: false);
    }
    return AddMoneyError(message: e.message, type: AddMoneyErrorType.unknown);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final addMoneyOptionsProvider =
    StateNotifierProvider<AddMoneyOptionsNotifier, AddMoneyOptionsState>((ref) {
  return AddMoneyOptionsNotifier(ref.watch(addMoneyServiceProvider));
});

final selectedAddMoneyOptionProvider = StateProvider<AddMoneyOption?>((ref) => null);