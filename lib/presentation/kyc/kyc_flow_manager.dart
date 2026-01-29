import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/presentation/Identity/chooseID.dart';


import 'package:kudipay/presentation/address/verify_address.dart';
import 'package:kudipay/presentation/homescreen/home_screen.dart';
import 'package:kudipay/presentation/selfie/selfie_instruction.dart';
import 'package:kudipay/provider/auth_provider.dart';


/// Smart KYC Flow Manager - Automatically navigates to the next incomplete step
class KycFlowManager extends ConsumerWidget {
  const KycFlowManager({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine next KYC step
    Widget nextScreen;

    if (user.isKycComplete) {
      // All KYC complete - go to home
      nextScreen = const HomeScreen();
    } else if (!user.isSelfieVerified) {
      nextScreen = const SelfieInstructionsScreen();
    } else if (!user.isBvnVerified) {
      nextScreen = const IdVerificationScreen();
    } else if (!user.isAddressVerified) {
      nextScreen = const AddressVerificationScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    // Navigate to the next screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF389165),
        ),
      ),
    );
  }
}