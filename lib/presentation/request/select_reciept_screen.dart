import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kudipay/presentation/request/preview_request_screen.dart';
import 'package:kudipay/provider/request/request_provider.dart';
import 'package:provider/provider.dart';

import '../../model/request/request_model.dart';


class SelectRecipientsScreen extends StatefulWidget {
  const SelectRecipientsScreen({super.key});

  @override
  State<SelectRecipientsScreen> createState() => _SelectRecipientsScreenState();
}

class _SelectRecipientsScreenState extends State<SelectRecipientsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _phoneController.text = '+234';
    
    // Load mock data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequestProvider>(context, listen: false).loadMockData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  List<Contact> _filterContacts(List<Contact> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    return contacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contact.phone.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        final selectedCount = provider.selectedContacts.length;
        
        return Scaffold(
          backgroundColor: const Color(0xFFE8F5E9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFE8F5E9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Request Money',
              style: GoogleFonts.openSans(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search.....',
                    hintStyle: GoogleFonts.openSans(
                      color: Colors.grey[400],
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              // Selected contacts chips
              if (selectedCount > 0)
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.selectedContacts.length,
                    itemBuilder: (context, index) {
                      final contact = provider.selectedContacts[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(
                            contact.name.split(' ')[0],
                            style: GoogleFonts.openSans(fontSize: 13),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            provider.toggleContactSelection(contact);
                          },
                          backgroundColor: const Color(0xFFE8F5E9),
                          deleteIconColor: const Color(0xFF2E7D32),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2E7D32),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF2E7D32),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Contact'),
                    Tab(text: 'Recent'),
                    Tab(text: 'Phone No.'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All Contacts
                      _buildContactsList(
                        _filterContacts(provider.allContacts),
                        provider,
                      ),
                      // Recent Contacts
                      _buildContactsList(
                        _filterContacts(provider.recentContacts),
                        provider,
                      ),
                      // Phone Number
                      _buildPhoneNumberTab(provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: selectedCount > 0
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PreviewRequestScreen(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  selectedCount > 0
                      ? 'Continue with $selectedCount Recipient${selectedCount > 1 ? 's' : ''}'
                      : 'Continue',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactsList(List<Contact> contacts, RequestProvider provider) {
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No contacts found',
              style: GoogleFonts.openSans(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isSelected = provider.selectedContacts.any((c) => c.id == contact.id);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getAvatarColor(index),
            child: Text(
              contact.initials,
              style: GoogleFonts.openSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                contact.name,
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              if (contact.isVerified)
                const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 16),
            ],
          ),
          subtitle: Text(
            contact.phone,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          trailing: contact.isInvited
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Invite',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: (value) {
                    provider.toggleContactSelection(contact);
                  },
                  activeColor: const Color(0xFF2E7D32),
                ),
          onTap: () {
            provider.toggleContactSelection(contact);
          },
        );
      },
    );
  }

  Widget _buildPhoneNumberTab(RequestProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter phone no.',
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.openSans(fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Add recipient logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('If they\'re not on Kudikil, they\'ll receive an SMS invitation'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8F5E9),
                foregroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add Recipient',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If they\'re not on Kudikil, they\'ll receive an SMS invitation',
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(int index) {
    final colors = [
      const Color(0xFF4CAF50),
      Colors.black,
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
      const Color(0xFFFFA726),
    ];
    return colors[index % colors.length];
  }
}