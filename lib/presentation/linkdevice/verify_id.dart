import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:kudipay/presentation/linkdevice/data_sync.dart';

class VerifyIdentityScreen extends ConsumerStatefulWidget {
  const VerifyIdentityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VerifyIdentityScreen> createState() =>
      _VerifyIdentityScreenState();
}

class _VerifyIdentityScreenState extends ConsumerState<VerifyIdentityScreen> {
  File? _idDocument;
  File? _selfie;
  bool _isIdUploaded = false;
  bool _isSelfieUploaded = false;
  int _progressPercentage = 48;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickIdDocument() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _idDocument = File(image.path);
        _isIdUploaded = true;
        _updateProgress();
      });
    }
  }

  Future<void> _takeSelfie() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selfie = File(image.path);
        _isSelfieUploaded = true;
        _updateProgress();
      });
    }
  }

  void _updateProgress() {
    int completed = 0;
    if (_isIdUploaded) completed++;
    if (_isSelfieUploaded) completed++;

    setState(() {
      _progressPercentage =
          48 + (completed * 26); // 48% + 52% split between 2 tasks
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      bottomNavigationBar: _buildButton(context),
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
                  SizedBox(
                    width: AppLayout.scaleWidth(context, 56),
                    height: AppLayout.scaleWidth(context, 56),
                    child: CircularProgressIndicator(
                      value: _progressPercentage / 100,
                      strokeWidth: 3,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF069494),
                      ),
                    ),
                  ),
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

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Icon
            _buildIcon(context),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Title
            Text(
              'Verify your identity',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 24),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Subtitle
            Text(
              'Since you don\'t have access to your old device, we\'ll\nneed to confirm your identity to keep your account\nsecure.',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // Upload ID Document
            _buildUploadCard(
              context,
              icon: Icons.upload_file,
              iconColor: const Color(0xFF5E35B1),
              title: 'Upload ID',
              subtitle: 'Driver\'s license or passport',
              isCompleted: _isIdUploaded,
              onTap: _pickIdDocument,
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Take a selfie
            _buildUploadCard(
              context,
              icon: Icons.camera_alt,
              iconColor: const Color(0xFF5E35B1),
              title: 'Take a selfie',
              subtitle: 'Verify it\'s really you',
              isCompleted: _isSelfieUploaded,
              onTap: _takeSelfie,
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Info card
            _buildInfoCard(context),

            SizedBox(height: AppLayout.scaleHeight(context, 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: AppLayout.scaleWidth(context, 64),
      height: AppLayout.scaleWidth(context, 64),
      decoration: BoxDecoration(
        color: const Color(0xFF5E35B1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.shield_outlined,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 32),
      ),
    );
  }

  Widget _buildUploadCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted ? const Color(0xFF4CAF50) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: AppLayout.scaleWidth(context, 48),
              height: AppLayout.scaleWidth(context, 48),
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFFE8F5E9)
                    : iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted ? const Color(0xFF4CAF50) : iconColor,
                size: AppLayout.scaleWidth(context, 24),
              ),
            ),

            SizedBox(width: AppLayout.scaleWidth(context, 16)),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 4)),
                  Text(
                    isCompleted
                        ? '${subtitle.split(' ')[0]} uploaded successfully'
                        : subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: isCompleted
                          ? const Color(0xFF4CAF50)
                          : Colors.black54,
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

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: const Color(0xFF1976D2),
            size: AppLayout.scaleWidth(context, 20),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Text(
              'Your documents are encrypted and only used for verification. We\'ll delete them after review.',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                color: const Color(0xFF1565C0),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Positioned(
      bottom: AppLayout.scaleHeight(context, 40),
      left: AppLayout.scaleWidth(context, 24),
      right: AppLayout.scaleWidth(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 56),
            child: ElevatedButton(
              onPressed: (_isIdUploaded && _isSelfieUploaded)
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataSyncScreen(),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                'Start Verification',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: const Color(0xFF069494),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
