import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/page_transition.dart';

// KudiCard, KudiPrimaryButton, KudiCircularProgress are defined in
// agent_registration_flow.dart and imported here. Do NOT redefine them.
import 'agent_registration_flow.dart'
    show AgentRegistrationFlow, KudiCard, KudiPrimaryButton, KudiCircularProgress;

// ── Screen: Tier 2 Required Gate ──────────────────────────────────────────────

class TierCheckScreen extends StatelessWidget {
  const TierCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Identity Verification',
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: KudiCircularProgress(progress: 0.36),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 32)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Upgrade to Tier 2',
                style: TextStyle(
                  fontFamily: 'PolySans',
                  fontSize: AppLayout.fontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 12)),
              Text(
                'You need to upgrade to tier 2 before applying to become a kudikit agent',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: AppColors.textGrey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 32)),
              SizedBox(
                width: double.infinity,
                height: AppLayout.scaleHeight(context, 52),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to real Tier 2 KYC upgrade flow.
                    // For demo, skip straight to the verified screen.
                    Navigator.pushReplacement(
                      context,
                      PageTransition(const IdentityVerifiedScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 28)),
                    ),
                  ),
                  child: Text(
                    'Upgrade to Tier 2',
                    style: AppTextStyles.responsiveButtonText(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Screen: Identity Verified ─────────────────────────────────────────────────

class IdentityVerifiedScreen extends StatelessWidget {
  const IdentityVerifiedScreen({super.key});

  // TODO: replace with values from your auth provider
  static const _fullName = 'Adewale Johnson';
  static const _phone = '+234 803 456 7890';
  static const _email = 'adewale.j@email.com';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundScreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Identity Verification',
          style: TextStyle(
            fontFamily: 'PolySans',
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: AppLayout.scaleWidth(context, 16)),
            child: KudiCircularProgress(progress: 0.36),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 8)),

            // ── Success banner ──────────────────────────────────────────────
            KudiCard(
              child: Row(
                children: [
                  Container(
                    width: AppLayout.scaleWidth(context, 44),
                    height: AppLayout.scaleWidth(context, 44),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: AppColors.white,
                      size: AppLayout.scaleWidth(context, 22),
                    ),
                  ),
                  SizedBox(width: AppLayout.scaleWidth(context, 14)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Identity Verified!',
                          style: TextStyle(
                            fontFamily: 'PolySans',
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: AppLayout.scaleHeight(context, 2)),
                        Text(
                          'Your Tier 2 KYC verification is complete',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 12),
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // ── Verified information card ───────────────────────────────────
            KudiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified Information',
                    style: TextStyle(
                      fontFamily: 'PolySans',
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 16)),
                  _InfoRow(label: 'Full Name', value: _fullName),
                  Divider(height: AppLayout.scaleHeight(context, 20)),
                  _InfoRow(label: 'Phone Number', value: _phone),
                  Divider(height: AppLayout.scaleHeight(context, 20)),
                  _InfoRow(label: 'Email Address', value: _email),
                  Divider(height: AppLayout.scaleHeight(context, 20)),
                  const _BvnStatusRow(),
                ],
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 100)),
          ],
        ),
      ),
      bottomNavigationBar: KudiPrimaryButton(
        label: 'Continue',
        onPressed: () => Navigator.pushReplacement(
          context,
          PageTransition(const AgentRegistrationFlow()),
        ),
      ),
    );
  }
}

// ── Private sub-widgets (local to this file only) ─────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 11),
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 4)),
        Text(
          value,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: AppColors.textDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BvnStatusRow extends StatelessWidget {
  const _BvnStatusRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BVN Status',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 11),
            color: AppColors.textLight,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 4)),
        Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: AppColors.primaryTeal,
              size: AppLayout.scaleWidth(context, 16),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 4)),
            Text(
              'Verified',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: AppColors.primaryTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}