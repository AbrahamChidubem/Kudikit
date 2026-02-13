import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/presentation/request/request_detail_screen.dart';
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
    
    // Load mock data
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          'My Request',
          style: GoogleFonts.openSans(
            color: Colors.black,
            fontSize: AppLayout.fontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Summary Cards
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppLayout.scaleWidth(context, 16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'To Receive',
                    amount: provider.totalToReceive,
                    color: const Color(0xFFE8F5E9),
                  ),
                ),
                SizedBox(width: AppLayout.scaleWidth(context, 12)),
                Expanded(
                  child: _SummaryCard(
                    title: 'Waiting On',
                    amount: provider.totalWaitingOn,
                    color: const Color(0xFFE3F2FD),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF2E7D32),
              indicatorWeight: 3,
              isScrollable: true,
              labelStyle: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 14),
                fontWeight: FontWeight.w600,
              ),
              tabs: [
                Tab(
                  child: Row(
                    children: [
                      const Text('Received'),
                      SizedBox(width: AppLayout.scaleWidth(context, 6)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppLayout.scaleWidth(context, 8),
                          vertical: AppLayout.scaleHeight(context, 2),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(
                            AppLayout.scaleWidth(context, 10),
                          ),
                        ),
                        child: Text(
                          '${provider.receivedRequests.length}',
                          style: GoogleFonts.openSans(
                            color: Colors.white,
                            fontSize: AppLayout.fontSize(context, 12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Tab(text: 'Sent'),
                const Tab(text: 'Paid'),
                const Tab(text: 'Expired'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
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
          Navigator.pop(context);
        },
        backgroundColor: const Color(0xFF2E7D32),
        child: Icon(Icons.add, 
          color: Colors.white,
          size: AppLayout.scaleWidth(context, 24),
        ),
      ),
    );
  }

  Widget _buildReceivedTab(RequestProvider provider) {
    final requests = provider.receivedRequests;

    if (requests.isEmpty) {
      return _buildEmptyState('No received requests');
    }

    return Container(
      color: const Color(0xFFE8F5E9),
      child: ListView.builder(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _RequestCard(
            request: request,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestDetailScreen(request: request),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSentTab(RequestProvider provider) {
    final requests = provider.sentRequests;

    if (requests.isEmpty) {
      return _buildEmptyState('No sent requests');
    }

    return Container(
      color: const Color(0xFFE8F5E9),
      child: ListView.builder(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _RequestCard(
            request: request,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestDetailScreen(request: request),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPaidTab(RequestProvider provider) {
    final requests = provider.receivedRequests
        .where((r) => r.status == RequestStatus.paid)
        .toList();

    if (requests.isEmpty) {
      return _buildEmptyState('No paid requests');
    }

    return Container(
      color: const Color(0xFFE8F5E9),
      child: ListView.builder(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _RequestCard(request: requests[index]);
        },
      ),
    );
  }

  Widget _buildExpiredTab(RequestProvider provider) {
    final requests = provider.receivedRequests
        .where((r) => r.status == RequestStatus.expired)
        .toList();

    if (requests.isEmpty) {
      return _buildEmptyState('No expired requests');
    }

    return Container(
      color: const Color(0xFFE8F5E9),
      child: ListView.builder(
        padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return _RequestCard(request: requests[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, 
            size: AppLayout.scaleWidth(context, 64), 
            color: Colors.grey[300],
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
          Text(
            message,
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 16),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 4)),
          Text(
            '₦${NumberFormat('#,###').format(amount)}',
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final MoneyRequest request;
  final VoidCallback? onTap;

  const _RequestCard({
    required this.request,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppLayout.scaleHeight(context, 12)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
              leading: CircleAvatar(
                radius: AppLayout.scaleWidth(context, 20),
                backgroundColor: _getAvatarColor(),
                child: Text(
                  request.requesterName.substring(0, 2).toUpperCase(),
                  style: GoogleFonts.openSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: AppLayout.fontSize(context, 14),
                  ),
                ),
              ),
              title: Text(
                request.requesterName,
                style: GoogleFonts.openSans(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _getTimeAgo(request.createdAt),
                style: GoogleFonts.openSans(
                  fontSize: AppLayout.fontSize(context, 13),
                  color: Colors.grey[600],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦${NumberFormat('#,###.00').format(request.amount)}',
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 15),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppLayout.scaleHeight(context, 4)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 8),
                      vertical: AppLayout.scaleHeight(context, 4),
                    ),
                    decoration: BoxDecoration(
                      color: request.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 8),
                      ),
                    ),
                    child: Text(
                      request.statusText,
                      style: GoogleFonts.openSans(
                        fontSize: AppLayout.fontSize(context, 11),
                        fontWeight: FontWeight.w600,
                        color: request.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor() {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFFE91E63),
      const Color(0xFFFFA726),
    ];
    return colors[request.id.hashCode % colors.length];
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Sent ${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return 'Sent ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return 'Sent ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Sent just now';
    }
  }
}