import 'package:flutter/material.dart';

class AppColors {
  // Pookie Match Exact CSS Theme Variables (from app/globals.css)
  static const Color coral = Color(0xFFF06B72);        // --coral: #f06b72
  static const Color coralDark = Color(0xFFDF5961);    // --coral-dark: #df5961
  static const Color coralLight = Color(0xFFFF858B);
  static const Color coralPale = Color(0xFFFFF1F0);    // --coral-pale: #fff1f0
  static const Color coralSoft = Color(0xFFFFF1F0);

  // Semantic Primary Aliases
  static const Color primary = coral;
  static const Color primaryDark = coralDark;
  static const Color primaryPale = coralPale;

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFFFFFFF);   // --surface: #ffffff
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFFFAF9);   // --surface-soft: #fffaf9
  static const Color surfaceMuted = Color(0xFFFFFAF9);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE9E0E2);        // --line: #e9e0e2
  static const Color borderSubtle = Color(0xFFF4ECEE);

  // Typography
  static const Color ink = Color(0xFF292536);           // --ink: #292536
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF555060);
  static const Color textMuted = Color(0xFF777182);     // --muted: #777182
  static const Color textDisabled = Color(0xFFA39DAA);

  // Accents & Badges
  static const Color success = Color(0xFF2E9B71);       // --green: #2e9b71
  static const Color successSoft = Color(0xFFEAF8F2);
  static const Color emerald = success;
  static const Color emeraldPale = successSoft;
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color amber = warning;
  static const Color error = Color(0xFFDF5961);
  static const Color errorSoft = Color(0xFFFEE8E8);
  static const Color cardShadowColor = Color.fromRGBO(41, 37, 54, 0.08);

  // Dark Stage for Video Calling
  static const Color callBackground = Color(0xFF181524);
  static const Color callSurface = Color(0xFF242033);
  static const Color callBorder = Color(0xFF38324A);

  // Gradients
  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFF06B72), Color(0xFFFF858B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFFFFF1F0), Color(0xFFFFFAF9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Box Shadows matching website: 0 16px 42px rgba(41, 37, 54, 0.08)
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color.fromRGBO(41, 37, 54, 0.08),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get subtleShadow => [
        const BoxShadow(
          color: Color.fromRGBO(41, 37, 54, 0.05),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ];
}
