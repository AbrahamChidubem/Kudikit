import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/presentation/transfer/transaction_review.dart';
import 'package:kudipay/provider/provider.dart';


class ConfirmTransferBottomSheet extends ConsumerWidget {
  const ConfirmTransferBottomSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ConfirmTransferBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(p2pTransferProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppLayout.scaleWidth(context, 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kindly confirm',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 18),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Amount
              Text(
                currencyFormat.format(state.transferData.amount),
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 36),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF389165),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 24)),

              // Message
              Text(
                'You\'re about to transfer funds to ${state.transferData.recipient!.name.toUpperCase()}. Double-check the amount and recipient before proceeding.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 32)),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                        'Cancel',
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
                        Navigator.pop(context);
                        TransactionReviewBottomSheet.show(context);
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
                        'Proceed',
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
    );
  }
}