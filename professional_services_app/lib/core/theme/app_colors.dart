import 'package:flutter/material.dart';

abstract class AppColors {
  // Paleta Principal - Estilo Moderno / Profesional
  static const Color primary = Color(0xFF6366F1); // Indigo moderno
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color primaryContainer = Color(0xFFEEF2FF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF3730A3);

  static const Color secondary = Color(0xFF10B981); // Emerald
  static const Color secondaryLight = Color(0xFF34D399);
  static const Color secondaryContainer = Color(0xFFECFDF5);
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Colores de Superficie y Fondo
  static const Color background = Color(0xFFF9FAFB); // Gris muy claro
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Bordes y Divisores
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFD1D5DB);
  static const Color borderFocused = Color(0xFF6366F1);

  // Tipografía
  static const Color textPrimary = Color(0xFF111827); // Gris casi negro
  static const Color textSecondary = Color(0xFF4B5563); // Gris medio
  static const Color textTertiary = Color(0xFF9CA3AF); // Gris claro

  // Estados
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Estados de Bookings / Chips
  static const Color statusActive = Color(0xFF059669);
  static const Color statusActiveBg = Color(0xFFD1FAE5);
  static const Color statusCompleted = Color(0xFF6366F1);
  static const Color statusCompletedBg = Color(0xFFE0E7FF);
  static const Color statusCancelled = Color(0xFFDC2626);
  static const Color statusCancelledBg = Color(0xFFFEE2E2);
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusPendingBg = Color(0xFFFEF3C7);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );
}
