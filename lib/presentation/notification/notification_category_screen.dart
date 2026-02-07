import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/provider/provider.dart';

enum NotificationCategory {
  transaction,
  bills,
  rewards,
  appUpdates,
}

class NotificationCategoryScreen extends ConsumerWidget {
  final NotificationCategory category;

  const NotificationCategoryScreen({
    super.key,
    required this.category,
  });

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
          data: (preferences) => _buildContent(context, ref, preferences),
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF5C7C6F),
            ),
          ),
          error: (error, stack) => const Center(
            child: Text('Error loading preferences'),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, dynamic preferences) {
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
              children: _buildCategoryItems(context, ref, preferences),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryItems(
      BuildContext context, WidgetRef ref, dynamic preferences) {
    List<Widget> items = [];
    List<Map<String, dynamic>> categoryData = _getCategoryData(preferences);

    for (int i = 0; i < categoryData.length; i++) {
      final item = categoryData[i];
      items.add(
        _buildToggleTile(
          context,
          ref,
          title: item['title'],
          value: item['value'],
          key: item['key'],
        ),
      );

      if (i < categoryData.length - 1) {
        items.add(_buildDivider());
      }
    }

    return items;
  }

  List<Map<String, dynamic>> _getCategoryData(dynamic preferences) {
    switch (category) {
      case NotificationCategory.transaction:
        return [
          {
            'title': 'Transaction success / failure',
            'value': preferences.transactionSuccess,
            'key': 'transactionSuccess',
          },
          {
            'title': 'Deposit notification',
            'value': preferences.depositNotification,
            'key': 'depositNotification',
          },
          {
            'title': 'Withdrawal notification',
            'value': preferences.withdrawalNotification,
            'key': 'withdrawalNotification',
          },
          {
            'title': 'Large transaction alert',
            'value': preferences.largeTransactionAlert,
            'key': 'largeTransactionAlert',
          },
        ];

      case NotificationCategory.bills:
        return [
          {
            'title': 'Bill payment reminder',
            'value': preferences.billPaymentReminder,
            'key': 'billPaymentReminder',
          },
          {
            'title': 'Failed bill payment alert',
            'value': preferences.failedBillPaymentAlert,
            'key': 'failedBillPaymentAlert',
          },
          {
            'title': 'Large transaction alert',
            'value': preferences.largeTransactionAlert,
            'key': 'largeTransactionAlert',
          },
        ];

      case NotificationCategory.rewards:
        return [
          {
            'title': 'Reward earned alert',
            'value': preferences.rewardEarnedAlert,
            'key': 'rewardEarnedAlert',
          },
          {
            'title': 'Reward expiry alert',
            'value': preferences.rewardExpiryAlert,
            'key': 'rewardExpiryAlert',
          },
          {
            'title': 'Promotional offers',
            'value': preferences.promotionalOffers,
            'key': 'promotionalOffers',
          },
          {
            'title': 'Partner offers',
            'value': preferences.partnerOffers,
            'key': 'partnerOffers',
          },
        ];

      case NotificationCategory.appUpdates:
        return [
          {
            'title': 'New feature announcements',
            'value': preferences.newFeatureAnnouncements,
            'key': 'newFeatureAnnouncements',
          },
          {
            'title': 'Tutorial prompt',
            'value': preferences.tutorialPrompt,
            'key': 'tutorialPrompt',
          },
          {
            'title': 'Feedback request',
            'value': preferences.feedbackRequest,
            'key': 'feedbackRequest',
          },
          {
            'title': 'Announcement banners',
            'value': preferences.announcementBanners,
            'key': 'announcementBanners',
          },
        ];
    }
  }

  Widget _buildToggleTile(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required bool value,
    required String key,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 15),
                fontWeight: FontWeight.w400,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(width: AppLayout.scaleWidth(context, 12)),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: value,
              onChanged: (newValue) {
                ref
                    .read(notificationPreferencesProvider.notifier)
                    .togglePreference(key, newValue);
              },
              activeColor: Colors.white,
              activeTrackColor: const Color(0xFF5C7C6F),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
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
