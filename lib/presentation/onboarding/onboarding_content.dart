import 'package:flutter/material.dart';

class OnboardingContent {
  final String title;
  final String description;
  final String imagePath; 
  final String subtext;
  final Color color;

  const OnboardingContent({
    required this.title,
    required this.description,
    required this.imagePath, 
    required this.subtext,
    required this.color,
  });
}

// App features for onboarding
final List<OnboardingContent> onboardingContents = [
  const OnboardingContent(
    title: 'Welcome to KudiKit',
    description:
        'Trusted by users across Nigeria',
    imagePath: 'assets/images/frame1.png', 
    subtext: 'Secure. Licensed. Built for everyday payments',
    color:  Colors.transparent
  ),
  const OnboardingContent(
    title: 'Pay bills, send money, and manage your finances',
    description:
        'Anytime, anywhere!',
    imagePath: 'assets/images/frame2.png', 
    subtext: 'Clear steps, instant confirmation and full transaction history',
   color:  Colors.transparent
  ),
  const OnboardingContent(
    title: 'Send and receive cash from a Kudikit Tribe member closest to you',
    color:  Colors.transparent,
    description:
        'No bank/POS needed',
    imagePath: 'assets/images/frame3.png', 
    subtext: 'Only verified KudiKit members can exchange cash',
  ),
  const OnboardingContent(
    title: 'Earn rewards with every transaction you make!',
    description:
        '',
    imagePath: 'assets/images/frame4.png', 
    subtext: '',
    color:  Color(0xFF069494)
  ),
];