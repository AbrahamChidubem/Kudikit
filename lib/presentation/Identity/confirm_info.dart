import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/formatting/widget/bottom_nav.dart';
import 'package:kudipay/model/user/user_info.dart';
import 'package:kudipay/presentation/transactionpin/transaction_pin_screen.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';


class ConfirmInfoScreen extends ConsumerWidget {
  final UserInfo userInfo;

  const ConfirmInfoScreen({
    super.key,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF069494), width: 2),
              ),
              child: const Center(
                child: Text(
                  '100%',
                  style: TextStyle(
                    color: Color(0xFF069494),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Confirm your Info',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Please confirm that these details are yours and correct. Once submitted, they cannot be changed',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Information Cards
              _InfoCard(
                label: 'First Name',
                value: userInfo.firstName,
              ),
              const SizedBox(height: 16),

              _InfoCard(
                label: 'Last Name',
                value: userInfo.lastName,
              ),
              const SizedBox(height: 16),

              _InfoCard(
                label: 'BVN',
                value: userInfo.maskedBvn,
              ),
              const SizedBox(height: 16),

              _InfoCard(
                label: 'Date of Birth',
                value: _formatDate(userInfo.dateOfBirth),
              ),

              const Spacer(),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleSubmit(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF069494),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Edit Info Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    foregroundColor: const Color(0xFF069494),
                    side: BorderSide.none,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Edit Info',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Handle submit action
  Future<void> _handleSubmit(BuildContext context, WidgetRef ref) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF069494),
        ),
      ),
    );

    try {
      // Submit user info via AuthService backend API
      final authService = ref.read(authServiceProvider);
      final success = await authService.submitUserInfo(userInfo);

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (success) {
        // Update auth state with KYC completion
        await ref.read(authProvider.notifier).updateKycStatus(
              isBvnVerified: true,
              isDocumentVerified: true,
              bvn: userInfo.bvn,
            );

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Information submitted successfully!'),
              backgroundColor: Color(0xFF069494),
              duration: Duration(seconds: 2),
            ),
          );

          // Navigate to transaction PIN creation — required before home
           Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CreateTransactionPinScreen()),
      );
        }
      } else {
        throw Exception('Failed to submit information');
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Format date
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }
}

// ============================================================================
// INFO CARD WIDGET
// ============================================================================

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}