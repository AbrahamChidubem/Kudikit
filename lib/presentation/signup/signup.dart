import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/color_app_button.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/provider/auth_provider.dart';
import 'package:kudipay/services/api_services.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/presentation/login/login_page.dart';
import 'package:kudipay/presentation/signup/signup_verify.dart';

// =============================================================================
// SignUpScreen
// -----------------------------------------------------------------------------
// This is the first step of account creation. The user enters:
//   - Email
//   - Phone number
//   - Passcode (8-12 chars with complexity rules)
//   - Confirm passcode
//   - Agree to Terms & Conditions
//
// On submit → calls AuthNotifier.signup() → navigates to email verification.
// =============================================================================

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {

  // ---------------------------------------------------------------------------
  // CONTROLLERS
  // ---------------------------------------------------------------------------

  final TextEditingController emailController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // ---------------------------------------------------------------------------
  // FORM KEY
  // ---------------------------------------------------------------------------

  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // LOCAL TERMS ACCEPTANCE STATE
  // ---------------------------------------------------------------------------

  final _termsAcceptedProvider = StateProvider<bool>((ref) => false);

  // ---------------------------------------------------------------------------
  // PASSCODE CRITERIA STATE
  // ---------------------------------------------------------------------------

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _passcodeFieldTouched = false;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    numberController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CONNECTIVITY LISTENER
  // ---------------------------------------------------------------------------

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        final wasConnected = previous?.value ?? true;
        if (wasConnected && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
        } else if (!wasConnected && isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  // ---------------------------------------------------------------------------
  // PASSCODE CRITERIA UPDATER
  // ---------------------------------------------------------------------------

  void _updatePasscodeCriteria(String value) {
    setState(() {
      _passcodeFieldTouched = value.isNotEmpty;
      _hasMinLength = value.length >= 8 && value.length <= 12;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasLowercase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*]'));
    });
  }

  // ---------------------------------------------------------------------------
  // HANDLE SIGN UP
  // ---------------------------------------------------------------------------

  Future<void> _handleSignUp() async {
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) {
      await NoInternetDialog.show(context);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final termsAccepted = ref.read(_termsAcceptedProvider);
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions and Privacy Policy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final email = emailController.text.trim();
    final phoneNumber = '+234${numberController.text.trim()}';
    final password = passwordController.text.trim();

    try {
      await ref.read(authProvider.notifier).signup(
            email: email,
            phoneNumber: phoneNumber,
            password: password,
          );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailVerifySignup(
            email: email,
            phoneNumber: phoneNumber,
            pin: password,
          ),
        ),
      );
    } on NoInternetException {
      if (!mounted) return;
      ConnectivitySnackBar.showNoInternet(context);
    } on TimeoutException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.orange,
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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final connectivityState = ref.watch(connectivityStateProvider);
    final isLoading = authState.isLoading;
    final isOnline = connectivityState.isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context, isOnline),
      body: Column(
        children: [
          if (!isOnline) _buildOfflineBanner(context),
          Expanded(
            child: SingleChildScrollView(
              child: SafeArea(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: AppLayout.pagePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppLayout.scaleHeight(context, 25)),

                        Text(
                          'Create an account with KudiKit',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 25),
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 25)),

                        // ── Email ──────────────────────────────────────────
                        _buildLabel(context, 'Email'),
                        SizedBox(height: AppLayout.scaleHeight(context, 8)),
                        _buildTextField(
                          context,
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isLoading && isOnline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 16)),

                        // ── Phone Number ───────────────────────────────────
                        _buildLabel(context, 'Phone Number'),
                        SizedBox(height: AppLayout.scaleHeight(context, 5)),
                        _buildTextField(
                          context,
                          controller: numberController,
                          prefixText: '+234 ',
                          keyboardType: TextInputType.phone,
                          enabled: !isLoading && isOnline,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your phone number';
                            }
                            if (value.trim().length != 10) {
                              return 'Enter a valid 10-digit Nigerian phone number';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 16)),

                        // ── Passcode ───────────────────────────────────────
                        _buildLabel(context, 'Passcode'),
                        SizedBox(height: AppLayout.scaleHeight(context, 5)),
                        _buildTextField(
                          context,
                          controller: passwordController,
                          obscureText: !ref.watch(pinVisibilityProvider),
                          enabled: !isLoading && isOnline,
                          onChanged: _updatePasscodeCriteria,
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
                              return 'Please enter a passcode';
                            }
                            if (!_hasMinLength) return 'Passcode must be 8–12 characters';
                            if (!_hasUppercase) return 'Must contain at least one uppercase letter';
                            if (!_hasLowercase) return 'Must contain at least one lowercase letter';
                            if (!_hasNumber) return 'Must contain at least one number';
                            if (!_hasSpecialChar) return 'Must contain at least one special character (!@#\$%^&*)';
                            return null;
                          },
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 10)),
                        _buildPasscodeCriteria(context),

                        SizedBox(height: AppLayout.scaleHeight(context, 14)),

                        // ── Confirm Passcode ───────────────────────────────
                        _buildLabel(context, 'Confirm Passcode'),
                        SizedBox(height: AppLayout.scaleHeight(context, 5)),
                        _buildTextField(
                          context,
                          controller: confirmPasswordController,
                          obscureText: !ref.watch(confirmPinVisibilityProvider),
                          enabled: !isLoading && isOnline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              ref.watch(confirmPinVisibilityProvider)
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              size: AppLayout.scaleWidth(context, 20),
                            ),
                            onPressed: () {
                              ref.read(confirmPinVisibilityProvider.notifier).state =
                                  !ref.read(confirmPinVisibilityProvider.notifier).state;
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please confirm your passcode';
                            }
                            if (value != passwordController.text) {
                              return 'Passcodes do not match';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 20)),

                        // ── Terms & Conditions Checkbox ────────────────────
                        _buildTermsCheckbox(context, isLoading, isOnline),

                        SizedBox(height: AppLayout.scaleHeight(context, 14)),

                        // ── Submit Button — full-width, responsive ─────────
                        _buildSubmitButton(context, isLoading, isOnline),

                        SizedBox(height: AppLayout.scaleHeight(context, 24)),

                        // ── Already have an account? ───────────────────────
                        _buildLoginRow(context, isLoading, isOnline),

                        SizedBox(height: AppLayout.scaleHeight(context, 20)),

                        // ── CBN / NDIC Licensing Footer ────────────────────
                        _buildLicensingFooter(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // EXTRACTED WIDGET BUILDERS
  // =============================================================================

  // FIX 1: Removed the ConnectivityIndicator action from the AppBar.
  //         Only the 25% progress ring remains in the trailing actions.
  AppBar _buildAppBar(BuildContext context, bool isOnline) {
    return AppBar(
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
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
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.red.shade700,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'No internet — Sign up requires a connection',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(connectivityStateProvider.notifier).refresh(),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(BuildContext context, bool isLoading, bool isOnline) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: AppLayout.scaleWidth(context, 24),
          height: AppLayout.scaleWidth(context, 24),
          child: Checkbox(
            value: ref.watch(_termsAcceptedProvider),
            onChanged: (isLoading || !isOnline)
                ? null
                : (value) {
                    ref.read(_termsAcceptedProvider.notifier).state = value ?? false;
                  },
            activeColor: const Color(0xFF069494),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 4)),
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
                TextSpan(text: 'I have read, understood and agreed to the '),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: TextStyle(
                    color: Color(0xFF069494),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Color(0xFF069494),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // FIX 2: Wrapped ColorAppButton in SizedBox(width: double.infinity) so it
  //         always stretches to the full available width — responsive across
  //         all screen sizes. The loading spinner stays centered as before.
  Widget _buildSubmitButton(BuildContext context, bool isLoading, bool isOnline) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF069494),
          strokeWidth: AppLayout.scaleWidth(context, 3),
        ),
      );
    }
    if (!isOnline) {
      return SizedBox(
        width: double.infinity,
        child: Opacity(
          opacity: 0.5,
          child: ColorAppButton(
            press: () => ConnectivitySnackBar.showNoInternet(context),
            text: 'No Internet Connection',
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ColorAppButton(
        press: _handleSignUp,
        text: 'Continue',
      ),
    );
  }

  Widget _buildLoginRow(BuildContext context, bool isLoading, bool isOnline) {
    return Row(
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
          onPressed: (isLoading || !isOnline)
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
              color: isOnline ? const Color(0xFF069494) : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLicensingFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/images/cbn.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_balance, size: 20, color: Color(0xFF2C2C2C)),
            ),
          ),
          const SizedBox(width: 8),
          const Text('Licensed by the ', style: TextStyle(color: Colors.black, fontSize: 12)),
          const Text('CBN', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Text('and insured by the', style: TextStyle(color: Colors.black, fontSize: 12)),
          const SizedBox(width: 8),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Image.asset(
              'assets/images/ndicc.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.account_balance, size: 20, color: Color(0xFF2C2C2C)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PASSCODE CRITERIA CHECKLIST
  // ---------------------------------------------------------------------------

  Widget _buildPasscodeCriteria(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCriteriaRow(context, '8–12 characters', _hasMinLength),
        _buildCriteriaRow(context, 'At least one uppercase letter', _hasUppercase),
        _buildCriteriaRow(context, 'At least one lowercase letter', _hasLowercase),
        _buildCriteriaRow(context, 'At least one number', _hasNumber),
        _buildCriteriaRow(context, 'At least one special character (!@#\$%^&*)', _hasSpecialChar),
      ],
    );
  }

  Widget _buildCriteriaRow(BuildContext context, String label, bool isMet) {
    final Color activeColor = const Color(0xFF069494);
    final Color inactiveColor = Colors.grey[400]!;

    return Padding(
      padding: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 5)),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: (_passcodeFieldTouched && isMet)
                ? Icon(Icons.check_circle,
                    key: const ValueKey(true),
                    size: AppLayout.scaleWidth(context, 15),
                    color: activeColor)
                : Icon(Icons.radio_button_unchecked,
                    key: const ValueKey(false),
                    size: AppLayout.scaleWidth(context, 15),
                    color: inactiveColor),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 6)),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                color: (_passcodeFieldTouched && isMet) ? Colors.black87 : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REUSABLE FIELD BUILDERS
  // ---------------------------------------------------------------------------

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
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
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
        onChanged: onChanged,
        style: TextStyle(
          fontSize: AppLayout.fontSize(context, 15),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintStyle: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
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