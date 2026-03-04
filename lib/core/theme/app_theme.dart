import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF069494);
  static const Color lightGreen = Color(0xFFE8F5EE);
  static const Color backgroundGreen = Color(0xFFEDF7F1);
  static const Color searchBackground = Color(0xFFDCEFE4);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF9E9E9E);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color avatarTeal = Color(0xFF26A69A);
  static const Color avatarDark = Color(0xFF37474F);
  static const Color avatarBlue = Color(0xFF5C6BC0);
  static const Color avatarLightBlue = Color(0xFF42A5F5);
  static const Color avatarRed = Color(0xFFC62828);
  static const Color avatarOrange = Color(0xFFFFA726);
  static const Color inviteBadgeBackground = Color(0xFFDCEFE4);
  static const Color inviteBadgeText = Color(0xFF4CAF8A);
  static const Color checkGreen = Color(0xFF4CAF8A);
}

class AppTextStyles {
  static const TextStyle pageTitle = TextStyle(
    fontFamily: 'PolySans',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: 0.2,
  );

  static const TextStyle tabActive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryGreen,
  );

  static const TextStyle tabInactive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static const TextStyle contactName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: 0.1,
  );

  static const TextStyle contactPhone = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
    letterSpacing: 0.1,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static const TextStyle phoneInput = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.3,
  );

  static const TextStyle footerNote = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static const TextStyle inviteText = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.inviteBadgeText,
  );

  static const TextStyle searchHint = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );
}