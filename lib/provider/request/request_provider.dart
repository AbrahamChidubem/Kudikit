import 'package:flutter/material.dart';
import '../../model/request/request_model.dart';

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
      requesterId: 'current_user_id', // Replace with actual user ID
      requesterName: 'Current User', // Replace with actual user name
      requesterPhone: '+234 8124608695', // Replace with actual phone
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

  // Load mock data
  void loadMockData() {
    _allContacts.addAll([
      Contact(
        id: '1',
        name: 'Kemi Alabi',
        phone: '+234 8124608695',
        isVerified: true,
      ),
      Contact(
        id: '2',
        name: 'Asuquo Michael',
        phone: '+234 8124608695',
        isVerified: true,
      ),
      Contact(
        id: '3',
        name: 'Victor Obisi',
        phone: '+234 8124608695',
        isVerified: true,
      ),
      Contact(
        id: '4',
        name: 'Tega Ibrahim',
        phone: '+234 8124608695',
        isVerified: true,
      ),
      Contact(
        id: '5',
        name: 'Ameachi Uche',
        phone: '+234 8124608695',
        isInvited: true,
        isVerified: false,
      ),
      Contact(
        id: '6',
        name: 'Paul Adegoke',
        phone: '+234 8124608695',
        isInvited: true,
        isVerified: false,
      ),
    ]);

    _recentContacts.addAll([
      _allContacts[0],
      _allContacts[1],
      _allContacts[2],
    ]);

    // Mock received requests
    _receivedRequests.add(
      MoneyRequest(
        id: '1',
        requesterId: '2',
        requesterName: 'Kemi Alabi',
        requesterPhone: '+234 8124608695',
        amount: 10000.00,
        category: 'Transportation',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: RequestStatus.pending,
        recipientIds: ['current_user'],
      ),
    );

    _receivedRequests.add(
      MoneyRequest(
        id: '2',
        requesterId: '3',
        requesterName: 'Tega Ibrahim',
        requesterPhone: '+234 8124608695',
        amount: 10000.00,
        category: 'Dinner',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: RequestStatus.partial,
        paidAmount: 5000.00,
        recipientIds: ['current_user'],
      ),
    );

    _receivedRequests.add(
      MoneyRequest(
        id: '3',
        requesterId: '4',
        requesterName: 'Victor Obisi',
        requesterPhone: '+234 8124608695',
        amount: 10000.00,
        category: 'Other',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: RequestStatus.expired,
        recipientIds: ['current_user'],
      ),
    );

    // Mock sent request
    _sentRequests.add(
      MoneyRequest(
        id: '4',
        requesterId: 'current_user',
        requesterName: 'Asuquo Michael',
        requesterPhone: '+234 8124608695',
        amount: 10000.00,
        reason: 'Dinner',
        category: 'Transportation',
        description: 'Group dinner at Ocean Basket',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        status: RequestStatus.pending,
        isPrivate: true,
        recipientIds: ['2'],
      ),
    );

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
        .where((r) => r.status == RequestStatus.pending || r.status == RequestStatus.partial)
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
      _receivedRequests[index] = request.copyWith(status: RequestStatus.declined);
      notifyListeners();
    }
  }
}