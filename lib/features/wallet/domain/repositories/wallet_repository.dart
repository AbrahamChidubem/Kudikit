// lib/features/wallet/domain/repositories/wallet_repository.dart

import 'package:kudipay/features/wallet/domain/entities/wallet_entities.dart';

abstract interface class WalletRepository {
  /// Fetches balance and account details in parallel.
  Future<WalletEntity> getWallet();

  /// Fetches virtual account details for bank transfer.
  Future<VirtualAccountEntity> getAccountDetails();

  /// Generates a QR code URL for cash deposit.
  Future<String> generateQrCode();
}