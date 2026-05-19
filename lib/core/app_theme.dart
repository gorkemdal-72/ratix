import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ratix uygulama teması — Merkezi renk, tipografi ve bileşen stilleri.
class AppTheme {
  AppTheme._();

  // ─── ANA RENKLER ───
  // Genel puanlama uygulaması — Indigo/Violet ton
  static const Color _primaryLight = Color(0xFF6366F1); // Indigo 500
  static const Color _primaryDark = Color(0xFF818CF8);  // Indigo 400 (dark mode)

  // Arka plan renkleri
  static const Color _scaffoldLight = Color(0xFFF8FAFC); // Slate 50
  static const Color _scaffoldDark = Color(0xFF0F172A);  // Slate 900

  // Surface renkleri
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceDark = Color(0xFF1E293B); // Slate 800

  // Kart renkleri
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF1E293B);

  // Metin renkleri
  static const Color _textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color _textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color _textPrimaryDark = Color(0xFFF1F5F9); // Slate 100
  static const Color _textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  // Vurgu renkleri
  static const Color accent = Color(0xFF06B6D4);   // Cyan 500
  static const Color success = Color(0xFF10B981);   // Emerald 500
  static const Color warning = Color(0xFFF59E0B);   // Amber 500
  static const Color danger = Color(0xFFEF4444);    // Red 500

  // Gradient renkleri
  static const Color gradientStart = Color(0xFF6366F1); // Indigo
  static const Color gradientEnd = Color(0xFF8B5CF6);    // Violet 500

  // ─── PUAN RENK KODLARl ───
  static Color ratingColor(double rating, double maxRating) {
    final ratio = rating / maxRating;
    if (ratio <= 0.3) return const Color(0xFFEF4444);      // Kötü → Kırmızı
    if (ratio <= 0.6) return const Color(0xFFF59E0B);      // Orta → Amber
    return const Color(0xFF10B981);                         // İyi → Yeşil
  }

  // ─── BORDER RADIUS ───
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ─── SPACING ───
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;

  // ─── GÖLGE ───
  static List<BoxShadow> cardShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark ? Colors.black26 : Colors.black.withOpacity(0.06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  // ─── GRADIENTS ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient headerGradientLight = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── LIGHT TEMA ───
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryLight,
        brightness: Brightness.light,
        primary: _primaryLight,
        onPrimary: Colors.white,
        surface: _surfaceLight,
        onSurface: _textPrimaryLight,
      ),
      scaffoldBackgroundColor: _scaffoldLight,
      
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _scaffoldLight,
        foregroundColor: _textPrimaryLight,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryLight,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: _cardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        margin: const EdgeInsets.only(bottom: spaceSm),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryLight,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: danger,
          side: const BorderSide(color: danger),
          padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: _primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: _textSecondaryLight, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: _textSecondaryLight, fontSize: 14),
        prefixIconColor: _textSecondaryLight,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        backgroundColor: _surfaceLight,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryLight,
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        backgroundColor: _textPrimaryLight,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        space: spaceLg,
        thickness: 1,
      ),

      // SwitchListTile / Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryLight;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryLight.withOpacity(0.3);
          return Colors.grey.shade300;
        }),
      ),

      // Text theme
      textTheme: _buildTextTheme(Brightness.light),

      // Popup Menu
      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        elevation: 8,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
        backgroundColor: _surfaceLight,
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: 4),
      ),
    );
  }

  // ─── DARK TEMA ───
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryDark,
        brightness: Brightness.dark,
        primary: _primaryDark,
        onPrimary: _scaffoldDark,
        surface: _surfaceDark,
        onSurface: _textPrimaryDark,
      ),
      scaffoldBackgroundColor: _scaffoldDark,

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _scaffoldDark,
        foregroundColor: _textPrimaryDark,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDark,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: _cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        margin: const EdgeInsets.only(bottom: spaceSm),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryDark,
        foregroundColor: _scaffoldDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: _scaffoldDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryDark,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: danger,
          side: const BorderSide(color: danger),
          padding: const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: _textSecondaryDark, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: _textSecondaryDark, fontSize: 14),
        prefixIconColor: _textSecondaryDark,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusLg)),
        backgroundColor: _surfaceDark,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimaryDark,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        backgroundColor: _surfaceDark,
        contentTextStyle: GoogleFonts.inter(color: _textPrimaryDark, fontSize: 14),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.08),
        space: spaceLg,
        thickness: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryDark;
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryDark.withOpacity(0.3);
          return Colors.grey.shade700;
        }),
      ),

      textTheme: _buildTextTheme(Brightness.dark),

      popupMenuTheme: PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        elevation: 8,
        color: _surfaceDark,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
        backgroundColor: _surfaceDark,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        contentPadding: const EdgeInsets.symmetric(horizontal: spaceMd, vertical: 4),
      ),
    );
  }

  // ─── TİPOGRAFİ ───
  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light ? _textPrimaryLight : _textPrimaryDark;
    final secondaryColor = brightness == Brightness.light ? _textSecondaryLight : _textSecondaryDark;

    return TextTheme(
      displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: color),
      displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: color),
      displaySmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: color),
      headlineLarge: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: color),
      headlineMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: color),
      headlineSmall: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500, color: color),
      titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: color),
      titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: color),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor),
      labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: secondaryColor),
      labelSmall: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: secondaryColor),
    );
  }
}
