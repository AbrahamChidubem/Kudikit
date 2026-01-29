import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kudipay/features/onboarding/data/datasources/onboarding_services.dart';


final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

final hasSeenOnboardingProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  return await service.hasSeenOnboarding();
});