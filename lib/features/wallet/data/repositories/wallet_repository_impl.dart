// lib/features/wallet/data/repositories/wallet_repository_impl.dart

import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/features/wallet/domain/entities/wallet_entities.dart';
import 'package:kudipay/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final DioClient _client;
  const WalletRepositoryImpl(this._client);

  @override
  Future<WalletEntity> getWallet() async {
    final results = await Future.wait([
      _client.get<Map<String, dynamic>>('/wallet/balance'),
      _client.get<Map<String, dynamic>>('/wallet/account-details'),
    ]);

    final balanceData = results[0].data!;
    final acctData = results[1].data!;

    return WalletEntity(
      balance: (balanceData['balance'] as num).toDouble(),
      accountNumber: acctData['account_number'] as String,
      accountName: acctData['account_name'] as String,
      bankName: (acctData['bank_name'] as String?) ?? 'KudiPay MFB',
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<VirtualAccountEntity> getAccountDetails() async {
    final res =
        await _client.get<Map<String, dynamic>>('/wallet/account-details');
    final data = res.data!;
    return VirtualAccountEntity(
      accountNumber: data['account_number'] as String,
      accountName: data['account_name'] as String,
      bankName: data['bank_name'] as String,
      referenceCode: data['reference_code'] as String?,
    );
  }

  @override
  Future<String> generateQrCode() async {
    final res = await _client.get<Map<String, dynamic>>('/wallet/qr-code');
    return res.data!['qr_code_url'] as String;
  }
}