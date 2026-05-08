// lib/provider/transfer/bulk_transfer_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/model/transfer/bulk_transfer_model.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:kudipay/provider/network/dio_provider.dart' hide dioClientProvider;
class BulkTransferNotifier extends StateNotifier<BulkTransferState> {
  final DioClient _client;

  BulkTransferNotifier(this._client) : super(BulkTransferState());

  void addRecipient(BulkTransferRecipient recipient) {
    state = state.copyWith(
      recipients: [...state.recipients, recipient],
    );
  }

  void removeRecipient(String recipientId) {
    state = state.copyWith(
      recipients: state.recipients.where((r) => r.id != recipientId).toList(),
    );
  }

  void updateRecipient(
      String recipientId, BulkTransferRecipient updatedRecipient) {
    state = state.copyWith(
      recipients: state.recipients.map((r) {
        return r.id == recipientId ? updatedRecipient : r;
      }).toList(),
    );
  }

  void setDistributionType(AmountDistributionType type) {
    state = state.copyWith(distributionType: type);
  }

  void setAmountPerRecipient(double amount) {
    state = state.copyWith(amountPerRecipient: amount);
  }

  void setTotalAmount(double amount) {
    state = state.copyWith(totalAmount: amount);
  }

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

  void clearRecipients() {
    state = state.copyWith(recipients: []);
  }

  void reset() {
    state = BulkTransferState();
  }

  void loadFromTemplate(BulkTransferTemplate template) {
    state = state.copyWith(
      recipients: template.recipients,
    );
  }

  Future<void> executeBulkTransfer({String? pin}) async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Invalid transfer data');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/transfer/bulk/execute',
        data: {
          'recipients': state.recipients.map((r) => r.toJson()).toList(),
          'total_amount':
              state.totalAmount ?? state.calculatedTotalAmount,
          'distribution_type': state.distributionType.name,
          if (pin != null) 'pin': pin,
          if (state.isScheduled && state.scheduledDate != null)
            'scheduled_at': state.scheduledDate!.toIso8601String(),
        },
      );

      final result = response.data!;
      if (result['success'] == true) {
        state = state.copyWith(isLoading: false);
        reset();
      } else {
        throw Exception(result['message'] ?? 'Bulk transfer failed');
      }
    } on KudiApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final bulkTransferProvider =
    StateNotifierProvider<BulkTransferNotifier, BulkTransferState>((ref) {
  return BulkTransferNotifier(ref.read(dioClientProvider));
});

// Templates provider — fetched from API, falls back to empty list on error
final bulkTransferTemplatesProvider =
    FutureProvider<List<BulkTransferTemplate>>((ref) async {
  final client = ref.read(dioClientProvider);
  try {
    final response =
        await client.get<Map<String, dynamic>>('/transfer/bulk/templates');
    final raw = response.data!['templates'] as List<dynamic>;
    return raw
        .map((t) =>
            BulkTransferTemplate.fromJson(t as Map<String, dynamic>))
        .toList();
  } on KudiApiException {
    return [];
  }
});