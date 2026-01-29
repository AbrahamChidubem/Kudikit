import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';
import 'package:kudipay/model/bankmodel/bank_model.dart';
import 'package:kudipay/provider/provider.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banksState = ref.watch(banksProvider);
    final searchQuery = ref.watch(bankSearchQueryProvider);

    // Filter banks based on search
    final filteredBanks = searchQuery.isEmpty
        ? banksState.banks
        : ref.read(banksProvider.notifier).searchBanks(searchQuery);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
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
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
      );
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
    return Center(
      child: Padding(
        padding: AppLayout.pagePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: AppLayout.scaleWidth(context, 64),
              color: Colors.red[300],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              error.message,
              style: TextStyle(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (error.isRetryable) ...[
              SizedBox(height: AppLayout.scaleHeight(context, 24)),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(banksProvider.notifier).loadBanks();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
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
        return const Color(0xFF4CAF50);
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