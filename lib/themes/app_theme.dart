import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FemoraTheme {
  // ── Colours ────────────────────────────────────────────────────────────────
  // SOMA brand palette (somafemtech.com). Names kept for backwards-compat;
  // values remapped to the navy/blue brand. Contrast tuned for WCAG AA.
  //
  // `rose` = primary brand navy (primary buttons, headings, key text).
  // `sage` = bright secondary accent (icons, links, highlights).
  // `amber` = text-safe deep accent. `lavender` = slate accent.
  static const Color rose = Color(0xFF112347);       // primary / brand navy
  static const Color roseLight = Color(0xFFDCE5F0);  // light brand tint (nav indicator, chips)
  static const Color roseMid = Color(0xFFCBD6E2);    // mid brand tint (tonal buttons)

  static const Color amber = Color(0xFF2E63C0);      // deep accent (safe for small text)
  static const Color amberLight = Color(0xFFE2E8F5);

  static const Color sage = Color(0xFF3B76D7);       // secondary accent blue
  static const Color sageLight = Color(0xFFDCEAFB);

  static const Color lavender = Color(0xFF44566F);   // slate accent
  static const Color lavenderLight = Color(0xFFE7ECF1);

  static const Color warmGray = Color(0xFFEAF0F6);   // subtle surface
  static const Color warmBorder = Color(0xFFD1DCE5); // borders
  static const Color warmText = Color(0xFF5E7191);   // muted text (AA on bg: 4.6:1)
  static const Color background = Color(0xFFF5F8FA); // page background
  static const Color cardBg = Color(0xFFFFFFFF);     // cards / contrast surface
  static const Color ink = Color(0xFF112347);        // primary text (navy)

  // Phase colours — light tinted background + AA-contrast text.
  static const Color menstrualColor = Color(0xFFE3E7EE);
  static const Color menstrualText = Color(0xFF3A4A63);
  static const Color follicularColor = Color(0xFFDCEAFB);
  static const Color follicularText = Color(0xFF2E63C0);
  static const Color ovulationColor = Color(0xFFD6E4FC);
  static const Color ovulationText = Color(0xFF1E4FA8);
  static const Color lutealColor = Color(0xFFE7ECF1);
  static const Color lutealText = Color(0xFF4F627F);

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