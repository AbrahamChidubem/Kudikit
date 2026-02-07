import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';

class AccountActiveScreen extends ConsumerWidget {
  const AccountActiveScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBody(context),
          _buildButton(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Icon
            _buildSuccessIcon(context),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // Title
            Text(
              'You\'re all set!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 28),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Subtitle
            Text(
              'Your account is now active on this device. You can\nstart using the app right away.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Container(
      width: AppLayout.scaleWidth(context, 120),
      height: AppLayout.scaleWidth(context, 120),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 60),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Positioned(
      bottom: AppLayout.scaleHeight(context, 40),
      left: AppLayout.scaleWidth(context, 24),
      right: AppLayout.scaleWidth(context, 24),
      child: SizedBox(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 56),
        child: ElevatedButton(
          onPressed: () {
            // Navigate to dashboard/home screen
            // For now, just pop back to root
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF389165),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 0,
          ),
          child: Text(
            'Continue to dashboard',
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
}