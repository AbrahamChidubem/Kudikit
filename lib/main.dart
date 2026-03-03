import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/formatting/widget/connectivity_widget.dart';
import 'package:kudipay/presentation/splashscreen/splashscreen.dart';
import 'package:kudipay/provider/provider.dart';
import 'package:kudipay/services/connectivity_service.dart';
import 'package:camera/camera.dart';

final availableCamerasProvider = Provider<List<CameraDescription>>((ref) {
  throw UnimplementedError('availableCamerasProvider must be overridden');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cameras
  final cameras = await availableCameras();
  
  // Initialize connectivity service
  await ConnectivityService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: [
        availableCamerasProvider.overrideWithValue(cameras),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KudiKit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'PolySans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF389165),
        ),
      ),
      // Wrap the entire app with connectivity banner
      home: const ConnectivityBanner(
        child: SplashScreen(),
      ),
    );
  }
}

/// Alternative: If you want to show connectivity status in all screens
/// You can create a custom wrapper:
class AppWithConnectivity extends ConsumerWidget {
  final Widget child;
  
  const AppWithConnectivity({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityState = ref.watch(connectivityProvider);
    
    // Listen for connectivity changes and show snackbar
    ref.listen(connectivityProvider, (previous, next) {
      next.whenData((isConnected) {
        if (previous?.value != null && previous!.value! && !isConnected) {
          // Connection lost
          ConnectivitySnackBar.showNoInternet(context);
        } else if (previous?.value != null && !previous!.value! && isConnected) {
          // Connection restored
          ConnectivitySnackBar.showConnectionRestored(context);
        }
      });
    });

    return child;
  }
}