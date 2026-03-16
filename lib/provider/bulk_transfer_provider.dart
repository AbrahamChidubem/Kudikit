import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/transfer/bulk_transfer_model.dart';


class BulkTransferNotifier extends StateNotifier<BulkTransferState> {
  BulkTransferNotifier() : super(BulkTransferState());

  // Add recipient
  void addRecipient(BulkTransferRecipient recipient) {
    state = state.copyWith(
      recipients: [...state.recipients, recipient],
    );
  }

  // Remove recipient
  void removeRecipient(String recipientId) {
    state = state.copyWith(
      recipients: state.recipients.where((r) => r.id != recipientId).toList(),
    );
  }

  // Update recipient
  void updateRecipient(String recipientId, BulkTransferRecipient updatedRecipient) {
    final updatedRecipients = state.recipients.map((r) {
      return r.id == recipientId ? updatedRecipient : r;
    }).toList();

    state = state.copyWith(recipients: updatedRecipients);
  }

  // Set distribution type
  void setDistributionType(AmountDistributionType type) {
    state = state.copyWith(distributionType: type);
  }

  // Set amount per recipient (for equal split)
  void setAmountPerRecipient(double amount) {
    state = state.copyWith(amountPerRecipient: amount);
  }

  // Set total amount
  void setTotalAmount(double amount) {
    state = state.copyWith(totalAmount: amount);
  }

  // Set scheduled transfer
  void setScheduledTransfer({
    required bool isScheduled,
    DateTime? date,
    TimeOfDay? time,
  }) {
    state = state.copyWith(
      isScheduled: isScheduled,
      scheduledDate: date,
      scheduledTime: time,
    );
  }

  // Clear all recipients
  void clearRecipients() {
    state = state.copyWith(recipients: []);
  }

  // Reset entire state
  void reset() {
    state = BulkTransferState();
  }

  // Load from template
  void loadFromTemplate(BulkTransferTemplate template) {
    state = state.copyWith(
      recipients: template.recipients,
    );
  }

  // Execute bulk transfer
  Future<void> executeBulkTransfer() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Invalid transfer data');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement actual API call
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success
      state = state.copyWith(
        isLoading: false,
      );
      
      // Reset after successful transfer
      reset();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Provider
final bulkTransferProvider =
    StateNotifierProvider<BulkTransferNotifier, BulkTransferState>((ref) {
  return BulkTransferNotifier();
});

// Templates provider (mock data for now)
final bulkTransferTemplatesProvider = Provider<List<BulkTransferTemplate>>((ref) {
  return [
    BulkTransferTemplate(
      id: '1',
      name: 'Monthly Staff Salary',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      useCount: 5,
      recipients: [
        BulkTransferRecipient(
          id: '1',
          name: 'John Doe',
          accountType: TransferAccountType.bank,
          accountNumber: '0123456789',
          bankName: 'GTBank',
          amount: 50000,
        ),
        BulkTransferRecipient(
          id: '2',
          name: 'Jane Smith',
          accountType: TransferAccountType.kudikit,
          accountNumber: '08124608695',
          phoneNumber: '08124608695',
          amount: 60000,
        ),
      ],
    ),
    BulkTransferTemplate(
      id: '2',
      name: 'Vendor Payments',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      useCount: 3,
      recipients: [
        BulkTransferRecipient(
          id: '3',
          name: 'Vendor A',
          accountType: TransferAccountType.bank,
          accountNumber: '9876543210',
          bankName: 'Access Bank',
          amount: 100000,
        ),
      ],
    ),
  ];
});