import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/formatters.dart';
import 'package:kudipay/model/transaction/transaction_model.dart';
import 'package:kudipay/provider/provider.dart';


class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load transactions on screen init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).loadTransactions(refresh: true);
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final transactionState = ref.watch(transactionProvider);
    final groupedTransactions = ref.watch(groupedTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(isTablet),
          Expanded(
            child: _buildBody(
              context,
              transactionState,
              groupedTransactions,
              isTablet,
            ),
          ),
        ],
      ),
     
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Color(0xFFF9F9F9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Transactions',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_outlined, color: Colors.black),
          onPressed: _handleDownload,
        ),
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.black),
          onPressed: () => _showFilterDialog(context),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isTablet) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (query) {
            ref.read(searchQueryProvider.notifier).state = query;
            ref.read(transactionProvider.notifier).searchTransactions(query);
          },
          decoration: const InputDecoration(
            hintText: 'Search.....',
            hintStyle: TextStyle(
              color: Color(0xFFB0BEC5),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Color(0xFFB0BEC5),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TransactionState state,
    Map<String, List<Transaction>> groupedTransactions,
    bool isTablet,
  ) {
    if (state.isLoading && state.transactions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF069494),
        ),
      );
    }

    if (state.error != null && state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading transactions',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(transactionProvider.notifier)
                  .loadTransactions(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF069494),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No transactions found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(transactionProvider.notifier)
            .loadTransactions(refresh: true);
      },
      color: const Color(0xFF069494),
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 24 : 16,
          vertical: 8,
        ),
        children: [
          ..._buildTransactionGroups(groupedTransactions, isTablet),
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF069494),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionGroups(
    Map<String, List<Transaction>> grouped,
    bool isTablet,
  ) {
    List<Widget> widgets = [];

    grouped.forEach((dateHeader, transactions) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            dateHeader,
            style: TextStyle(
              fontSize: isTablet ? 14 : 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      for (var transaction in transactions) {
        widgets.add(_buildTransactionCard(transaction, isTablet));
      }
    });

    return widgets;
  }

  Widget _buildTransactionCard(Transaction transaction, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTransactionIcon(transaction, isTablet),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTransactionDetails(transaction, isTablet),
          ),
          const SizedBox(width: 12),
          _buildAmountAndStatus(transaction, isTablet),
        ],
      ),
    );
  }

  Widget _buildTransactionIcon(Transaction transaction, bool isTablet) {
    final isDebit = transaction.type == TransactionType.debit;
    return Container(
      width: isTablet ? 44 : 40,
      height: isTablet ? 44 : 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isDebit ? Icons.arrow_upward : Icons.arrow_downward,
        color: const Color(0xFF069494),
        size: 20,
      ),
    );
  }

  Widget _buildTransactionDetails(Transaction transaction, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          transaction.description,
          style: TextStyle(
            fontSize: isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          TransactionFormatter.formatDateTime(transaction.date),
          style: TextStyle(
            fontSize: isTablet ? 13 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountAndStatus(Transaction transaction, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          transaction.type == TransactionType.debit
              ? '-₦${TransactionFormatter.formatAmount(transaction.amount)}'
              : '+₦${TransactionFormatter.formatAmount(transaction.amount)}',
          style: TextStyle(
            fontSize: isTablet ? 16 : 15,
            fontWeight: FontWeight.w600,
            color: transaction.type == TransactionType.debit
                ? Colors.black87
                : const Color(0xFF069494),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(transaction.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            transaction.status.value,
            style: TextStyle(
              fontSize: isTablet ? 11 : 10,
              color: _getStatusColor(transaction.status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.successful:
        return const Color(0xFF069494);
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.pending:
        return Colors.orange;
    }
  }

  Future<void> _handleDownload() async {
    final url = await ref.read(transactionProvider.notifier).downloadTransactions();
    if (url != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download started')),
      );
      // Open URL or download file
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed')),
      );
    }
  }

  void _showFilterDialog(BuildContext context) {
    final currentFilter = ref.read(transactionFilterProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Transactions'),
              leading: Radio<TransactionStatus?>(
                value: null,
                groupValue: currentFilter.status,
                onChanged: (val) {
                  ref.read(transactionFilterProvider.notifier).state =
                      currentFilter.copyWith(clearStatus: true);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Successful'),
              leading: Radio<TransactionStatus?>(
                value: TransactionStatus.successful,
                groupValue: currentFilter.status,
                onChanged: (val) {
                  ref.read(transactionFilterProvider.notifier).state =
                      currentFilter.copyWith(status: val);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Failed'),
              leading: Radio<TransactionStatus?>(
                value: TransactionStatus.failed,
                groupValue: currentFilter.status,
                onChanged: (val) {
                  ref.read(transactionFilterProvider.notifier).state =
                      currentFilter.copyWith(status: val);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Pending'),
              leading: Radio<TransactionStatus?>(
                value: TransactionStatus.pending,
                groupValue: currentFilter.status,
                onChanged: (val) {
                  ref.read(transactionFilterProvider.notifier).state =
                      currentFilter.copyWith(status: val);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

}