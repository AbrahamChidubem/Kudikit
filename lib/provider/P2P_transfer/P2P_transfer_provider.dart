
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/mock/mock_api_data.dart';

// ==================== P2P TRANSFER MODELS ====================

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
      transferData: const TransferData(),
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
      if (pin.length != 4) {
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

  void addFavourite() {}
}

// ==================== PROVIDERS ====================

final p2pTransferServiceProvider = Provider<P2PTransferService>((ref) {
  return P2PTransferService(
    baseUrl: kBaseUrl,
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