// lib/features/bills/data/repositories/bills_repository_impl.dart

import 'package:kudipay/features/bills/domain/entities/bill_entities.dart';
import 'package:kudipay/features/bills/domain/repositories/bills_repository.dart';
import 'package:kudipay/model/bill/bill_model.dart';
import 'package:kudipay/services/bill_service.dart';

class BillsRepositoryImpl implements BillsRepository {
  final BillsService _service;
  const BillsRepositoryImpl(this._service);

  // ── Airtime ──────────────────────────────────────────────────────────────

  @override
  Future<BillPaymentResultEntity> buyAirtime(
      AirtimePurchaseEntity req) async {
    final response = await _service.buyAirtime(
      AirtimePurchaseRequest(
        phoneNumber: req.phoneNumber,
        network: NetworkProvider.values.firstWhere(
          (n) => n.name == req.network,
          orElse: () => NetworkProvider.mtn,
        ),
        amount: req.amount,
      ),
    );
    return BillPaymentResultEntity(
      transactionId: response.transactionId,
      amount: response.amount,
      phoneNumber: response.phoneNumber,
      providerName: response.network,
      transactionDate: response.transactionDate,
      isSuccessful: response.isSuccessful,
    );
  }

  // ── Data ─────────────────────────────────────────────────────────────────

  @override
  Future<List<DataPlanEntity>> getDataPlans(NetworkProvider network) async {
    final plans = await _service.getDataPlans(network);
    return plans
        .map((p) => DataPlanEntity(
              id: p.id,
              name: p.name,
              price: p.price,
              validity: p.validity,
              network: p.network.name,
            ))
        .toList();
  }

  @override
  Future<BillPaymentResultEntity> buyData(DataPurchaseEntity req) async {
    final response = await _service.buyData(
      DataPurchaseRequest(
        phoneNumber: req.phoneNumber,
        network: NetworkProvider.values.firstWhere(
          (n) => n.name == req.plan.network,
          orElse: () => NetworkProvider.mtn,
        ),
        plan: DataPlan(
          id: req.plan.id,
          name: req.plan.name,
          price: req.plan.price,
          validity: req.plan.validity,
          network: NetworkProvider.values.firstWhere(
            (n) => n.name == req.plan.network,
            orElse: () => NetworkProvider.mtn,
          ),
        ),
      ),
    );
    return BillPaymentResultEntity(
      transactionId: response.transactionId,
      amount: response.amount,
      phoneNumber: response.phoneNumber,
      providerName: response.network,
      transactionDate: response.transactionDate,
      isSuccessful: response.isSuccessful,
    );
  }

  // ── Cable TV ─────────────────────────────────────────────────────────────

  @override
  Future<CableTvAccountEntity> validateIuc({
    required String iucNumber,
    required String providerName,
  }) async {
    // Delegates to cable_tv_provider's existing DioClient call pattern
    // The cable TV provider calls this directly — no BillsService wrapper
    throw UnimplementedError(
        'Cable TV validation is handled by CableTvNotifier directly');
  }

  @override
  Future<BillPaymentResultEntity> payCableTv({
    required String iucNumber,
    required String providerName,
    required String planId,
    required double amount,
    required bool autoRenew,
    required String pin,
  }) async {
    throw UnimplementedError(
        'Cable TV payment is handled by CableTvNotifier directly');
  }

  // ── Electricity ──────────────────────────────────────────────────────────

  @override
  Future<MeterAccountEntity> validateMeter({
    required String meterNumber,
    required String providerCode,
    required String meterType,
  }) async {
    throw UnimplementedError(
        'Electricity validation is handled by ElectricityNotifier directly');
  }

  @override
  Future<BillPaymentResultEntity> payElectricity({
    required String meterNumber,
    required double amount,
    required String providerCode,
    required String pin,
  }) async {
    throw UnimplementedError(
        'Electricity payment is handled by ElectricityNotifier directly');
  }

  // ── Shared ───────────────────────────────────────────────────────────────

  @override
  Future<List<BillsBeneficiary>> getBeneficiaries() =>
      _service.getBeneficiaries();

  @override
  NetworkProvider? detectNetwork(String phoneNumber) =>
      _service.detectNetwork(phoneNumber);
}