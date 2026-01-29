import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/formatting/widget/bottom_nav.dart';

import 'package:kudipay/presentation/signup/signup.dart';
import 'package:kudipay/provider/auth_provider.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: Column(
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpScreen()));
                    // TODO: Implement account switching
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Switch account feature coming soon'),
                        backgroundColor: Color(0xFF4CAF50),
                      ),
                    );
                  },
                  child: const Text(
                    'Switch account',
                    style: TextStyle(
                      color: Color(0xFF5C7C6F),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Profile Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFF4CAF50),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Phone Number with Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.phoneNumber ?? '08124608695',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ],
            ),

            const SizedBox(height: 60),

            // PIN Input Section
            const Text(
              'Enter 6 digits PIN to login',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 16),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pinFilled[index]
                        ? const Color(0xFF5C7C6F)
                        : const Color(0xFFD1D9D5),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // Forgot PIN
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Forgot PIN feature coming soon'),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              child: const Text(
                'Forgot PIN',
                style: TextStyle(
                  color: Color(0xFF5C7C6F),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(),

            // Number Pad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Column(
                children: [
                  _buildNumberRow([1, 2, 3]),
                  const SizedBox(height: 32),
                  _buildNumberRow([4, 5, 6]),
                  const SizedBox(height: 32),
                  _buildNumberRow([7, 8, 9]),
                  const SizedBox(height: 32),
                  _buildBottomRow(),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // Footer - CBN and NDIC
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // CBN Logo
                  Container(
                    width: 32,
                    height: 32,
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(
                      'assets/images/cbn.png', // Add your CBN logo
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
    );
  }

  Widget _buildNumberRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((number) => _buildNumberButton(number)).toList(),
    );
  }

  Widget _buildNumberButton(int number) {
    return InkWell(
      onTap: () => _onNumberTap(number.toString()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        height: 50,
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Biometric Button
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Biometric login coming soon'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 70,
            height: 50,
            alignment: Alignment.center,
            child: Icon(
              Icons.fingerprint,
              size: 32,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Zero Button
        _buildNumberButton(0),

        // Delete Button
        InkWell(
          onTap: _onDeleteTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 70,
            height: 50,
            alignment: Alignment.center,
            child: Icon(
              Icons.backspace_outlined,
              size: 28,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  void _onNumberTap(String number) {
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
