// lib/features/bills/domain/repositories/bills_repository.dart

import 'package:kudipay/features/bills/domain/entities/bill_entities.dart';
import 'package:kudipay/model/bill/bill_model.dart';

abstract interface class BillsRepository {
  // ── Airtime ──────────────────────────────────────────────────────────────
  Future<BillPaymentResultEntity> buyAirtime(AirtimePurchaseEntity request);

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<List<DataPlanEntity>> getDataPlans(NetworkProvider network);
  Future<BillPaymentResultEntity> buyData(DataPurchaseEntity request);

  // ── Cable TV ─────────────────────────────────────────────────────────────
  Future<CableTvAccountEntity> validateIuc({
    required String iucNumber,
    required String providerName,
  });

  Future<BillPaymentResultEntity> payCableTv({
    required String iucNumber,
    required String providerName,
    required String planId,
    required double amount,
    required bool autoRenew,
    required String pin,
  });

  // ── Electricity ──────────────────────────────────────────────────────────
  Future<MeterAccountEntity> validateMeter({
    required String meterNumber,
    required String providerCode,
    required String meterType,
  });

  Future<BillPaymentResultEntity> payElectricity({
    required String meterNumber,
    required double amount,
    required String providerCode,
    required String pin,
  });

  // ── Shared ───────────────────────────────────────────────────────────────
  Future<List<BillsBeneficiary>> getBeneficiaries();
  NetworkProvider? detectNetwork(String phoneNumber);
}