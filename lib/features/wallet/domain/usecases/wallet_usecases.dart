// lib/features/wallet/domain/usecases/wallet_usecases.dart

import 'package:kudipay/features/wallet/domain/entities/wallet_entities.dart';
import 'package:kudipay/features/wallet/domain/repositories/wallet_repository.dart';

class GetWalletUseCase {
  final WalletRepository _repository;
  const GetWalletUseCase(this._repository);
  Future<WalletEntity> call() => _repository.getWallet();
}

class GetAccountDetailsUseCase {
  final WalletRepository _repository;
  const GetAccountDetailsUseCase(this._repository);
  Future<VirtualAccountEntity> call() => _repository.getAccountDetails();
}

class GenerateQrCodeUseCase {
  final WalletRepository _repository;
  const GenerateQrCodeUseCase(this._repository);
  Future<String> call() => _repository.generateQrCode();
}