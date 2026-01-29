import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/presentation/splashscreen/splashscreen.dart';
import 'package:camera/camera.dart';

final availableCamerasProvider = Provider<List<CameraDescription>>((ref) {
  throw UnimplementedError('availableCamerasProvider must be overridden');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final cameras = await availableCameras();

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
        fontFamily: 'OpenSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF389165),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
