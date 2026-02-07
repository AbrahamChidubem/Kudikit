import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/presentation/transfer/transaction_detail.dart';
import 'package:kudipay/provider/provider.dart';


class TransactionSuccessBottomSheet extends ConsumerStatefulWidget {
  const TransactionSuccessBottomSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => const TransactionSuccessBottomSheet(),
    );
  }

  @override
  ConsumerState<TransactionSuccessBottomSheet> createState() =>
      _TransactionSuccessBottomSheetState();
}

class _TransactionSuccessBottomSheetState
    extends ConsumerState<TransactionSuccessBottomSheet> {
  bool _addToFavourite = false;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(p2pTransferProvider);
    final result = state.transactionResult!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // Success icon
                Container(
                  width: AppLayout.scaleWidth(context, 64),
                  height: AppLayout.scaleWidth(context, 64),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: AppLayout.scaleWidth(context, 36),
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // Amount
                Text(
                  '-${_currencyFormat.format(result.amount)}',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 32),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 16)),

                // Success message
                Text(
                  'Transfer to ${state.transferData.recipient!.name.toUpperCase()} is successfully completed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 14),
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // Transaction details summary
                _buildDetailRow(
                  context,
                  'Transaction Type',
                  result.transactionType,
                ),
                _buildDetailRow(
                  context,
                  'Paying Bank',
                  '${result.payingBank}\n(${result.payingBankAccount})',
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // Add to favourite toggle
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 16),
                    vertical: AppLayout.scaleHeight(context, 12),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add to favourite',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Switch(
                        value: _addToFavourite,
                        onChanged: (value) {
                          setState(() {
                            _addToFavourite = value;
                          });
                        },
                        activeColor: const Color(0xFF389165),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 24)),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TransactionDetailsScreen(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppLayout.scaleHeight(context, 14),
                          ),
                          side: const BorderSide(
                            color: Color(0xFF389165),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          'Details',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF389165),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 12)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Save to favourites if toggled
                          if (_addToFavourite) {
                            // TODO: Implement save to favourites
                          }

                          // Navigate back to home or reset flow
                          ref.read(p2pTransferProvider.notifier).reset();
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppLayout.scaleHeight(context, 14),
                          ),
                          backgroundColor: const Color(0xFF389165),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize: AppLayout.fontSize(context, 15),
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: AppLayout.scaleHeight(context, 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppLayout.scaleHeight(context, 6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.black54,
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 16)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 13),
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}