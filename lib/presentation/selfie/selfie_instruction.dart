import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/presentation/selfie/selfie_capture_screen.dart';

class SelfieInstructionsScreen extends ConsumerWidget {
  const SelfieInstructionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Stack(
                children: [
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: 0.36,
                      strokeWidth: 3,
                      backgroundColor: Color(0xFFE0E0E0),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF4DB6AC)),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Text(
                        '36%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Photo Capture',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We\'ll match your face with your NIN/BVN photo to verify your identity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 60),
            // Face Detection Icon
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.person,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  // Corner brackets
                  Positioned(
                    top: 30,
                    left: 30,
                    child: _buildCornerBracket(isTopLeft: true),
                  ),
                  Positioned(
                    top: 30,
                    right: 30,
                    child: _buildCornerBracket(isTopRight: true),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 30,
                    child: _buildCornerBracket(isBottomLeft: true),
                  ),
                  Positioned(
                    bottom: 30,
                    right: 30,
                    child: _buildCornerBracket(isBottomRight: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Instructions Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please ensure the following',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInstruction('Ensure your face is well-lit'),
                  const SizedBox(height: 12),
                  _buildInstruction(
                      'Your entire face is clearly visible within the frame'),
                  const SizedBox(height: 12),
                  _buildInstruction(
                      'Take off glasses, hats, masks, or anything covering your face'),
                ],
              ),
            ),
            const Spacer(),
            // Next Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelfieCaptureScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF389165),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[600]!,
            width: 4,
          ),
          left: BorderSide(
            color: isTopLeft || isBottomLeft
                ? Colors.grey[600]!
                : Colors.transparent,
            width: 4,
          ),
          right: BorderSide(
            color: isTopRight || isBottomRight
                ? Colors.grey[600]!
                : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(
            color: isBottomLeft || isBottomRight
                ? Colors.grey[600]!
                : Colors.transparent,
            width: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
