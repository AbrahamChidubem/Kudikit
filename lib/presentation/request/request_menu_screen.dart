import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/request/my_request_screen.dart';
import 'package:kudipay/presentation/request/request_money_screen.dart';



class RequestMenuScreen extends StatelessWidget {
  const RequestMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, 
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request Menu',
          style: GoogleFonts.openSans(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        child: Column(
          children: [
            _MenuCard(
              icon: Icons.request_page_outlined,
              title: 'Request Money',
              subtitle: 'Create a new money request',
              color: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF2196F3),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RequestMoneyScreen(),
                  ),
                );
              },
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            _MenuCard(
              icon: Icons.receipt_long,
              title: 'My Request',
              subtitle: 'Manage all your request',
              color: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyRequestsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
      child: Container(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: AppLayout.scaleWidth(context, 10),
              offset: Offset(0, AppLayout.scaleHeight(context, 4)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 56),
              height: AppLayout.scaleWidth(context, 56),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: AppLayout.scaleWidth(context, 28),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 4)),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: AppLayout.scaleWidth(context, 16),
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}