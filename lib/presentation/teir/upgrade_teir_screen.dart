import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/model/teir/teir_model.dart';
import 'package:kudipay/presentation/teir/upgrade_success_screen.dart';
import 'package:kudipay/presentation/teir/upload_document_screen.dart';


class UpgradeTierScreen extends StatelessWidget {
  final UpgradeTier tier;

  const UpgradeTierScreen({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final allRequirementsCompleted = tier.requirements.every((r) => r.isCompleted);

    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upgrade Tier',
          style: GoogleFonts.openSans(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tier Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: tier.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tier.icon,
                size: 40,
                color: tier.color,
              ),
            ),
            const SizedBox(height: 16),

            // Tier Title
            Text(
              '${tier.displayName} (Tier ${tier.tierNumber})',
              style: GoogleFonts.openSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Requirements Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tier.name} (Tier ${tier.tierNumber})',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...tier.requirements.map((requirement) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            requirement.icon ?? Icons.circle,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              requirement.title,
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          Icon(
                            requirement.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: requirement.isCompleted
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[400],
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Benefits Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tier.name} Benefits',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...tier.benefits.map((benefit) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit.title,
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          if (benefit.value != null)
                            Text(
                              benefit.value!,
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              if (allRequirementsCompleted) {
                // All requirements met, proceed to upgrade
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpgradeSuccessScreen(tier: tier),
                  ),
                );
              } else {
                // Need to upload documents
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadDocumentScreen(tier: tier),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue Upgrade',
              style: GoogleFonts.openSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}