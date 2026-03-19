// =============================================================================
// lib/mock/mock_api_data.dart
// Kudikit — Centralised API base URL + mock response contracts
// Replace kBaseUrl with your real domain, then swap each mock method for
// an actual HTTP call — zero other changes required.
// =============================================================================

/// Single source of truth for the API base URL.
/// Update this ONE constant when the backend is ready.
const String kBaseUrl = 'https://api.Kudikit.com/api/v1';

String _txId() => 'TXN${DateTime.now().millisecondsSinceEpoch}';
String _mockToken() => 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';

// ── Auth ─────────────────────────────────────────────────────────────────────
class MockAuthData {
  static Map<String, dynamic> registerSuccess({required String email, required String phoneNumber}) => {
    'success': true,
    'userId': 'usr_${DateTime.now().millisecondsSinceEpoch}',
    'message': 'Verification code sent to $email',
  };

  static const Map<String, dynamic> registerEmailTaken = {
    'success': false, 'message': 'An account with this email already exists.',
  };

  static Map<String, dynamic> loginSuccess({String email = 'user@example.com'}) => {
    'success': true,
    'token': _mockToken(),
    'user': {
      'id': 'usr_001', 'email': email, 'phone_number': '+2348012345678',
      'name': 'Abraham Chidubem', 'first_name': 'Abraham', 'last_name': 'Chidubem',
      'is_email_verified': true, 'kyc_status': 'pending', 'tier': 1,
      'created_at': '2024-01-15T08:30:00Z',
      'last_login': DateTime.now().toIso8601String(),
    },
  };

  static const Map<String, dynamic> loginInvalidCredentials = {
    'success': false, 'message': 'Invalid email or password.',
  };

  static Map<String, dynamic> verifyEmailSuccess({String email = 'user@example.com'}) => {
    'success': true,
    'token': _mockToken(),
    'user': {
      'id': 'usr_001', 'email': email, 'phone_number': '+2348012345678',
      'name': 'Abraham Chidubem', 'first_name': 'Abraham', 'last_name': 'Chidubem',
      'is_email_verified': true, 'kyc_status': 'pending', 'tier': 1,
      'created_at': '2024-01-15T08:30:00Z',
      'last_login': DateTime.now().toIso8601String(),
    },
  };

  static const Map<String, dynamic> tokenValid = {'valid': true};

  static const Map<String, dynamic> userProfile = {
    'id': 'usr_001', 'email': 'dubemkudikit@gmail.com',
    'phone_number': '+2348014532643',
    'name': 'Abraham',
    'first_name': 'Abraham', 'middle_name': 'Chidubem', 'last_name': 'Kudikit',
    'date_of_birth': '1990-05-15', 'gender': 'Male',
    'address': '15 Victoria Island, Lagos', 'state': 'Lagos',
    'is_email_verified': true, 'is_bvn_verified': false, 'is_nin_verified': false,
    'is_address_verified': false, 'is_selfie_verified': false, 'is_document_verified': false,
    'kyc_status': 'pending', 'tier': 1, 'profile_photo_url': null,
    'created_at': '2024-01-15T08:30:00Z',
  };
}

// ── Wallet ────────────────────────────────────────────────────────────────────
class MockWalletData {
  static const Map<String, dynamic> balanceResponse = {
    'balance': 135780.00, 'currency': 'NGN',
    'last_updated': '2025-03-16T10:00:00Z',
  };

  static const Map<String, dynamic> accountDetailsResponse = {
    'account_number': '8123456789',
    'account_name': 'Abraham Chidubem Kudikit',
    'bank_name': 'Kudikit MFB', 'bank_code': '090267',
  };
}

// ── Transfer (P2P) ────────────────────────────────────────────────────────────
class MockTransferData {
  static Map<String, dynamic> validateAccountSuccess({
    String accountNumber = '3004749378',
    String name = 'PETER AKINOLA',
    String bankName = 'Guaranty Trust Bank',
  }) => {
    'success': true, 'account_number': accountNumber,
    'account_name': name, 'bank_name': bankName, 'bank_code': '058',
  };

  static const Map<String, dynamic> validateAccountNotFound = {
    'success': false, 'message': 'Account number not found.',
  };

  static Map<String, dynamic> transferSuccess({required double amount, String recipientName = 'PETER AKINOLA'}) => {
    'success': true, 'transaction_id': _txId(),
    'transaction_type': 'Transfer', 'amount': amount, 'fee': 0.00,
    'paying_bank': 'Kudikit MFB', 'paying_bank_account': '8123456789',
    'credited_to': 'Guaranty Trust Bank', 'recipient_name': recipientName,
    'status': 'successful', 'created_at': DateTime.now().toIso8601String(),
  };

  static const Map<String, dynamic> transferInsufficientFunds = {
    'success': false, 'message': 'Insufficient balance to complete this transfer.',
  };
  static const Map<String, dynamic> transferInvalidPin = {
    'success': false, 'message': 'Incorrect transaction PIN.',
  };

  static const Map<String, dynamic> recentContactsResponse = {
    'contacts': [
      {'id': '1', 'name': 'Squad YEM YEM SUPERSTORE LIMITED', 'account_number': '3004749378', 'bank_name': 'GTBank', 'bank_code': '058', 'last_transfer_date': '2024-12-13T10:00:00Z'},
      {'id': '2', 'name': 'John Doe Peters', 'account_number': '3004749378', 'bank_name': 'GTBank', 'bank_code': '058', 'last_transfer_date': '2024-12-09T14:22:00Z'},
      {'id': '3', 'name': 'Amaka Obi', 'account_number': '8001234567', 'bank_name': 'Kudikit MFB', 'bank_code': '090267', 'last_transfer_date': '2024-12-01T08:10:00Z'},
    ],
  };

  static Map<String, dynamic> feeResponse({double amount = 5000}) => {
    'amount': amount, 'fee': amount <= 5000 ? 10.75 : 26.88, 'currency': 'NGN',
  };
}

// ── Transactions ──────────────────────────────────────────────────────────────
class MockTransactionData {
  static const Map<String, dynamic> transactionListResponse = {
    'transactions': [
      {'id': 'TXN1704067200000', 'title': 'Transfer to POS Transfer - TEMI OLUWA', 'type': 'debit', 'amount': 10200.00, 'status': 'successful', 'category': 'transfer', 'recipient': 'TEMI OLUWA', 'note': null, 'date': '2024-12-20T10:39:25Z', 'reference': 'REF_1704067200000'},
      {'id': 'TXN1704010000000', 'title': 'Airtime - MTN 08012345678', 'type': 'debit', 'amount': 500.00, 'status': 'successful', 'category': 'airtime', 'recipient': '08012345678', 'note': null, 'date': '2024-12-19T14:05:00Z', 'reference': 'REF_1704010000000'},
      {'id': 'TXN1703950000000', 'title': 'Credit - Bank Transfer', 'type': 'credit', 'amount': 50000.00, 'status': 'successful', 'category': 'transfer', 'sender': 'JOHN OKAFOR', 'note': 'Monthly allowance', 'date': '2024-12-18T08:00:00Z', 'reference': 'REF_1703950000000'},
      {'id': 'TXN1703900000000', 'title': 'DSTV Premium Subscription', 'type': 'debit', 'amount': 24500.00, 'status': 'successful', 'category': 'cable_tv', 'recipient': 'MultiChoice', 'note': null, 'date': '2024-12-17T12:30:00Z', 'reference': 'REF_1703900000000'},
      {'id': 'TXN1703850000000', 'title': 'Transfer to GTBank', 'type': 'debit', 'amount': 5000.00, 'status': 'failed', 'category': 'transfer', 'recipient': 'AMAKA OBI', 'note': 'Lunch', 'date': '2024-12-16T09:15:00Z', 'reference': 'REF_1703850000000'},
    ],
    'total': 5, 'page': 1, 'limit': 50,
  };

  static const Map<String, dynamic> downloadResponse = {
    'download_url': 'https://api.Kudikit.com/downloads/statement_2024.pdf',
    'expires_at': '2025-03-17T10:00:00Z',
  };
}

// ── Bills ─────────────────────────────────────────────────────────────────────
class MockBillsData {
  static Map<String, dynamic> airtimePurchaseSuccess({required String phoneNumber, required String network, required double amount}) => {
    'success': true, 'transaction_id': _txId(), 'message': 'Airtime purchase successful',
    'amount': amount, 'phone_number': phoneNumber, 'network': network.toUpperCase(),
    'created_at': DateTime.now().toIso8601String(),
  };

  static const Map<String, dynamic> cableTvBillersResponse = {
    'billers': [
      {'id': 'dstv', 'name': 'DSTV', 'logo_url': null},
      {'id': 'gotv', 'name': 'GOTV', 'logo_url': null},
      {'id': 'starsat', 'name': 'StarSat', 'logo_url': null},
      {'id': 'showmax', 'name': 'Showmax', 'logo_url': null},
    ],
  };

  static const Map<String, dynamic> dstvPackagesResponse = {
    'packages': [
      {'id': 'dstv_padi', 'name': 'Padi', 'amount': 2950, 'validity': '30 days'},
      {'id': 'dstv_compact', 'name': 'Compact', 'amount': 15700, 'validity': '30 days'},
      {'id': 'dstv_premium', 'name': 'Premium', 'amount': 37000, 'validity': '30 days'},
    ],
  };

  static const Map<String, dynamic> electricityDiscosResponse = {
    'discos': [
      {'id': 'ekedc', 'name': 'Eko Electric (EKEDC)'},
      {'id': 'ikedc', 'name': 'Ikeja Electric (IKEDC)'},
      {'id': 'aedc',  'name': 'Abuja Electric (AEDC)'},
      {'id': 'phedc', 'name': 'Port Harcourt Electric (PHEDC)'},
      {'id': 'bedc',  'name': 'Chidubemin Electric (BEDC)'},
      {'id': 'eedc',  'name': 'Enugu Electric (EEDC)'},
      {'id': 'kedco', 'name': 'Kano Electric (KEDCO)'},
    ],
  };

  static Map<String, dynamic> validateMeterSuccess({String meterNumber = '12345678901', String customerName = 'Abraham Chidubem', String address = '15 Victoria Island, Lagos'}) => {
    'success': true, 'meter_number': meterNumber,
    'customer_name': customerName, 'address': address,
    'account_number': 'ECN0012345678', 'tariff': 'R2',
  };

  static Map<String, dynamic> electricityPurchaseSuccess({required String meterNumber, required double amount}) => {
    'success': true, 'transaction_id': _txId(),
    'token': '4521 8932 7781 2309 4400',
    'units': (amount / 70).toStringAsFixed(2),
    'amount': amount, 'meter_number': meterNumber,
    'message': 'Electricity purchase successful',
    'created_at': DateTime.now().toIso8601String(),
  };
}

// ── Add Money ─────────────────────────────────────────────────────────────────
class MockAddMoneyData {
  static const Map<String, dynamic> virtualAccountResponse = {
    'account_number': '8123456789', 'account_name': 'Kudikit - Abraham Chidubem',
    'bank_name': 'Providus Bank', 'bank_code': '101', 'reference_code': 'KDP123456',
  };

  static const Map<String, dynamic> banksResponse = {
    'banks': [
      {'id': '1',  'name': 'Guaranty Trust Bank',          'code': '058', 'ussd_code': '*737*'},
      {'id': '2',  'name': 'FirstBank of Nigeria',          'code': '011', 'ussd_code': '*894*'},
      {'id': '3',  'name': 'Zenith Bank',                   'code': '057', 'ussd_code': '*966*'},
      {'id': '4',  'name': 'Access Bank',                   'code': '044', 'ussd_code': '*901*'},
      {'id': '5',  'name': 'United Bank for Africa (UBA)',  'code': '033', 'ussd_code': '*919*'},
      {'id': '6',  'name': 'FCMB',                          'code': '214', 'ussd_code': '*329*'},
      {'id': '7',  'name': 'Wema Bank (ALAT)',              'code': '035', 'ussd_code': '*945*'},
      {'id': '8',  'name': 'Sterling Bank',                 'code': '232', 'ussd_code': '*822*'},
      {'id': '9',  'name': 'Union Bank',                    'code': '032', 'ussd_code': '*826*'},
      {'id': '10', 'name': 'Fidelity Bank',                 'code': '070', 'ussd_code': '*770*'},
    ],
  };

  static Map<String, dynamic> ussdGenerateResponse({required String bankCode, required double amount, String bankName = 'GTBank', String ussdPrefix = '*737*'}) => {
    'bank_code': bankCode, 'bank_name': bankName,
    'ussd_code': '${ussdPrefix}000*7795#',
    'account_number': '8123456789', 'amount': amount,
    'time_remaining_minutes': 4, 'time_remaining_seconds': 24,
  };

  static const Map<String, dynamic> cardTopUpInitiateResponse = {
    'success': true, 'message': 'OTP sent to your registered phone number',
    'requires_otp': true, 'otp_reference': 'OTP-REF-123456789',
    'masked_card': '534256*******6758',
  };

  static Map<String, dynamic> cardTopUpVerifyOtpResponse({double amount = 100.00}) => {
    'success': true, 'transaction_id': _txId(),
    'transaction_type': 'Add Money - Bank Card', 'amount': amount,
    'status': 'successful', 'paying_bank': 'Guaranty Trust Bank (534256*******6758)',
    'credited_to': 'Kudikit wallet', 'transaction_date': DateTime.now().toIso8601String(),
  };

  // QR code URL uses the app's own domain (not a third-party service)
  static const Map<String, dynamic> qrCodeResponse = {
    'qr_code_url': 'https://api.Kudikit.com/qr/8123456789',
    'account_number': '8123456789', 'expires_at': null,
  };
}

// ── KYC / Identity ────────────────────────────────────────────────────────────
class MockKycData {
  static Map<String, dynamic> verifyIdentitySuccess({String idNumber = '22234567890', String idType = 'BVN'}) => {
    'success': true,
    'first_name': 'Abraham', 'middle_name': 'Chidubem', 'last_name': 'Kudikit',
    'full_name': 'Abraham Chidubem Kudikit',
    'date_of_birth': '1990-05-15', 'phone_number': '08012345678',
    'gender': 'Male', 'photo_url': null,
    'id_number': idNumber, 'id_type': idType,
  };

  static const Map<String, dynamic> verifyIdentityNotFound = {
    'success': false, 'message': 'BVN/NIN not found. Please check the number and try again.',
  };

  static const Map<String, dynamic> uploadDocumentSuccess = {
    'success': true, 'message': 'Document uploaded successfully. Under review.',
    'document_id': 'doc_001', 'status': 'under_review',
  };

  static const Map<String, dynamic> uploadSelfieSuccess = {
    'success': true, 'message': 'Selfie submitted for verification.',
    'match_score': 0.97, 'is_verified': true,
  };

  static const Map<String, dynamic> kycStatusResponse = {
    'bvn_verified': false, 'nin_verified': false, 'address_verified': false,
    'selfie_verified': false, 'document_verified': false,
    'kyc_level': 1, 'pending_review': false,
  };
}

// ── Requests ──────────────────────────────────────────────────────────────────
class MockRequestData {
  static Map<String, dynamic> sendRequestSuccess({required double amount, String recipientName = 'John Doe'}) => {
    'success': true, 'request_id': 'REQ_${DateTime.now().millisecondsSinceEpoch}',
    'amount': amount, 'recipient_name': recipientName,
    'status': 'pending', 'message': 'Money request sent successfully.',
    'created_at': DateTime.now().toIso8601String(),
  };

  static const Map<String, dynamic> requestListResponse = {
    'requests': [
      {'id': 'REQ_001', 'amount': 5000.00, 'requester_name': 'Abraham Chidubem', 'requester_account': '8123456789', 'note': 'Lunch money', 'status': 'pending', 'created_at': '2024-12-20T10:00:00Z'},
      {'id': 'REQ_002', 'amount': 15000.00, 'requester_name': 'Amaka Obi', 'requester_account': '8001234567', 'note': 'Project contribution', 'status': 'accepted', 'created_at': '2024-12-18T14:00:00Z'},
    ],
  };
}

// ── Notifications ─────────────────────────────────────────────────────────────
class MockNotificationData {
  static const Map<String, dynamic> preferencesResponse = {
    'preferences': {
      'transaction_alerts': true, 'promotional_offers': false,
      'security_alerts': true, 'account_updates': true,
      'bill_reminders': true, 'transfer_receipts': true,
      'login_alerts': true, 'push_enabled': true,
      'email_enabled': true, 'sms_enabled': false,
    },
  };

  static const Map<String, dynamic> updatePreferencesSuccess = {
    'success': true, 'message': 'Notification preferences updated.',
  };
}

// ── Email Change ──────────────────────────────────────────────────────────────
class MockEmailChangeData {
  static Map<String, dynamic> requestOtpSuccess({String email = 'm****@example.com'}) => {
    'success': true, 'message': 'OTP sent to your current email address.', 'maskedEmail': email,
  };

  static const Map<String, dynamic> verifyOtpSuccess = {
    'success': true, 'message': 'OTP verified successfully.',
    'verificationToken': 'email_change_token_abc123',
  };

  static Map<String, dynamic> changeEmailSuccess({String newEmail = 'new@example.com'}) => {
    'success': true, 'message': 'Email address updated successfully.', 'newEmail': newEmail,
  };

  static const Map<String, dynamic> changeEmailTaken = {
    'success': false, 'message': 'This email address is already associated with another account.',
  };
}

// ── Device Linking ────────────────────────────────────────────────────────────
class MockDeviceLinkData {
  static const Map<String, dynamic> requestDeviceLinkSuccess = {
    'success': true, 'message': 'Verification code sent to your registered email.',
    'session_id': 'session_device_abc123',
  };

  static const Map<String, dynamic> verifyDeviceLinkSuccess = {
    'success': true, 'message': 'Device linked successfully.',
    'device_id': 'device_001', 'token': 'new_device_token_xyz',
  };
}

// ── Tier ──────────────────────────────────────────────────────────────────────
class MockTierData {
  static const Map<String, dynamic> tierResponse = {
    'current_tier': 1, 'tier_name': 'Starter',
    'daily_transfer_limit': 50000.00, 'single_transfer_limit': 20000.00,
    'monthly_transfer_limit': 200000.00,
    'requirements_met': ['phone_verified', 'email_verified'],
    'requirements_pending': ['bvn_verified', 'address_verified', 'selfie_verified'],
  };

  static const Map<String, dynamic> tierRequirementsResponse = {
    'tiers': [
      {'tier': 1, 'name': 'Starter', 'requirements': ['phone_verified', 'email_verified'], 'daily_limit': 50000, 'single_limit': 20000},
      {'tier': 2, 'name': 'Standard', 'requirements': ['bvn_verified', 'selfie_verified'], 'daily_limit': 200000, 'single_limit': 100000},
      {'tier': 3, 'name': 'Premium', 'requirements': ['nin_verified', 'address_verified', 'document_verified'], 'daily_limit': 5000000, 'single_limit': 1000000},
    ],
  };
}

// ── Bulk Transfer ─────────────────────────────────────────────────────────────
class MockBulkTransferData {
  static const Map<String, dynamic> validateBulkResponse = {
    'success': true, 'valid_count': 2, 'invalid_count': 0,
    'total_amount': 110000.00, 'fee': 53.75,
    'results': [
      {'account_number': '0123456789', 'account_name': 'JOHN DOE', 'bank_name': 'GTBank', 'status': 'valid'},
      {'account_number': '08124608695', 'account_name': 'JANE SMITH', 'bank_name': 'Kudikit MFB', 'status': 'valid'},
    ],
  };

  static Map<String, dynamic> executeBulkSuccess({double totalAmount = 110000.00}) => {
    'success': true, 'batch_id': 'BATCH_${DateTime.now().millisecondsSinceEpoch}',
    'total_amount': totalAmount, 'recipient_count': 2,
    'status': 'processing',
    'message': 'Bulk transfer initiated. You will be notified when complete.',
    'created_at': DateTime.now().toIso8601String(),
  };

  static const Map<String, dynamic> templatesResponse = {
    'templates': [
      {'id': '1', 'name': 'Monthly Staff Salary', 'created_at': '2024-11-15T08:00:00Z', 'use_count': 5, 'recipient_count': 2, 'total_amount': 110000.00},
      {'id': '2', 'name': 'Vendor Payments', 'created_at': '2024-12-01T10:00:00Z', 'use_count': 3, 'recipient_count': 1, 'total_amount': 100000.00},
    ],
  };
}