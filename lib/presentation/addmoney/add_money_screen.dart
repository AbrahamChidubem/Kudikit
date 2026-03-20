import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/addmoney/addmoney.dart';
import 'package:kudipay/presentation/addmoney/cash_deposit.dart';
import 'package:kudipay/presentation/addmoney/top_up_with_card.dart';
import 'package:kudipay/presentation/bankdeposit/bank_ussd_screen.dart';
import 'package:kudipay/presentation/bankdeposit/select_bank.dart';
import 'package:kudipay/presentation/bankdeposit/ussd_code_display_screen.dart';
import 'package:kudipay/presentation/qrcode/qr_code_screen.dart';

import 'package:kudipay/provider/funding/funding_provider.dart';


class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addMoneyOptionsProvider.notifier).loadOptions();
      ref.read(accountDetailsProvider.notifier).loadAccountDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final optionsState = ref.watch(addMoneyOptionsProvider);
    final accountDetailsState = ref.watch(accountDetailsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: _buildBody(context, optionsState, accountDetailsState),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Add Money',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(
    BuildContext context,
    AddMoneyOptionsState optionsState,
    AccountDetailsState accountDetailsState,
  ) {
    if (optionsState.isLoading && optionsState.options.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF069494)),
      );
    }

    if (optionsState.error != null && optionsState.options.isEmpty) {
      return _buildErrorView(context, optionsState.error!);
    }

    return SingleChildScrollView(
      padding: AppLayout.pagePadding(context),
      child: Column(
        children: [
          if (optionsState.options.isNotEmpty)
            _buildBankTransferCard(context, accountDetailsState),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          _buildOrDivider(context),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          ...optionsState.options
              .where((option) => option.type != AddMoneyType.bankTransfer)
              .map((option) => Padding(
                    padding: EdgeInsets.only(
                      bottom: AppLayout.scaleHeight(context, 12),
                    ),
                    child: _buildAddMoneyOption(context, option),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildBankTransferCard(
    BuildContext context,
    AccountDetailsState accountDetailsState,
  ) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _handleBankTransferTap(context, accountDetailsState),
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppLayout.scaleHeight(context, 8),
              ),
              child: Row(
                children: [
                  Container(
                    width: AppLayout.scaleWidth(context, 40),
                    height: AppLayout.scaleWidth(context, 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 8),
                      ),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: const Color(0xFF069494),
                      size: AppLayout.scaleWidth(context, 20),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Transfer',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 4)),
                        Text(
                          'Add money via mobile or internet banking',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 13),
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: AppLayout.scaleWidth(context, 16),
                  ),
                ],
              ),
            ),
          ),
          if (accountDetailsState.accountDetails != null) ...[
            Divider(
              height: AppLayout.scaleHeight(context, 24),
              color: Colors.grey[200],
            ),
            _buildAccountDetailsSection(
              context,
              accountDetailsState.accountDetails!,
            ),
          ],
          if (accountDetailsState.isLoading)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppLayout.scaleHeight(context, 16),
              ),
              child: const CircularProgressIndicator(
                color: Color(0xFF069494),
                strokeWidth: 2,
              ),
            ),
          if (accountDetailsState.error != null)
            Padding(
              padding: EdgeInsets.only(
                top: AppLayout.scaleHeight(context, 12),
              ),
              child: Text(
                accountDetailsState.error!.message,
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: AppLayout.fontSize(context, 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountDetailsSection(
    BuildContext context,
    AccountDetails accountDetails,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kudiklit Account Number',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              accountDetails.accountNumber,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 24),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                letterSpacing: 2,
              ),
            ),
            InkWell(
              onTap: () =>
                  _copyToClipboard(context, accountDetails.accountNumber),
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
              child: Container(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 8)),
                child: Icon(
                  Icons.share,
                  color: const Color(0xFF069494),
                  size: AppLayout.scaleWidth(context, 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
          ),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 12),
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoneyOption(BuildContext context, AddMoneyOption option) {
    IconData iconData;
    switch (option.icon) {
      case 'cash':
        iconData = Icons.money;
        break;
      case 'card':
        iconData = Icons.credit_card;
        break;
      case 'phone':
        iconData = Icons.phone_android;
        break;
      case 'qr':
        iconData = Icons.qr_code_2;
        break;
      default:
        iconData = Icons.account_balance;
    }

    return InkWell(
      onTap: () => _handleOptionTap(context, option),
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 40),
              height: AppLayout.scaleWidth(context, 40),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(
                  AppLayout.scaleWidth(context, 8),
                ),
              ),
              child: Icon(
                iconData,
                color: const Color(0xFF069494),
                size: AppLayout.scaleWidth(context, 20),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 4)),
                  Text(
                    option.subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: AppLayout.scaleWidth(context, 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, AddMoneyError error) {
    return Center(
      child: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppLayout.scaleWidth(context, 64),
              color: Colors.red[300],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              error.message,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (error.isRetryable) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(addMoneyOptionsProvider.notifier).loadOptions();
                  ref
                      .read(accountDetailsProvider.notifier)
                      .loadAccountDetails();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF069494),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 32),
                    vertical: AppLayout.scaleHeight(context, 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleBankTransferTap(
    BuildContext context,
    AccountDetailsState accountDetailsState,
  ) {
    if (accountDetailsState.accountDetails != null) {
      _showAccountDetailsBottomSheet(
        context,
        accountDetailsState.accountDetails!,
      );
    }
  }

  void _handleOptionTap(BuildContext context, AddMoneyOption option) {
    ref.read(selectedAddMoneyOptionProvider.notifier).state = option;

    switch (option.type) {
      case AddMoneyType.cashDeposit:
        // Navigate to Cash Deposit Instructions Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CashDepositInstructionsScreen(),
          ),
        );
        break;

      case AddMoneyType.cardTopUp:
        // Navigate to Card Top-up Form Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CardTopUpFormScreen(),
          ),
        );
        break;

      case AddMoneyType.ussdTransfer:
        // Navigate to Bank USSD Screen (select bank & amount)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BankUssdScreen(),
          ),
        );
        break;

      case AddMoneyType.qrCode:
        // Navigate to QR Code Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const QrCodeScreen(),
          ),
        );
        break;

      default:
        break;
    }
  }

  void _showAccountDetailsBottomSheet(
    BuildContext context,
    AccountDetails accountDetails,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppLayout.scaleWidth(context, 24)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 40),
              height: AppLayout.scaleHeight(context, 4),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            Text(
              'Bank Transfer Details',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 18),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),
            _buildDetailRow(context, 'Bank Name', accountDetails.bankName),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _buildDetailRow(
                context, 'Account Name', accountDetails.accountName),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _buildDetailRow(
              context,
              'Account Number',
              accountDetails.accountNumber,
              isCopyable: true,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 32)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                minimumSize: Size(
                  double.infinity,
                  AppLayout.scaleHeight(context, 50),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppLayout.scaleWidth(context, 12),
                  ),
                ),
              ),
              child: Text(
                'Got it',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isCopyable = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.grey[600],
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isCopyable) ...[
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              InkWell(
                onTap: () => _copyToClipboard(context, value),
                child: Icon(
                  Icons.copy,
                  size: AppLayout.scaleWidth(context, 16),
                  color: const Color(0xFF069494),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard'),
        backgroundColor: const Color(0xFF069494),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }
}
