import 'package:flutter/foundation.dart';

@immutable
class Transaction {
  final String id;
  final String description;
  final DateTime date;
  final double amount;
  final TransactionStatus status;
  final TransactionType type;

  const Transaction({
    required this.id,
    required this.description,
    required this.date,
    required this.amount,
    required this.status,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: TransactionStatus.fromString(json['status'] as String),
      type: TransactionType.fromString(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'date': date.toIso8601String(),
      'amount': amount,
      'status': status.value,
      'type': type.value,
    };
  }

  Transaction copyWith({
    String? id,
    String? description,
    DateTime? date,
    double? amount,
    TransactionStatus? status,
    TransactionType? type,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum TransactionStatus {
  successful('Successful'),
  failed('Failed'),
  pending('Pending');

  final String value;
  const TransactionStatus(this.value);

  static TransactionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'successful':
      case 'success':
        return TransactionStatus.successful;
      case 'failed':
        return TransactionStatus.failed;
      case 'pending':
        return TransactionStatus.pending;
      default:
        return TransactionStatus.pending;
    }
  }
}

enum TransactionType {
  debit('debit'),
  credit('credit');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'debit':
        return TransactionType.debit;
      case 'credit':
        return TransactionType.credit;
      default:
        return TransactionType.debit;
    }
  }
}