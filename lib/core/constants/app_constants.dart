import 'package:flutter/material.dart';

class AppColors {
  // ===========================================================================
  // MUSTER — Operational Editorial Visual Identity (COLOR_PALETTE.md)
  // ===========================================================================

  // 1. Foundational Reference Colors
  static const Color primaryInk = Color(0xFF1A1A1A); // Deep Charcoal Black (#1A1A1A)
  static const Color musterOrange = Color(0xFFE65100); // Deep Operational Orange (#E65100)
  static const Color forestGreen = Color(0xFF436D4F); // Restrained Deep Green (#436D4F)
  static const Color warmPaper = Color(0xFFF9F8F6); // Warm Editorial Cream (#F9F8F6)

  // 2. Structural & Canvas Tokens
  static const Color bgCanvas = Color(0xFFF9F8F6); // Main page canvas (#F9F8F6)
  static const Color bgSurface = Color(0xFFFFFFFF); // Card & table container surface (#FFFFFF)
  static const Color bgSurfaceElevated = Color(0xFFF2EFE9); // Elevated modal/dropdown (#F2EFE9)
  static const Color bgSurfaceSubtle = Color(0xFFF2EFE9); // Subtle surface container (#F2EFE9)
  static const Color bgContainer = Color(0xFFE7E2D8); // Structural container (#E7E2D8)

  // 3. Grid & Border Tokens (1px structural lines)
  static const Color border = Color(0xFFE7E2D8); // Standard 1px grid line (#E7E2D8)
  static const Color borderStrong = Color(0xFFD6CEBE); // Active container border (#D6CEBE)

  // 4. Primary Brand / Action Tokens (MUSTER Orange)
  static const Color primary = Color(0xFFE65100); // MUSTER Orange (#E65100)
  static const Color primaryHover = Color(0xFFF57C00); // Hover state (#F57C00)
  static const Color primaryActive = Color(0xFFEF6C00); // Active pressed (#EF6C00)
  static const Color primaryLight = Color(0xFFFB8C00); // Vibrant accent (#FB8C00)
  static const Color primaryDark = Color(0xFFB73C00); // Deep operational text (#B73C00)

  // 5. Semantic Status Palette
  // SUCCESS (Forest Green)
  static const Color success = Color(0xFF436D4F); // Forest Green (#436D4F)
  static const Color successBg = Color(0xFFEBF2EE); // Soft success BG (#EBF2EE)
  static const Color successBorder = Color(0xFFD2E3D7); // Soft success border (#D2E3D7)
  static const Color successText = Color(0xFF294732); // Strong confirmed text (#294732)

  // WARNING (Amber Ochre)
  static const Color warning = Color(0xFFD97706); // Amber Ochre (#D97706)
  static const Color warningBg = Color(0xFFFEF3C7); // Soft warning BG (#FEF3C7)
  static const Color warningBorder = Color(0xFFFDE68A); // Soft warning border (#FDE68A)

  // DANGER / ERROR (Restrained Crimson)
  static const Color danger = Color(0xFFC0392B); // Restrained Crimson (#C0392B)
  static const Color dangerBg = Color(0xFFFDEDEC); // Soft danger BG (#FDEDEC)
  static const Color dangerBorder = Color(0xFFF9EBEA); // Soft danger border (#F9EBEA)

  // INFO (Slate Blue)
  static const Color info = Color(0xFF2563EB); // Slate Blue (#2563EB)
  static const Color infoBg = Color(0xFFEFF6FF); // Soft info BG (#EFF6FF)
  static const Color infoBorder = Color(0xFFBFDBFE); // Soft info border (#BFDBFE)

  // 6. Typography Tokens
  static const Color textMain = Color(0xFF1A1A1A); // Primary Ink (#1A1A1A)
  static const Color textSecondary = Color(0xFF4D4D4D); // Body text secondary (#4D4D4D)
  static const Color textMuted = Color(0xFF786E5D); // Captions & metadata (#786E5D)
  static const Color textDisabled = Color(0xFFA39885); // Disabled state labels (#A39885)
}

class AppConstants {
  static const String appName = 'MUSTER';
  static const String appTagline = 'AI-Powered Crew Assembly for Event Staffing';
  static const String version = '1.0.0';
}
