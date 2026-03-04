import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/linkdevice/get_verification_code_screen.dart';
import 'package:kudipay/provider/provider.dart';

class LinkDeviceScreen extends ConsumerStatefulWidget {
  const LinkDeviceScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends ConsumerState<LinkDeviceScreen> {
  @override
  void initState() {
    super.initState();
    // Load user device info when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceLinkingProvider.notifier).loadUserDeviceInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceLinkingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          state.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF069494),
                  ),
                )
              : _buildBody(context, state),
          
          _buildButton(context),
        ],
      ),
      // body: state.isLoading
      //     ? const Center(
      //         child: CircularProgressIndicator(
      //           color: Color(0xFF069494),
      //         ),
      //       )
      //     : _buildBody(context, state),
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

  Widget _buildBody(BuildContext context, DeviceLinkingState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 40)),

            // Icon
            _buildIcon(context),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // Title
            Text(
              'Link your account to this\ndevice',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 24),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.3,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Subtitle
            Text(
              'To keep your account secure, we need to verify\nthat it\'s really you. This will only take a moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 40)),

            // Security info card
            _buildSecurityCard(context),

            SizedBox(height: AppLayout.scaleHeight(context, 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: AppLayout.scaleWidth(context, 80),
      height: AppLayout.scaleWidth(context, 80),
      decoration: BoxDecoration(
        color: const Color(0xFF069494),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.shield_outlined,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 40),
      ),
    );
  }

  Widget _buildSecurityCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.security,
              color: const Color(0xFF069494),
              size: AppLayout.scaleWidth(context, 20),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              'Your data is protected with bank-level security',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Positioned(
      bottom: AppLayout.scaleHeight(context, 40),
      left: AppLayout.scaleWidth(context, 24),
      right: AppLayout.scaleWidth(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppLayout.scaleWidth(context, 320),
            height: AppLayout.scaleHeight(context, 56),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GetVerificationCodeScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Get verification code',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          TextButton(
            onPressed: () {
              // Navigate to alternative verification
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GetVerificationCodeScreen(),
                ),
              );
            },
            child: Text(
              'I don\'t have access to my old phone',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: const Color(0xFF069494),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
