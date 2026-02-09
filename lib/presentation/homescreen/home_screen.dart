import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/presentation/addmoney/add_money_screen.dart';
import 'package:kudipay/presentation/transfer/transfer_reciept_screen.dart';
import 'package:kudipay/provider/provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    // Listen to connectivity changes and show feedback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupConnectivityListener();
    });
  }

  void _setupConnectivityListener() {
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          // Connection lost
          ConnectivitySnackBar.showNoInternet(context);
        } else if (previous?.value != null &&
            !previous!.value! &&
            isConnected) {
          // Connection restored
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);
    final connectivityState = ref.watch(connectivityStateProvider);

    // The name comes from the BVN/NIN verification!
    final firstName = userInfo?.firstName ?? 'User';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Connectivity Status Bar (shows when offline)
            if (!connectivityState.isConnected)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 8),
                  horizontal: AppLayout.scaleWidth(context, 16),
                ),
                color: Colors.red.shade700,
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                      size: AppLayout.scaleWidth(context, 20),
                    ),
                    SizedBox(width: AppLayout.scaleWidth(context, 8)),
                    Expanded(
                      child: Text(
                        'No internet connection',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppLayout.fontSize(context, 14),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(connectivityStateProvider.notifier).refresh();
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppLayout.fontSize(context, 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    Padding(
                      padding: AppLayout.pagePadding(context),
                      child: Row(
                        children: [
                          // Profile Image
                          Container(
                            width: AppLayout.scaleWidth(context, 45),
                            height: AppLayout.scaleWidth(context, 45),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 12),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppLayout.scaleWidth(context, 12),
                              ),
                              child: Image.asset(
                                'assets/images/img_placeholder.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF4CAF50),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: AppLayout.scaleWidth(context, 24),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 12)),

                          // Greeting
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, $firstName 👋',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 16),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppLayout.scaleWidth(context, 8),
                                    vertical: AppLayout.scaleHeight(context, 2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4CAF50)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppLayout.scaleWidth(context, 8),
                                    ),
                                  ),
                                  child: Text(
                                    'Tier 1',
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 11),
                                      color: const Color(0xFF4CAF50),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Icons with connectivity indicator
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.headphones_outlined),
                            color: Colors.grey[700],
                            iconSize: AppLayout.scaleWidth(context, 24),
                          ),
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: const Icon(Icons.notifications_outlined),
                                color: Colors.grey[700],
                                iconSize: AppLayout.scaleWidth(context, 24),
                              ),
                              // Small connectivity indicator dot
                              Positioned(
                                right: AppLayout.scaleWidth(context, 8),
                                top: AppLayout.scaleHeight(context, 8),
                                child: Container(
                                  width: AppLayout.scaleWidth(context, 8),
                                  height: AppLayout.scaleWidth(context, 8),
                                  decoration: BoxDecoration(
                                    color: connectivityState.isConnected
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 8)),

                    // Balance Card
                    Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                      ),
                      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF52B788),
                            Color(0xFF40916C),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppLayout.scaleWidth(context, 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF52B788).withOpacity(0.3),
                            blurRadius: AppLayout.scaleWidth(context, 20),
                            offset: Offset(0, AppLayout.scaleHeight(context, 8)),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Available Balance',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 13),
                                  color: Colors.white70,
                                ),
                              ),
                              // Connection status indicator on balance card
                              Row(
                                children: [
                                  Icon(
                                    connectivityState.isConnected
                                        ? Icons.wifi
                                        : Icons.wifi_off,
                                    color: Colors.white70,
                                    size: AppLayout.scaleWidth(context, 14),
                                  ),
                                  SizedBox(width: AppLayout.scaleWidth(context, 4)),
                                  Text(
                                    connectivityState.isConnected
                                        ? (connectivityState.connectionType ??
                                            'Online')
                                        : 'Offline',
                                    style: TextStyle(
                                      fontSize: AppLayout.fontSize(context, 10),
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 8)),
                          Row(
                            children: [
                              Text(
                                _isBalanceVisible
                                    ? '₦135,780.00'
                                    : '₦**********',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 32),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: AppLayout.scaleWidth(context, 12)),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isBalanceVisible = !_isBalanceVisible;
                                  });
                                },
                                child: Icon(
                                  _isBalanceVisible
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white70,
                                  size: AppLayout.scaleWidth(context, 20),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 16)),
                          Row(
                            children: [
                              Text(
                                connectivityState.isConnected
                                    ? 'Last updated 2 minutes ago'
                                    : 'Offline - Last sync 2 minutes ago',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 11),
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppLayout.scaleHeight(context, 8)),
                          Row(
                            children: [
                              Text(
                                '8124608695',
                                style: TextStyle(
                                  fontSize: AppLayout.fontSize(context, 12),
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: AppLayout.scaleWidth(context, 8)),
                              Flexible(
                                child: Text(
                                  'Michael Asuquo Taluwalase',
                                  style: TextStyle(
                                    fontSize: AppLayout.fontSize(context, 12),
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: AppLayout.scaleWidth(context, 4)),
                              Icon(
                                Icons.copy,
                                size: AppLayout.scaleWidth(context, 14),
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 20)),

                    // Quick Actions with connectivity-aware buttons
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                      ),
                      child: Row(
                        children: [
                          _buildQuickAction(
                            icon: Icons.send_outlined,
                            label: 'Transfer',
                            onTap: () {
                              _handleQuickAction(context, 'Transfer',
                                  navigateTo: const TransferRecipientScreen());
                            },
                            isEnabled: connectivityState.isConnected,
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 12)),
                          _buildQuickAction(
                            icon: Icons.add_circle_outline,
                            label: 'Top Up',
                            onTap: () {
                              _handleQuickAction(
                                context,
                                'Top Up',
                                navigateTo: const AddMoneyScreen(),
                              );
                            },
                            isEnabled: connectivityState.isConnected,
                          ),
                          SizedBox(width: AppLayout.scaleWidth(context, 12)),
                          _buildQuickAction(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Cash out',
                            onTap: () {
                              _handleQuickAction(context, 'Cash out');
                            },
                            isEnabled: connectivityState.isConnected,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: AppLayout.scaleHeight(context, 24)),

                    // Bill & Utilities
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                      ),
                      child: Text(
                        'Bill & Utilities',
                        style: TextStyle(
                          fontSize: AppLayout.fontSize(context, 14),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    SizedBox(height: AppLayout.scaleHeight(context, 12)),

                    // Bill Services Grid
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppLayout.scaleWidth(context, 16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildServiceCard(
                                icon: Icons.phone_callback,
                                label: 'Airtime',
                                isEnabled: connectivityState.isConnected,
                              ),
                              const SizedBox(width: 12),
                              _buildServiceCard(
                                icon: Icons.wifi,
                                label: 'Data',
                                isEnabled: connectivityState.isConnected,
                              ),
                              const SizedBox(width: 12),
                              _buildServiceCard(
                                icon: Icons.tv,
                                label: 'TV',
                                isEnabled: connectivityState.isConnected,
                              ),
                              const SizedBox(width: 12),
                              _buildServiceCard(
                                icon: Icons.bolt_outlined,
                                label: 'Electricity',
                                isEnabled: connectivityState.isConnected,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildServiceCard(
                                icon: Icons.school_outlined,
                                label: 'Education',
                                isEnabled: connectivityState.isConnected,
                              ),
                              const SizedBox(width: 12),
                              _buildServiceCard(
                                icon: Icons.sports_soccer_outlined,
                                label: 'Betting',
                                isEnabled: connectivityState.isConnected,
                              ),
                              const SizedBox(width: 12),
                              _buildServiceCard(
                                icon: Icons.savings_outlined,
                                label: 'Savings',
                                isEnabled: connectivityState.isConnected,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(child: SizedBox()),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Recent Transactions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transaction',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          TextButton(
                            onPressed: connectivityState.isConnected
                                ? () {
                                    // Navigate to all transactions
                                  }
                                : () {
                                    ConnectivitySnackBar.showNoInternet(
                                        context);
                                  },
                            child: Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 12,
                                color: connectivityState.isConnected
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transaction List (with offline indicator if needed)
                    if (!connectivityState.isConnected)
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'You\'re viewing cached transactions. Connect to internet for latest updates.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    _buildTransactionItem(
                      title: 'Transfer to POS Transfer - TEMI...',
                      date: 'Dec 20th, 10:39:25',
                      amount: '-₦10,200.00',
                      isSuccess: true,
                    ),
                    _buildTransactionItem(
                      title: 'Transfer to POS Transfer - TEMI...',
                      date: 'Dec 20th, 10:39:25',
                      amount: '-₦10,200.00',
                      isSuccess: true,
                    ),
                    _buildTransactionItem(
                      title: 'Transfer to POS Transfer - TEMI...',
                      date: 'Dec 20th, 10:39:25',
                      amount: '-₦10,200.00',
                      isSuccess: true,
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle quick action with connectivity check
  void _handleQuickAction(
    BuildContext context,
    String actionName, {
    Widget? navigateTo,
  }) {
    final isConnected = ref.read(currentConnectivityProvider);

    if (!isConnected) {
      // Show no internet dialog for critical actions
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.wifi_off,
            size: 48,
            color: Colors.red.shade700,
          ),
          title: const Text('No Internet Connection'),
          content: Text(
            'You need an internet connection to use $actionName. Please check your connection and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(connectivityStateProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
      return;
    }

    // If connected, proceed with action
    if (navigateTo != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => navigateTo),
      );
    } else {
      // Handle other actions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actionName feature coming soon'),
        ),
      );
    }
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    return Expanded(
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            AppLayout.scaleWidth(context, 12),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: AppLayout.scaleHeight(context, 16),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                AppLayout.scaleWidth(context, 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: AppLayout.scaleWidth(context, 10),
                  offset: Offset(0, AppLayout.scaleHeight(context, 2)),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: AppLayout.scaleWidth(context, 24),
                  color: isEnabled ? Colors.grey[700] : Colors.grey[400],
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 8)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 12),
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.black87 : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String label,
    bool isEnabled = true,
  }) {
    return Expanded(
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: InkWell(
          onTap: () {
            if (!isEnabled) {
              ConnectivitySnackBar.showNoInternet(context);
            } else {
              // Handle service action
            }
          },
          borderRadius: BorderRadius.circular(
            AppLayout.scaleWidth(context, 12),
          ),
          child: Container(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                AppLayout.scaleWidth(context, 12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: AppLayout.scaleWidth(context, 10),
                  offset: Offset(0, AppLayout.scaleHeight(context, 2)),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: AppLayout.scaleWidth(context, 24),
                  color: isEnabled ? Colors.grey[700] : Colors.grey[400],
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 6)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 11),
                    fontWeight: FontWeight.w500,
                    color: isEnabled ? Colors.black87 : Colors.grey[400],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String date,
    required String amount,
    required bool isSuccess,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
        vertical: AppLayout.scaleHeight(context, 4),
      ),
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppLayout.scaleWidth(context, 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: AppLayout.scaleWidth(context, 10),
            offset: Offset(0, AppLayout.scaleHeight(context, 2)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 8)),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(
                AppLayout.scaleWidth(context, 8),
              ),
            ),
            child: Icon(
              Icons.arrow_upward,
              color: const Color(0xFF4CAF50),
              size: AppLayout.scaleWidth(context, 16),
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
                    fontSize: AppLayout.fontSize(context, 13),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppLayout.scaleHeight(context, 2)),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 11),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: AppLayout.fontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: AppLayout.scaleHeight(context, 2)),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 8),
                  vertical: AppLayout.scaleHeight(context, 2),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    AppLayout.scaleWidth(context, 8),
                  ),
                ),
                child: Text(
                  'Successful',
                  style: TextStyle(
                    fontSize: AppLayout.fontSize(context, 9),
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}