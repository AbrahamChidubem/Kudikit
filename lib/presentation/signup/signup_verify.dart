import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/color_app_button.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/presentation/signup/signup_more_details.dart';

import 'package:pinput/pinput.dart';

class EmailVerifySignup extends ConsumerStatefulWidget {
  final String email;

  final String phoneNumber; 
  final String pin; 

  const EmailVerifySignup({
    super.key,
    required this.email,
    required this.phoneNumber, 
    required this.pin, 
  });

  @override
  ConsumerState<EmailVerifySignup> createState() => _EmailVerifySignupState();
}

class _EmailVerifySignupState extends ConsumerState<EmailVerifySignup> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool isLoading = false;
  bool isResending = false;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Send verification code when screen loads
    _sendVerificationCode();
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      isResending = true;
    });

    try {
      // TODO: Replace with actual email service
      // Send verification code to email
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to ${widget.email}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send code: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _pinController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Replace with actual verification service
      // Verify code with backend
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful verification (replace with real logic)
      // For now, accept any 5-digit code
      if (code.isNotEmpty) {
        // Update user providers after successful verification
        // Assuming userId is generated or retrieved from signup process
        final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        ref.read(userIdProvider.notifier).state = userId;
        // Use the name from signup
        ref.read(userEmailProvider.notifier).state = widget.email;

        if (mounted) {
          // Navigate to home and remove all previous routes
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KnowYouBetterForm(),
            ),
          );

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account verified successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Invalid verification code');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Color(0xFF389165),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 0.5, color: Colors.teal),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF009985), width: 2),
      borderRadius: BorderRadius.circular(10),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: Color.fromARGB(255, 235, 238, 237).withOpacity(0.8),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: Center(
              child: Stack(
                children: [
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 30),
                    height: AppLayout.scaleWidth(context, 30),
                    child: CircularProgressIndicator(
                      value: 0.50,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4DB6AC)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '50%',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(
                  height: 10,
                ),
                // Title and Subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verify your Identity',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: isSmallScreen ? 23 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Enter the 6-digit code sent to ${widget.email} and ${widget.phoneNumber}",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Enter Code Label
                    const Text(
                      'Enter code',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // PIN Input
                Pinput(
                  length: 6,
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  pinAnimationType: PinAnimationType.fade,
                  onCompleted: (pin) {
                    // Auto-verify when all digits entered
                    _verifyCode();
                  },
                ),
                const SizedBox(height: 30),

                // Verify Button
                isLoading
                    ? const CircularProgressIndicator(
                        color: Color(0xFF389165),
                      )
                    : ColorAppButton(
                        press: _verifyCode,
                        text: 'Continue',
                      ),
                const SizedBox(height: 20),

                // Resend Code
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive code? ",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    if (isResending)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF389165),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _sendVerificationCode,
                        child: const Text(
                          "Resend Code",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF389165),
                          ),
                        ),
                      )
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Change email",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF389165),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
