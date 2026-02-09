import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/model/id&document/document_data.dart';
import 'package:kudipay/model/address/nigeria_state.dart';
import 'package:kudipay/model/transaction/transaction_model.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/presentation/notification/notification_preferences.dart';
import 'package:kudipay/services/add_money_services.dart';
import 'package:kudipay/services/email_change_services.dart';
import 'package:kudipay/services/notification_preference_services.dart';
import 'package:kudipay/services/transaction_service.dart';
import 'package:kudipay/usecases/selfie_state.dart';
import 'package:kudipay/model/user/user.dart';
import 'package:kudipay/presentation/address/address_notifier.dart';
import 'package:kudipay/presentation/selfie/selfie_notifier.dart';
import 'package:kudipay/services/connectivity_service.dart';



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

final qrCodeProvider =
    StateNotifierProvider<QrCodeNotifier, QrCodeState>((ref) {
  final service = ref.watch(addMoneyServiceProvider);
  return QrCodeNotifier(service);
});

final selectedAddMoneyOptionProvider =
    StateProvider<AddMoneyOption?>((ref) => null);

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

// Identification Type Enum
enum IdentificationType {
  BVN,
  NIN,
}

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

  // Detect if input is BVN or NIN
  IdentificationType detectIdType(String input) {
    if (input.length != 11) {
      throw VerificationException('Invalid ID length. Must be 11 digits.');
    }

    // BVN typically starts with 2, but this is simplified logic
    // Adjust based on actual requirements
    if (input.startsWith('2')) {
      return IdentificationType.BVN;
    } else {
      return IdentificationType.NIN;
    }
  }

  Future<UserVerificationData> verifyIdentity({
    required String idNumber,
    String? idType,
  }) async {
    // Auto-detect ID type if not provided
    final detectedIdType = idType ?? detectIdType(idNumber).name;

    // Mock implementation for testing
    return _mockVerifyIdentity(idNumber, detectedIdType);

    // TODO: Replace with real API call
    // final response = await http.post(
    //   Uri.parse('$baseUrl/verify-identity'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     if (authToken != null) 'Authorization': 'Bearer $authToken',
    //   },
    //   body: jsonEncode({
    //     'id_number': idNumber,
    //     'id_type': detectedIdType,
    //   }),
    // );
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body);
    //   return UserVerificationData.fromJson(data['user_data']);
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
class IdentityVerificationNotifier
    extends StateNotifier<IdentityVerificationState> {
  final IdentityVerificationService _service;

  IdentityVerificationNotifier(this._service)
      : super(const IdentityVerificationState());

  Future<void> verifyIdentity({
    required String idNumber,
    dynamic idType,
  }) async {
    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      String? idTypeString;
      if (idType != null) {
        idTypeString = idType.toString().contains('.')
            ? idType.toString().split('.').last
            : idType.toString();
      }

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

// Auth Token Provider (add this if you have authentication)
final authTokenProvider = StateProvider<String?>((ref) => null);

// Identity Verification Service Provider
final identityVerificationServiceProvider =
    Provider<IdentityVerificationService>((ref) {
  final authToken = ref.watch(authTokenProvider);
  return IdentityVerificationService(
    baseUrl: 'https://api.kudipay.com/api/v1',
    authToken: authToken,
  );
});

// Identity Verification Provider
final identityVerificationProvider = StateNotifierProvider<
    IdentityVerificationNotifier, IdentityVerificationState>((ref) {
  final service = ref.watch(identityVerificationServiceProvider);
  return IdentityVerificationNotifier(service);
});

// ==================== REGISTRATION PROVIDER ====================

class RegistrationState {
  final String? email;
  final String? phone;
  final String? password;
  final UserVerificationData? verificationData;
  final bool isVerifying;
  final bool isRegistering;
  final String? error;

  const RegistrationState({
    this.email,
    this.phone,
    this.password,
    this.verificationData,
    this.isVerifying = false,
    this.isRegistering = false,
    this.error,
  });

  RegistrationState copyWith({
    String? email,
    String? phone,
    String? password,
    UserVerificationData? verificationData,
    bool? isVerifying,
    bool? isRegistering,
    String? error,
    bool clearError = false,
  }) {
    return RegistrationState(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      verificationData: verificationData ?? this.verificationData,
      isVerifying: isVerifying ?? this.isVerifying,
      isRegistering: isRegistering ?? this.isRegistering,
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

  void setPhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password);
  }

  Future<void> verifyIdentity(String idNumber) async {
    state = state.copyWith(isVerifying: true, clearError: true);

    try {
      final verificationData = await _verificationService.verifyIdentity(
        idNumber: idNumber,
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
        error: 'Verification failed: ${e.toString()}',
      );
    }
  }

  Future<void> completeRegistration() async {
    if (state.email == null ||
        state.password == null ||
        state.verificationData == null) {
      state = state.copyWith(
        error: 'Missing required registration information',
      );
      return;
    }

    state = state.copyWith(isRegistering: true, clearError: true);

    try {
      // TODO: Replace with actual user creation logic
      // Example:
      // final user = UserModel(
      //   email: state.email!,
      //   password: state.password!, // Should be hashed on backend
      //   fullName: state.verificationData!.fullName,
      //   firstName: state.verificationData!.firstName,
      //   lastName: state.verificationData!.lastName,
      //   dateOfBirth: state.verificationData!.dateOfBirth,
      //   idNumber: state.verificationData!.idNumber,
      //   phone: state.verificationData!.phoneNumber,
      // );

      // await UserService().createAccount(user);

      // Mock delay
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(isRegistering: false);
    } catch (e) {
      state = state.copyWith(
        isRegistering: false,
        error: 'Registration failed: ${e.toString()}',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const RegistrationState();
  }
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  final service = ref.watch(identityVerificationServiceProvider);
  return RegistrationNotifier(service);
});


// =============== INTERNET CONNECTION================



/// Provider for connectivity service singleton
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService.instance;
  
  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Stream provider that monitors internet connectivity in real-time
/// 
/// Usage:
/// ```dart
/// final connectivityState = ref.watch(connectivityProvider);
/// connectivityState.when(
///   data: (isConnected) => isConnected ? OnlineWidget() : OfflineWidget(),
///   loading: () => LoadingWidget(),
///   error: (error, stack) => ErrorWidget(error),
/// );
/// ```
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectionChange;
});

/// Provider to get current connectivity status synchronously
/// 
/// Usage:
/// ```dart
/// final isConnected = ref.watch(currentConnectivityProvider);
/// if (isConnected) {
///   // Perform online operations
/// }
/// ```
final currentConnectivityProvider = Provider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.hasConnection;
});

/// Future provider to check internet connection once
/// 
/// Usage:
/// ```dart
/// final hasInternet = await ref.read(checkInternetProvider.future);
/// if (hasInternet) {
///   // Proceed with API call
/// }
/// ```
final checkInternetProvider = FutureProvider<bool>((ref) async {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return await connectivityService.hasInternetConnection();
});

/// State notifier for more complex connectivity state management
class ConnectivityState {
  final bool isConnected;
  final String? connectionType;
  final DateTime? lastChecked;
  final String? errorMessage;

  ConnectivityState({
    required this.isConnected,
    this.connectionType,
    this.lastChecked,
    this.errorMessage,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    String? connectionType,
    DateTime? lastChecked,
    String? errorMessage,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityService _connectivityService;

  ConnectivityNotifier(this._connectivityService)
      : super(ConnectivityState(isConnected: false)) {
    _initialize();
  }

  void _initialize() async {
    // Initialize connectivity service
    await _connectivityService.initialize();
    
    // Set initial state
    final isConnected = _connectivityService.hasConnection;
    final connectivityTypes = await _connectivityService.getConnectivityType();
    
    state = ConnectivityState(
      isConnected: isConnected,
      connectionType: connectivityTypes.isNotEmpty 
          ? connectivityTypes.first.displayName 
          : 'Unknown',
      lastChecked: DateTime.now(),
    );

    // Listen to connectivity changes
    _connectivityService.connectionChange.listen((isConnected) async {
      final connectivityTypes = await _connectivityService.getConnectivityType();
      
      state = ConnectivityState(
        isConnected: isConnected,
        connectionType: connectivityTypes.isNotEmpty 
            ? connectivityTypes.first.displayName 
            : 'Unknown',
        lastChecked: DateTime.now(),
      );
    });
  }

  /// Manually refresh connectivity status
  Future<void> refresh() async {
    try {
      final isConnected = await _connectivityService.hasInternetConnection();
      final connectivityTypes = await _connectivityService.getConnectivityType();
      
      state = ConnectivityState(
        isConnected: isConnected,
        connectionType: connectivityTypes.isNotEmpty 
            ? connectivityTypes.first.displayName 
            : 'Unknown',
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to check connectivity: $e',
      );
    }
  }
}

/// State notifier provider for advanced connectivity management
final connectivityStateProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return ConnectivityNotifier(connectivityService);
});

// ======================DEVICE LINKING========================== this thing really stress me .. jesus

// ==================== MODELS ====================

enum VerificationMethod {
  email,
  oldDevice,
}

class DeviceLinkingData {
  final String? email;
  final String? maskedEmail;
  final String? oldDeviceName;
  final String? verificationCode;
  final bool isCodeSent;
  final bool isVerified;
  final DateTime? codeSentAt;

  const DeviceLinkingData({
    this.email,
    this.maskedEmail,
    this.oldDeviceName,
    this.verificationCode,
    this.isCodeSent = false,
    this.isVerified = false,
    this.codeSentAt,
  });

  DeviceLinkingData copyWith({
    String? email,
    String? maskedEmail,
    String? oldDeviceName,
    String? verificationCode,
    bool? isCodeSent,
    bool? isVerified,
    DateTime? codeSentAt,
  }) {
    return DeviceLinkingData(
      email: email ?? this.email,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      oldDeviceName: oldDeviceName ?? this.oldDeviceName,
      verificationCode: verificationCode ?? this.verificationCode,
      isCodeSent: isCodeSent ?? this.isCodeSent,
      isVerified: isVerified ?? this.isVerified,
      codeSentAt: codeSentAt ?? this.codeSentAt,
    );
  }
}

class DataSyncSelection {
  final bool savedBeneficiary;
  final bool recentTransactions;
  final bool appPreferences;

  const DataSyncSelection({
    this.savedBeneficiary = true,
    this.recentTransactions = true,
    this.appPreferences = false,
  });

  DataSyncSelection copyWith({
    bool? savedBeneficiary,
    bool? recentTransactions,
    bool? appPreferences,
  }) {
    return DataSyncSelection(
      savedBeneficiary: savedBeneficiary ?? this.savedBeneficiary,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      appPreferences: appPreferences ?? this.appPreferences,
    );
  }
}

// ==================== STATE ====================

class DeviceLinkingState {
  final DeviceLinkingData? data;
  final DataSyncSelection syncSelection;
  final VerificationMethod selectedMethod;
  final bool isLoading;
  final bool isSendingCode;
  final bool isVerifyingCode;
  final bool isSyncing;
  final String? error;
  final String? successMessage;

  const DeviceLinkingState({
    this.data,
    this.syncSelection = const DataSyncSelection(),
    this.selectedMethod = VerificationMethod.email,
    this.isLoading = false,
    this.isSendingCode = false,
    this.isVerifyingCode = false,
    this.isSyncing = false,
    this.error,
    this.successMessage,
  });

  DeviceLinkingState copyWith({
    DeviceLinkingData? data,
    DataSyncSelection? syncSelection,
    VerificationMethod? selectedMethod,
    bool? isLoading,
    bool? isSendingCode,
    bool? isVerifyingCode,
    bool? isSyncing,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return DeviceLinkingState(
      data: data ?? this.data,
      syncSelection: syncSelection ?? this.syncSelection,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      isLoading: isLoading ?? this.isLoading,
      isSendingCode: isSendingCode ?? this.isSendingCode,
      isVerifyingCode: isVerifyingCode ?? this.isVerifyingCode,
      isSyncing: isSyncing ?? this.isSyncing,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ==================== SERVICE ====================

class DeviceLinkingException implements Exception {
  final String message;
  final int? statusCode;

  DeviceLinkingException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class DeviceLinkingService {
  final String baseUrl;
  final String? authToken;

  DeviceLinkingService({
    required this.baseUrl,
    this.authToken,
  });

  Future<DeviceLinkingData> getUserDeviceInfo() async {
    // Mock implementation
    return _mockGetUserDeviceInfo();
  }

  Future<bool> sendVerificationCode(String email, VerificationMethod method) async {
    // Mock implementation
    return _mockSendVerificationCode(email, method);
  }

  Future<bool> verifyCode(String code) async {
    // Mock implementation
    return _mockVerifyCode(code);
  }

  Future<bool> syncData(DataSyncSelection selection) async {
    // Mock implementation
    return _mockSyncData(selection);
  }

  // Mock implementations
  Future<DeviceLinkingData> _mockGetUserDeviceInfo() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const DeviceLinkingData(
      email: 'user@example.com',
      maskedEmail: 'u***8@gmail.com',
      oldDeviceName: 'iPhone 14 Pro',
    );
  }

  Future<bool> _mockSendVerificationCode(String email, VerificationMethod method) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  Future<bool> _mockVerifyCode(String code) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simple mock validation
    return code.length == 6;
  }

  Future<bool> _mockSyncData(DataSyncSelection selection) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}

// ==================== NOTIFIER ====================

class DeviceLinkingNotifier extends StateNotifier<DeviceLinkingState> {
  final DeviceLinkingService _service;

  DeviceLinkingNotifier(this._service) : super(const DeviceLinkingState());

  Future<void> loadUserDeviceInfo() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final data = await _service.getUserDeviceInfo();
      state = state.copyWith(
        data: data,
        isLoading: false,
      );
    } on SocketException {
      state = state.copyWith(
        isLoading: false,
        error: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load device information.',
      );
    }
  }

  void selectVerificationMethod(VerificationMethod method) {
    state = state.copyWith(selectedMethod: method);
  }

  Future<void> sendVerificationCode() async {
    if (state.data?.email == null) {
      state = state.copyWith(error: 'Email not found');
      return;
    }

    state = state.copyWith(isSendingCode: true, clearError: true);

    try {
      await _service.sendVerificationCode(
        state.data!.email!,
        state.selectedMethod,
      );

      state = state.copyWith(
        isSendingCode: false,
        data: state.data?.copyWith(
          isCodeSent: true,
          codeSentAt: DateTime.now(),
        ),
        successMessage: 'Verification code sent successfully',
      );
    } on SocketException {
      state = state.copyWith(
        isSendingCode: false,
        error: 'No internet connection. Please check your network.',
      );
    } catch (e) {
      state = state.copyWith(
        isSendingCode: false,
        error: 'Failed to send verification code.',
      );
    }
  }

  Future<bool> verifyCode(String code) async {
    state = state.copyWith(isVerifyingCode: true, clearError: true);

    try {
      final isValid = await _service.verifyCode(code);

      if (isValid) {
        state = state.copyWith(
          isVerifyingCode: false,
          data: state.data?.copyWith(
            verificationCode: code,
            isVerified: true,
          ),
        );
        return true;
      } else {
        state = state.copyWith(
          isVerifyingCode: false,
          error: 'Invalid verification code',
        );
        return false;
      }
    } on SocketException {
      state = state.copyWith(
        isVerifyingCode: false,
        error: 'No internet connection. Please check your network.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isVerifyingCode: false,
        error: 'Verification failed. Please try again.',
      );
      return false;
    }
  }

  void updateSyncSelection({
    bool? savedBeneficiary,
    bool? recentTransactions,
    bool? appPreferences,
  }) {
    state = state.copyWith(
      syncSelection: state.syncSelection.copyWith(
        savedBeneficiary: savedBeneficiary,
        recentTransactions: recentTransactions,
        appPreferences: appPreferences,
      ),
    );
  }

  Future<bool> syncData() async {
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      await _service.syncData(state.syncSelection);

      state = state.copyWith(
        isSyncing: false,
        successMessage: 'Data synced successfully',
      );
      return true;
    } on SocketException {
      state = state.copyWith(
        isSyncing: false,
        error: 'No internet connection. Please check your network.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        error: 'Failed to sync data.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  void reset() {
    state = const DeviceLinkingState();
  }
}

// ====================DEVICE LINKING PROVIDERS ====================

final deviceLinkingServiceProvider = Provider<DeviceLinkingService>((ref) {
  return DeviceLinkingService(
    baseUrl: 'https://api.kudipay.com/api/v1',
  );
});

final deviceLinkingProvider =
    StateNotifierProvider<DeviceLinkingNotifier, DeviceLinkingState>((ref) {
  final service = ref.watch(deviceLinkingServiceProvider);
  return DeviceLinkingNotifier(service);
});



// ====================   P2P TRANSFER MODELS   ====================

enum TransferType {
  kudikit,
  otherBank,
}

enum TransactionCategory {
  food,
  transport,
  bills,
  shopping,
  entertainment,
  others,
}

class RecipientInfo {
  final String accountNumber;
  final String name;
  final String? bank;
  final String? avatarUrl;

  const RecipientInfo({
    required this.accountNumber,
    required this.name,
    this.bank,
    this.avatarUrl,
  });

  RecipientInfo copyWith({
    String? accountNumber,
    String? name,
    String? bank,
    String? avatarUrl,
  }) {
    return RecipientInfo(
      accountNumber: accountNumber ?? this.accountNumber,
      name: name ?? this.name,
      bank: bank ?? this.bank,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class RecentContact {
  final String id;
  final String name;
  final String accountNumber;
  final String bank;
  final String? avatarUrl;
  final DateTime lastTransferDate;

  const RecentContact({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bank,
    this.avatarUrl,
    required this.lastTransferDate,
  });
}

class TransferData {
  final RecipientInfo? recipient;
  final double? amount;
  final TransactionCategory? category;
  final String? note;
  final double balance;
  final double fee;

  const TransferData({
    this.recipient,
    this.amount,
    this.category,
    this.note,
    this.balance = 5000.00,
    this.fee = 0.0,
  });

  TransferData copyWith({
    RecipientInfo? recipient,
    double? amount,
    TransactionCategory? category,
    String? note,
    double? balance,
    double? fee,
  }) {
    return TransferData(
      recipient: recipient ?? this.recipient,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      note: note ?? this.note,
      balance: balance ?? this.balance,
      fee: fee ?? this.fee,
    );
  }

  bool get hasInsufficientBalance {
    if (amount == null) return false;
    return (amount! + fee) > balance;
  }
}

class TransactionResult {
  final String transactionId;
  final String transactionType;
  final double amount;
  final double fee;
  final String payingBank;
  final String payingBankAccount;
  final String creditedTo;
  final String? note;
  final DateTime transactionDate;
  final bool isSuccessful;

  const TransactionResult({
    required this.transactionId,
    required this.transactionType,
    required this.amount,
    required this.fee,
    required this.payingBank,
    required this.payingBankAccount,
    required this.creditedTo,
    this.note,
    required this.transactionDate,
    this.isSuccessful = true,
  });
}

// ==================== STATE ====================

class P2PTransferState {
  final TransferType transferType;
  final TransferData transferData;
  final List<RecentContact> recentContacts;
  final List<RecentContact> favouriteContacts;
  final bool isValidatingAccount;
  final bool isProcessingTransfer;
  final String? error;
  final TransactionResult? transactionResult;
  final bool showPinDialog;
  final bool showConfirmDialog;

  const P2PTransferState({
    this.transferType = TransferType.kudikit,
    this.transferData = const TransferData(),
    this.recentContacts = const [],
    this.favouriteContacts = const [],
    this.isValidatingAccount = false,
    this.isProcessingTransfer = false,
    this.error,
    this.transactionResult,
    this.showPinDialog = false,
    this.showConfirmDialog = false,
  });

  P2PTransferState copyWith({
    TransferType? transferType,
    TransferData? transferData,
    List<RecentContact>? recentContacts,
    List<RecentContact>? favouriteContacts,
    bool? isValidatingAccount,
    bool? isProcessingTransfer,
    String? error,
    TransactionResult? transactionResult,
    bool? showPinDialog,
    bool? showConfirmDialog,
    bool clearError = false,
  }) {
    return P2PTransferState(
      transferType: transferType ?? this.transferType,
      transferData: transferData ?? this.transferData,
      recentContacts: recentContacts ?? this.recentContacts,
      favouriteContacts: favouriteContacts ?? this.favouriteContacts,
      isValidatingAccount: isValidatingAccount ?? this.isValidatingAccount,
      isProcessingTransfer: isProcessingTransfer ?? this.isProcessingTransfer,
      error: clearError ? null : (error ?? this.error),
      transactionResult: transactionResult ?? this.transactionResult,
      showPinDialog: showPinDialog ?? this.showPinDialog,
      showConfirmDialog: showConfirmDialog ?? this.showConfirmDialog,
    );
  }
}

// ==================== SERVICE ====================

class P2PTransferException implements Exception {
  final String message;
  final int? statusCode;

  P2PTransferException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class P2PTransferService {
  final String baseUrl;
  final String? authToken;

  P2PTransferService({
    required this.baseUrl,
    this.authToken,
  });

  Future<RecipientInfo> validateAccount(String accountNumber, TransferType type) async {
    return _mockValidateAccount(accountNumber, type);
  }

  Future<List<RecentContact>> getRecentContacts() async {
    return _mockGetRecentContacts();
  }

  Future<TransactionResult> processTransfer(TransferData data) async {
    return _mockProcessTransfer(data);
  }

  // Mock implementations
  Future<RecipientInfo> _mockValidateAccount(String accountNumber, TransferType type) async {
    await Future.delayed(const Duration(seconds: 1));

    if (accountNumber.length < 10) {
      throw P2PTransferException('Invalid account number');
    }

    if (type == TransferType.kudikit && !accountNumber.startsWith('8')) {
      throw P2PTransferException('Invalid Kudikit account number.');
    }

    return RecipientInfo(
      accountNumber: accountNumber,
      name: 'PETER AKINOLA',
      bank: type == TransferType.kudikit ? 'Kudikit' : 'Guaranty Trust Bank',
    );
  }

  Future<List<RecentContact>> _mockGetRecentContacts() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      RecentContact(
        id: '1',
        name: 'Squad YEM YEM SUPERSTORE LIMITED',
        accountNumber: '3004749378',
        bank: 'GTBank',
        lastTransferDate: DateTime.now().subtract(const Duration(days: 7)),
      ),
      RecentContact(
        id: '2',
        name: 'John Doe Peters',
        accountNumber: '3004749378',
        bank: 'GTBank',
        lastTransferDate: DateTime.now().subtract(const Duration(days: 11)),
      ),
    ];
  }

  Future<TransactionResult> _mockProcessTransfer(TransferData data) async {
    await Future.delayed(const Duration(seconds: 2));

    return TransactionResult(
      transactionId: '213546364738829374474939',
      transactionType: 'Transfer',
      amount: data.amount!,
      fee: data.fee,
      payingBank: 'Guaranty Trust Bank',
      payingBankAccount: '534256**********6758',
      creditedTo: 'Kudikit wallet',
      note: data.note,
      transactionDate: DateTime.now(),
      isSuccessful: true,
    );
  }
}

// ==================== NOTIFIER ====================

class P2PTransferNotifier extends StateNotifier<P2PTransferState> {
  final P2PTransferService _service;

  P2PTransferNotifier(this._service) : super(const P2PTransferState()) {
    _loadRecentContacts();
  }

  Future<void> _loadRecentContacts() async {
    try {
      final contacts = await _service.getRecentContacts();
      state = state.copyWith(recentContacts: contacts);
    } catch (e) {
      // Silently fail for initial load
    }
  }

  void setTransferType(TransferType type) {
    state = state.copyWith(
      transferType: type,
      transferData: const TransferData(), // Reset transfer data
    );
  }

  Future<void> validateAccount(String accountNumber) async {
    state = state.copyWith(isValidatingAccount: true, clearError: true);

    try {
      final recipient = await _service.validateAccount(
        accountNumber,
        state.transferType,
      );

      state = state.copyWith(
        isValidatingAccount: false,
        transferData: state.transferData.copyWith(recipient: recipient),
      );
    } on SocketException {
      state = state.copyWith(
        isValidatingAccount: false,
        error: 'No internet connection. Please check your network.',
      );
    } on P2PTransferException catch (e) {
      state = state.copyWith(
        isValidatingAccount: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isValidatingAccount: false,
        error: 'Account validation failed. Please try again.',
      );
    }
  }

  void selectRecipient(RecipientInfo recipient) {
    state = state.copyWith(
      transferData: state.transferData.copyWith(recipient: recipient),
    );
  }

  void setAmount(double amount) {
    state = state.copyWith(
      transferData: state.transferData.copyWith(amount: amount),
    );
  }

  void setCategory(TransactionCategory category) {
    state = state.copyWith(
      transferData: state.transferData.copyWith(category: category),
    );
  }

  void setNote(String note) {
    state = state.copyWith(
      transferData: state.transferData.copyWith(note: note),
    );
  }

  void showConfirmation() {
    state = state.copyWith(showConfirmDialog: true);
  }

  void hideConfirmation() {
    state = state.copyWith(showConfirmDialog: false);
  }

  void showPinEntry() {
    state = state.copyWith(showPinDialog: true, showConfirmDialog: false);
  }

  void hidePinEntry() {
    state = state.copyWith(showPinDialog: false);
  }

  Future<void> processTransfer(String pin) async {
    state = state.copyWith(isProcessingTransfer: true, clearError: true);

    try {
      // Validate PIN (mock validation)
      if (pin.length != 6) {
        throw P2PTransferException('Invalid PIN');
      }

      final result = await _service.processTransfer(state.transferData);

      state = state.copyWith(
        isProcessingTransfer: false,
        transactionResult: result,
        showPinDialog: false,
      );
    } on SocketException {
      state = state.copyWith(
        isProcessingTransfer: false,
        error: 'No internet connection. Please check your network.',
      );
    } on P2PTransferException catch (e) {
      state = state.copyWith(
        isProcessingTransfer: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessingTransfer: false,
        error: 'Transfer failed. Please try again.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  void reset() {
    state = const P2PTransferState();
    _loadRecentContacts();
  }
}

// ==================== PROVIDERS ====================

final p2pTransferServiceProvider = Provider<P2PTransferService>((ref) {
  return P2PTransferService(
    baseUrl: 'https://api.kudipay.com/api/v1',
  );
});

final p2pTransferProvider =
    StateNotifierProvider<P2PTransferNotifier, P2PTransferState>((ref) {
  final service = ref.watch(p2pTransferServiceProvider);
  return P2PTransferNotifier(service);
});

// Helper provider for quick amount selection
final quickAmountsProvider = Provider<List<double>>((ref) {
  return [200, 1000, 2000, 3000, 5000, 9999];
});

// ================================ NOTIFICATION PROVIDER ==============================

final notificationPreferencesServiceProvider = Provider<NotificationPreferencesService>((ref) {
  return NotificationPreferencesService();
});

// State notifier for notification preferences
class NotificationPreferencesNotifier extends StateNotifier<AsyncValue<NotificationPreferences>> {
  final NotificationPreferencesService _service;

  NotificationPreferencesNotifier(this._service) : super(const AsyncValue.loading()) {
    loadPreferences();
  }

  /// Load preferences from server or local storage
  Future<void> loadPreferences() async {
    state = const AsyncValue.loading();
    
    try {
      // Try to load from local storage first for instant UI
      final localPrefs = await _service.loadLocalPreferences();
      state = AsyncValue.data(localPrefs);
      
      // Then fetch from server to sync
      final serverPrefs = await _service.fetchPreferences();
      state = AsyncValue.data(serverPrefs);
      
      // Save to local storage
      await _service.savePreferencesLocally(serverPrefs);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Toggle a specific preference
  Future<void> togglePreference(String key, bool value) async {
    final currentPrefs = state.value;
    if (currentPrefs == null) return;

    // Optimistically update UI
    final updatedPrefs = _updatePreferenceByKey(currentPrefs, key, value);
    state = AsyncValue.data(updatedPrefs);

    try {
      // Update on server
      final success = await _service.updateSinglePreference(key, value);
      
      if (success) {
        // Save to local storage
        await _service.savePreferencesLocally(updatedPrefs);
      } else {
        // Revert on failure
        state = AsyncValue.data(currentPrefs);
      }
    } catch (e) {
      // Revert on error
      state = AsyncValue.data(currentPrefs);
    }
  }

  /// Update all preferences at once
  Future<void> updateAllPreferences(NotificationPreferences preferences) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await _service.updatePreferences(preferences);
      
      if (success) {
        state = AsyncValue.data(preferences);
        await _service.savePreferencesLocally(preferences);
      } else {
        throw Exception('Failed to update preferences');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Helper to update preference by key
  NotificationPreferences _updatePreferenceByKey(
    NotificationPreferences prefs,
    String key,
    bool value,
  ) {
    switch (key) {
      // Transaction
      case 'transactionSuccess':
        return prefs.copyWith(transactionSuccess: value);
      case 'depositNotification':
        return prefs.copyWith(depositNotification: value);
      case 'withdrawalNotification':
        return prefs.copyWith(withdrawalNotification: value);
      case 'largeTransactionAlert':
        return prefs.copyWith(largeTransactionAlert: value);
      
      // Bills & Reminders
      case 'billPaymentReminder':
        return prefs.copyWith(billPaymentReminder: value);
      case 'failedBillPaymentAlert':
        return prefs.copyWith(failedBillPaymentAlert: value);
      
      // Rewards & Offers
      case 'rewardEarnedAlert':
        return prefs.copyWith(rewardEarnedAlert: value);
      case 'rewardExpiryAlert':
        return prefs.copyWith(rewardExpiryAlert: value);
      case 'promotionalOffers':
        return prefs.copyWith(promotionalOffers: value);
      case 'partnerOffers':
        return prefs.copyWith(partnerOffers: value);
      
      // App Updates & Tips
      case 'newFeatureAnnouncements':
        return prefs.copyWith(newFeatureAnnouncements: value);
      case 'tutorialPrompt':
        return prefs.copyWith(tutorialPrompt: value);
      case 'feedbackRequest':
        return prefs.copyWith(feedbackRequest: value);
      case 'announcementBanners':
        return prefs.copyWith(announcementBanners: value);
      
      default:
        return prefs;
    }
  }
}

// Provider for notification preferences
final notificationPreferencesProvider = 
    StateNotifierProvider<NotificationPreferencesNotifier, AsyncValue<NotificationPreferences>>((ref) {
  final service = ref.watch(notificationPreferencesServiceProvider);
  return NotificationPreferencesNotifier(service);
});




// =============================== EMAIL CHANGE PROVIDER ==================================



// Service provider
final emailChangeServiceProvider = Provider<EmailChangeService>((ref) {
  return EmailChangeService();
});

// Email change flow state
enum EmailChangeStep {
  initial,        // Show current email
  requestingOtp,  // Getting OTP
  verifyingOtp,   // Entering OTP
  changingEmail,  // Entering new email
  success,        // Email changed successfully
}

class EmailChangeState {
  final EmailChangeStep step;
  final String? currentEmail;
  final String? maskedEmail;
  final String? verificationToken;
  final String? newEmail;
  final String? errorMessage;
  final bool isLoading;

  EmailChangeState({
    this.step = EmailChangeStep.initial,
    this.currentEmail,
    this.maskedEmail,
    this.verificationToken,
    this.newEmail,
    this.errorMessage,
    this.isLoading = false,
  });

  EmailChangeState copyWith({
    EmailChangeStep? step,
    String? currentEmail,
    String? maskedEmail,
    String? verificationToken,
    String? newEmail,
    String? errorMessage,
    bool? isLoading,
  }) {
    return EmailChangeState(
      step: step ?? this.step,
      currentEmail: currentEmail ?? this.currentEmail,
      maskedEmail: maskedEmail ?? this.maskedEmail,
      verificationToken: verificationToken ?? this.verificationToken,
      newEmail: newEmail ?? this.newEmail,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Email change notifier
class EmailChangeNotifier extends StateNotifier<EmailChangeState> {
  final EmailChangeService _service;

  EmailChangeNotifier(this._service) : super(EmailChangeState()) {
    _loadCurrentEmail();
  }

  /// Load current user email
  Future<void> _loadCurrentEmail() async {
    final email = await _service.getCurrentEmail();
    if (email != null) {
      state = state.copyWith(
        currentEmail: email,
        maskedEmail: _service.maskEmail(email),
      );
    }
  }

  /// Request OTP for email change
  Future<bool> requestOTP() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.requestOTP(state.currentEmail ?? '');
      
      if (result['success']) {
        state = state.copyWith(
          step: EmailChangeStep.verifyingOtp,
          maskedEmail: result['maskedEmail'] ?? state.maskedEmail,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: result['message'],
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to request OTP: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOTP(String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.verifyOTP(otp);
      
      if (result['success']) {
        state = state.copyWith(
          step: EmailChangeStep.changingEmail,
          verificationToken: result['verificationToken'],
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: result['message'],
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to verify OTP: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Change email address
  Future<bool> changeEmail(String newEmail) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.changeEmail(
        newEmail: newEmail,
        verificationToken: state.verificationToken ?? '',
      );
      
      if (result['success']) {
        state = state.copyWith(
          step: EmailChangeStep.success,
          newEmail: result['newEmail'],
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: result['message'],
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to change email: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Resend OTP
  Future<bool> resendOTP() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.resendOTP();
      
      state = state.copyWith(isLoading: false);
      
      if (result['success']) {
        return true;
      } else {
        state = state.copyWith(errorMessage: result['message']);
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to resend OTP: ${e.toString()}',
        isLoading: false,
      );
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = EmailChangeState(
      currentEmail: state.currentEmail,
      maskedEmail: state.maskedEmail,
    );
  }

  /// Go back to previous step
  void goBack() {
    switch (state.step) {
      case EmailChangeStep.verifyingOtp:
        state = state.copyWith(step: EmailChangeStep.initial);
        break;
      case EmailChangeStep.changingEmail:
        state = state.copyWith(step: EmailChangeStep.verifyingOtp);
        break;
      default:
        break;
    }
  }
}

// Provider for email change
final emailChangeProvider = StateNotifierProvider<EmailChangeNotifier, EmailChangeState>((ref) {
  final service = ref.watch(emailChangeServiceProvider);
  return EmailChangeNotifier(service);
});