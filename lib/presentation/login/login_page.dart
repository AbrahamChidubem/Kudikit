import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/bottom_nav.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/presentation/linkdevice/link_device_screen.dart';
import 'package:kudipay/presentation/signup/signup.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/services/api_services.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? email;
  final String? phoneNumber;

  const LoginPage({this.email, this.phoneNumber, super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final List<bool> _pinFilled = [false, false, false, false, false, false];
  final List<String> _pinDigits = ['', '', '', '', '', ''];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Setup connectivity listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          // Connection lost
          ConnectivitySnackBar.showNoInternet(context);
          // Clear any ongoing login attempt
          setState(() {
            _pinDigits.fillRange(0, 6, '');
            _pinFilled.fillRange(0, 6, false);
            _currentIndex = 0;
          });
        } else if (previous?.value != null &&
            !previous!.value! &&
            isConnected) {
          // Connection restored
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityStateProvider);
    final isOnline = connectivityState.isConnected;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // Connectivity Banner (shows when offline)
            if (!isOnline)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 8),
                  horizontal: AppLayout.scaleWidth(context, 16),
                ),
                color: Colors.red.shade700,
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                      size: AppLayout.scaleWidth(context, 20),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 8)),
                    Expanded(
                      child: Text(
                        'No internet - Login requires connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppLayout.fontSize(context, 14),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(connectivityStateProvider.notifier).refresh();
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppLayout.fontSize(context, 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        (isOnline ? 0 : 48), // Adjust for connectivity banner
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Top Section
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 24),
                            vertical: AppLayout.scaleHeight(context, 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Connectivity indicator
                              Row(
                                children: [
                                  Container(
                                    width: AppLayout.scaleWidth(context, 8),
                                    height: AppLayout.scaleWidth(context, 8),
                                    decoration: BoxDecoration(
                                      color:
                                          isOnline ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(
                                      width: AppLayout.scaleWidth(context, 8)),
                                  Text(
                                    isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      color:
                                          isOnline ? Colors.green : Colors.red,
                                      fontSize: AppLayout.fontSize(context, 12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: isOnline
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LinkDeviceScreen(),
                                                // const SignUpScreen(),
                                          ),
                                        );
                                      }
                                    : () {
                                        ConnectivitySnackBar.showNoInternet(
                                            context);
                                      },
                                child: Text(
                                  'Link new device',
                                  style: TextStyle(
                                    color: isOnline
                                        ? const Color(0xFF5C7C6F)
                                        : Colors.grey,
                                    fontSize: AppLayout.fontSize(context, 14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 10)),

                        // Profile Image
                        Container(
                          width: AppLayout.scaleWidth(context, 80),
                          height: AppLayout.scaleWidth(context, 80),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: AppLayout.scaleWidth(context, 10),
                                offset: Offset(
                                    0, AppLayout.scaleHeight(context, 4)),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/img_placeholder.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFE8F5E9),
                                  child: Icon(
                                    Icons.person,
                                    size: AppLayout.scaleWidth(context, 40),
                                    color: const Color(0xFF4CAF50),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 10)),

                        // Phone Number with Dropdown
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.phoneNumber ?? '08104532643',
                              style: TextStyle(
                                fontSize: AppLayout.fontSize(context, 20),
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: AppLayout.scaleWidth(context, 8)),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[600],
                              size: AppLayout.scaleWidth(context, 24),
                            ),
                          ],
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 30)),

                        // PIN Input Section
                        Text(
                          isOnline
                              ? 'Enter 6 digits PIN to login'
                              : 'Internet required to login',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 14),
                            color: isOnline ? Colors.black54 : Colors.red,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 16)),

                        // PIN Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            return Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: AppLayout.scaleWidth(context, 6),
                              ),
                              width: AppLayout.scaleWidth(context, 12),
                              height: AppLayout.scaleWidth(context, 12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _pinFilled[index]
                                    ? (isOnline
                                        ? const Color(0xFF5C7C6F)
                                        : Colors.grey)
                                    : const Color(0xFFD1D9D5),
                              ),
                            );
                          }),
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 16)),

                        // Forgot PIN
                        TextButton(
                          onPressed: isOnline
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Forgot PIN feature coming soon'),
                                      backgroundColor: Color(0xFF4CAF50),
                                    ),
                                  );
                                }
                              : () {
                                  ConnectivitySnackBar.showNoInternet(context);
                                },
                          child: Text(
                            'Forgot PIN',
                            style: TextStyle(
                              color: isOnline
                                  ? const Color(0xFF5C7C6F)
                                  : Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        // const Spacer(),

                        // Number Pad
                        Opacity(
                          opacity: isOnline ? 1.0 : 0.5,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60),
                            child: Column(
                              children: [
                                _buildNumberRow([1, 2, 3], isOnline),
                                const SizedBox(height: 24),
                                _buildNumberRow([4, 5, 6], isOnline),
                                const SizedBox(height: 24),
                                _buildNumberRow([7, 8, 9], isOnline),
                                const SizedBox(height: 24),
                                _buildBottomRow(isOnline),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: AppLayout.scaleHeight(context, 15)),

                        // Footer - CBN and NDIC
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2),
                                child: Image.asset(
                                  'assets/images/cbn.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.account_balance,
                                        size: 16, color: Color(0xFF2C2C2C));
                                  },
                                ),
                              ),
                              const Text(
                                'Licensed by the ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const Text(
                                'CBN',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'and insured by the',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Container(
                                height: 20,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Image.asset(
                                  'assets/images/ndicc.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.account_balance,
                                        size: 16, color: Color(0xFF2C2C2C));
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
          ],
        ),
      ),
    );
  }

  Widget _buildNumberRow(List<int> numbers, bool isEnabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers
          .map((number) => _buildNumberButton(number, isEnabled))
          .toList(),
    );
  }

  Widget _buildNumberButton(int number, bool isEnabled) {
    return InkWell(
      onTap: isEnabled ? () => _onNumberTap(number.toString()) : null,
      borderRadius: BorderRadius.circular(
        AppLayout.scaleWidth(context, 12),
      ),
      child: Container(
        width: AppLayout.scaleWidth(context, 70),
        height: AppLayout.scaleHeight(context, 50),
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 28),
            fontWeight: FontWeight.w400,
            color: isEnabled ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow(bool isEnabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Biometric Button
        InkWell(
          onTap: isEnabled
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Biometric login coming soon'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(
            AppLayout.scaleWidth(context, 12),
          ),
          child: Container(
            width: AppLayout.scaleWidth(context, 70),
            height: AppLayout.scaleHeight(context, 50),
            alignment: Alignment.center,
            child: Icon(
              Icons.fingerprint,
              size: AppLayout.scaleWidth(context, 32),
              color: isEnabled ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ),

        // Zero Button
        _buildNumberButton(0, isEnabled),

        // Delete Button
        InkWell(
          onTap: isEnabled ? _onDeleteTap : null,
          borderRadius: BorderRadius.circular(
            AppLayout.scaleWidth(context, 12),
          ),
          child: Container(
            width: AppLayout.scaleWidth(context, 70),
            height: AppLayout.scaleHeight(context, 50),
            alignment: Alignment.center,
            child: Icon(
              Icons.backspace_outlined,
              size: AppLayout.scaleWidth(context, 28),
              color: isEnabled ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
        ),
      ],
    );
  }

  void _onNumberTap(String number) {
    final isOnline = ref.read(currentConnectivityProvider);
    if (!isOnline) {
      ConnectivitySnackBar.showNoInternet(context);
      return;
    }

    if (_currentIndex < 6) {
      setState(() {
        _pinDigits[_currentIndex] = number;
        _pinFilled[_currentIndex] = true;
        _currentIndex++;
      });

      // Auto-submit when all 6 digits are entered
      if (_currentIndex == 6) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _handleLogin();
        });
      }
    }
  }

  void _onDeleteTap() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _pinDigits[_currentIndex] = '';
        _pinFilled[_currentIndex] = false;
      });
    }
  }

  Future<void> _handleLogin() async {
    // Check connectivity first
    final isConnected = ref.read(currentConnectivityProvider);
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login requires an internet connection'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );

      // Clear PIN
      setState(() {
        _pinDigits.fillRange(0, 6, '');
        _pinFilled.fillRange(0, 6, false);
        _currentIndex = 0;
      });
      return;
    }

    final pin = _pinDigits.join();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4CAF50),
        ),
      ),
    );

    try {
      // Use the email passed to LoginPage or fall back to stored email
      final email = widget.email ?? 'dubem@example.com';

      await ref.read(authProvider.notifier).login(
            email: email,
            pin: pin,
          );

      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    } on NoInternetException {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Clear PIN on error
      setState(() {
        _pinDigits.fillRange(0, 6, '');
        _pinFilled.fillRange(0, 6, false);
        _currentIndex = 0;
      });

      ConnectivitySnackBar.showNoInternet(context);
    } on TimeoutException catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Clear PIN on error
      setState(() {
        _pinDigits.fillRange(0, 6, '');
        _pinFilled.fillRange(0, 6, false);
        _currentIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog
      Navigator.pop(context);

      // Clear PIN on error
      setState(() {
        _pinDigits.fillRange(0, 6, '');
        _pinFilled.fillRange(0, 6, false);
        _currentIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
