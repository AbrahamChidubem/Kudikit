import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/provider/provider.dart';

class UssdCodeDisplayScreen extends ConsumerStatefulWidget {
  const UssdCodeDisplayScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UssdCodeDisplayScreen> createState() => _UssdCodeDisplayScreenState();
}

class _UssdCodeDisplayScreenState extends ConsumerState<UssdCodeDisplayScreen> {
  Timer? _countdownTimer;
  Duration _timeRemaining = const Duration(minutes: 4, seconds: 24);

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
        });
      } else {
        timer.cancel();
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('The USSD code has expired. Please generate a new code.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ussdState = ref.watch(ussdTransferProvider);
    final ussdData = ussdState.data;

    if (ussdData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F9F5),
        appBar: _buildAppBar(context),
        body: const Center(
          child: Text('No USSD data available'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: _buildBody(context, ussdData),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () {
          _countdownTimer?.cancel();
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Dial USSD code',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, UssdTransferData ussdData) {
    return SingleChildScrollView(
      padding: AppLayout.pagePadding(context),
      child: Column(
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Info Message
          _buildInfoMessage(context, ussdData),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),

          // Bank Logo and Name
          _buildBankInfo(context, ussdData),

          SizedBox(height: AppLayout.scaleHeight(context, 24)),

          // USSD Code Display
          _buildUssdCode(context, ussdData),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Timer Message
          _buildTimerMessage(context),

          SizedBox(height: AppLayout.scaleHeight(context, 8)),

          // Countdown Timer
          _buildCountdownTimer(context),

          SizedBox(height: AppLayout.scaleHeight(context, 48)),

          // Copy Code Button
          _buildCopyButton(context, ussdData),

          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Completed Payment Button
          _buildCompletedButton(context),

          SizedBox(height: AppLayout.scaleHeight(context, 32)),
        ],
      ),
    );
  }

  Widget _buildInfoMessage(BuildContext context, UssdTransferData ussdData) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: Colors.black87,
            height: 1.4,
          ),
          children: [
            const TextSpan(text: 'Dial the code below to fund your Kudikit Account with '),
            TextSpan(
              text: '₦${_formatAmount(ussdData.amount)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankInfo(BuildContext context, UssdTransferData ussdData) {
    return Column(
      children: [
        Container(
          width: AppLayout.scaleWidth(context, 60),
          height: AppLayout.scaleWidth(context, 60),
          decoration: BoxDecoration(
            color: _getBankColor(ussdData.bank.logo),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _getBankInitials(ussdData.bank.name),
              style: TextStyle(
                color: Colors.white,
                fontSize: AppLayout.fontSize(context, 20),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 12)),
        Text(
          ussdData.bank.name,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 15),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildUssdCode(BuildContext context, UssdTransferData ussdData) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 24),
        vertical: AppLayout.scaleHeight(context, 20),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        ussdData.ussdCode,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 32),
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: 4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTimerMessage(BuildContext context) {
    return Text(
      'Dial the code & fund your Account within the allocated time',
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 13),
        color: Colors.grey[600],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildCountdownTimer(BuildContext context) {
    final minutes = _timeRemaining.inMinutes;
    final seconds = _timeRemaining.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeBox(context, minutes.toString()),
        SizedBox(width: AppLayout.scaleWidth(context, 8)),
        Text(
          ':',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 24),
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: AppLayout.scaleWidth(context, 8)),
        _buildTimeBox(context, seconds.toString().padLeft(2, '0')),
      ],
    );
  }

  Widget _buildTimeBox(BuildContext context, String value) {
    return Container(
      width: AppLayout.scaleWidth(context, 60),
      height: AppLayout.scaleWidth(context, 60),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 28),
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCopyButton(BuildContext context, UssdTransferData ussdData) {
    return ElevatedButton(
      onPressed: () => _copyCode(context, ussdData.ussdCode),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF069494),
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
        'Copy code',
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 16),
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCompletedButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        _countdownTimer?.cancel();
        // Navigate back to home or show success
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      style: OutlinedButton.styleFrom(
        minimumSize: Size(
          double.infinity,
          AppLayout.scaleHeight(context, 50),
        ),
        side: const BorderSide(color: Color(0xFF069494), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        ),
      ),
      child: Text(
        'Completed payment',
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 16),
          fontWeight: FontWeight.w600,
          color: const Color(0xFF069494),
        ),
      ),
    );
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('USSD code copied to clipboard'),
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

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  Color _getBankColor(String logo) {
    switch (logo.toLowerCase()) {
      case 'gtbank':
        return const Color(0xFFFF6600);
      case 'firstbank':
        return const Color(0xFF002244);
      case 'wema':
        return const Color(0xFF722C7A);
      case 'uba':
        return const Color(0xFFD32F2F);
      case 'fcmb':
        return const Color(0xFF7B1FA2);
      case 'sterling':
        return const Color(0xFFD32F2F);
      case 'parallex':
        return const Color(0xFF1E3A8A);
      case 'globus':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF069494);
    }
  }

  String _getBankInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}