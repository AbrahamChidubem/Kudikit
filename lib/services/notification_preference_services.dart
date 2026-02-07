import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:kudipay/presentation/notification/notification_preferences.dart';
import 'package:kudipay/services/storage_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesService {
  final String baseUrl = 'https://api.yourapp.com'; // Replace with your API URL
  final StorageService _storageService = StorageService();

  /// Fetch notification preferences from server
  Future<NotificationPreferences> fetchPreferences() async {
    try {
      final token = await _storageService.getAuthToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/notifications/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NotificationPreferences.fromJson(data['preferences']);
      } else {
        throw Exception('Failed to load notification preferences');
      }
    } catch (e) {
      // Return default preferences if API fails
      return NotificationPreferences();
    }
  }

  /// Update notification preferences on server
  Future<bool> updatePreferences(NotificationPreferences preferences) async {
    try {
      final token = await _storageService.getAuthToken();

      final response = await http.put(
        Uri.parse('$baseUrl/api/notifications/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'preferences': preferences.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update notification preferences');
      }
    } catch (e) {
      print('Error updating preferences: $e');
      return false;
    }
  }

  /// Update a single notification preference
  Future<bool> updateSinglePreference(String key, bool value) async {
    try {
      final token = await _storageService.getAuthToken();

      final response = await http.patch(
        Uri.parse('$baseUrl/api/notifications/preferences/$key'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'value': value,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating preference: $e');
      return false;
    }
  }

  /// Save preferences locally using SharedPreferences
  Future<void> savePreferencesLocally(
      NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'notification_preferences',
        json.encode(preferences.toJson()),
      );
    } catch (e) {
      print('Error saving preferences locally: $e');
    }
  }

  /// Load preferences from local storage
  Future<NotificationPreferences> loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('notification_preferences');
      if (data != null) {
        return NotificationPreferences.fromJson(json.decode(data));
      }
    } catch (e) {
      print('Error loading local preferences: $e');
    }
    return NotificationPreferences();
  }
}
