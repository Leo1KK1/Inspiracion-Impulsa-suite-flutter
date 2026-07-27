import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color foreground) {
    final body = GoogleFonts.dmSansTextTheme();
    final display = GoogleFonts.plusJakartaSansTextTheme();
    return body.copyWith(
      headlineLarge: display.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      headlineSmall: display.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      titleLarge: display.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      titleMedium: display.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      bodyLarge: body.bodyLarge?.copyWith(color: foreground),
      bodyMedium: body.bodyMedium?.copyWith(color: foreground),
      labelLarge: body.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
