import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';

import 'package:intl/intl.dart';
import 'package:kudipay/presentation/transfer/confirm_transfer_buttom_sheet.dart';
import 'package:kudipay/presentation/transfer/schedule_transfer_screen.dart';
import 'package:kudipay/presentation/transfer/transfer_success_dialogue.dart';
import 'package:kudipay/provider/provider.dart';

class TransferAmountScreen extends ConsumerStatefulWidget {
  const TransferAmountScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TransferAmountScreen> createState() =>
      _TransferAmountScreenState();
}

class _TransferAmountScreenState extends ConsumerState<TransferAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  TransactionCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _amountFocus.addListener(() {
      if (!_amountFocus.hasFocus && _amountController.text.isNotEmpty) {
        _updateAmount();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _updateAmount() {
    final text = _amountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (text.isNotEmpty) {
      final amount = double.tryParse(text) ?? 0;
      ref.read(p2pTransferProvider.notifier).setAmount(amount);
    }
  }

  void _setQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(2);
    _updateAmount();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pTransferProvider);
    final quickAmounts = ref.watch(quickAmountsProvider);

    // Listen for transaction success to show modal
    ref.listen<P2PTransferState>(p2pTransferProvider, (previous, next) {
      if (next.transactionResult != null &&
          previous?.transactionResult == null) {
        TransactionSuccessBottomSheet.show(context);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildBody(context, state, quickAmounts),
          _buildSendButton(context, state),
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
      title: const Text(
        'Transfer Money',
        style: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(
    BuildContext context,
    P2PTransferState state,
    List<double> quickAmounts,
  ) {
    final recipient = state.transferData.recipient!;
    final hasInsufficientBalance = state.transferData.hasInsufficientBalance;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Recipient info
            _buildRecipientCard(context, recipient),

            SizedBox(height: AppLayout.scaleHeight(context, 24)),

            // Amount input card
            Container(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount label
                  Text(
                    'Amount',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black54,
                    ),
                  ),

                  SizedBox(height: AppLayout.scaleHeight(context, 8)),

                  // Amount input
                  TextField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 24),
                      fontWeight: FontWeight.w600,
                      color:
                          hasInsufficientBalance ? Colors.red : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: '₦1,000.00',
                      hintStyle: TextStyle(
                        color: Colors.black26,
                        fontSize: AppLayout.fontSize(context, 24),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: hasInsufficientBalance
                              ? Colors.red
                              : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: hasInsufficientBalance
                              ? Colors.red
                              : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF389165),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) => _updateAmount(),
                  ),

                  // Balance and fee info
                  SizedBox(height: AppLayout.scaleHeight(context, 8)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Balance: ${_currencyFormat.format(state.transferData.balance)}',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        'Fee: ${_currencyFormat.format(state.transferData.fee)}',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 12),
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  // Insufficient balance error
                  if (hasInsufficientBalance) ...[
                    SizedBox(height: AppLayout.scaleHeight(context, 8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 12),
                        vertical: AppLayout.scaleHeight(context, 8),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red[700],
                            size: AppLayout.scaleWidth(context, 16),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 8)),
                          Text(
                            'Insufficient balance',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 12),
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: AppLayout.scaleHeight(context, 16)),

                  // Quick amounts
                  Wrap(
                    spacing: AppLayout.scaleWidth(context, 8),
                    runSpacing: AppLayout.scaleHeight(context, 8),
                    children: quickAmounts.map((amount) {
                      final isSelected = state.transferData.amount == amount;
                      return InkWell(
                        onTap: () => _setQuickAmount(amount),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppLayout.scaleWidth(context, 16),
                            vertical: AppLayout.scaleHeight(context, 8),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF389165)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            '₦${amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              color: isSelected
                                  ? const Color(0xFF389165)
                                  : Colors.black54,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Category dropdown
            _buildCategoryDropdown(context),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Note input
            _buildNoteInput(context),

            SizedBox(height: AppLayout.scaleHeight(context, 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientCard(BuildContext context, RecipientInfo recipient) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: AppLayout.scaleWidth(context, 20),
            backgroundColor: const Color(0xFF389165),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: AppLayout.scaleWidth(context, 20),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.name,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  recipient.accountNumber,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category (optional)',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.black54,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          DropdownButtonFormField<TransactionCategory>(
            value: _selectedCategory,
            decoration: InputDecoration(
              hintText: 'Select Category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            items: TransactionCategory.values.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category.name[0].toUpperCase() + category.name.substring(1),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
              if (value != null) {
                ref.read(p2pTransferProvider.notifier).setCategory(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Note',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.black54,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'What\'s this for? (Optional)',
              hintStyle: TextStyle(
                color: Colors.black38,
                fontSize: AppLayout.fontSize(context, 14),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF389165),
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              ref.read(p2pTransferProvider.notifier).setNote(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton(BuildContext context, P2PTransferState state) {
    final canSend = state.transferData.amount != null &&
        state.transferData.amount! > 0 &&
        !state.transferData.hasInsufficientBalance;

    return Positioned(
      bottom: AppLayout.scaleHeight(context, 24),
      left: AppLayout.scaleWidth(context, 24),
      right: AppLayout.scaleWidth(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Send Now button
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 56),
            child: ElevatedButton(
              onPressed: canSend
                  ? () {
                      ConfirmTransferBottomSheet.show(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF389165),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFB2DFDB),
              ),
              child: Text(
                'Send Now',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 12)),

          // Schedule Payment button
          SizedBox(
            width: double.infinity,
            height: AppLayout.scaleHeight(context, 56),
            child: OutlinedButton(
              onPressed: canSend
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScheduledTransferScreen(),
                        ),
                      );
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: canSend ? const Color(0xFF389165) : Colors.grey[300]!,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Schedule Payment',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: canSend ? const Color(0xFF389165) : Colors.grey,
                ),
              ),
            ),
          ),

          SizedBox(height: AppLayout.scaleHeight(context, 8)),

          Text(
            'Send later at a specific date & time',
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 12),
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
