import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/services/storage_services.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});