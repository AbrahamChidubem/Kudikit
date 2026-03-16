import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/formatting/widget/shimmer_widget.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
// import 'package:kudipay/provider/funding/funding_provider.dart';
import 'package:kudipay/provider/add_money_provider.dart';

class SelectBankScreen extends ConsumerStatefulWidget {
  const SelectBankScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SelectBankScreen> createState() => _SelectBankScreenState();
}

class _SelectBankScreenState extends ConsumerState<SelectBankScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(banksProvider.notifier).loadBanks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Clear search state so stale query doesn't persist when returning to this screen
    ref.read(bankSearchQueryProvider.notifier).state = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banksState = ref.watch(banksProvider);
    final searchQuery = ref.watch(bankSearchQueryProvider);

    // Pure computation off watched state — reacts correctly when either
    // the bank list or the query changes. Previously used ref.read(notifier)
    // which would not recompute when banks updated while search was active.
    final filteredBanks = searchQuery.isEmpty
        ? banksState.banks
        : banksState.banks
            .where((b) =>
                b.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: _buildBody(context, banksState, filteredBanks),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Select Bank',
        style: TextStyle(
          color: Colors.black,
          fontSize: AppLayout.fontSize(context, 18),
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(
    BuildContext context,
    BanksState banksState,
    List<Bank> filteredBanks,
  ) {
    return Column(
      children: [
        // Search Bar
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 12),
          ),
          child: _buildSearchBar(context),
        ),

        SizedBox(height: AppLayout.scaleHeight(context, 16)),

        // Banks Grid
        Expanded(
          child: _buildBanksList(context, banksState, filteredBanks),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final searchQuery = ref.watch(bankSearchQueryProvider);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 25)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          ref.read(bankSearchQueryProvider.notifier).state = query;
        },
        decoration: InputDecoration(
          hintText: 'Search bank',
          hintStyle: TextStyle(
            color: const Color(0xFFB0BEC5),
            fontSize: AppLayout.fontSize(context, 14),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: const Color(0xFFB0BEC5),
            size: AppLayout.scaleWidth(context, 20),
          ),
          // Fix 4: clear button — only shows when there is text
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey[500],
                    size: AppLayout.scaleWidth(context, 18),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(bankSearchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppLayout.scaleWidth(context, 16),
            vertical: AppLayout.scaleHeight(context, 12),
          ),
        ),
      ),
    );
  }

  Widget _buildBanksList(
    BuildContext context,
    BanksState banksState,
    List<Bank> filteredBanks,
  ) {
    if (banksState.isLoading && banksState.banks.isEmpty) {
      return const BankListShimmer();
    }

    if (banksState.error != null && banksState.banks.isEmpty) {
      return _buildErrorView(context, banksState.error!);
    }

    if (filteredBanks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: AppLayout.scaleWidth(context, 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              'No banks found',
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: AppLayout.scaleWidth(context, 16),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppLayout.scaleWidth(context, 16),
        mainAxisSpacing: AppLayout.scaleHeight(context, 16),
      ),
      itemCount: filteredBanks.length,
      itemBuilder: (context, index) {
        final bank = filteredBanks[index];
        return _buildBankItem(context, bank);
      },
    );
  }

  Widget _buildBankItem(BuildContext context, Bank bank) {
    return InkWell(
      onTap: () {
        ref.read(selectedBankProvider.notifier).state = bank;
        Navigator.pop(context, bank);
      },
      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: AppLayout.scaleWidth(context, 60),
            height: AppLayout.scaleWidth(context, 60),
            decoration: BoxDecoration(
              color: _getBankColor(bank.logo),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getBankInitials(bank.name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Text(
            bank.name,
            style: TextStyle(
              fontSize: AppLayout.fontSize(context, 12),
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, AddMoneyError error) {
    // Pick icon and title based on the classified error type
    final IconData icon;
    final String title;
    switch (error.type) {
      case AddMoneyErrorType.network:
        icon = Icons.wifi_off_rounded;
        title = 'No internet connection';
        break;
      case AddMoneyErrorType.timeout:
        icon = Icons.timer_off_rounded;
        title = 'Request timed out';
        break;
      case AddMoneyErrorType.authentication:
        icon = Icons.lock_outline_rounded;
        title = 'Session expired';
        break;
      default:
        icon = Icons.cloud_off_rounded;
        title = 'Unable to load banks';
    }

    return Center(
      child: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppLayout.scaleWidth(context, 64),
              color: Colors.grey[400],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              title,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 8)),
            Text(
              error.message,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 14),
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (error.isRetryable) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(banksProvider.notifier).loadBanks();
                },
                icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                label: const Text(
                  'Try Again',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF069494),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        AppLayout.scaleWidth(context, 32)),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 32),
                    vertical: AppLayout.scaleHeight(context, 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBankColor(String logo) {
    switch (logo.toLowerCase()) {
      case 'gtbank':
        return const Color(0xFFFF6600);
      case 'firstbank':
        return const Color(0xFF002244);
      case 'wema':
        return const Color(0xFF722C7A);
      case 'uba':
        return const Color(0xFFD32F2F);
      case 'fcmb':
        return const Color(0xFF7B1FA2);
      case 'sterling':
        return const Color(0xFFD32F2F);
      case 'parallex':
        return const Color(0xFF1E3A8A);
      case 'globus':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF069494);
    }
  }

  String _getBankInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }
}