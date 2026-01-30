import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/address/verify_address.dart';
import 'package:kudipay/provider/id_verification_provider.dart';
import 'package:kudipay/provider/provider.dart';

class IdVerificationScreen extends ConsumerStatefulWidget {
  const IdVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IdVerificationScreen> createState() =>
      _IdVerificationScreenState();
}

class _IdVerificationScreenState extends ConsumerState<IdVerificationScreen> {
  final TextEditingController _idNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Selected ID type (BVN or NIN)
  IdType _selectedIdType = IdType.BVN;

  // Progress percentage (can be calculated based on registration steps)
  final int _progressPercentage = 48;

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(identityVerificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBody(context, verificationState),
          _buildNextButton(context),
          if (verificationState.isVerifying)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F9F5),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Progress Indicator Circle
        Padding(
          padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
          child: Center(
            child: SizedBox(
              width: AppLayout.scaleWidth(context, 56),
              height: AppLayout.scaleWidth(context, 56),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress Circle
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 56),
                    height: AppLayout.scaleWidth(context, 56),
                    child: CircularProgressIndicator(
                      value: _progressPercentage / 100,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  // Percentage Text
                  Text(
                    '$_progressPercentage%',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 12),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
      BuildContext context, IdentityVerificationState verificationState) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: AppLayout.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Title
            Text(
              'Choose an ID type',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 28),
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Subtitle
            Text(
              'We\'ll need a valid ID type to confirm who you are.',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // BVN/NIN Toggle Buttons
            _buildIdTypeToggle(context),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // ID Number Input Field
            _buildIdNumberField(context),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Display Fetched Name if Available
            if (verificationState.verificationData != null)
              _buildFetchedNameDisplay(
                context,
                verificationState.verificationData!,
              ),

            // Error Message
            if (verificationState.error != null)
              Padding(
                padding:
                    EdgeInsets.only(top: AppLayout.scaleHeight(context, 16)),
                child: Container(
                  padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 8),
                    ),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: AppLayout.scaleWidth(context, 20),
                      ),
                      SizedBox(width: AppLayout.scaleWidth(context, 12)),
                      Expanded(
                        child: Text(
                          verificationState.error!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: AppLayout.fontSize(context, 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: AppLayout.scaleHeight(context, 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildIdTypeToggle(BuildContext context) {
    return Row(
      children: [
        // BVN Button
        Expanded(
          child: _buildToggleButton(
            context: context,
            label: 'BVN',
            isSelected: _selectedIdType == IdType.BVN,
            onTap: () {
              setState(() {
                _selectedIdType = IdType.BVN;
                _idNumberController.clear();
              });
            },
          ),
        ),

        SizedBox(width: AppLayout.scaleWidth(context, 12)),

        // NIN Button
        Expanded(
          child: _buildToggleButton(
            context: context,
            label: 'NIN',
            isSelected: _selectedIdType == IdType.NIN,
            onTap: () {
              setState(() {
                _selectedIdType = IdType.NIN;
                _idNumberController.clear();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      child: Container(
        height: AppLayout.scaleHeight(context, 56),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4F1D4) : Colors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIdNumberField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your ${_selectedIdType == IdType.BVN ? "BVN" : "NIN"}',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 8)),
        TextFormField(
          controller: _idNumberController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          onChanged: (value) {
            // Auto-verify when 11 digits are entered
            if (value.length == 11) {
              _handleVerification();
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your ${_selectedIdType == IdType.BVN ? "BVN" : "NIN"}';
            }
            if (value.length != 11) {
              return '${_selectedIdType == IdType.BVN ? "BVN" : "NIN"} must be 11 digits';
            }
            return null;
          },
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
          decoration: InputDecoration(
            hintText: 'Enter 11-digit number',
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: AppLayout.fontSize(context, 16),
              letterSpacing: 0,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFetchedNameDisplay(
    BuildContext context,
    UserVerificationData verificationData,
  ) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF4CAF50),
                size: AppLayout.scaleWidth(context, 20),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              Text(
                'Identity Verified',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          Text(
            verificationData.fullName.toUpperCase(),
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 14),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4CAF50),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    final verificationState = ref.watch(identityVerificationProvider);
    final isEnabled = verificationState.verificationData != null;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F9F5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? _handleNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            disabledBackgroundColor: Colors.grey[300],
            minimumSize: Size(
              double.infinity,
              AppLayout.scaleHeight(context, 56),
            ),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 28)),
            ),
            elevation: 0,
          ),
          child: Text(
            'Next',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleVerification() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(identityVerificationProvider.notifier).verifyIdentity(
          idNumber: _idNumberController.text,
          idType: _selectedIdType,
        );
  }

  void _handleNext() {
    final verificationData =
        ref.read(identityVerificationProvider).verificationData;

    if (verificationData != null) {
      // Navigate to next registration step
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddressVerificationScreen(),
          ));
      // Or pass the data to the next screen
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => CompleteRegistrationScreen(
      //       verificationData: verificationData,
      //     ),
      //   ),
      // );
    }
  }
}

// ID Type Enum
enum IdType {
  BVN,
  NIN,
}
