import 'package:flutter/material.dart';

/// Centralized Design System Colors for TORI MFI & Digital Banking App.
/// Adheres to Material 3 tokens with comprehensive Light and Dark mode support.
class ToriColors {
  ToriColors._();

  // Primary Brand Colors
  static const Color primaryTeal = Color(0xFF0D9488);
  static const Color primaryTealDark = Color(0xFF059669);
  static const Color primaryTealLight = Color(0xFF14B8A6);
  static const Color electricCyan = Color(0xFF06B6D4);
  static const Color vividCyan = Color(0xFF22D3EE);
  static const Color deepNavy = Color(0xFF0F172A);
  static const Color midnightNavy = Color(0xFF0B132B);
  static const Color royalBlue = Color(0xFF1E3A8A);

  // Light Mode Surfaces
  static const Color lightCanvasDeep = Color(0xFFF8FAFC);
  static const Color lightSurfaceCard = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceSubtle = Color(0xFFECFEFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightBorderHairline = Color(0xFFE2E8F0);
  static const Color lightBorderFocus = Color(0xFF0D9488);

  // Dark Mode Surfaces
  static const Color darkCanvasDeep = Color(0xFF020617);
  static const Color darkSurfaceCard = Color(0xFF0F172A);
  static const Color darkSurfaceElevated = Color(0xFF1E293B);
  static const Color darkSurfaceSubtle = Color(0xFF081C28);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);
  static const Color darkBorderHairline = Color(0xFF1E293B);
  static const Color darkBorderFocus = Color(0xFF22D3EE);

  // Semantic Status Colors
  static const Color successEmerald = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color criticalRose = Color(0xFFF43F5E);
  static const Color criticalBg = Color(0xFFFFF1F2);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);

  // MFI Specific Accent Colors
  static const Color bKashPink = Color(0xFFE2136E);
  static const Color nagadOrange = Color(0xFFF7941D);
  static const Color rocketPurple = Color(0xFF8C3494);

  // EMV Chip Metallic Gradient Colors
  static const Color goldChip1 = Color(0xFFE5BA6A);
  static const Color goldChip2 = Color(0xFFFDE047);
  static const Color goldChip3 = Color(0xFFD4A247);
  static const Color goldChipBorder = Color(0xFF9A7228);

  // Gradients
  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF030D28), Color(0xFF0C2461), Color(0xFF1B6EF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emvChipGradient = LinearGradient(
    colors: [goldChip1, goldChip2, goldChip1, goldChip3],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
