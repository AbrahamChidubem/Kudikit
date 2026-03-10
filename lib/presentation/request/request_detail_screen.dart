import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/provider/request/request_provider.dart';
import 'package:provider/provider.dart';
import '../../model/request/request_model.dart';


class RequestDetailScreen extends StatefulWidget {
  final MoneyRequest request;

  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  void _showPartialPaymentDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PartialPaymentSheet(request: widget.request),
    );
  }

  void _showPaymentConfirmation(double amount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentConfirmationSheet(
        request: widget.request,
        amount: amount,
      ),
    );
  }

  void _showCounterOfferDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Counter offer feature coming soon')),
    );
  }

  void _declineRequest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Decline Request?',
          style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to decline this request?',
          style: GoogleFonts.openSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.openSans(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              await Provider.of<RequestProvider>(context, listen: false)
                  .declineRequest(widget.request);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(
              'Decline',
              style: GoogleFonts.openSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Request',
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
            // Requester Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.black,
                    child: Text(
                      request.requesterName.substring(0, 2).toUpperCase(),
                      style: GoogleFonts.openSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.requesterName,
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          request.requesterPhone,
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF069494),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Money Requesting',
                    style: GoogleFonts.openSans(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₦${NumberFormat('#,###.00').format(request.amount)}',
                    style: GoogleFonts.openSans(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Overdue Warning (if applicable)
            if (request.isOverdue)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Overdue',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                          Text(
                            'This request was due ${request.daysOverdue} day${request.daysOverdue > 1 ? 's' : ''} ago',
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (request.isOverdue) const SizedBox(height: 16),

            // Request Details
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
                    'Request Details',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Category', request.category),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Due date',
                    request.dueDate != null
                        ? DateFormat('MMMM dd, yyyy').format(request.dueDate!)
                        : 'Not set',
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Privacy',
                    request.isPrivate ? 'Private' : 'Public',
                    icon: Icons.lock_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Status',
                    request.statusText,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description (if available)
            if (request.description != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.description!,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: request.status == RequestStatus.pending ||
              request.status == RequestStatus.partial
          ? Container(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showPaymentConfirmation(request.remainingAmount),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF069494),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          'Pay Full Amount  ₦${NumberFormat('#,###').format(request.remainingAmount)}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showPartialPaymentDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF069494),
                              side: const BorderSide(color: Color(0xFF069494)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Pay partial',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showCounterOfferDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF069494),
                              side: const BorderSide(color: Color(0xFF069494)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Counter',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _declineRequest,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Decline',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
        ],
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PartialPaymentSheet extends StatefulWidget {
  final MoneyRequest request;

  const _PartialPaymentSheet({required this.request});

  @override
  State<_PartialPaymentSheet> createState() => _PartialPaymentSheetState();
}

class _PartialPaymentSheetState extends State<_PartialPaymentSheet> {
  final TextEditingController _amountController = TextEditingController();
  double _selectedPercentage = 0.25;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectPercentage(double percentage) {
    setState(() {
      _selectedPercentage = percentage;
      final amount = widget.request.remainingAmount * percentage;
      _amountController.text = NumberFormat('#,###').format(amount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.request.remainingAmount;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Partial Payment',
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the amount you want to pay now',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Amount',
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                prefixText: '₦ ',
                prefixStyle: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Remaining: ₦${NumberFormat('#,###.00').format(remaining)}',
              style: GoogleFonts.openSans(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _PercentageChip(
                  label: '25% ( ₦${NumberFormat('#,###').format(remaining * 0.25)})',
                  percentage: 0.25,
                  selectedPercentage: _selectedPercentage,
                  onTap: _selectPercentage,
                ),
                const SizedBox(width: 8),
                _PercentageChip(
                  label: '50% ( ₦${NumberFormat('#,###').format(remaining * 0.50)})',
                  percentage: 0.50,
                  selectedPercentage: _selectedPercentage,
                  onTap: _selectPercentage,
                ),
                const SizedBox(width: 8),
                _PercentageChip(
                  label: '75% ( ₦${NumberFormat('#,###').format(remaining * 0.75)})',
                  percentage: 0.75,
                  selectedPercentage: _selectedPercentage,
                  onTap: _selectPercentage,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(
                  _amountController.text.replaceAll(',', ''),
                );
                if (amount != null && amount > 0 && amount <= remaining) {
                  Navigator.pop(context);
                  // Show confirmation
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _PaymentConfirmationSheet(
                      request: widget.request,
                      amount: amount,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Continue to Payment',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentageChip extends StatelessWidget {
  final String label;
  final double percentage;
  final double selectedPercentage;
  final Function(double) onTap;

  const _PercentageChip({
    required this.label,
    required this.percentage,
    required this.selectedPercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = percentage == selectedPercentage;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(percentage),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8F5E9) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF069494) : Colors.transparent,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF069494) : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentConfirmationSheet extends StatelessWidget {
  final MoneyRequest request;
  final double amount;

  const _PaymentConfirmationSheet({
    required this.request,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirm Payment',
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Review payment details',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Paying to', request.requesterName),
            const SizedBox(height: 12),
            _buildDetailRow('Amount', '₦${NumberFormat('#,###.00').format(amount)}'),
            const SizedBox(height: 12),
            _buildDetailRow('Reason', request.reason ?? 'Dinner'),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Your payment will be processed immediately and ${request.requesterName} will be notified',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: const Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Process payment
                await Provider.of<RequestProvider>(context, listen: false)
                    .payRequest(request, amount);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close confirmation sheet
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment successful!'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Pay Now',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Cancel',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}