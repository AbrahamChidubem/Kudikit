import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/model/id&document/document_data.dart';
import 'package:kudipay/model/address/nigeria_state.dart';
import 'package:kudipay/model/transaction/transaction_model.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/services/add_money_services.dart';
import 'package:kudipay/services/transaction_service.dart';
import 'package:kudipay/usecases/selfie_state.dart';
import 'package:kudipay/model/user/user.dart';
import 'package:kudipay/presentation/address/address_notifier.dart';
import 'package:kudipay/presentation/selfie/selfie_notifier.dart';

// ==================== EXISTING PROVIDERS ====================

final pinVisibilityProvider = StateProvider<bool>((ref) => false);
final confirmPinVisibilityProvider = StateProvider<bool>((ref) => false);
final userIdProvider = StateProvider<String?>((ref) => null);
final userProvider = StateProvider<String>((ref) => 'Dubeeem');
final userEmailProvider = StateProvider<String>((ref) => 'example@gmail.com');

final isAuthenticatedProvider = Provider<bool>((ref) {
  final userId = ref.watch(userIdProvider);
  return userId != null && userId.isNotEmpty;
});

final userProfileProvider = Provider<UserProfile>((ref) {
  return UserProfile(
    userId: ref.watch(userIdProvider),
    name: ref.watch(userProvider),
    email: ref.watch(userEmailProvider),
  );
});

final selfieStateProvider =
    StateNotifierProvider<SelfieNotifier, SelfieState>((ref) {
  return SelfieNotifier();
});

final addressProvider = StateNotifierProvider<AddressNotifier, AddressData>(
  (ref) => AddressNotifier(),
);

final selectedStateProvider = StateProvider<String?>((ref) => null);

final availableLgasProvider = Provider<List<String>>((ref) {
  final selectedState = ref.watch(selectedStateProvider);
  if (selectedState == null) return [];

  final location = nigeriaLocations.firstWhere(
    (loc) => loc.state == selectedState,
    orElse: () => NigeriaLocation(state: "", lgas: []),
  );

  return location.lgas;
});

final documentUploadProvider =
    StateNotifierProvider<DocumentUploadNotifier, DocumentUploadData>(
  (ref) => DocumentUploadNotifier(),
);

class DocumentUploadNotifier extends StateNotifier<DocumentUploadData> {
  DocumentUploadNotifier() : super(DocumentUploadData());

  void setDocumentType(DocumentType type) {
    state = state.copyWith(documentType: type);
  }

  void setUploadedFile(File file, String fileName) {
    state = state.copyWith(
      uploadedFile: file,
      fileName: fileName,
      uploadProgress: 1.0,
    );
  }

  void updateProgress(double progress) {
    state = state.copyWith(uploadProgress: progress);
  }

  void reset() {
    state = DocumentUploadData();
  }
}

final userInfoProvider = StateProvider<UserInfo?>((ref) => null);

// ==================== TRANSACTION PROVIDERS ====================

final transactionServiceProvider = Provider<TransactionService>((ref) {
  return TransactionService(
    baseUrl: 'https://api.kudipay.com/api/v1',
  );
});

class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    bool? hasMore,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionService _service;

  TransactionNotifier(this._service) : super(const TransactionState());

  Future<void> loadTransactions({
    bool refresh = false,
    TransactionStatus? status,
  }) async {
    if (refresh) {
      state = const TransactionState(isLoading: true);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final transactions = await _service.getTransactions(
        status: status,
        limit: 50,
      );

      state = TransactionState(
        transactions: transactions,
        isLoading: false,
        hasMore: transactions.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    try {
      final newTransactions = await _service.getTransactions(
        offset: state.transactions.length,
        limit: 50,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...newTransactions],
        hasMore: newTransactions.length >= 50,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> searchTransactions(String query) async {
    if (query.isEmpty) {
      await loadTransactions(refresh: true);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final transactions = await _service.searchTransactions(query);
      state = TransactionState(
        transactions: transactions,
        isLoading: false,
        hasMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> downloadTransactions({
    String format = 'pdf',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return await _service.downloadTransactions(
        format: format,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final service = ref.watch(transactionServiceProvider);
  return TransactionNotifier(service);
});

class TransactionFilter {
  final TransactionStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionFilter({
    this.status,
    this.startDate,
    this.endDate,
  });

  TransactionFilter copyWith({
    TransactionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStatus = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TransactionFilter(
      status: clearStatus ? null : (status ?? this.status),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => const TransactionFilter());

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final state = ref.watch(transactionProvider);
  final filter = ref.watch(transactionFilterProvider);

  var transactions = state.transactions;

  if (filter.status != null) {
    transactions = transactions
        .where((transaction) => transaction.status == filter.status)
        .toList();
  }

  if (filter.startDate != null) {
    transactions = transactions
        .where((transaction) => transaction.date.isAfter(filter.startDate!))
        .toList();
  }
  if (filter.endDate != null) {
    transactions = transactions
        .where((transaction) => transaction.date.isBefore(filter.endDate!))
        .toList();
  }

  return transactions;
});

final groupedTransactionsProvider =
    Provider<Map<String, List<Transaction>>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  final Map<String, List<Transaction>> grouped = {};

  for (var transaction in transactions) {
    final key = _getDateKey(transaction.date);
    if (!grouped.containsKey(key)) {
      grouped[key] = [];
    }
    grouped[key]!.add(transaction);
  }

  return grouped;
});

String _getDateKey(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final transactionDate = DateTime(date.year, date.month, date.day);

  if (transactionDate == today) {
    return 'Today';
  }

  final days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  String dayName = days[date.weekday - 1];
  String monthName = months[date.month - 1];
  String dayWithSuffix = _getDayWithSuffix(date.day);

  return '$dayName, $monthName $dayWithSuffix, ${date.year}';
}

String _getDayWithSuffix(int day) {
  if (day >= 11 && day <= 13) {
    return '${day}th';
  }
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

class TransactionStats {
  final double totalIncome;
  final double totalExpense;
  final int totalTransactions;
  final int successfulCount;
  final int failedCount;
  final int pendingCount;

  TransactionStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalTransactions,
    required this.successfulCount,
    required this.failedCount,
    required this.pendingCount,
  });

  double get netBalance => totalIncome - totalExpense;
}

final transactionStatsProvider = Provider<TransactionStats>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);

  double totalIncome = 0;
  double totalExpense = 0;
  int successfulCount = 0;
  int failedCount = 0;
  int pendingCount = 0;

  for (var transaction in transactions) {
    if (transaction.type == TransactionType.credit) {
      totalIncome += transaction.amount;
    } else {
      totalExpense += transaction.amount;
    }

    switch (transaction.status) {
      case TransactionStatus.successful:
        successfulCount++;
        break;
      case TransactionStatus.failed:
        failedCount++;
        break;
      case TransactionStatus.pending:
        pendingCount++;
        break;
    }
  }

  return TransactionStats(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    totalTransactions: transactions.length,
    successfulCount: successfulCount,
    failedCount: failedCount,
    pendingCount: pendingCount,
  );
});

// ==================== ADD MONEY PROVIDERS ====================

final addMoneyServiceProvider = Provider<AddMoneyService>((ref) {
  return MockAddMoneyService();
});

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

enum AddMoneyErrorType {
  network,
  authentication,
  serverError,
  validation,
  timeout,
  unknown,
}

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

class AddMoneyOptionsNotifier extends StateNotifier<AddMoneyOptionsState> {
  final AddMoneyService _service;

  AddMoneyOptionsNotifier(this._service) : super(const AddMoneyOptionsState());

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

final addMoneyOptionsProvider =
    StateNotifierProvider<AddMoneyOptionsNotifier, AddMoneyOptionsState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return AddMoneyOptionsNotifier(service);
});

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

class AccountDetailsNotifier extends StateNotifier<AccountDetailsState> {
  final AddMoneyService _service;

  AccountDetailsNotifier(this._service) : super(const AccountDetailsState());

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

final accountDetailsProvider =
    StateNotifierProvider<AccountDetailsNotifier, AccountDetailsState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return AccountDetailsNotifier(service);
});

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

class QrCodeNotifier extends StateNotifier<QrCodeState> {
  final AddMoneyService _service;

  QrCodeNotifier(this._service) : super(const QrCodeState());

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

final qrCodeProvider = StateNotifierProvider<QrCodeNotifier, QrCodeState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return QrCodeNotifier(service);
});

final selectedAddMoneyOptionProvider = StateProvider<AddMoneyOption?>((ref) => null);

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

class BanksNotifier extends StateNotifier<BanksState> {
  final AddMoneyService _service;

  BanksNotifier(this._service) : super(const BanksState());

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

final banksProvider = StateNotifierProvider<BanksNotifier, BanksState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return BanksNotifier(service);
});

final selectedBankProvider = StateProvider<Bank?>((ref) => null);

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

class UssdTransferNotifier extends StateNotifier<UssdTransferState> {
  final AddMoneyService _service;

  UssdTransferNotifier(this._service) : super(const UssdTransferState());

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

final ussdTransferProvider =
    StateNotifierProvider<UssdTransferNotifier, UssdTransferState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return UssdTransferNotifier(service);
});

enum CardTopUpStep {
  enterDetails,
  verifyOtp,
  success,
}

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

class CardTopUpNotifier extends StateNotifier<CardTopUpState> {
  final AddMoneyService _service;

  CardTopUpNotifier(this._service) : super(const CardTopUpState());

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

final cardTopUpProvider =
    StateNotifierProvider<CardTopUpNotifier, CardTopUpState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return CardTopUpNotifier(service);
});

final selectedAmountProvider = StateProvider<double>((ref) => 0.0);
final bankSearchQueryProvider = StateProvider<String>((ref) => '');

// ==================== IDENTITY VERIFICATION PROVIDERS ====================

// User Verification Data Model
class UserVerificationData {
  final String firstName;
  final String middleName;
  final String lastName;
  final String fullName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String? photoUrl;
  final String gender;
  final String idNumber;
  final String idType;

  UserVerificationData({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.fullName,
    required this.dateOfBirth,
    required this.phoneNumber,
    this.photoUrl,
    required this.gender,
    required this.idNumber,
    required this.idType,
  });

  factory UserVerificationData.fromJson(Map<String, dynamic> json) {
    return UserVerificationData(
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      middleName: json['middle_name'] ?? json['middleName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      fullName: json['full_name'] ?? 
                json['fullName'] ?? 
                '${json['first_name']} ${json['middle_name']} ${json['last_name']}',
      dateOfBirth: DateTime.parse(json['date_of_birth'] ?? json['dateOfBirth']),
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      photoUrl: json['photo_url'] ?? json['photoUrl'],
      gender: json['gender'] ?? '',
      idNumber: json['bvn'] ?? json['nin'] ?? json['id_number'] ?? '',
      idType: json['id_type'] ?? 'BVN',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'phone_number': phoneNumber,
      'photo_url': photoUrl,
      'gender': gender,
      'id_number': idNumber,
      'id_type': idType,
    };
  }
}

// Identity Verification State
class IdentityVerificationState {
  final UserVerificationData? verificationData;
  final bool isVerifying;
  final String? error;

  const IdentityVerificationState({
    this.verificationData,
    this.isVerifying = false,
    this.error,
  });

  IdentityVerificationState copyWith({
    UserVerificationData? verificationData,
    bool? isVerifying,
    String? error,
    bool clearError = false,
  }) {
    return IdentityVerificationState(
      verificationData: verificationData ?? this.verificationData,
      isVerifying: isVerifying ?? this.isVerifying,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Verification Exception
class VerificationException implements Exception {
  final String message;
  final int? statusCode;

  VerificationException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

// Identity Verification Service
class IdentityVerificationService {
  final String baseUrl;
  final String? authToken;

  IdentityVerificationService({
    required this.baseUrl,
    this.authToken,
  });

  Future<UserVerificationData> verifyIdentity({
    required String idNumber,
    required String idType,
  }) async {
    // Mock implementation for testing
    return _mockVerifyIdentity(idNumber, idType);
    
    // TODO: Replace with real API call
    // final response = await http.post(
    //   Uri.parse('$baseUrl/verify-bvn-nin'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     if (authToken != null) 'Authorization': 'Bearer $authToken',
    //   },
    //   body: jsonEncode({
    //     'id_number': idNumber,
    //     'id_type': idType,
    //   }),
    // );
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   return UserVerificationData.fromJson(data);
    // } else if (response.statusCode == 404) {
    //   throw VerificationException('BVN/NIN not found', 404);
    // } else if (response.statusCode == 400) {
    //   throw VerificationException('Invalid format', 400);
    // } else {
    //   throw VerificationException('Verification failed', response.statusCode);
    // }
  }

  Future<UserVerificationData> _mockVerifyIdentity(
    String idNumber,
    String idType,
  ) async {
    await Future.delayed(const Duration(seconds: 2));

    if (idNumber.length != 11) {
      throw VerificationException('Invalid $idType format');
    }

    return UserVerificationData(
      firstName: 'MICHAEL',
      middleName: 'ASUQUO',
      lastName: 'TOLUWLASE',
      fullName: 'MICHAEL ASUQUO TOLUWLASE',
      dateOfBirth: DateTime(1990, 5, 15),
      phoneNumber: '08012345678',
      gender: 'Male',
      idNumber: idNumber,
      idType: idType,
    );
  }
}

// Identity Verification Notifier
class IdentityVerificationNotifier extends StateNotifier<IdentityVerificationState> {
  final IdentityVerificationService _service;

  IdentityVerificationNotifier(this._service) 
      : super(const IdentityVerificationState());

  Future<void> verifyIdentity({
    required String idNumber,
    required dynamic idType,
  }) async {
    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      final idTypeString = idType.toString().split('.').last;
      final verificationData = await _service.verifyIdentity(
        idNumber: idNumber,
        idType: idTypeString,
      );

      state = state.copyWith(
        verificationData: verificationData,
        isVerifying: false,
      );
    } on SocketException {
      state = state.copyWith(
        isVerifying: false,
        error: 'No internet connection. Please check your network.',
      );
    } on TimeoutException {
      state = state.copyWith(
        isVerifying: false,
        error: 'Request timed out. Please try again.',
      );
    } on VerificationException catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: 'Verification failed. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const IdentityVerificationState();
  }
}

// Identity Verification Service Provider
final identityVerificationServiceProvider = Provider<IdentityVerificationService>((ref) {
  return IdentityVerificationService(
    baseUrl: 'https://api.kudipay.com/api/v1',
    // authToken: ref.watch(authTokenProvider), // Add when you have auth token provider
  );
});

// Identity Verification Provider
final identityVerificationProvider = StateNotifierProvider<
    IdentityVerificationNotifier, IdentityVerificationState>((ref) {
  final service = ref.watch(identityVerificationServiceProvider);
  return IdentityVerificationNotifier(service);
});



// ==================REGISTRATION PROVIDER=======

class RegistrationState {
  final String? email;
  final String? phone;
  final String? password;
  final UserVerificationData? verificationData;
  final bool isVerifying;
  final String? error;
  
  const RegistrationState({
    this.email,
    this.phone,
    this.password,
    this.verificationData,
    this.isVerifying = false,
    this.error,
  });
  
  RegistrationState copyWith({
    String? email,
    String? phone,
    String? password,
    UserVerificationData? verificationData,
    bool? isVerifying,
    String? error,
    bool clearError = false,
  }) {
    return RegistrationState(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      verificationData: verificationData ?? this.verificationData,
      isVerifying: isVerifying ?? this.isVerifying,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final IdentityVerificationService _verificationService;
  
  RegistrationNotifier(this._verificationService) 
      : super(const RegistrationState());
  
  void setEmail(String email) {
    state = state.copyWith(email: email);
  }
  
  void setPassword(String password) {
    state = state.copyWith(password: password);
  }
  
  Future<void> verifyIdentity(String bvnOrNin) async {
    state = state.copyWith(isVerifying: true, clearError: true);
    
    try {
      final verificationData = 
          await _verificationService.verifyIdentity(bvnOrNin);
      
      state = state.copyWith(
        verificationData: verificationData,
        isVerifying: false,
      );
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: e.toString(),
      );
    }
  }
  
  Future<void> completeRegistration() async {
    // Save user to database with the verified information
    final user = User(
      email: state.email!,
      password: state.password!, // Should be hashed on backend
      fullName: state.verificationData!.fullName,
      firstName: state.verificationData!.firstName,
      lastName: state.verificationData!.lastName,
      dateOfBirth: state.verificationData!.dateOfBirth,
      bvn: state.verificationData!.bvn,
      phone: state.verificationData!.phoneNumber,
    );
    
    // Send to backend...
    await UserService().createAccount(user);
  }
}

final registrationProvider = 
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  final service = IdentityVerificationService(baseUrl: '');
  return RegistrationNotifier(service);
});