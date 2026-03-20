import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/shimmer_widget.dart';
import 'package:kudipay/presentation/request/request_detail_screen.dart';
import 'package:kudipay/presentation/request/request_money_main_screen.dart';
import 'package:kudipay/provider/request/request_provider.dart';

import '../../model/request/request_model.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ref.read is correct here — one-shot call on init, not for rebuilds
      ref.read(requestProvider).loadMockData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(requestProvider);

    // ── Derived counts for tab badges ──────────────────────────────────────
    final receivedCount = provider.receivedRequests.length;
    final sentCount = provider.sentRequests.length;
    final paidCount = [
      ...provider.receivedRequests.where((r) => r.status == RequestStatus.paid),
      ...provider.sentRequests.where((r) => r.status == RequestStatus.paid),
    ].length;
    final expiredCount = [
      ...provider.receivedRequests
          .where((r) => r.status == RequestStatus.expired),
      ...provider.sentRequests.where((r) => r.status == RequestStatus.expired),
    ].length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: AppLayout.scaleWidth(context, 24),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Request',
          style: TextStyle(
            fontFamily: 'PolySans',
            color: AppColors.textDark,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Summary cards ────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              AppLayout.scaleWidth(context, 16),
              AppLayout.scaleHeight(context, 16),
              AppLayout.scaleWidth(context, 16),
              AppLayout.scaleHeight(context, 16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'To Receive',
                    amount: provider.totalToReceive,
                    iconColor: const Color(0xFF4CAF50),
                    backgroundColor: const Color(0xFFF0FBF0),
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 12)),
                Expanded(
                  child: _SummaryCard(
                    title: 'Waiting On',
                    amount: provider.totalWaitingOn,
                    iconColor: const Color(0xFF2196F3),
                    backgroundColor: const Color(0xFFF0F7FF),
                  ),
                ),
              ],
            ),
          ),

          // ── Tab bar ──────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF069494),
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: const Color(0xFF069494),
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 4),
              ),
              labelStyle: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 13),
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                _TabWithBadge(label: 'Received', count: receivedCount),
                _TabWithBadge(label: 'Sent', count: sentCount),
                _TabWithBadge(label: 'Paid', count: paidCount),
                _TabWithBadge(label: 'Expired', count: expiredCount),
              ],
            ),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: provider.isLoading
                ? const RequestListShimmer(itemCount: 5)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReceivedTab(provider),
                      _buildSentTab(provider),
                      _buildPaidTab(provider),
                      _buildExpiredTab(provider),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RequestMoneyMainScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF069494),
        elevation: 2,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: AppLayout.scaleWidth(context, 26),
        ),
      ),
    );
  }

  // ── Received: pending + partial requests only ──────────────────────────
  Widget _buildReceivedTab(RequestProvider provider) {
    final requests = provider.receivedRequests
        .where((r) =>
            r.status == RequestStatus.pending ||
            r.status == RequestStatus.partial)
        .toList();

    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        message: 'No pending requests',
        subtitle: 'Requests sent to you will appear here',
      );
    }

    return _RequestList(
      requests: requests,
      onTap: (request) => _navigateToDetail(request),
    );
  }

  // ── Sent: all outgoing requests ─────────────────────────────────────────
  Widget _buildSentTab(RequestProvider provider) {
    final requests = provider.sentRequests;

    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.send_outlined,
        message: 'No sent requests',
        subtitle: 'Requests you send will appear here',
      );
    }

    return _RequestList(
      requests: requests,
      onTap: (request) => _navigateToDetail(request),
    );
  }

  // ── Paid: from both received & sent ────────────────────────────────────
  Widget _buildPaidTab(RequestProvider provider) {
    final requests = [
      ...provider.receivedRequests.where((r) => r.status == RequestStatus.paid),
      ...provider.sentRequests.where((r) => r.status == RequestStatus.paid),
    ];

    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        message: 'No paid requests',
        subtitle: 'Completed payments will appear here',
      );
    }

    return _RequestList(requests: requests);
  }

  // ── Expired: from both received & sent ─────────────────────────────────
  Widget _buildExpiredTab(RequestProvider provider) {
    final requests = [
      ...provider.receivedRequests
          .where((r) => r.status == RequestStatus.expired),
      ...provider.sentRequests.where((r) => r.status == RequestStatus.expired),
    ];

    if (requests.isEmpty) {
      return _buildEmptyState(
        icon: Icons.access_time_outlined,
        message: 'No expired requests',
        subtitle: 'Requests that timed out will appear here',
      );
    }

    return _RequestList(requests: requests);
  }

  void _navigateToDetail(MoneyRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailScreen(request: request),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppLayout.scaleWidth(context, 72),
            height: AppLayout.scaleWidth(context, 72),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppLayout.scaleWidth(context, 36),
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          Text(
            message,
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppLayout.scaleHeight(context, 6)),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 13),
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab with optional count badge ──────────────────────────────────────────
class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;

  const _TabWithBadge({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.scaleWidth(context, 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0) ...[
              SizedBox(width: AppLayout.scaleWidth(context, 6)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 7),
                  vertical: AppLayout.scaleHeight(context, 2),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF069494),
                  borderRadius: BorderRadius.circular(
                    AppLayout.scaleWidth(context, 10),
                  ),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'PolySans',
                    color: Colors.white,
                    fontSize: AppLayout.fontSize(context, 11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Scrollable request list ─────────────────────────────────────────────────
class _RequestList extends StatelessWidget {
  final List<MoneyRequest> requests;
  final void Function(MoneyRequest)? onTap;

  const _RequestList({required this.requests, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppLayout.scaleWidth(context, 16),
        AppLayout.scaleHeight(context, 16),
        AppLayout.scaleWidth(context, 16),
        AppLayout.scaleHeight(context, 24),
      ),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _RequestCard(
          request: requests[index],
          onTap: onTap != null ? () => onTap!(requests[index]) : null,
        );
      },
    );
  }
}

// ── Summary card ────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color iconColor;
  final Color backgroundColor;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 12),
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 6)),
          Text(
            '₦${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 20),
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Individual request card ─────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  final MoneyRequest request;
  final VoidCallback? onTap;

  const _RequestCard({required this.request, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(AppLayout.scaleWidth(context, 14)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 10),
          ),
          leading: CircleAvatar(
            radius: AppLayout.scaleWidth(context, 22),
            backgroundColor: _getAvatarColor(),
            child: Text(
              _getInitials(),
              style: TextStyle(
                fontFamily: 'PolySans',
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: AppLayout.fontSize(context, 13),
              ),
            ),
          ),
          title: Padding(
            padding: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 2)),
            child: Text(
              request.requesterName,
              style: TextStyle(
                fontFamily: 'PolySans',
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          subtitle: Text(
            _getTimeAgo(request.createdAt),
            style: TextStyle(
              fontFamily: 'PolySans',
              fontSize: AppLayout.fontSize(context, 12),
              color: Colors.grey[500],
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₦${NumberFormat('#,###.00').format(request.amount)}',
                style: TextStyle(
                  fontFamily: 'PolySans',
                  fontSize: AppLayout.fontSize(context, 14),
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 5)),
              _StatusBadge(request: request),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final name = request.requesterName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.length >= 2
        ? name.substring(0, 2).toUpperCase()
        : name[0].toUpperCase();
  }

  Color _getAvatarColor() {
    const colors = [
      Color(0xFF069494),
      Color(0xFFE91E63),
      Color(0xFFFFA726),
      Color(0xFF7C4DFF),
      Color(0xFF00897B),
    ];
    return colors[request.id.hashCode.abs() % colors.length];
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

// ── Status badge ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final MoneyRequest request;

  const _StatusBadge({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 8),
        vertical: AppLayout.scaleHeight(context, 3),
      ),
      decoration: BoxDecoration(
        color: request.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 20)),
      ),
      child: Text(
        request.statusText,
        style: TextStyle(
          fontFamily: 'PolySans',
          fontSize: AppLayout.fontSize(context, 11),
          fontWeight: FontWeight.w600,
          color: request.statusColor,
        ),
      ),
    );
  }
}
