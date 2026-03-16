import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/tier/tier_model.dart';
import 'package:kudipay/provider/tier_provider.dart';
import 'package:kudipay/presentation/tier/upgrade_success_screen.dart';
import 'package:kudipay/presentation/tier/upload_document_screen.dart';


class UpgradeTierScreen extends ConsumerWidget {
  final UpgradeTier tier;

  const UpgradeTierScreen({super.key, required this.tier});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tierState = ref.watch(tierProvider);
    final allRequirementsCompleted = tier.requirements.every((r) => r.isCompleted);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upgrade Tier',
          style: GoogleFonts.openSans(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          children: [
            // Current Tier Badge
            if (tierState.currentTier == tier.level)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16), 
                  vertical: AppLayout.scaleHeight(context, 8),
                ),
                decoration: BoxDecoration(
                  color: tier.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
                  border: Border.all(color: tier.color, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, 
                      color: tier.color, 
                      size: AppLayout.scaleWidth(context, 16),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 8)),
                    Text(
                      'Current Tier',
                      style: GoogleFonts.openSans(
                        color: tier.color,
                        fontSize: AppLayout.fontSize(context, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Tier Icon
            Container(
              width: AppLayout.scaleWidth(context, 80),
              height: AppLayout.scaleWidth(context, 80),
              decoration: BoxDecoration(
                color: tier.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tier.icon,
                size: AppLayout.scaleWidth(context, 40),
                color: tier.color,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Tier Title
            Text(
              '${tier.displayName} (Tier ${tier.tierNumber})',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Requirements Card
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tier.name} (Tier ${tier.tierNumber})',
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  ...tier.requirements.map((requirement) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 12)),
                      child: Row(
                        children: [
                          Icon(
                            requirement.icon ?? Icons.circle,
                            size: AppLayout.scaleWidth(context, 20),
                            color: Colors.grey[700],
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 12)),
                          Expanded(
                            child: Text(
                              requirement.title,
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 14),
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          Icon(
                            requirement.isCompleted
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: requirement.isCompleted
                                ? const Color(0xFF069494)
                                : Colors.grey[400],
                            size: AppLayout.scaleWidth(context, 20),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Benefits Card
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tier.name} Benefits',
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  ...tier.benefits.map((benefit) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 12)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: AppLayout.scaleWidth(context, 20),
                            color: const Color(0xFF069494),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 12)),
                          Expanded(
                            child: Text(
                              benefit.title,
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 14),
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          if (benefit.value != null)
                            Text(
                              benefit.value!,
                              style: GoogleFonts.openSans(
                                fontSize: AppLayout.fontSize(context, 14),
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
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: AppLayout.scaleWidth(context, 10),
              offset: Offset(0, -AppLayout.scaleHeight(context, 4)),
            ),
          ],
        ),
        child: SafeArea(
          child: tierState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: tierState.currentTier == tier.level
                      ? null // Disable if already on this tier
                      : () => _handleUpgrade(context, ref, allRequirementsCompleted),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tierState.currentTier == tier.level
                        ? Colors.grey
                        : const Color(0xFF069494),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: AppLayout.scaleHeight(context, 16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    tierState.currentTier == tier.level
                        ? 'Current Tier'
                        : 'Continue Upgrade',
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _handleUpgrade(BuildContext context, WidgetRef ref, bool allRequirementsCompleted) {
    if (allRequirementsCompleted) {
      // All requirements met, proceed to upgrade
      _completeUpgrade(context, ref);
    } else {
      // Need to upload documents
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadDocumentScreen(tier: tier),
        ),
      );
    }
  }

  Future<void> _completeUpgrade(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(tierProvider.notifier).upgradeTier(tier.level);
    
    if (success && context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UpgradeSuccessScreen(tier: tier),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(tierProvider).error ?? 'Failed to upgrade tier'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}