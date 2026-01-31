import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/color_app_button.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/presentation/signup/signup_more_details.dart';
import 'package:kudipay/services/api_services.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();

      // Send verification code when screen loads (only if online)
      final isConnected = ref.read(currentConnectivityProvider);
      if (isConnected) {
        _sendVerificationCode();
      } else {
        _showNoInternetOnLoad();
      }
    });
  }

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          ConnectivitySnackBar.showNoInternet(context);
        } else if (previous?.value != null &&
            !previous!.value! &&
            isConnected) {
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  void _showNoInternetOnLoad() {
    if (!mounted) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
          title: const Text('No Internet Connection'),
          content: const Text(
            'Verification code could not be sent. Please check your connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref
                    .read(connectivityStateProvider.notifier)
                    .refresh()
                    .then((_) {
                  if (ref.read(currentConnectivityProvider)) {
                    _sendVerificationCode();
                  }
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _sendVerificationCode() async {
    final isConnected = ref.read(currentConnectivityProvider);

    if (!isConnected) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.wifi_off, size: 48, color: Colors.red),
            title: const Text('No Internet Connection'),
            content: const Text(
              'Sending verification code requires internet. Please check your connection.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref
                      .read(connectivityStateProvider.notifier)
                      .refresh()
                      .then((_) {
                    if (ref.read(currentConnectivityProvider)) {
                      _sendVerificationCode();
                    }
                  });
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }
      return;
    }

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
    } on NoInternetException {
      if (mounted) {
        ConnectivitySnackBar.showNoInternet(context);
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.orange,
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
    final isConnected = ref.read(currentConnectivityProvider);

    if (!isConnected) {
      await NoInternetDialog.show(context);
      return;
    }

    final code = _pinController.text.trim();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // TODO: Replace with actual verification service
      await Future.delayed(const Duration(seconds: 2));

      if (code.isNotEmpty) {
        final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        ref.read(userIdProvider.notifier).state = userId;
        ref.read(userEmailProvider.notifier).state = widget.email;

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KnowYouBetterForm(),
            ),
          );

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
    } on NoInternetException {
      if (mounted) {
        ConnectivitySnackBar.showNoInternet(context);
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.orange,
          ),
        );
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
    final connectivityState = ref.watch(connectivityStateProvider);
    final isOnline = connectivityState.isConnected;

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
        color: const Color.fromARGB(255, 235, 238, 237).withOpacity(0.8),
      ),
    );

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
          // Connectivity indicator
          if (!isOnline)
            Padding(
              padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 8)),
              child: const Center(child: ConnectivityIndicator()),
            ),
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
      body: Column(
        children: [
          // Connectivity Banner
          if (!isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.red.shade700,
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Verification requires internet connection',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(connectivityStateProvider.notifier).refresh();
                    },
                    child: const Text(
                      'Retry',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

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
                        enabled: isOnline && !isLoading,
                        onCompleted: (pin) {
                          if (isOnline) {
                            _verifyCode();
                          } else {
                            ConnectivitySnackBar.showNoInternet(context);
                          }
                        },
                      ),

                      if (!isOnline)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Internet required to verify code',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ),

                      const SizedBox(height: 30),

                      // Verify Button
                      if (isLoading)
                        const CircularProgressIndicator(
                          color: Color(0xFF389165),
                        )
                      else if (!isOnline)
                        Opacity(
                          opacity: 0.5,
                          child: ColorAppButton(
                            press: () {
                              ConnectivitySnackBar.showNoInternet(context);
                            },
                            text: 'No Internet Connection',
                          ),
                        )
                      else
                        ColorAppButton(
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
                              onPressed: isOnline
                                  ? _sendVerificationCode
                                  : () {
                                      ConnectivitySnackBar.showNoInternet(
                                          context);
                                    },
                              child: Text(
                                "Resend Code",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isOnline
                                      ? const Color(0xFF389165)
                                      : Colors.grey,
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
          ),
        ],
      ),
    );
  }
}
