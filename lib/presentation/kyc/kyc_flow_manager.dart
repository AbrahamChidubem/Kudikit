import 'package:flutter/material.dart';
import 'package:kudipay/formatting/widget/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/presentation/Identity/chooseID.dart';
import 'package:kudipay/presentation/address/verify_address.dart';
import 'package:kudipay/presentation/homescreen/home_screen.dart';
import 'package:kudipay/presentation/selfie/selfie_instruction.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/provider.dart';


/// Smart KYC Flow Manager - Automatically navigates to the next incomplete step
class KycFlowManager extends ConsumerWidget {
  const KycFlowManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final connectivityState = ref.watch(connectivityStateProvider);

    // Check internet connection first
    if (!connectivityState.isConnected) {
      return Scaffold(
        backgroundColor: Color(0xFFF9F9F9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Offline icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off,
                    size: 64,
                    color: Colors.red.shade700,
                  ),
                ),
                
                const SizedBox(height: 32),

                // Title
                const Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 16),

                // Description
                Text(
                  'KYC verification requires an active internet connection to proceed. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 32),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(connectivityStateProvider.notifier).refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Check Connection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Connection tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connection Tips',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTip('Turn on WiFi or mobile data'),
                      _buildTip('Check airplane mode is off'),
                      _buildTip('Try moving to a different location'),
                      _buildTip('Restart your device if needed'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Loading state while checking user
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLoadingIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading your information...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Determine next KYC step based on user's completion status
    Widget nextScreen;

    if (user.isKycComplete) {
      // All KYC complete - go to home
      nextScreen = const HomeScreen();
    } else if (!user.isSelfieVerified) {
      // First step: Selfie verification
      nextScreen = const SelfieInstructionsScreen();
    } else if (!user.isBvnVerified) {
      // Second step: ID/BVN verification
      nextScreen = const IdVerificationScreen();
    } else if (!user.isAddressVerified) {
      // Third step: Address verification
      nextScreen = const AddressVerificationScreen();
    } else {
      // Fallback to home if all checks pass
      nextScreen = const HomeScreen();
    }

    // Navigate to the determined screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    });

    // Show loading while navigation is pending
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoadingIndicator(),
            const SizedBox(height: 16),
            Text(
              _getLoadingMessage(user),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            // Online indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Connected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF069494),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue,
            ),
          ),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLoadingMessage(dynamic user) {
    if (user.isKycComplete) {
      return 'Preparing your dashboard...';
    } else if (!user.isSelfieVerified) {
      return 'Preparing selfie verification...';
    } else if (!user.isBvnVerified) {
      return 'Preparing identity verification...';
    } else if (!user.isAddressVerified) {
      return 'Preparing address verification...';
    } else {
      return 'Setting up your account...';
    }
  }
}