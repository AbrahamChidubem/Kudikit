// // lib/core/navigation/app_router.dart
// //
// // Single source of truth for all navigation in the app.
// //
// // USAGE — pushing a screen:
// //
// //   // No arguments:
// //   Navigator.pushNamed(context, AppRoutes.home);
// //
// //   // With arguments:
// //   Navigator.pushNamed(context, AppRoutes.upgradeTier,
// //     arguments: UpgradeTierArgs(tier: currentTierObj));
// //
// //   // Replace current screen:
// //   Navigator.pushReplacementNamed(context, AppRoutes.login);
// //
// //   // Clear stack (e.g. after login):
// //   Navigator.pushNamedAndRemoveUntil(
// //     context, AppRoutes.home, (route) => false);
// //
// // HOW TO ADD A NEW ROUTE:
// //   1. Add a constant to AppRoutes
// //   2. Add an args class below if the screen needs parameters
// //   3. Add a case to AppRouter.generateRoute

// import 'package:flutter/material.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // Screen imports
// // ─────────────────────────────────────────────────────────────────────────────

// import 'package:kudipay/presentation/splashscreen/splashscreen.dart';
// import 'package:kudipay/presentation/onboarding/onboarding_screen.dart';
// import 'package:kudipay/presentation/login/login.dart';
// import 'package:kudipay/presentation/signup/signup.dart';
// import 'package:kudipay/presentation/signup/signup_verify.dart';
// import 'package:kudipay/presentation/signup/email_verify_signup.dart';
// import 'package:kudipay/presentation/passcode/create_passcode.dart';
// import 'package:kudipay/presentation/passcode/confirm_passcode.dart';
// import 'package:kudipay/presentation/account_ready/account_ready.dart';
// import 'package:kudipay/formatting/widget/bottom_nav.dart';
// import 'package:kudipay/presentation/homescreen/home_screen.dart';

// // KYC
// import 'package:kudipay/presentation/Identity/chooseID.dart';
// import 'package:kudipay/presentation/Identity/id_verification_screen.dart';
// import 'package:kudipay/presentation/Identity/confirm_info.dart';
// import 'package:kudipay/presentation/Identity/verification_in_progress.dart';
// import 'package:kudipay/presentation/selfie/selfie_instructions_screen.dart';
// import 'package:kudipay/presentation/selfie/selfie_capture_screen.dart';
// import 'package:kudipay/presentation/address/verify_address.dart';
// import 'package:kudipay/presentation/Identity/upload_ID.dart';

// // Transfer
// import 'package:kudipay/presentation/transfer/single_transfer/transfer_amount_screen.dart';
// import 'package:kudipay/presentation/transfer/single_transfer/add_recipient_screen.dart';
// import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_upload_file_screen.dart';
// import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_preview.dart';

// // Bills
// import 'package:kudipay/presentation/bill/airtime/airtime_phone_screen.dart';
// import 'package:kudipay/presentation/bill/airtime/airtime_amount_screen.dart';
// import 'package:kudipay/presentation/bill/data/data_phone_screen.dart';
// import 'package:kudipay/presentation/bill/data/data_plan_screen.dart';
// import 'package:kudipay/presentation/bill/cable_tv/cable_tv_screen.dart';
// import 'package:kudipay/presentation/bill/electricity/electricity_screen.dart';
// import 'package:kudipay/presentation/bill/bill_transaction_detail.dart';

// // Wallet / Add money
// import 'package:kudipay/presentation/addmoney/add_money_screen.dart';
// import 'package:kudipay/presentation/bankdeposit/select_bank.dart';
// import 'package:kudipay/presentation/bankdeposit/bank_ussd_screen.dart';
// import 'package:kudipay/presentation/bankdeposit/ussd_code_display_screen.dart';
// import 'package:kudipay/presentation/bankdeposit/card_topup_form_screen.dart';
// import 'package:kudipay/presentation/qrcode/qr_code_screen.dart';

// // Transactions
// import 'package:kudipay/presentation/transaction/transaction_screen.dart';
// import 'package:kudipay/presentation/transaction/transaction_filter_screen.dart';

// // Requests
// import 'package:kudipay/presentation/request/request_money_main_screen.dart';
// import 'package:kudipay/presentation/request/request_money_screen.dart';
// import 'package:kudipay/presentation/request/select_recipient_screen.dart';
// import 'package:kudipay/presentation/request/preview_request_screen.dart';
// import 'package:kudipay/presentation/request/my_request_screen.dart';
// import 'package:kudipay/presentation/request/request_detail_screen.dart';
// import 'package:kudipay/presentation/request/request_sent_screen.dart';

// // Cashout
// import 'package:kudipay/presentation/cashout/cashout_map_screen.dart';
// import 'package:kudipay/presentation/cashout/enter_amount_screen.dart';

// // Agent
// import 'package:kudipay/presentation/agent/become_agent_screen.dart';
// import 'package:kudipay/presentation/agent/agent_registration_screen.dart';
// import 'package:kudipay/presentation/agent/agent_details_screen.dart';
// import 'package:kudipay/presentation/agent/agent_dashboard_screen.dart';

// // Tier
// import 'package:kudipay/presentation/tier/tier_selection_screen.dart';
// import 'package:kudipay/presentation/tier/upgrade_tier_screen.dart';
// import 'package:kudipay/presentation/tier/upgrade_success_screen.dart';

// // Notifications
// import 'package:kudipay/presentation/notification/notification_category_screen.dart';
// import 'package:kudipay/presentation/notification/notification_preference_screen.dart';

// // Profile / Settings
// import 'package:kudipay/presentation/profile/profile_screen.dart';
// import 'package:kudipay/presentation/transactionpin/transaction_pin_screen.dart';
// import 'package:kudipay/presentation/linkdevice/link_device_screen.dart';
// import 'package:kudipay/presentation/linkdevice/data_sync_screen.dart';

// // Support / Tickets
// import 'package:kudipay/presentation/support/support_screen.dart';
// import 'package:kudipay/presentation/ticket/features/tickets/presentation/screens/tickets_screen.dart';

// // Tribe
// import 'package:kudipay/presentation/tribe/tribe_screen.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // AppRoutes — all route name constants
// // ─────────────────────────────────────────────────────────────────────────────

// abstract final class AppRoutes {
//   // Auth / Onboarding
//   static const splash             = '/';
//   static const onboarding         = '/onboarding';
//   static const login              = '/login';
//   static const signup             = '/signup';
//   static const signupVerify       = '/signup/verify';
//   static const emailVerifySignup  = '/signup/email-verify';
//   static const createPasscode     = '/passcode/create';
//   static const confirmPasscode    = '/passcode/confirm';
//   static const accountReady       = '/account-ready';

//   // Home
//   static const bottomNav          = '/nav';
//   static const home               = '/home';

//   // KYC
//   static const chooseId           = '/kyc/choose-id';
//   static const idVerification     = '/kyc/id-verify';
//   static const confirmInfo        = '/kyc/confirm-info';
//   static const verificationInProgress = '/kyc/in-progress';
//   static const selfieInstructions = '/kyc/selfie-instructions';
//   static const selfieCapture      = '/kyc/selfie-capture';
//   static const verifyAddress      = '/kyc/address';
//   static const uploadId           = '/kyc/upload-id';

//   // Transfer
//   static const transferAmount     = '/transfer/amount';
//   static const addRecipient       = '/transfer/add-recipient';
//   static const bulkTransferUpload = '/transfer/bulk/upload';
//   static const bulkTransferPreview = '/transfer/bulk/preview';

//   // Bills
//   static const airtimePhone       = '/bills/airtime/phone';
//   static const airtimeAmount      = '/bills/airtime/amount';
//   static const dataPhone          = '/bills/data/phone';
//   static const dataPlans          = '/bills/data/plans';
//   static const cableTv            = '/bills/cable-tv';
//   static const electricity        = '/bills/electricity';
//   static const billTransactionDetail = '/bills/transaction-detail';

//   // Wallet / Add money
//   static const addMoney           = '/wallet/add-money';
//   static const selectBank         = '/wallet/select-bank';
//   static const bankUssd           = '/wallet/bank-ussd';
//   static const ussdCodeDisplay    = '/wallet/ussd-display';
//   static const cardTopUp          = '/wallet/card-topup';
//   static const qrCode             = '/wallet/qr-code';

//   // Transactions
//   static const transactions       = '/transactions';
//   static const transactionFilter  = '/transactions/filter';

//   // Requests
//   static const requestMoneyMain   = '/request/main';
//   static const requestMoney       = '/request/new';
//   static const selectRecipients   = '/request/select-recipients';
//   static const previewRequest     = '/request/preview';
//   static const myRequests         = '/request/my-requests';
//   static const requestDetail      = '/request/detail';
//   static const requestSent        = '/request/sent';

//   // Cashout
//   static const cashoutMap         = '/cashout/map';
//   static const enterAmount        = '/cashout/amount';

//   // Agent
//   static const becomeAgent        = '/agent/become';
//   static const agentRegistration  = '/agent/register';
//   static const agentDetails       = '/agent/details';
//   static const agentDashboard     = '/agent/dashboard';

//   // Tier
//   static const tierSelection      = '/tier/select';
//   static const upgradeTier        = '/tier/upgrade';
//   static const upgradeSuccess     = '/tier/success';

//   // Notifications
//   static const notificationCategory    = '/notifications/category';
//   static const notificationPreference  = '/notifications/preference';

//   // Profile / Settings
//   static const profile            = '/profile';
//   static const transactionPin     = '/settings/transaction-pin';
//   static const linkDevice         = '/settings/link-device';
//   static const dataSync           = '/settings/data-sync';

//   // Support / Tickets
//   static const support            = '/support';
//   static const tickets            = '/support/tickets';

//   // Tribe
//   static const tribe              = '/tribe';
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Route argument classes
// // One class per screen that requires typed arguments.
// // ─────────────────────────────────────────────────────────────────────────────

// class ConfirmInfoArgs {
//   final Map<String, dynamic> userInfo;
//   const ConfirmInfoArgs({required this.userInfo});
// }

// class RequestDetailArgs {
//   final dynamic request; // replace with your Request entity type
//   const RequestDetailArgs({required this.request});
// }

// class EnterAmountArgs {
//   final dynamic agent; // replace with your Agent entity type
//   const EnterAmountArgs({required this.agent});
// }

// class AgentDetailsArgs {
//   final dynamic agent;
//   const AgentDetailsArgs({required this.agent});
// }

// class UpgradeTierArgs {
//   final dynamic tier; // replace with your Tier entity type
//   const UpgradeTierArgs({required this.tier});
// }

// class UpgradeSuccessArgs {
//   final dynamic tier;
//   const UpgradeSuccessArgs({required this.tier});
// }

// class UploadDocumentArgs {
//   final dynamic tier;
//   const UploadDocumentArgs({required this.tier});
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // AppRouter
// // ─────────────────────────────────────────────────────────────────────────────

// class AppRouter {
//   /// Wire this to MaterialApp.onGenerateRoute:
//   ///   onGenerateRoute: AppRouter.generateRoute
//   static Route<dynamic> generateRoute(RouteSettings settings) {
//     final args = settings.arguments;

//     switch (settings.name) {

//       // ── Auth / Onboarding ─────────────────────────────────────────────────
//       case AppRoutes.splash:
//         return _build(const SplashScreen());
//       case AppRoutes.onboarding:
//         return _build(const OnboardingScreen());
//       case AppRoutes.login:
//         return _build(const LoginPage());
//       case AppRoutes.signup:
//         return _build(const SignUpScreen());
//       case AppRoutes.signupVerify:
//         return _build(const SignupVerifyScreen());
//       case AppRoutes.emailVerifySignup:
//         return _build(const EmailVerifySignup());
//       case AppRoutes.createPasscode:
//         return _build(const CreatePasscodeScreen());
//       case AppRoutes.confirmPasscode:
//         return _build(const ConfirmPasscodeScreen());
//       case AppRoutes.accountReady:
//         return _build(const AccountReadyScreen());

//       // ── Home ─────────────────────────────────────────────────────────────
//       case AppRoutes.bottomNav:
//         return _build(const BottomNavBar());
//       case AppRoutes.home:
//         return _build(const HomeScreen());

//       // ── KYC ──────────────────────────────────────────────────────────────
//       case AppRoutes.chooseId:
//         return _build(const ChooseIdScreen());
//       case AppRoutes.idVerification:
//         return _build(const IdVerificationScreen());
//       case AppRoutes.confirmInfo:
//         final a = args as ConfirmInfoArgs;
//         return _build(ConfirmInfoScreen(userInfo: a.userInfo));
//       case AppRoutes.verificationInProgress:
//         return _build(const VerificationInProgressScreen());
//       case AppRoutes.selfieInstructions:
//         return _build(const SelfieInstructionsScreen());
//       case AppRoutes.selfieCapture:
//         return _build(const SelfieCaptureScreen());
//       case AppRoutes.verifyAddress:
//         return _build(const VerifyAddressScreen());
//       case AppRoutes.uploadId:
//         return _build(const UploadIdScreen());

//       // ── Transfer ──────────────────────────────────────────────────────────
//       case AppRoutes.transferAmount:
//         return _build(const TransferAmountScreen());
//       case AppRoutes.addRecipient:
//         return _build(const AddRecipientScreen());
//       case AppRoutes.bulkTransferUpload:
//         return _build(const BulkTransferUploadFileScreen());
//       case AppRoutes.bulkTransferPreview:
//         return _build(const BulkTransferPreviewScreen());

//       // ── Bills ─────────────────────────────────────────────────────────────
//       case AppRoutes.airtimePhone:
//         return _build(const AirtimePhoneScreen());
//       case AppRoutes.airtimeAmount:
//         return _build(const AirtimeAmountScreen());
//       case AppRoutes.dataPhone:
//         return _build(const DataPhoneScreen());
//       case AppRoutes.dataPlans:
//         return _build(const DataPlansScreen());
//       case AppRoutes.cableTv:
//         return _build(const CableTvBillerScreen());
//       case AppRoutes.electricity:
//         return _build(const ElectricityScreen());
//       case AppRoutes.billTransactionDetail:
//         return _build(const BillTransactionDetail());

//       // ── Wallet / Add money ────────────────────────────────────────────────
//       case AppRoutes.addMoney:
//         return _build(const AddMoneyScreen());
//       case AppRoutes.selectBank:
//         return _build(const SelectBankScreen());
//       case AppRoutes.bankUssd:
//         return _build(const BankUssdScreen());
//       case AppRoutes.ussdCodeDisplay:
//         return _build(const UssdCodeDisplayScreen());
//       case AppRoutes.cardTopUp:
//         return _build(const CardTopUpFormScreen());
//       case AppRoutes.qrCode:
//         return _build(const QrCodeScreen());

//       // ── Transactions ──────────────────────────────────────────────────────
//       case AppRoutes.transactions:
//         return _build(const TransactionScreen());
//       case AppRoutes.transactionFilter:
//         return _build(const TransactionFilterScreen());

//       // ── Requests ──────────────────────────────────────────────────────────
//       case AppRoutes.requestMoneyMain:
//         return _build(const RequestMoneyMainScreen());
//       case AppRoutes.requestMoney:
//         return _build(const RequestMoneyScreen());
//       case AppRoutes.selectRecipients:
//         return _build(const SelectRecipientsScreen());
//       case AppRoutes.previewRequest:
//         return _build(const PreviewRequestScreen());
//       case AppRoutes.myRequests:
//         return _build(const MyRequestsScreen());
//       case AppRoutes.requestDetail:
//         final a = args as RequestDetailArgs;
//         return _build(RequestDetailScreen(request: a.request));
//       case AppRoutes.requestSent:
//         return _build(const RequestSentScreen());

//       // ── Cashout ───────────────────────────────────────────────────────────
//       case AppRoutes.cashoutMap:
//         return _build(const CashOutMapScreen());
//       case AppRoutes.enterAmount:
//         final a = args as EnterAmountArgs;
//         return _build(EnterAmountScreen(agent: a.agent));

//       // ── Agent ─────────────────────────────────────────────────────────────
//       case AppRoutes.becomeAgent:
//         return _build(const BecomeAgentScreen());
//       case AppRoutes.agentRegistration:
//         return _build(const AgentRegistrationScreen());
//       case AppRoutes.agentDetails:
//         final a = args as AgentDetailsArgs;
//         return _build(AgentDetailsScreen(agent: a.agent));
//       case AppRoutes.agentDashboard:
//         return _build(const AgentDashboardScreen());

//       // ── Tier ──────────────────────────────────────────────────────────────
//       case AppRoutes.tierSelection:
//         return _build(const TierSelectionScreen());
//       case AppRoutes.upgradeTier:
//         final a = args as UpgradeTierArgs;
//         return _build(UpgradeTierScreen(tier: a.tier));
//       case AppRoutes.upgradeSuccess:
//         final a = args as UpgradeSuccessArgs;
//         return _build(UpgradeSuccessScreen(tier: a.tier));

//       // ── Notifications ─────────────────────────────────────────────────────
//       case AppRoutes.notificationCategory:
//         return _build(const NotificationCategoryScreen());
//       case AppRoutes.notificationPreference:
//         return _build(const NotificationPreferenceScreen());

//       // ── Profile / Settings ────────────────────────────────────────────────
//       case AppRoutes.profile:
//         return _build(const ProfileScreen());
//       case AppRoutes.transactionPin:
//         return _build(const CreateTransactionPinScreen());
//       case AppRoutes.linkDevice:
//         return _build(const LinkDeviceScreen());
//       case AppRoutes.dataSync:
//         return _build(const DataSyncScreen());

//       // ── Support / Tickets ─────────────────────────────────────────────────
//       case AppRoutes.support:
//         return _build(const SupportScreen());
//       case AppRoutes.tickets:
//         return _build(const TicketsScreen());

//       // ── Tribe ─────────────────────────────────────────────────────────────
//       case AppRoutes.tribe:
//         return _build(const TribeScreen());

//       // ── Fallback ──────────────────────────────────────────────────────────
//       default:
//         return _build(const SplashScreen());
//     }
//   }

//   static MaterialPageRoute<dynamic> _build(Widget page) {
//     return MaterialPageRoute(builder: (_) => page);
//   }
// }