import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';


class CashDepositInstructionsScreen extends ConsumerWidget {
  const CashDepositInstructionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: _buildBody(context),
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
        'Cash Deposit',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: AppLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Header Text
          _buildHeaderText(context),

          SizedBox(height: AppLayout.scaleHeight(context, 24)),

          // Steps
          _buildStepCard(
            context,
            stepNumber: 1,
            title: 'Find any POS agent around',
            description: null,
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          _buildStepCard(
            context,
            stepNumber: 2,
            title: 'Give cash to the Agent',
            description: _buildAgentDetails(context),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          _buildStepCard(
            context,
            stepNumber: 3,
            title: 'Confirm receipt of funds',
            description: Text('Confirm that your account has been credited'),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),
        ],
      ),
    );
  }

  Widget _buildHeaderText(BuildContext context) {
    return Text(
      'You can deposit cash by the following steps:',
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context, {
    required int stepNumber,
    required String title,
    Widget? description,
  }) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Number and Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$stepNumber.',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),

          // Description (if provided)
          if (description != null) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 12)),
            description,
          ],
        ],
      ),
    );
  }

  Widget _buildAgentDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Give cash to the agent and ask for the cash to be transferred to your account details',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 16)),

        // Account Details Box
        Container(
          padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F9F5),
            borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
            border: Border.all(color: const Color(0xFFE8F5E9)),
          ),
          child: Column(
            children: [
              _buildAccountDetailRow(context, 'Bank Name:', 'Kudikit'),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              _buildAccountDetailRow(
                context,
                'Bank Account:',
                '8124608695',
                isCopyable: true,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              _buildAccountDetailRow(
                context,
                'Beneficiary:',
                'MICHAEL ASUQUO TOLUWLASE',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDetailRow(
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
            fontSize: AppLayout.fontSize(context, 13),
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            if (isCopyable) ...[
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              InkWell(
                onTap: () => _copyToClipboard(context, value),
                child: Icon(
                  Icons.copy,
                  size: AppLayout.scaleWidth(context, 16),
                  color: const Color(0xFF4CAF50),
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
        backgroundColor: const Color(0xFF4CAF50),
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