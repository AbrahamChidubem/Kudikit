import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';
import 'package:kudipay/mock/mock_api_data.dart';
import '../../model/request/request_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestProvider extends ChangeNotifier {
  // Current request being created
  double? _amount;
  String? _reason;
  String _category = 'Entertainment';
  String? _note;
  DateTime? _dueDate;
  bool _isPrivate = true;
  List<Contact> _selectedContacts = [];
  DeliveryMethod _deliveryMethod = DeliveryMethod.inAppNotification;

  // All requests
  final List<MoneyRequest> _sentRequests = [];
  final List<MoneyRequest> _receivedRequests = [];

  // Loading state — drives shimmer in MyRequestsScreen
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Contacts
  final List<Contact> _recentContacts = [];
  final List<Contact> _allContacts = [];

  // Getters
  double? get amount => _amount;
  String? get reason => _reason;
  String get category => _category;
  String? get note => _note;
  DateTime? get dueDate => _dueDate;
  bool get isPrivate => _isPrivate;
  List<Contact> get selectedContacts => _selectedContacts;
  DeliveryMethod get deliveryMethod => _deliveryMethod;
  List<MoneyRequest> get sentRequests => _sentRequests;
  List<MoneyRequest> get receivedRequests => _receivedRequests;
  List<Contact> get recentContacts => _recentContacts;
  List<Contact> get allContacts => _allContacts;

  // Setters
  void setAmount(double? value) {
    _amount = value;
    notifyListeners();
  }

  void setReason(String? value) {
    _reason = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setNote(String? value) {
    _note = value;
    notifyListeners();
  }

  void setDueDate(DateTime? value) {
    _dueDate = value;
    notifyListeners();
  }

  void setPrivacy(bool value) {
    _isPrivate = value;
    notifyListeners();
  }

  void setDeliveryMethod(DeliveryMethod value) {
    _deliveryMethod = value;
    notifyListeners();
  }

  void toggleContactSelection(Contact contact) {
    if (_selectedContacts.any((c) => c.id == contact.id)) {
      _selectedContacts.removeWhere((c) => c.id == contact.id);
    } else {
      _selectedContacts.add(contact);
    }
    notifyListeners();
  }

  void addContact(Contact contact) {
    if (!_selectedContacts.any((c) => c.id == contact.id)) {
      _selectedContacts.add(contact);
      notifyListeners();
    }
  }

  void removeContact(Contact contact) {
    _selectedContacts.removeWhere((c) => c.id == contact.id);
    notifyListeners();
  }

  void clearSelectedContacts() {
    _selectedContacts.clear();
    notifyListeners();
  }

  bool get canContinue {
    return _amount != null && _amount! > 0 && _selectedContacts.isNotEmpty;
  }

  // Request actions
  MoneyRequest createRequest() {
    if (!canContinue) {
      throw Exception('Cannot create request with incomplete data');
    }

    final request = MoneyRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      requesterId: 'current_user_id',
      requesterName: 'Current User',
      requesterPhone: '+2348012345678',
      amount: _amount!,
      reason: _reason,
      category: _category,
      description: _note,
      createdAt: DateTime.now(),
      dueDate: _dueDate,
      isPrivate: _isPrivate,
      recipientIds: _selectedContacts.map((c) => c.id).toList(),
      deliveryMethod: _deliveryMethod,
    );

    _sentRequests.add(request);
    resetForm();
    notifyListeners();
    return request;
  }

  void resetForm() {
    _amount = null;
    _reason = null;
    _category = 'Entertainment';
    _note = null;
    _dueDate = null;
    _isPrivate = true;
    _selectedContacts.clear();
    _deliveryMethod = DeliveryMethod.inAppNotification;
    notifyListeners();
  }

  // ✅ Fixed: contacts use distinct realistic phone numbers.
  // Received/sent requests now sourced from MockRequestData so they stay in
  // sync with the centralised mock API file.
  // isLoading set during fetch so UI can show RequestListShimmer.
  Future<void> loadMockData() async {
    if (_isLoading) return; // prevent double-load
    _isLoading = true;
    notifyListeners();

    // Simulate network latency — remove when wired to real API
    await Future.delayed(const Duration(milliseconds: 800));

    // ── Contacts ─────────────────────────────────────────────────────────────
    _allContacts.addAll([
      const Contact(
        id: '1',
        name: 'Kemi Alabi',
        phone: '+2348031234567',
        status: ContactStatus.onApp,
        avatarColor: AppColors.avatarTeal,
        isVerified: true,
      ),
      const Contact(
        id: '2',
        name: 'Asuquo Michael',
        phone: '+2348051234567',
        status: ContactStatus.onApp,
        avatarColor: AppColors.avatarDark,
        isVerified: true,
      ),
      const Contact(
        id: '3',
        name: 'Victor Obisi',
        phone: '+2348061234567',
        status: ContactStatus.onApp,
        avatarColor: AppColors.avatarOrange,
        isVerified: true,
      ),
      const Contact(
        id: '4',
        name: 'Tega Ibrahim',
        phone: '+2348071234567',
        status: ContactStatus.onApp,
        avatarColor: AppColors.avatarRed,
        isVerified: true,
      ),
      const Contact(
        id: '5',
        name: 'Ameachi Uche',
        phone: '+2348091234567',
        status: ContactStatus.invite,
        avatarColor: AppColors.avatarBlue,
        isInvited: true,
        isVerified: false,
      ),
      const Contact(
        id: '6',
        name: 'Paul Adegoke',
        phone: '+2349011234567',
        status: ContactStatus.invite,
        avatarColor: AppColors.avatarLightBlue,
        isInvited: true,
        isVerified: false,
      ),
    ]);

    _recentContacts.addAll([
      _allContacts[0],
      _allContacts[1],
      _allContacts[2],
    ]);

    // ── Requests — sourced from MockRequestData ───────────────────────────────
    // REQ_001 in the mock is a pending request (received by current user).
    // REQ_002 in the mock is a paid/sent request.
    final raw = MockRequestData.requestListResponse['requests'] as List<dynamic>;
    for (final item in raw) {
      final map = item as Map<String, dynamic>;
      final request = MoneyRequest.fromJson(map);

      // REQ_001 — pending incoming request → received list
      // REQ_002 — paid request → sent list (mirrors a sent + paid scenario)
      if (request.id == 'REQ_001') {
        _receivedRequests.add(request);
      } else {
        _sentRequests.add(request);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get statistics
  double get totalToReceive {
    return _receivedRequests
        .where((r) => r.status == RequestStatus.pending)
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  double get totalWaitingOn {
    return _sentRequests
        .where((r) =>
            r.status == RequestStatus.pending ||
            r.status == RequestStatus.partial)
        .fold(0.0, (sum, r) => sum + r.remainingAmount);
  }

  List<MoneyRequest> getReceivedByStatus(RequestStatus status) {
    return _receivedRequests.where((r) => r.status == status).toList();
  }

  List<MoneyRequest> getSentByStatus(RequestStatus status) {
    return _sentRequests.where((r) => r.status == status).toList();
  }

  // Pay request
  Future<void> payRequest(MoneyRequest request, double amount) async {
    final index = _receivedRequests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      final updatedRequest = request.copyWith(
        paidAmount: (request.paidAmount ?? 0) + amount,
        status: (request.paidAmount ?? 0) + amount >= request.amount
            ? RequestStatus.paid
            : RequestStatus.partial,
        paidAt: DateTime.now(),
      );
      _receivedRequests[index] = updatedRequest;
      notifyListeners();
    }
  }

  // Decline request
  Future<void> declineRequest(MoneyRequest request) async {
    final index = _receivedRequests.indexWhere((r) => r.id == request.id);
    if (index != -1) {
      _receivedRequests[index] =
          request.copyWith(status: RequestStatus.declined);
      notifyListeners();
    }
  }
}

// Riverpod Provider
final requestProvider = ChangeNotifierProvider<RequestProvider>((ref) {
  return RequestProvider();
});