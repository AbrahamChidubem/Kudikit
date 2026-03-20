import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final List<_FaqItem> _faqs = const [
    _FaqItem(
      question: 'How do I add money to my wallet?',
      answer:
          'You can add money via Bank Transfer, Card Top-up, Cash Deposit, Bank USSD, or QR Code. Go to Home → Add Money and choose a method.',
    ),
    _FaqItem(
      question: 'How long does a bank transfer take?',
      answer:
          'Bank transfers typically reflect within a few minutes. If your funds do not arrive within 30 minutes, please contact support.',
    ),
    _FaqItem(
      question: 'How do I upgrade my account tier?',
      answer:
          'Navigate to Profile → Account Tier to view requirements for each tier and begin the upgrade process.',
    ),
    _FaqItem(
      question: 'What are the transaction limits?',
      answer:
          'Tier 1 accounts can transact up to ₦50,000 daily. Tier 2 allows up to ₦200,000, and Tier 3 has no limits. Upgrade your tier for higher limits.',
    ),
    _FaqItem(
      question: 'How do I reset my transaction PIN?',
      answer:
          'Go to Profile → Security → Change Transaction PIN. You will need to verify your identity via OTP before setting a new PIN.',
    ),
    _FaqItem(
      question: 'My transfer failed but I was debited. What do I do?',
      answer:
          'Failed debits are reversed automatically within 24 hours. If the reversal does not happen, tap "Live Chat" below to speak to an agent immediately.',
    ),
  ];

  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundScreen,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Help & Support',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: AppLayout.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppLayout.scaleHeight(context, 8)),

          // Header
          _buildHeader(context),
          SizedBox(height: AppLayout.scaleHeight(context, 28)),

          // Quick contact cards
          _buildQuickContactSection(context),
          SizedBox(height: AppLayout.scaleHeight(context, 32)),

          // FAQ section
          _buildFaqSection(context),
          SizedBox(height: AppLayout.scaleHeight(context, 32)),

          // Business hours
          _buildBusinessHours(context),
          SizedBox(height: AppLayout.scaleHeight(context, 24)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How can we help you?',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 22),
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 6)),
        Text(
          'Choose a channel below or browse common questions.',
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 14),
            color: AppColors.textGrey,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Contact Us'),
        SizedBox(height: AppLayout.scaleHeight(context, 12)),
        Row(
          children: [
            Expanded(
              child: _buildContactCard(
                context,
                icon: Icons.chat_bubble_outline,
                label: 'Live Chat',
                subtitle: 'Chat with us now',
                onTap: () => _launchLiveChat(context),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
            Expanded(
              child: _buildContactCard(
                context,
                icon: Icons.mail_outline,
                label: 'Email Us',
                subtitle: 'support@kudikit.com',
                onTap: () => _copyEmail(context),
              ),
            ),
          ],
        ),
        SizedBox(height: AppLayout.scaleHeight(context, 12)),
        Row(
          children: [
            Expanded(
              child: _buildContactCard(
                context,
                icon: Icons.phone_outlined,
                label: 'Call Us',
                subtitle: '+234 700 000 0000',
                onTap: () => _copyPhone(context),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
            Expanded(
              child: _buildContactCard(
                context,
                icon: Icons.article_outlined,
                label: 'Report Issue',
                subtitle: 'Send a ticket',
                onTap: () => _showReportSheet(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 36),
              height: AppLayout.scaleWidth(context, 36),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius:
                    BorderRadius.circular(AppLayout.scaleWidth(context, 8)),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryTeal ,
                size: AppLayout.scaleWidth(context, 18),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 10)),
            Text(
              label,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 2)),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 11),
                color: AppColors.textGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Frequently Asked Questions'),
        SizedBox(height: AppLayout.scaleHeight(context, 12)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius:
                BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: List.generate(_faqs.length, (index) {
              final isLast = index == _faqs.length - 1;
              return _buildFaqItem(context, index, isLast);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(BuildContext context, int index, bool isLast) {
    final isExpanded = _expandedIndices.contains(index);
    final faq = _faqs[index];

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedIndices.remove(index);
              } else {
                _expandedIndices.add(index);
              }
            });
          },
          borderRadius: isLast
              ? BorderRadius.only(
                  bottomLeft:
                      Radius.circular(AppLayout.scaleWidth(context, 12)),
                  bottomRight:
                      Radius.circular(AppLayout.scaleWidth(context, 12)),
                )
              : BorderRadius.zero,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
              vertical: AppLayout.scaleHeight(context, 14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    faq.question,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 8)),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.primaryTeal ,
                  size: AppLayout.scaleWidth(context, 20),
                ),
              ],
            ),
          ),
        ),

        // Answer (animated)
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppLayout.scaleWidth(context, 16),
              0,
              AppLayout.scaleWidth(context, 16),
              AppLayout.scaleHeight(context, 14),
            ),
            child: Text(
              faq.answer,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: AppColors.textGrey,
                height: 1.5,
              ),
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),

        if (!isLast)
          Divider(
            height: 1,
            color: const Color(0xFFF0F0F0),
            indent: AppLayout.scaleWidth(context, 16),
            endIndent: AppLayout.scaleWidth(context, 16),
          ),
      ],
    );
  }

  Widget _buildBusinessHours(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                color: AppColors.primaryTeal ,
                size: AppLayout.scaleWidth(context, 18),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 8)),
              Text(
                'Business Hours',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          _buildHoursRow(context, 'Monday – Friday', '8:00 AM – 8:00 PM'),
          SizedBox(height: AppLayout.scaleHeight(context, 6)),
          _buildHoursRow(context, 'Saturday', '9:00 AM – 5:00 PM'),
          SizedBox(height: AppLayout.scaleHeight(context, 6)),
          _buildHoursRow(context, 'Sunday & Holidays', 'Closed'),
          SizedBox(height: AppLayout.scaleHeight(context, 12)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 10),
              vertical: AppLayout.scaleHeight(context, 6),
            ),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius:
                  BorderRadius.circular(AppLayout.scaleWidth(context, 6)),
            ),
            child: Text(
              '24/7 automated support via Live Chat',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 12),
                color: AppColors.primaryTeal ,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHoursRow(BuildContext context, String day, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            color: AppColors.textGrey,
          ),
        ),
        Text(
          hours,
          style: TextStyle(
            fontSize: AppLayout.fontSize(context, 13),
            fontWeight: FontWeight.w500,
            color: hours == 'Closed' ? Colors.red[400] : AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppLayout.fontSize(context, 15),
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _launchLiveChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening live chat…'),
        backgroundColor: AppColors.primaryTeal ,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: 'support@kudikit.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Email address copied'),
        backgroundColor: AppColors.primaryTeal ,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }

  void _copyPhone(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: '+2347000000000'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Phone number copied'),
        backgroundColor: AppColors.primaryTeal ,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportIssueSheet(),
    );
  }
}

// ─── Report Issue Bottom Sheet ────────────────────────────────────────────────

class _ReportIssueSheet extends StatefulWidget {
  @override
  State<_ReportIssueSheet> createState() => _ReportIssueSheetState();
}

class _ReportIssueSheetState extends State<_ReportIssueSheet> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;

  static const List<String> _categories = [
    'Transaction Issue',
    'Account Access',
    'Card Problem',
    'Transfer Failed',
    'KYC / Verification',
    'Other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedCategory != null &&
      _subjectController.text.trim().isNotEmpty &&
      _messageController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Your report has been submitted. We\'ll respond within 24 hours.'),
        backgroundColor: AppColors.primaryTeal ,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: AppLayout.scaleHeight(context, 16),
          left: AppLayout.scaleWidth(context, 16),
          right: AppLayout.scaleWidth(context, 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 20),
          AppLayout.scaleWidth(context, 20),
          AppLayout.scaleHeight(context, 32) +
              MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppLayout.scaleWidth(context, 20)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: AppLayout.scaleWidth(context, 40),
                height: AppLayout.scaleHeight(context, 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            Text(
              'Report an Issue',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Category chips
            Wrap(
              spacing: AppLayout.scaleWidth(context, 8),
              runSpacing: AppLayout.scaleHeight(context, 8),
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 12),
                      vertical: AppLayout.scaleHeight(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryTeal 
                          : AppColors.backgroundScreen,
                      borderRadius:
                          BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
                      border: Border.all(
                        color: selected
                            ? AppColors.primaryTeal 
                            : const Color(0xFFDDDDDD),
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 12),
                        fontWeight: FontWeight.w500,
                        color: selected ? Colors.white : AppColors.textGrey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Subject
            TextField(
              controller: _subjectController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: AppLayout.fontSize(context, 14)),
              decoration: InputDecoration(
                hintText: 'Subject',
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: AppLayout.fontSize(context, 14),
                ),
                filled: true,
                fillColor: AppColors.backgroundScreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 10)),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 10)),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 10)),
                  borderSide: const BorderSide(
                      color: AppColors.primaryTeal , width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 14),
                  vertical: AppLayout.scaleHeight(context, 12),
                ),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 12)),

            // Message
            TextField(
              controller: _messageController,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              style: TextStyle(fontSize: AppLayout.fontSize(context, 14)),
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail…',
                hintStyle: TextStyle(
                  color: AppColors.textLight,
                  fontSize: AppLayout.fontSize(context, 14),
                ),
                filled: true,
                fillColor: AppColors.backgroundScreen,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 10)),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 10)),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      AppLayout.scaleWidth(context, 10)),
                  borderSide: const BorderSide(
                      color: AppColors.primaryTeal , width: 1.5),
                ),
                contentPadding: EdgeInsets.all(AppLayout.scaleWidth(context, 14)),
              ),
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 20)),

            // Submit
            ElevatedButton(
              onPressed: (_canSubmit && !_isSubmitting) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal ,
                disabledBackgroundColor:
                    AppColors.primaryTeal .withOpacity(0.4),
                minimumSize: Size(
                    double.infinity, AppLayout.scaleHeight(context, 52)),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppLayout.scaleWidth(context, 30)),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Submit Report',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}