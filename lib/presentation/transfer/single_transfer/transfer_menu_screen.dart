import 'package:flutter/material.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/transfer/bulk_transfer/bulk_transfer_screen.dart';

import 'package:kudipay/presentation/transfer/single_transfer/transfer_receipt_screen.dart';

class TransferMenuScreen extends StatelessWidget {
  const TransferMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transfer Menu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          children: [
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            
            // Single Transfer Option
            _buildTransferOption(
              context: context,
              icon: Icons.person_outline,
              iconColor: const Color(0xFF069494),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Single Transfer',
              subtitle: 'Send money to one recipient',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransferRecipientScreen(),
                  ),
                );
              },
            ),
            
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            
            // Bulk Transfer Option
            _buildTransferOption(
              context: context,
              icon: Icons.group_outlined,
              iconColor: const Color(0xFF069494),
              iconBgColor: const Color(0xFFE8F5E9),
              title: 'Bulk Transfer',
              subtitle: 'Send money to up to 15 people at once',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BulkTransferScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
            child: Row(
              children: [
                // Icon
                Container(
                  width: AppLayout.scaleWidth(context, 48),
                  height: AppLayout.scaleWidth(context, 48),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: AppLayout.scaleWidth(context, 24),
                  ),
                ),
                
                SizedBox(width: AppLayout.scaleWidth(context, 16)),
                
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: AppLayout.scaleHeight(context, 4)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow
                Icon(
                  Icons.arrow_forward_ios,
                  size: AppLayout.scaleWidth(context, 16),
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}