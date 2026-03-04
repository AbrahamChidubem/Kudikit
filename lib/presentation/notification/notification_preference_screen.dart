import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/notification/notification_category_screen.dart';
import 'package:kudipay/provider/provider.dart';


class NotificationPreferenceScreen extends ConsumerWidget {
  const NotificationPreferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesState = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Preference',
          style: TextStyle(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: preferencesState.when(
          data: (preferences) => _buildContent(context, preferences),
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF069494),
            ),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: AppLayout.scaleWidth(context, 48),
                  color: Colors.red,
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 16)),
                Text(
                  'Failed to load preferences',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 16),
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                TextButton(
                  onPressed: () {
                    ref.read(notificationPreferencesProvider.notifier).loadPreferences();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic preferences) {
    return Padding(
      padding: AppLayout.pagePadding(context),
      child: Column(
        children: [
          Container(
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
              children: [
                _buildCategoryTile(
                  context,
                  icon: Icons.payment,
                  title: 'Transaction',
                  subtitle: 'Payments, deposits, balance alerts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationCategoryScreen(
                          category: NotificationCategory.transaction,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildCategoryTile(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Bills & Reminders',
                  subtitle: 'Upcoming bills and due dates',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationCategoryScreen(
                          category: NotificationCategory.bills,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildCategoryTile(
                  context,
                  icon: Icons.card_giftcard,
                  title: 'Reward & Offers',
                  subtitle: 'Cashback, rewards, and promotions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationCategoryScreen(
                          category: NotificationCategory.rewards,
                        ),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildCategoryTile(
                  context,
                  icon: Icons.lightbulb_outline,
                  title: 'App updates & Tips',
                  subtitle: 'New features, announcement, and tutorials',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationCategoryScreen(
                          category: NotificationCategory.appUpdates,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 16),
          vertical: AppLayout.scaleHeight(context, 16),
        ),
        child: Row(
          children: [
            Container(
              width: AppLayout.scaleWidth(context, 40),
              height: AppLayout.scaleWidth(context, 40),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF069494),
                size: AppLayout.scaleWidth(context, 20),
              ),
            ),
            SizedBox(width: AppLayout.scaleWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 16),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 4)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 13),
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: AppLayout.scaleWidth(context, 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.grey[200],
      ),
    );
  }
}