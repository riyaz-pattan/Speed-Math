import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/enums/enums.dart';

export '../data/repositories/settings_repository.dart' show themeModeProvider;

class AppTheme {
  AppTheme._();

  // Core Brand Tokens (WCAG AA/AAA compliant)
  static const Color primaryColor = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF6366F1); // Electric Indigo
  static const Color primaryTint = Color(0xFFEEF2FF); // Indigo 50
  static const Color secondaryColor = Color(0xFF0EA5E9); // Sky 500
  static const Color accentGreen = Color(0xFF10B981); // Emerald 500
  static const Color warningAmber = Color(0xFFF59E0B); // Amber 500
  static const Color errorRed = Color(0xFFEF4444); // Rose 500
  static const Color violetAccent = Color(0xFF7C3AED); // Violet
  static const Color cyanAccent = Color(0xFF06B6D4); // Cyan Accent
  static const Color accentColor = primaryColor;

  // Surface & Canvas Tokens
  static const Color canvasBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceCard = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF1F5F9); // Slate 100
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderSubtle = Color(0xFFCBD5E1); // Slate 300

  // Text Tokens
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900 (14.8:1 contrast)
  static const Color textSecondary = Color(0xFF475569); // Slate 600 (5.8:1 contrast)
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Semantic Color Aliases
  static const Color successColor = accentGreen;
  static const Color warningColor = warningAmber;
  static const Color errorColor = errorRed;
  static const Color infoColor = secondaryColor;
  static const Color cardBackground = surfaceCard;
  static const Color surfaceColor = surfaceCard;
  static const Color backgroundColor = canvasBackground;
  static const Color borderColor = borderLight;
  static const Color textTertiary = textMuted;

  // Radius Tokens
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 999.0;
  static const double cardRadius = radiusLg;
  static const double borderRadius = radiusLg;
  static const double chipRadius = radiusPill;
  static const double buttonRadius = radiusMd;

  // Pre-built const BorderRadius instances
  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusPill = BorderRadius.all(Radius.circular(radiusPill));
  static const BorderRadius cardBorderRadius = borderRadiusLg;

  // Ambient Soft Shadows (zero blur filter lag, smooth 60fps)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> stickyShadow = [
    BoxShadow(
      color: Color(0x0C0F172A),
      blurRadius: 18,
      offset: Offset(0, -3),
    ),
  ];

  static const List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: Color(0x284F46E5),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Standard Card Box Decoration
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.all(color: borderLight, width: 1.2),
    boxShadow: cardShadow,
  );

  static const String fontFamily = 'Poppins';

  // Topic Signature Colors
  static const Color additionColor = Color(0xFF10B981); // Emerald Green
  static const Color subtractionColor = Color(0xFFF97316); // Vibrant Orange
  static const Color multiplicationColor = Color(0xFF3B82F6); // Vivid Blue
  static const Color divisionColor = Color(0xFFEC4899); // Pink / Magenta
  static const Color squaresColor = Color(0xFF8B5CF6); // Rich Purple
  static const Color cubesColor = Color(0xFF14B8A6); // Teal
  static const Color squareRootsColor = Color(0xFFF59E0B); // Amber
  static const Color cubeRootsColor = Color(0xFF06B6D4); // Cyan
  static const Color exponentsColor = Color(0xFFEF4444); // Red
  static const Color percentagesColor = Color(0xFF65A30D); // Lime
  static const Color fractionsColor = Color(0xFFF43F5E); // Rose
  static const Color simplificationColor = Color(0xFF4F46E5); // Indigo
  static const Color averagesColor = Color(0xFFEA580C); // Deep Orange
  static const Color missingNumberColor = Color(0xFF64748B); // Slate
  static const Color numberSeriesColor = Color(0xFF0284C7); // Teal-Blue
  static const Color approximationColor = Color(0xFFB45309); // Amber-Brown
  static const Color mixedColor = Color(0xFF8B5CF6); // Violet for Mixed practice

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, violetAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color getTopicColor(Topic topic) {
    return switch (topic) {
      Topic.addition => additionColor,
      Topic.subtraction => subtractionColor,
      Topic.multiplication => multiplicationColor,
      Topic.division => divisionColor,
      Topic.squares => squaresColor,
      Topic.cubes => cubesColor,
      Topic.squareRoots => squareRootsColor,
      Topic.cubeRoots => cubeRootsColor,
      Topic.exponents => exponentsColor,
      Topic.percentages => percentagesColor,
      Topic.fractions => fractionsColor,
      Topic.simplification => simplificationColor,
      Topic.averages => averagesColor,
      Topic.missingNumber => missingNumberColor,
      Topic.numberSeries => numberSeriesColor,
      Topic.approximation => approximationColor,
      Topic.mixed => mixedColor,
    };
  }

  static LinearGradient getTopicGradient(Topic topic) {
    final color = getTopicColor(topic);
    return LinearGradient(
      colors: [color, color.withValues(alpha: 0.82)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static IconData getTopicIcon(Topic topic) {
    return switch (topic) {
      Topic.addition => Icons.add_rounded,
      Topic.subtraction => Icons.remove_rounded,
      Topic.multiplication => Icons.close_rounded,
      Topic.division => Icons.percent_rounded,
      Topic.squares => Icons.crop_square_rounded,
      Topic.cubes => Icons.view_in_ar_rounded,
      Topic.squareRoots => Icons.square_foot_rounded,
      Topic.cubeRoots => Icons.hub_rounded,
      Topic.exponents => Icons.superscript_rounded,
      Topic.percentages => Icons.pie_chart_outline_rounded,
      Topic.fractions => Icons.call_split_rounded,
      Topic.simplification => Icons.functions_rounded,
      Topic.averages => Icons.bar_chart_rounded,
      Topic.missingNumber => Icons.help_outline_rounded,
      Topic.numberSeries => Icons.timeline_rounded,
      Topic.approximation => Icons.waves_rounded,
      Topic.mixed => Icons.auto_awesome_rounded,
    };
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      surface: surfaceCard,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceSecondary,
      outline: borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvasBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderLight, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: borderLight, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textPrimary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderLight, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: primaryTint,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  /// Dark mode has been completely removed from Speed Math. Always returns [lightTheme].
  static ThemeData get darkTheme => lightTheme;
}
