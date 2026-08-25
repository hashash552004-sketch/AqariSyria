import 'package:flutter/material.dart';

/// Central color palette.
///
/// Theme-dependent colors ([background], [cards], [textPrimary], …) are
/// dynamic getters so the WHOLE app follows dark mode instantly.
/// Brand colors stay compile-time constants.
class AppColors {
  AppColors._();

  /// Set by ThemeProvider whenever dark mode changes.
  static bool isDark = false;

  // ---- Brand (constant) ----
  static const Color primary = Color(0xFF1677FF);
  static const Color secondary = Color(0xFF4DA3FF);
  static const Color accent = Color(0xFF76C7FF);
  static const Color success = Color(0xFF12B76A);
  static const Color warning = Color(0xFFF79009);
  static const Color error = Color(0xFFF04438);

  // ---- Light palette ----
  static const Color _lightBackground = Color(0xFFF8FAFD);
  static const Color _lightCards = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF1D2939);
  static const Color _lightTextSecondary = Color(0xFF667085);
  static const Color _lightBorder = Color(0xFFE4E7EC);
  static const Color _lightShimmerBase = Color(0xFFE4E7EC);
  static const Color _lightShimmerHighlight = Color(0xFFF0F2F5);

  // ---- Dark palette (elegant near-black) ----
  static const Color darkBackground = Color(0xFF07070A);
  static const Color darkCards = Color(0xFF13131A);
  static const Color darkTextPrimary = Color(0xFFF2F3F5);
  static const Color darkTextSecondary = Color(0xFF9AA1AC);
  static const Color darkBorder = Color(0xFF23232D);
  static const Color darkShimmerBase = Color(0xFF1B1B23);
  static const Color darkShimmerHighlight = Color(0xFF262631);

  // ---- Dynamic (theme-following) ----
  static Color get background => isDark ? darkBackground : _lightBackground;
  static Color get cards => isDark ? darkCards : _lightCards;
  static Color get textPrimary => isDark ? darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary => isDark ? darkTextSecondary : _lightTextSecondary;
  static Color get border => isDark ? darkBorder : _lightBorder;
  static Color get shimmerBase => isDark ? darkShimmerBase : _lightShimmerBase;
  static Color get shimmerHighlight =>
      isDark ? darkShimmerHighlight : _lightShimmerHighlight;

  static const Color verifiedBadge = Color(0xFF12B76A);
  static const Color featuredBadge = Color(0xFFF79009);
  static const Color urgentBadge = Color(0xFFF04438);

  static const Color glassWhite = Color(0x66FFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}
