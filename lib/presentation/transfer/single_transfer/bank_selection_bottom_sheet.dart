import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/core/utils/responsive.dart';

class Bank {
  final String name;
  final String code;
  final String? logo;

  const Bank({
    required this.name,
    required this.code,
    this.logo,
  });
}

class BankSelectionBottomSheet extends ConsumerStatefulWidget {
  final Function(Bank) onBankSelected;

  const BankSelectionBottomSheet({
    Key? key,
    required this.onBankSelected,
  }) : super(key: key);

  static void show(BuildContext context, {required Function(Bank) onBankSelected}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BankSelectionBottomSheet(onBankSelected: onBankSelected),
    );
  }

  @override
  ConsumerState<BankSelectionBottomSheet> createState() =>
      _BankSelectionBottomSheetState();
}

class _BankSelectionBottomSheetState
    extends ConsumerState<BankSelectionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Bank> _filteredBanks = [];

  final List<Bank> _banks = const [
    Bank(name: 'Access Bank', code: '044'),
    Bank(name: 'Citibank', code: '023'),
    Bank(name: 'Diamond Bank', code: '063'),
    Bank(name: 'Ecobank Nigeria', code: '050'),
    Bank(name: 'Fidelity Bank', code: '070'),
    Bank(name: 'First Bank of Nigeria', code: '011'),
    Bank(name: 'First City Monument Bank', code: '214'),
    Bank(name: 'Guaranty Trust Bank', code: '058'),
    Bank(name: 'Heritage Bank', code: '030'),
    Bank(name: 'Keystone Bank', code: '082'),
    Bank(name: 'Polaris Bank', code: '076'),
    Bank(name: 'Providus Bank', code: '101'),
    Bank(name: 'Stanbic IBTC Bank', code: '221'),
    Bank(name: 'Standard Chartered Bank', code: '068'),
    Bank(name: 'Sterling Bank', code: '232'),
    Bank(name: 'Union Bank of Nigeria', code: '032'),
    Bank(name: 'United Bank for Africa', code: '033'),
    Bank(name: 'Unity Bank', code: '215'),
    Bank(name: 'Wema Bank', code: '035'),
    Bank(name: 'Zenith Bank', code: '057'),
  ];

  @override
  void initState() {
    super.initState();
    _filteredBanks = _banks;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBanks(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredBanks = _banks;
      } else {
        _filteredBanks = _banks
            .where((bank) =>
                bank.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Bank',
                    style: TextStyle(
                      fontSize: AppLayout.fontSize(context, 18),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.scaleWidth(context, 20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterBanks,
                decoration: InputDecoration(
                  hintText: 'Search bank',
                  hintStyle: TextStyle(
                    color: Colors.black38,
                    fontSize: AppLayout.fontSize(context, 14),
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF069494),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ),

            SizedBox(height: AppLayout.scaleHeight(context, 16)),

            // Bank list
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 20),
                ),
                itemCount: _filteredBanks.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[200],
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final bank = _filteredBanks[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      vertical: AppLayout.scaleHeight(context, 8),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFF6B35),
                      radius: AppLayout.scaleWidth(context, 20),
                      child: Text(
                        bank.name[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppLayout.fontSize(context, 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(
                      bank.name,
                      style: TextStyle(
                        fontSize: AppLayout.fontSize(context, 15),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black26,
                    ),
                    onTap: () {
                      widget.onBankSelected(bank);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}