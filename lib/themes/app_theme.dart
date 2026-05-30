import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FemoraTheme {
  // ── Colours ────────────────────────────────────────────────────────────────
  static const Color rose = Color(0xFFC9476A);
  static const Color roseLight = Color(0xFFF5DCE3);
  static const Color roseMid = Color(0xFFE8A0B3);

  static const Color amber = Color(0xFFB8642A);
  static const Color amberLight = Color(0xFFF5EAD8);

  static const Color sage = Color(0xFF3A6B52);
  static const Color sageLight = Color(0xFFDDEEE6);

  static const Color lavender = Color(0xFF6B52A8);
  static const Color lavenderLight = Color(0xFFE8E3F5);

  static const Color warmGray = Color(0xFFF0ECE6);
  static const Color warmBorder = Color(0xFFE2DCD4);
  static const Color warmText = Color(0xFF7A6F65);
  static const Color background = Color(0xFFFAF8F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF1A1612);

  // Phase colours
  static const Color menstrualColor = Color(0xFFEDE8F5);
  static const Color menstrualText = Color(0xFF6B52A8);
  static const Color follicularColor = Color(0xFFDDEEE6);
  static const Color follicularText = Color(0xFF3A6B52);
  static const Color ovulationColor = Color(0xFFF5DCE3);
  static const Color ovulationText = Color(0xFFC9476A);
  static const Color lutealColor = Color(0xFFF5EAD8);
  static const Color lutealText = Color(0xFFB8642A);

  // ── Typography ─────────────────────────────────────────────────────────────
  static TextTheme get textTheme => GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 32,
          color: ink,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 26,
          color: ink,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: GoogleFonts.dmSerifDisplay(
          fontSize: 22,
          color: ink,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 17,
          color: ink,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 15,
          color: ink,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 13,
          color: ink,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.dmSans(
          fontSize: 11,
          color: warmText,
          fontWeight: FontWeight.w400,
        ),
        labelSmall: GoogleFonts.dmSans(
          fontSize: 11,
          color: warmText,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
        ),
      );

  // ── Material Theme ─────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: rose,
          secondary: sage,
          tertiary: lavender,
          surface: cardBg,
          surfaceContainerHighest: warmGray,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: ink,
          outline: warmBorder,
        ),
        scaffoldBackgroundColor: background,
        textTheme: textTheme,
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: warmBorder),
          ),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: cardBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: warmBorder,
          titleTextStyle: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            color: rose,
            fontWeight: FontWeight.w400,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: cardBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: warmBorder,
          indicatorColor: roseLight,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: rose,
              );
            }
            return GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: warmText,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: rose, size: 22);
            }
            return const IconThemeData(color: warmText, size: 22);
          }),
        ),
        dividerTheme: const DividerThemeData(
          color: warmBorder,
          thickness: 1,
          space: 1,
        ),
        chipTheme: ChipThemeData(
          backgroundColor: warmGray,
          labelStyle: GoogleFonts.dmSans(fontSize: 12, color: warmText),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
      );
}