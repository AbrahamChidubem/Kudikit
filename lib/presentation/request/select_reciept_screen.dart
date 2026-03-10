import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kudipay/core/utils/responsive.dart';
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
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF9F9F9),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, 
                color: Colors.black,
                size: AppLayout.scaleWidth(context, 24),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Request Money',
              style: GoogleFonts.openSans(
                color: Colors.black,
                fontSize: AppLayout.fontSize(context, 18),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
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
                      fontSize: AppLayout.fontSize(context, 14),
                    ),
                    prefixIcon: Icon(Icons.search, 
                      color: Colors.grey[400],
                      size: AppLayout.scaleWidth(context, 20),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppLayout.scaleWidth(context, 16),
                      vertical: AppLayout.scaleHeight(context, 14),
                    ),
                  ),
                ),
              ),

              // Selected contacts chips
              if (selectedCount > 0)
                Container(
                  height: AppLayout.scaleHeight(context, 50),
                  margin: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 16),
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: provider.selectedContacts.length,
                    itemBuilder: (context, index) {
                      final contact = provider.selectedContacts[index];
                      return Container(
                        margin: EdgeInsets.only(
                          right: AppLayout.scaleWidth(context, 8),
                        ),
                        child: Chip(
                          label: Text(
                            contact.name.split(' ')[0],
                            style: GoogleFonts.openSans(
                              fontSize: AppLayout.fontSize(context, 13),
                            ),
                          ),
                          deleteIcon: Icon(Icons.close, 
                            size: AppLayout.scaleWidth(context, 18),
                          ),
                          onDeleted: () {
                            provider.toggleContactSelection(contact);
                          },
                          backgroundColor: const Color(0xFFE8F5E9),
                          deleteIconColor: const Color(0xFF069494),
                        ),
                      );
                    },
                  ),
                ),

              SizedBox(height: AppLayout.scaleHeight(context, 8)),

              // Tabs
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppLayout.scaleWidth(context, 16),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF069494),
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: const Color(0xFF069494),
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.openSans(
                    fontSize: AppLayout.fontSize(context, 14),
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
                  margin: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 16)),
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
            padding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: AppLayout.scaleWidth(context, 10),
                  offset: Offset(0, -AppLayout.scaleHeight(context, 4)),
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
                  backgroundColor: const Color(0xFF069494),
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: AppLayout.scaleHeight(context, 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  selectedCount > 0
                      ? 'Continue with $selectedCount Recipient${selectedCount > 1 ? 's' : ''}'
                      : 'Continue',
                  style: GoogleFonts.openSans(
                    fontSize: AppLayout.fontSize(context, 16),
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
            Icon(Icons.person_outline, 
              size: AppLayout.scaleWidth(context, 64), 
              color: Colors.grey[300],
            ),
            SizedBox(height: AppLayout.scaleHeight(context, 16)),
            Text(
              'No contacts found',
              style: GoogleFonts.openSans(
                fontSize: AppLayout.fontSize(context, 16),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: AppLayout.scaleHeight(context, 8),
      ),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isSelected = provider.selectedContacts.any((c) => c.id == contact.id);

        return ListTile(
          leading: CircleAvatar(
            radius: AppLayout.scaleWidth(context, 20),
            backgroundColor: _getAvatarColor(index),
            child: Text(
              contact.initials,
              style: GoogleFonts.openSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: AppLayout.fontSize(context, 14),
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                contact.name,
                style: GoogleFonts.openSans(
                  fontSize: AppLayout.fontSize(context, 15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: AppLayout.scaleWidth(context, 4)),
              if (contact.isVerified)
                Icon(Icons.check_circle, 
                  color: const Color(0xFF069494), 
                  size: AppLayout.scaleWidth(context, 16),
                ),
            ],
          ),
          subtitle: Text(
            contact.phone,
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.grey[600],
            ),
          ),
          trailing: contact.isInvited
              ? Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppLayout.scaleWidth(context, 12), 
                    vertical: AppLayout.scaleHeight(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                  ),
                  child: Text(
                    'Invite',
                    style: GoogleFonts.openSans(
                      fontSize: AppLayout.fontSize(context, 12),
                      color: const Color(0xFF069494),
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
                  activeColor: const Color(0xFF069494),
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
      padding: EdgeInsets.all(AppLayout.scaleWidth(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter phone no.',
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 13),
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 16),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(AppLayout.scaleWidth(context, 16)),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 16)),
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
                foregroundColor: const Color(0xFF069494),
                padding: EdgeInsets.symmetric(
                  vertical: AppLayout.scaleHeight(context, 16),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppLayout.scaleWidth(context, 12)),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add Recipient',
                style: GoogleFonts.openSans(
                  fontSize: AppLayout.fontSize(context, 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: AppLayout.scaleHeight(context, 8)),
          Text(
            'If they\'re not on Kudikil, they\'ll receive an SMS invitation',
            style: GoogleFonts.openSans(
              fontSize: AppLayout.fontSize(context, 12),
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
      const Color(0xFF069494),
      Colors.black,
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
      const Color(0xFFE91E63),
      const Color(0xFFFFA726),
    ];
    return colors[index % colors.length];
  }
}