import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color primary = Color(0xFF2D3FE0);
  static const Color primaryLight = Color(0xFF5B6EF5);
  static const Color primaryDark = Color(0xFF1A2BB8);
  static const Color primaryContainer = Color(0xFFE8EBFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1A2BB8);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);
  static const Color secondaryContainer = Color(0xFFF3EEFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE8ECF4);
  static const Color textPrimary = Color(0xFF0D1117);
  static const Color textSecondary = Color(0xFF5A6478);
  static const Color textTertiary = Color(0xFF9BA3B8);
  static const Color divider = Color(0xFFECEFF6);
  static const Color border = Color(0xFFDDE2EE);
  static const Color borderFocused = Color(0xFF2D3FE0);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Estados de Bookings
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusActiveBg = Color(0xFFD1FAE5);
  static const Color statusCompleted = Color(0xFF2D3FE0);
  static const Color statusCompletedBg = Color(0xFFDEE2FF);
  static const Color statusCancelled = Color(0xFFEF4444);
  static const Color statusCancelledBg = Color(0xFFFFE4E6);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D3FE0), Color(0xFF7C3AED)],
  );
}
