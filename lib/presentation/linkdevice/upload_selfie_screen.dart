import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kudipay/presentation/linkdevice/verification_in_progress.dart';
import 'dart:io';


class UploadSelfieScreen extends ConsumerStatefulWidget {
  const UploadSelfieScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UploadSelfieScreen> createState() =>
      _UploadSelfieScreenState();
}

class _UploadSelfieScreenState extends ConsumerState<UploadSelfieScreen> {
  File? _selfie;
  bool _isUploading = false;
  int _progressPercentage = 74;

  final ImagePicker _picker = ImagePicker();

  Future<void> _takeSelfie() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _isUploading = true;
      });

      // Simulate upload progress
      await Future.delayed(const Duration(seconds: 2));

      setState(() {
        _selfie = File(image.path);
        _isUploading = false;
        _progressPercentage = 100;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBody(context),
          if (!_isUploading) _buildButton(context),
          if (_isUploading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF069494),
                ),
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
              'Take a selfie',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 20),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // Subtitle
            Text(
              'Make sure your face is clearly visible',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.black54,
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 32)),

            // Camera area
            _buildCameraArea(context),

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
      width: AppLayout.scaleWidth(context, 48),
      height: AppLayout.scaleWidth(context, 48),
      decoration: BoxDecoration(
        color: const Color(0xFF5E35B1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.camera_alt,
        color: Colors.white,
        size: AppLayout.scaleWidth(context, 24),
      ),
    );
  }

  Widget _buildCameraArea(BuildContext context) {
    if (_selfie != null) {
      return _buildSuccessCard(context);
    }

    return GestureDetector(
      onTap: _takeSelfie,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 40)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.camera_alt_outlined,
              color: Colors.black38,
              size: AppLayout.scaleWidth(context, 48),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              'Tap to take picture',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 4)),
            Text(
              'Look directly at the camera',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4CAF50),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: AppLayout.scaleWidth(context, 48),
            height: AppLayout.scaleWidth(context, 48),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              color: const Color(0xFF4CAF50),
              size: AppLayout.scaleWidth(context, 24),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selfie uploaded successfully',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 4)),
                Text(
                  'Ready for verification',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 13),
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      child: SizedBox(
        width: double.infinity,
        height: AppLayout.scaleHeight(context, 56),
        child: ElevatedButton(
          onPressed: _selfie != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const VerificationInProgressScreen(),
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
            'Submit for review',
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
}