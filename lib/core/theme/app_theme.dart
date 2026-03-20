// lib/core/theme/app_theme.dart
// FIXED: AppTextStyles now uses responsive font sizes via AppLayout.fontSize().
// The static TextStyle constants are kept for backward compatibility in contexts
// where BuildContext is not available, but widgets should prefer the responsive
// constructors (AppTextStyles.pageTitle(context)) wherever possible.

import 'package:flutter/material.dart';
import 'package:kudipay/core/utils/responsive.dart';

class AppColors {
  static const Color primaryTeal       = Color(0xFF069494);
  static const Color lightGreen        = Color(0xFFE8F5EE);
  static const Color backgroundScreen  = Color(0xFFF9F9F9);
  static const Color backgroundGreen   = Color(0xFFEDF7F1);
  static const Color searchBackground  = Color(0xFFDCEFE4);
  static const Color textDark          = Color(0xFF151717);
  static const Color textGrey          = Color(0xFF9E9E9E);
  static const Color textLight         = Color(0xFFBDBDBD);
  static const Color white             = Color(0xFFFFFFFF);
  static const Color divider           = Color(0xFFE0E0E0);
  static const Color avatarTeal        = Color(0xFF26A69A);
  static const Color avatarDark        = Color(0xFF37474F);
  static const Color avatarBlue        = Color(0xFF5C6BC0);
  static const Color avatarLightBlue   = Color(0xFF42A5F5);
  static const Color avatarRed         = Color(0xFFC62828);
  static const Color avatarOrange      = Color(0xFFFFA726);
  static const Color inviteBadgeBackground = Color(0xFFDCEFE4);
  static const Color inviteBadgeText   = Color(0xFF4CAF8A);
  static const Color checkGreen        = Color(0xFF4CAF8A);
}

/// Static text styles — font sizes are fixed (no BuildContext required).
/// Prefer the responsive factory methods below when a BuildContext is available.
class AppTextStyles {
  // ── Static (fixed px, backward-compatible) ─────────────────────────────    
  static const TextStyle pageTitle = TextStyle(
    fontFamily: 'PolySans', fontSize: 18, fontWeight: FontWeight.w700,
    color: AppColors.textDark, letterSpacing: 0.2,
  );
  static const TextStyle tabActive = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryTeal,
  );
  static const TextStyle tabInactive = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textGrey,
  );
  static const TextStyle contactName = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textDark, letterSpacing: 0.1,
  );
  static const TextStyle contactPhone = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textGrey, letterSpacing: 0.1,
  );
  static const TextStyle label = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textGrey,
  );
  static const TextStyle phoneInput = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.white, letterSpacing: 0.3,
  );
  static const TextStyle footerNote = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textGrey,
  );
  static const TextStyle inviteText = TextStyle(
    fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.inviteBadgeText,
  );
  static const TextStyle searchHint = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textGrey,
  );
static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark,
  );

  // ── FIXED: Responsive factory methods ──────────────────────────────────
  // Use these in widgets where BuildContext is available so that text scales
  // properly on tablets, foldables, and large-screen devices.

  static TextStyle responsivePageTitle(BuildContext context) => TextStyle(
    fontFamily: 'PolySans',
    fontSize: AppLayout.fontSize(context, 18),
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    letterSpacing: 0.2,
  );

  static TextStyle responsiveTabActive(BuildContext context) => TextStyle(
    fontSize: AppLayout.fontSize(context, 14),
    fontWeight: FontWeight.w600,
    color: AppColors.primaryTeal,
  );

  static TextStyle responsiveTabInactive(BuildContext context) => TextStyle(
    fontSize: AppLayout.fontSize(context, 14),
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static TextStyle responsiveContactName(BuildContext context) => TextStyle(
    fontSize: AppLayout.fontSize(context, 14),
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    letterSpacing: 0.1,
  );

  static TextStyle responsiveLabel(BuildContext context) => TextStyle(
    fontSize: AppLayout.fontSize(context, 13),
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );

  static TextStyle responsiveButtonText(BuildContext context) => TextStyle(
    fontSize: AppLayout.fontSize(context, 15),
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    letterSpacing: 0.3,
  );

  static TextStyle responsiveFooterNote(BuildContext context) => TextStyle(
    fontSize: AppLayout.fontSize(context, 11),
    fontWeight: FontWeight.w400,
    color: AppColors.textGrey,
  );
}