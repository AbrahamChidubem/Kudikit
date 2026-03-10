import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/presentation/transfer/single_transfer/transaction_review.dart';
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

  /// Returns up to 2 uppercase initials from a full name.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(p2pTransferProvider);
    // The logged-in user name comes from userProvider (e.g. 'MICHAEL ASUQUO TOLUWALASE')
    final senderName = ref.watch(userProvider);
    // The verification state holds the sender's account number (idNumber field)
    final verificationState = ref.watch(identityVerificationProvider);
    final senderAccountNumber =
        verificationState.verificationData?.idNumber ?? '';

    final currencyFormat =
        NumberFormat.currency(symbol: '₦', decimalDigits: 2);

    final recipient = state.transferData.recipient;
    final balance = state.transferData.balance;

    return Container(
      decoration: const BoxDecoration(
        color:  Color(0xFFF9F9F9),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 24),
            vertical: AppLayout.scaleHeight(context, 20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Center(
                    child: Text(
                      'Kindly confirm',
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 18),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 22,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Amount ──────────────────────────────────────────────
              Center(
                child: Text(
                  currencyFormat.format(state.transferData.amount ?? 0),
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 34),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF069494),
                  ),
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Recipient details card ───────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Row 1: Account details
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                        vertical: AppLayout.scaleHeight(context, 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Account details',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            // e.g. "8123456789 | OPay"
                            '${recipient?.accountNumber ?? ''}'
                            '${(recipient?.bank != null && recipient!.bank!.isNotEmpty) ? ' | ${recipient.bank}' : ''}',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(height: 1, color: Colors.grey.shade200),

                    // Row 2: Account name
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                        vertical: AppLayout.scaleHeight(context, 14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Account name',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              color: Colors.black45,
                            ),
                          ),
                          Text(
                            recipient?.name ?? '',
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 20)),

              // ── Paying from label ────────────────────────────────────
              Text(
                'Paying from',
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: Colors.black45,
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 10)),

              // ── Sender card ──────────────────────────────────────────
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                  vertical: AppLayout.scaleHeight(context, 14),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Sender initials avatar
                    CircleAvatar(
                      radius: AppLayout.scaleWidth(context, 20),
                      backgroundColor:
                          const Color(0xFF069494).withOpacity(0.15),
                      child: Text(
                        _initials(senderName),
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 13),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF069494),
                        ),
                      ),
                    ),

                    SizedBox(width: AppLayout.scaleWidth(context, 12)),

                    // Sender name + account number + balance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and account number on the same line
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  senderAccountNumber.isNotEmpty
                                      ? '${senderName.toUpperCase()}  $senderAccountNumber'
                                      : senderName.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 13),
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF171515),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 4)),
                          // Balance below
                          Text(
                            currencyFormat.format(balance),
                            style: TextStyle(
                              fontSize: AppLayout.fontSize(context, 13),
                              color: Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppLayout.scaleHeight(context, 28)),

              // ── Action buttons ────────────────────────────────────────
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
                          color: Color(0xFF069494),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 15),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF069494),
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
                        backgroundColor: const Color(0xFF069494),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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

              SizedBox(height: AppLayout.scaleHeight(context, 8)),
            ],
          ),
        ),
      ),
    );
  }
}