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
  //
  // Brand fonts are LICENSED (not free / not on Google Fonts):
  //   Headers  → Ogg (Sharp Type); fallbacks Canela / Chronicle Display.
  //   Body/sub → LL Circular (Lineto).
  //
  // To enable them: license the fonts, drop the files into assets/fonts/, and
  // un-comment the `fonts:` block in pubspec.yaml. Until then, these helpers
  // request the real families first and gracefully fall back to the closest
  // free Google Fonts match (Fraunces for the serif, Outfit for the sans), so
  // nothing breaks and the real fonts take over automatically once added.
  static const String headerFontFamily = 'Ogg';
  static const List<String> headerFontFallback = ['Canela', 'Chronicle Display', 'Fraunces'];
  static const String bodyFontFamily = 'Circular'; // LL Circular
  static const List<String> bodyFontFallback = ['Outfit'];

  /// Serif style for headers (Ogg → Fraunces fallback).
  static TextStyle serif({
    required double fontSize,
    Color color = ink,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) =>
      // Calling GoogleFonts.fraunces registers the fallback family at runtime;
      // we then prefer the licensed `Ogg` family if it is bundled.
      GoogleFonts.fraunces(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      ).copyWith(
        fontFamily: headerFontFamily,
        fontFamilyFallback: headerFontFallback,
      );

  /// Sans style for body text and subheaders (LL Circular → Outfit fallback).
  static TextStyle sans({
    required double fontSize,
    Color color = ink,
    FontWeight fontWeight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.outfit(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      ).copyWith(
        fontFamily: bodyFontFamily,
        fontFamilyFallback: bodyFontFallback,
      );

  static TextTheme get textTheme => GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: serif(fontSize: 32),
        displayMedium: serif(fontSize: 26),
        displaySmall: serif(fontSize: 22),
        headlineMedium: sans(fontSize: 17, fontWeight: FontWeight.w500),
        bodyLarge: sans(fontSize: 15),
        bodyMedium: sans(fontSize: 13),
        bodySmall: sans(fontSize: 11, color: warmText),
        labelSmall: sans(
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
          titleTextStyle: serif(fontSize: 22, color: rose),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: cardBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: warmBorder,
          indicatorColor: roseLight,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return sans(fontSize: 11, fontWeight: FontWeight.w500, color: rose);
            }
            return sans(fontSize: 11, fontWeight: FontWeight.w400, color: warmText);
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
          selectedColor: rose,
          checkmarkColor: Colors.white,
          // Selected chips get a dark (navy) fill, so flip the label to white
          // when selected; revert to muted text when not.
          labelStyle: WidgetStateTextStyle.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return sans(
              fontSize: 12,
              color: selected ? Colors.white : warmText,
              fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            );
          }),
          secondaryLabelStyle: sans(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide.none,
        ),
      );
}