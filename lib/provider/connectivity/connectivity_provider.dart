import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/services/connectivity_service.dart';

/// ==================== CONNECTIVITY PROVIDERS ====================
/// 
/// This file contains all network connectivity related state providers:
/// - Real-time connectivity monitoring
/// - Connection status checks
/// - Connection type detection

// ==================== SERVICE PROVIDER ====================

/// Provider for connectivity service singleton
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService.instance;
  
  // Dispose the service when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

// ==================== STREAM PROVIDERS ====================

/// Stream provider that monitors internet connectivity in real-time
/// 
/// Usage:
/// ```dart
/// final connectivityState = ref.watch(connectivityProvider);
/// connectivityState.when(
///   data: (isConnected) => isConnected ? OnlineWidget() : OfflineWidget(),
///   loading: () => LoadingWidget(),
///   error: (error, stack) => ErrorWidget(error),
/// );
/// ```
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectionChange;
});

// ==================== SYNCHRONOUS PROVIDERS ====================

/// Provider to get current connectivity status synchronously
/// 
/// Usage:
/// ```dart
/// final isConnected = ref.watch(currentConnectivityProvider);
/// if (isConnected) {
///   // Perform online operations
/// }
/// ```
final currentConnectivityProvider = Provider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.hasConnection;
});

// ==================== FUTURE PROVIDERS ====================

/// Future provider to check internet connection once
/// 
/// Usage:
/// ```dart
/// final hasInternet = await ref.read(checkInternetProvider.future);
/// if (hasInternet) {
///   // Proceed with API call
/// }
/// ```
final checkInternetProvider = FutureProvider<bool>((ref) async {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return await connectivityService.hasInternetConnection();
});

// ==================== STATE MANAGEMENT ====================

/// State class for advanced connectivity management
class ConnectivityState {
  final bool isConnected;
  final String? connectionType;
  final DateTime? lastChecked;
  final String? errorMessage;

  ConnectivityState({
    required this.isConnected,
    this.connectionType,
    this.lastChecked,
    this.errorMessage,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    String? connectionType,
    DateTime? lastChecked,
    String? errorMessage,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      connectionType: connectionType ?? this.connectionType,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// State notifier for advanced connectivity management
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityService _connectivityService;

  ConnectivityNotifier(this._connectivityService)
      : super(ConnectivityState(isConnected: false)) {
    _initialize();
  }

  void _initialize() async {
    // Initialize connectivity service
    await _connectivityService.initialize();
    
    // Set initial state
    final isConnected = _connectivityService.hasConnection;
    final connectivityTypes = await _connectivityService.getConnectivityType();
    
    state = ConnectivityState(
      isConnected: isConnected,
      connectionType: connectivityTypes.isNotEmpty 
          ? connectivityTypes.first.displayName 
          : 'Unknown',
      lastChecked: DateTime.now(),
    );

    // Listen to connectivity changes
    _connectivityService.connectionChange.listen((isConnected) async {
      final connectivityTypes = await _connectivityService.getConnectivityType();
      
      state = ConnectivityState(
        isConnected: isConnected,
        connectionType: connectivityTypes.isNotEmpty 
            ? connectivityTypes.first.displayName 
            : 'Unknown',
        lastChecked: DateTime.now(),
      );
    });
  }

  /// Manually refresh connectivity status
  Future<void> refresh() async {
    try {
      final isConnected = await _connectivityService.hasInternetConnection();
      final connectivityTypes = await _connectivityService.getConnectivityType();
      
      state = ConnectivityState(
        isConnected: isConnected,
        connectionType: connectivityTypes.isNotEmpty 
            ? connectivityTypes.first.displayName 
            : 'Unknown',
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to check connectivity: $e',
      );
    }
  }
}

/// State notifier provider for advanced connectivity management
final connectivityStateProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return ConnectivityNotifier(connectivityService);
});