import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/config/dio_client.dart';
import 'package:kudipay/provider/auth/auth_provider.dart';
import 'package:kudipay/provider/connectivity/connectivity_provider.dart';
import 'package:kudipay/mock/mock_api_data.dart';

final dioClientProvider = Provider<DioClient>((ref) {
  final token = ref.watch(authTokenProvider);
  final storage = ref.watch(storageServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  return DioClient(
    baseUrl: kBaseUrl,
    storage: storage,               // ✅ FIXED
    connectivity: connectivity,     // ✅ FIXED
    authToken: token,
  );
});