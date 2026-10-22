import 'package:flutter/material.dart';
import '../core/enums/enums.dart';

export '../data/repositories/settings_repository.dart' show themeModeProvider;

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF4F46E5); // Deep Indigo
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color violetAccent = Color(0xFF7C3AED); // Violet
  static const Color cyanAccent = Color(0xFF06B6D4); // Cyan Accent
  static const Color accentColor = primaryColor;
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
  static const Color mixedColor = Color(0xFF6366F1); // Indigo / Violet for Smart Practice

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
      Topic.mixed => Icons.auto_awesome_rounded,
    };
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Color(0xFF0F172A),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        indicatorColor: primaryColor.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBackground = Color(0xFF0F172A); // Slate 900
    const darkSurface = Color(0xFF1E293B); // Slate 800

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      surface: darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155), width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: primaryColor.withValues(alpha: 0.25),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
