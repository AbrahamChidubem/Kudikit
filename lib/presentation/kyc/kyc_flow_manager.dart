import 'package:flutter/material.dart';
import 'package:kudipay/formatting/widget/app_loading_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/presentation/Identity/chooseID.dart';
import 'package:kudipay/presentation/address/verify_address.dart';
import 'package:kudipay/presentation/homescreen/home_screen.dart';
import 'package:kudipay/presentation/selfie/selfie_instruction.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/provider/tier/tier_provider.dart';



/// Smart KYC Flow Manager - Routes to the correct next KYC step based on
/// both the user's SELECTED TIER and their current KYC completion status.
///
/// TIER ROUTING RULES
/// ──────────────────
/// Tier 1 (Basic)  → ID verification only → Dashboard
/// Tier 2 (Pro)    → Selfie → ID → Dashboard
/// Tier 3 (Mega)   → Selfie → ID → Address verification → Dashboard
///
/// The manager checks which steps are already complete so returning users
/// are always dropped into their next *incomplete* step, not the first one.
class KycFlowManager extends ConsumerWidget {
  const KycFlowManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user        = ref.watch(currentUserProvider);
    final tierState   = ref.watch(tierProvider);
    final connectivityState = ref.watch(connectivityStateProvider);

    // ── Offline guard ────────────────────────────────────────────────────────
    if (!connectivityState.isConnected) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.wifi_off, size: 64, color: Colors.red.shade700),
                ),
                const SizedBox(height: 32),
                const Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'KYC verification requires an active internet connection to proceed. Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(connectivityStateProvider.notifier).refresh(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF069494),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Check Connection',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Go Back', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ),
                const SizedBox(height: 32),
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
                          Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Connection Tips',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
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

    // ── Loading guard ────────────────────────────────────────────────────────
    if (user == null || tierState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLoadingIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading your information...',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // ── Determine the correct next screen based on TIER + KYC status ────────
    final tier = tierState.currentTier;
    Widget nextScreen = _resolveNextScreen(tier, user);

    // Navigate after the current frame finishes building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextScreen),
        );
      }
    });

    // ── Loading placeholder while navigation is pending ──────────────────────
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoadingIndicator(),
            const SizedBox(height: 16),
            Text(
              _getLoadingMessage(tier, user),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
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
                  style: TextStyle(fontSize: 12, color: Color(0xFF069494)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ROUTING LOGIC
  // ---------------------------------------------------------------------------
  // Each tier has a defined KYC funnel. We walk the funnel top-to-bottom and
  // return the first step that is NOT yet complete.
  //
  //  Tier 1 (Basic):  [ID]
  //  Tier 2 (Pro):    [Selfie → ID]
  //  Tier 3 (Mega):   [Selfie → ID → Address]
  // ---------------------------------------------------------------------------

  Widget _resolveNextScreen(TierLevel tier, dynamic user) {
    switch (tier) {
      case TierLevel.basic:
        // Tier 1 — only ID verification required.
        if (!user.isBvnVerified) return const IdVerificationScreen();
        return const HomeScreen();

      case TierLevel.pro:
        // Tier 2 — Selfie first, then ID.
        if (!user.isSelfieVerified) return const SelfieInstructionsScreen();
        if (!user.isBvnVerified)    return const IdVerificationScreen();
        return const HomeScreen();

      case TierLevel.mega:
        // Tier 3 — Selfie, ID, then Address.
        if (!user.isSelfieVerified)   return const SelfieInstructionsScreen();
        if (!user.isBvnVerified)      return const IdVerificationScreen();
        if (!user.isAddressVerified)  return const AddressVerificationScreen();
        return const HomeScreen();
    }
  }

  String _getLoadingMessage(TierLevel tier, dynamic user) {
    switch (tier) {
      case TierLevel.basic:
        if (!user.isBvnVerified) return 'Preparing identity verification...';
        return 'Preparing your dashboard...';
      case TierLevel.pro:
        if (!user.isSelfieVerified) return 'Preparing selfie verification...';
        if (!user.isBvnVerified)    return 'Preparing identity verification...';
        return 'Preparing your dashboard...';
      case TierLevel.mega:
        if (!user.isSelfieVerified)  return 'Preparing selfie verification...';
        if (!user.isBvnVerified)     return 'Preparing identity verification...';
        if (!user.isAddressVerified) return 'Preparing address verification...';
        return 'Preparing your dashboard...';
    }
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 14, color: Colors.blue)),
          Expanded(
            child: Text(tip, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}