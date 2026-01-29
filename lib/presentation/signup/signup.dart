// ===================================================================
// FILE: lib/presentation/signup/signup.dart (RESPONSIVE VERSION)
// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/color_app_button.dart';
import 'package:kudipay/provider/auth_provider.dart';

import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/presentation/signup/signup_verify.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController confirmPinController = TextEditingController();
  final _termsAcceptedProvider = StateProvider<bool>((ref) => false);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    numberController.dispose();
    pinController.dispose();
    confirmPinController.dispose();
    super.dispose();
  }

  Future<void> handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final termsAccepted = ref.read(_termsAcceptedProvider);
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please accept the Terms & Conditions and Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = emailController.text.trim();
    final phoneNumber = '+234${numberController.text.trim()}';
    final pin = pinController.text.trim();

    try {
      await ref.read(authProvider.notifier).signup(
            email: email,
            phoneNumber: phoneNumber,
            pin: pin,
          );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerifySignup(
            email: email,
            phoneNumber: phoneNumber,
            pin: pin,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
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
                      value: 0.25,
                      strokeWidth: AppLayout.scaleWidth(context, 2),
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF4DB6AC)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '25%',
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
          child: Form(
            key: _formKey,
            child: Padding(
              padding: AppLayout.pagePadding(context),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppLayout.scaleHeight(context, 25)),

                  // Title
                  Text(
                    'Create an account with KudiKit',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 25),
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 25)),

                  /// Email
                  _buildLabel(context, 'Email'),
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  _buildTextField(
                    context,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  /// Phone Number
                  _buildLabel(context, 'Number'),
                  SizedBox(height: AppLayout.scaleHeight(context, 5)),
                  _buildTextField(
                    context,
                    controller: numberController,
                    prefixText: '+234 ',
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      if (value.length != 10) {
                        return 'Enter a valid Nigerian phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  /// PIN
                  _buildLabel(context, 'Passcode'),
                  SizedBox(height: AppLayout.scaleHeight(context, 5)),
                  _buildTextField(
                    context,
                    controller: pinController,
                    obscureText: !ref.watch(pinVisibilityProvider),
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    suffixIcon: IconButton(
                      icon: Icon(
                        ref.watch(pinVisibilityProvider)
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      onPressed: () {
                        ref.read(pinVisibilityProvider.notifier).state =
                            !ref.read(pinVisibilityProvider.notifier).state;
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Your passcode must be 6-8 digits and not sequential';
                      }

                      if (value.length < 6 || value.length > 8) {
                        return 'passcode must be 6–8 digits';
                      }

                      bool isSequential(String s) {
                        bool asc = true;
                        bool desc = true;

                        for (int i = 0; i < s.length - 1; i++) {
                          if (s.codeUnitAt(i + 1) != s.codeUnitAt(i) + 1) {
                            asc = false;
                          }
                          if (s.codeUnitAt(i + 1) != s.codeUnitAt(i) - 1) {
                            desc = false;
                          }
                        }
                        return asc || desc;
                      }

                      if (isSequential(value)) {
                        return 'Sequential numbers are not allowed';
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 14)),

                  /// Confirm PIN
                  _buildLabel(context, 'Confirm Passcode'),
                  SizedBox(height: AppLayout.scaleHeight(context, 5)),
                  _buildTextField(
                    context,
                    controller: confirmPinController,
                    obscureText: !ref.watch(confirmPinVisibilityProvider),
                    enabled: !isLoading,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    suffixIcon: IconButton(
                      icon: Icon(
                        ref.watch(confirmPinVisibilityProvider)
                            ? Icons.visibility
                            : Icons.visibility_off,
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      onPressed: () {
                        ref.read(confirmPinVisibilityProvider.notifier).state =
                            !ref
                                .read(confirmPinVisibilityProvider.notifier)
                                .state;
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please confirm your passcode';
                      }

                      if (value != pinController.text) {
                        return 'passcode does not match';
                      }

                      return null;
                    },
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 20)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: AppLayout.scaleWidth(context, 24),
                        height: AppLayout.scaleWidth(context, 24),
                        child: Checkbox(
                          value: ref.watch(_termsAcceptedProvider),
                          onChanged: isLoading
                              ? null
                              : (value) {
                                  ref
                                      .read(_termsAcceptedProvider.notifier)
                                      .state = value ?? false;
                                },
                          activeColor: const Color(0xFF389165),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppLayout.scaleWidth(context, 4),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 12)),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            children: const [
                              TextSpan(
                                text:
                                    'I have read, understood and agreed to the ',
                              ),
                              TextSpan(
                                text: 'Term & Conditions',
                                style: TextStyle(
                                  color: Color(0xFF389165),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                // Add GestureRecognizer here for tap handling if needed
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: Color(0xFF389165),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                // Add GestureRecognizer here for tap handling if needed
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 14)),

                  /// Sign Up Button
                  isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFF389165),
                            strokeWidth: AppLayout.scaleWidth(context, 3),
                          ),
                        )
                      : ColorAppButton(
                          press: handleSignUp,
                          text: 'Continue',
                        ),

                  SizedBox(height: AppLayout.scaleHeight(context, 24)),

                  // Already have account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LoginPage(
                                      email: emailController.text.trim(),
                                    ),
                                  ),
                                );
                              },
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF389165),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 40)),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // CBN Logo
                        Container(
                          width: 32,
                          height: 32,
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/cbn.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.account_balance,
                                  size: 20, color: Color(0xFF2C2C2C));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Licensed by the ',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Text(
                          'CBN',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'and insured by the',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // NDIC Logo
                        Container(
                          height: 24,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Image.asset(
                            'assets/images/ndicc.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.account_balance,
                                  size: 20, color: Color(0xFF2C2C2C));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 14),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    String? prefixText,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool enabled = true,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        // border: Border.all(
        //   color: Colors.grey[300]!,
        //   width: AppLayout.scaleWidth(context, 1.5),
        // ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: AppLayout.scaleWidth(context, 8),
            offset: Offset(0, AppLayout.scaleHeight(context, 2)),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 15),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintStyle: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w400,
            color: Colors.grey[500],
          ),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            fontSize: AppLayout.fontSize(context, 16),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 12),
            vertical: AppLayout.scaleHeight(context, 12),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
