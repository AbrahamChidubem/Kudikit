// ============================================================================
// lib/services/contact_service.dart
//
// Handles everything related to device contacts for the airtime/data flows:
//   • Runtime permission requesting (Android + iOS)
//   • Fetching contacts from the device phonebook
//   • Filtering to ONLY Nigerian mobile numbers (NCC-assigned prefixes)
//   • Normalizing all number formats to local 0xxx format
//   • Running NCC prefix detection on each valid number
//   • Processing on a background isolate to keep UI smooth
//
// Dependencies: flutter_contacts, permission_handler
// ============================================================================

import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:kudipay/model/bill/bill_model.dart';
import 'package:permission_handler/permission_handler.dart';

// ============================================================================
// NigerianContact
// A processed contact ready to display in the picker.
// ============================================================================

class NigerianContact {
  /// Display name from the phonebook (e.g. "Chioma Eze")
  final String displayName;

  /// First letter of display name — used for alphabet index
  final String indexLetter;

  /// All Nigerian-valid phone numbers this contact has.
  /// Most contacts will have exactly 1, some will have 2.
  final List<NigerianPhoneNumber> nigerianNumbers;

  const NigerianContact({
    required this.displayName,
    required this.indexLetter,
    required this.nigerianNumbers,
  });
}

class NigerianPhoneNumber {
  /// Normalized local format: always "0XXXXXXXXXX" (11 digits)
  final String normalizedNumber;

  /// Pretty-printed for display: "0803 456 0109"
  final String displayNumber;

  /// Auto-detected network (null if unrecognized prefix — shouldn't happen
  /// since we only keep numbers whose prefix matches the NCC list)
  final NetworkProvider? network;

  /// Label from phonebook: "mobile", "home", "work", etc.
  final String label;

  const NigerianPhoneNumber({
    required this.normalizedNumber,
    required this.displayNumber,
    required this.network,
    required this.label,
  });
}

// ============================================================================
// ContactPermissionStatus
// ============================================================================

enum ContactPermissionStatus {
  granted,
  denied, // Denied but can still request again
  permanentlyDenied, // Must open Settings
  restricted, // iOS parental controls / MDM
}

// ============================================================================
// ContactService
// Singleton — no need to instantiate multiple times.
// ============================================================================

class ContactService {
  ContactService._();
  static final instance = ContactService._();

  // ── Permission ────────────────────────────────────────────────────────────

  /// Returns the current contacts permission status without requesting it.
  Future<ContactPermissionStatus> checkPermission() async {
    final status = await Permission.contacts.status;
    return _mapStatus(status);
  }

  /// Requests contacts permission if not already granted.
  /// Returns the resulting status after the request dialog.
  Future<ContactPermissionStatus> requestPermission() async {
    final current = await Permission.contacts.status;

    if (current.isGranted) return ContactPermissionStatus.granted;

    // isPermanentlyDenied = user hit "Never ask again" (Android)
    //                     OR denied twice on iOS
    if (current.isPermanentlyDenied || current.isRestricted) {
      return current.isRestricted
          ? ContactPermissionStatus.restricted
          : ContactPermissionStatus.permanentlyDenied;
    }

    // Ask the OS to show the permission dialog
    final result = await Permission.contacts.request();
    return _mapStatus(result);
  }

  /// Opens the device app settings page so the user can manually
  /// grant contacts permission after permanently denying it.
  Future<void> openSettings() => openAppSettings();

  ContactPermissionStatus _mapStatus(PermissionStatus status) {
    if (status.isGranted) return ContactPermissionStatus.granted;
    if (status.isPermanentlyDenied)
      return ContactPermissionStatus.permanentlyDenied;
    if (status.isRestricted) return ContactPermissionStatus.restricted;
    return ContactPermissionStatus.denied;
  }

  // ── Contact Fetching + Filtering ──────────────────────────────────────────

  /// Fetches all device contacts, filters to Nigerian numbers only,
  /// and returns them sorted alphabetically.
  ///
  /// Runs the heavy filtering work on a background isolate so the
  /// UI thread stays completely smooth even with 1,500+ contacts.
  ///
  /// Only call this after permission has been granted.
  Future<List<NigerianContact>> getNigerianContacts() async {
    // Fetch raw contacts from device (name + phones only — no photos,
    // notes, etc. — keeps memory lean and fetch fast)
    final rawContacts = await FlutterContacts.getContacts(
      withProperties: true, // includes phone numbers
      withPhoto: false,
      withThumbnail: false,
      withGroups: false,
      withAccounts: false,
      deduplicateProperties: true,
    );

    // Hand off to background isolate — returns List<NigerianContact>
    final result = await compute(_processContacts, rawContacts);
    return result;
  }

  // ── Background Isolate Worker ─────────────────────────────────────────────
  // This is a top-level (static) function — required by compute().
  // It runs entirely off the main thread.

  static List<NigerianContact> _processContacts(List<Contact> rawContacts) {
    final List<NigerianContact> result = [];

    for (final contact in rawContacts) {
      // Skip contacts with no name and no numbers
      if (contact.phones.isEmpty) continue;

      final String displayName = _buildDisplayName(contact);
      if (displayName.isEmpty) continue;

      // Process each phone number on this contact
      final List<NigerianPhoneNumber> validNumbers = [];

      for (final phone in contact.phones) {
        final processed = _processPhoneNumber(phone);
        if (processed != null) {
          validNumbers.add(processed);
        }
      }

      // Only include this contact if they have ≥1 valid Nigerian number
      if (validNumbers.isEmpty) continue;

      // Deduplicate numbers (same normalized number from multiple sources)
      final deduped = _deduplicateNumbers(validNumbers);

      result.add(NigerianContact(
        displayName: displayName,
        indexLetter: _indexLetter(displayName),
        nigerianNumbers: deduped,
      ));
    }

    // Sort alphabetically by display name (case-insensitive)
    result.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    return result;
  }

  // ── Number Processing ─────────────────────────────────────────────────────

  static NigerianPhoneNumber? _processPhoneNumber(Phone phone) {
    final raw = phone.number;
    if (raw.isEmpty) return null;

    // Step 1: Strip all non-digit characters
    // Removes: spaces, dashes, parentheses, dots, +
    String digits = raw.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) return null;

    // Step 2: Handle Excel import artifact (numbers saved as "08031234567.0")
    // The replaceAll above already strips the dot; handle trailing zeros
    // that were decimal places — but only if the result has too many digits
    if (digits.length > 13) {
      // Truncate to 13 max (longest valid: 234 + 10 digit subscriber)
      digits = digits.substring(0, 13);
    }

    // Step 3: Normalize to local 0xxx format
    String normalized;

    if (digits.startsWith('234') && digits.length >= 13) {
      // +234XXXXXXXXXX → 0XXXXXXXXXX
      normalized = '0${digits.substring(3)}';
    } else if (digits.startsWith('0') && digits.length == 11) {
      // Already in local format
      normalized = digits;
    } else if (digits.startsWith('0') && digits.length == 10) {
      // Saved without leading zero properly — very rare but handle
      normalized = '0$digits';
      if (normalized.length != 11) return null;
    } else if (digits.length == 10 && !digits.startsWith('0')) {
      // Saved as 8031234567 (missing leading 0) — seen with some imports
      normalized = '0$digits';
    } else {
      // Doesn't match any known Nigerian format
      return null;
    }

    // Step 4: Must be exactly 11 digits after normalization
    if (normalized.length != 11) return null;

    // Step 5: Must start with '0' (local format)
    if (!normalized.startsWith('0')) return null;

    // Step 6: Run NCC prefix detection
    // This uses the same prefix table as BillsService.detectNetwork()
    final network = _detectNetworkLocal(normalized);

    // Only Nigerian MOBILE numbers pass — landlines (01x, 02x) won't match
    // any mobile prefix and will return null here
    if (network == null) return null;

    // Step 7: Format for display: "0803 456 0109"
    final display = '${normalized.substring(0, 4)} '
        '${normalized.substring(4, 7)} '
        '${normalized.substring(7)}';

    return NigerianPhoneNumber(
      normalizedNumber: normalized,
      displayNumber: display,
      network: network,
      label: _formatLabel(phone.label),
    );
  }

  // ── NCC Prefix Detection (inline copy for isolate) ───────────────────────
  // compute() can't access providers or singletons in the main isolate,
  // so we inline the detection logic here.

  static const Map<String, NetworkProvider> _prefixMap = {
    // 5-digit prefixes MUST come first to avoid partial matches
    '07025': NetworkProvider.mtn,
    '07026': NetworkProvider.mtn,
    '07028': NetworkProvider.airtel,
    '07029': NetworkProvider.airtel,
    '07057': NetworkProvider.glo,
    '07058': NetworkProvider.glo,
    // MTN 4-digit
    '0703': NetworkProvider.mtn,
    '0706': NetworkProvider.mtn,
    '0803': NetworkProvider.mtn,
    '0806': NetworkProvider.mtn,
    '0810': NetworkProvider.mtn,
    '0813': NetworkProvider.mtn,
    '0814': NetworkProvider.mtn,
    '0816': NetworkProvider.mtn,
    '0903': NetworkProvider.mtn,
    '0906': NetworkProvider.mtn,
    '0913': NetworkProvider.mtn,
    '0916': NetworkProvider.mtn,
    // Airtel 4-digit
    '0701': NetworkProvider.airtel,
    '0708': NetworkProvider.airtel,
    '0802': NetworkProvider.airtel,
    '0808': NetworkProvider.airtel,
    '0812': NetworkProvider.airtel,
    '0901': NetworkProvider.airtel,
    '0902': NetworkProvider.airtel,
    '0904': NetworkProvider.airtel,
    '0907': NetworkProvider.airtel,
    '0912': NetworkProvider.airtel,
    // Glo 4-digit
    '0705': NetworkProvider.glo,
    '0805': NetworkProvider.glo,
    '0807': NetworkProvider.glo,
    '0811': NetworkProvider.glo,
    '0815': NetworkProvider.glo,
    '0905': NetworkProvider.glo,
    '0915': NetworkProvider.glo,
    // 9mobile 4-digit
    '0809': NetworkProvider.nineMobile,
    '0817': NetworkProvider.nineMobile,
    '0818': NetworkProvider.nineMobile,
    '0908': NetworkProvider.nineMobile,
    '0909': NetworkProvider.nineMobile,
  };

  static NetworkProvider? _detectNetworkLocal(String normalized) {
    // Check 5-digit prefixes first
    if (normalized.length >= 5) {
      final five = normalized.substring(0, 5);
      if (_prefixMap.containsKey(five)) return _prefixMap[five];
    }
    // Then 4-digit prefixes
    if (normalized.length >= 4) {
      final four = normalized.substring(0, 4);
      if (_prefixMap.containsKey(four)) return _prefixMap[four];
    }
    return null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _buildDisplayName(Contact contact) {
    final name = contact.displayName.trim();
    if (name.isNotEmpty) return name;

    // Fallback: construct from name components
    final parts = [
      contact.name.first,
      contact.name.middle,
      contact.name.last,
    ].where((s) => s.isNotEmpty).toList();

    return parts.join(' ').trim();
  }

  static String _indexLetter(String displayName) {
    if (displayName.isEmpty) return '#';
    final first = displayName[0].toUpperCase();
    // Return '#' for contacts starting with a digit or symbol
    return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
  }

  static String _formatLabel(PhoneLabel label) {
    switch (label) {
      case PhoneLabel.mobile:
        return 'Mobile';
      case PhoneLabel.home:
        return 'Home';
      case PhoneLabel.work:
        return 'Work';
      case PhoneLabel.main:
        return 'Main';
      case PhoneLabel.faxHome:
        return 'Fax';
      case PhoneLabel.faxWork:
        return 'Work Fax';
      case PhoneLabel.other:
        return 'Other';
      default:
        return 'Mobile';
    }
  }

  static List<NigerianPhoneNumber> _deduplicateNumbers(
      List<NigerianPhoneNumber> numbers) {
    final seen = <String>{};
    return numbers.where((n) => seen.add(n.normalizedNumber)).toList();
  }
}
