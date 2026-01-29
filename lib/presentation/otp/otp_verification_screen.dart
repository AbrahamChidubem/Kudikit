import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/transaction/transaction_success.dart';
import 'package:kudipay/provider/provider.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardTopUpState = ref.watch(cardTopUpProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBody(context),
          _buildVerifyButton(context),
          if (cardTopUpState.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            ),
        ],
      ),
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
        'Top-up with card or account',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Instruction Text
            _buildInstructionText(context),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // OTP Input Field
            _buildOtpField(context),

            SizedBox(height: AppLayout.scaleHeight(context, 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionText(BuildContext context) {
    return Text(
      'Enter the code sent to your the number connected to the bank card details you filled.',
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }

  Widget _buildOtpField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Code',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter OTP code';
            }
            if (value.length < 4) {
              return 'Please enter valid OTP code';
            }
            return null;
          },
          onChanged: (value) {
            // Auto-submit when OTP is complete
            if (value.length == 6) {
              _handleVerify();
            }
          },
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 16),
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyButton(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _handleVerify,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            minimumSize: Size(
              double.infinity,
              AppLayout.scaleHeight(context, 50),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
            ),
            elevation: 0,
          ),
          child: Text(
            'Verify Payment',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(cardTopUpProvider.notifier).verifyOtp(_otpController.text);

    final state = ref.read(cardTopUpProvider);

    if (mounted) {
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!.message),
            backgroundColor: Colors.red,
          ),
        );
      } else if (state.receipt != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const TransactionReceiptScreen(),
          ),
        );
      }
    }
  }
}