// lib/features/bills/domain/usecases/bills_usecases.dart

import 'package:kudipay/features/bills/domain/entities/bill_entities.dart';
import 'package:kudipay/features/bills/domain/repositories/bills_repository.dart';
import 'package:kudipay/model/bill/bill_model.dart';

class BuyAirtimeUseCase {
  final BillsRepository _repository;
  const BuyAirtimeUseCase(this._repository);
  Future<BillPaymentResultEntity> call(AirtimePurchaseEntity request) =>
      _repository.buyAirtime(request);
}

class GetDataPlansUseCase {
  final BillsRepository _repository;
  const GetDataPlansUseCase(this._repository);
  Future<List<DataPlanEntity>> call(NetworkProvider network) =>
      _repository.getDataPlans(network);
}

class BuyDataUseCase {
  final BillsRepository _repository;
  const BuyDataUseCase(this._repository);
  Future<BillPaymentResultEntity> call(DataPurchaseEntity request) =>
      _repository.buyData(request);
}

class ValidateIucUseCase {
  final BillsRepository _repository;
  const ValidateIucUseCase(this._repository);
  Future<CableTvAccountEntity> call({
    required String iucNumber,
    required String providerName,
  }) =>
      _repository.validateIuc(iucNumber: iucNumber, providerName: providerName);
}

class PayCableTvUseCase {
  final BillsRepository _repository;
  const PayCableTvUseCase(this._repository);
  Future<BillPaymentResultEntity> call({
    required String iucNumber,
    required String providerName,
    required String planId,
    required double amount,
    required bool autoRenew,
    required String pin,
  }) =>
      _repository.payCableTv(
        iucNumber: iucNumber,
        providerName: providerName,
        planId: planId,
        amount: amount,
        autoRenew: autoRenew,
        pin: pin,
      );
}

class ValidateMeterUseCase {
  final BillsRepository _repository;
  const ValidateMeterUseCase(this._repository);
  Future<MeterAccountEntity> call({
    required String meterNumber,
    required String providerCode,
    required String meterType,
  }) =>
      _repository.validateMeter(
        meterNumber: meterNumber,
        providerCode: providerCode,
        meterType: meterType,
      );
}

class PayElectricityUseCase {
  final BillsRepository _repository;
  const PayElectricityUseCase(this._repository);
  Future<BillPaymentResultEntity> call({
    required String meterNumber,
    required double amount,
    required String providerCode,
    required String pin,
  }) =>
      _repository.payElectricity(
        meterNumber: meterNumber,
        amount: amount,
        providerCode: providerCode,
        pin: pin,
      );
}

class GetBeneficiariesUseCase {
  final BillsRepository _repository;
  const GetBeneficiariesUseCase(this._repository);
  Future<List<BillsBeneficiary>> call() => _repository.getBeneficiaries();
}

class DetectNetworkUseCase {
  final BillsRepository _repository;
  const DetectNetworkUseCase(this._repository);
  NetworkProvider? call(String phoneNumber) =>
      _repository.detectNetwork(phoneNumber);
}