import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Colour palette for Random Magic.
///
/// All colours are sourced from here — never hardcode hex values elsewhere.
abstract final class AppColors {
  // Backgrounds
  /// Deep navy — primary background colour.
  static const Color background = Color(0xFF1A1D2E);

  /// Slightly elevated surface — cards, bottom sheets, dialogs.
  static const Color surface = Color(0xFF252840);

  /// Raised surface — input fields, chips, secondary cards.
  static const Color surfaceContainer = Color(0xFF2F3250);

  // Accents
  /// Gold — primary accent, interactive elements, highlights.
  static const Color primary = Color(0xFFC9A84C);

  /// Amber — secondary accent, hover/pressed states.
  static const Color primaryVariant = Color(0xFFF0A500);

  // Content
  /// Near-white — primary text on dark backgrounds.
  static const Color onBackground = Color(0xFFE8E8E8);

  /// Muted — secondary text, captions, hints.
  static const Color onSurfaceMuted = Color(0xFF9E9EAE);

  // Semantic
  /// Error red.
  static const Color error = Color(0xFFCF6679);

  /// Blue-grey accent used for network-unreachable and rate-limit error states.
  static const Color networkError = Color(0xFF607D8B);

  /// Green — used for "Legal" legality badge in CardDetailScreen.
  /// Required by CLAUDE.md §No magic numbers — must not be hardcoded inline.
  static const Color legal = Color(0xFF4CAF50);
}

/// Provides the [ThemeData] for the Random Magic app.
///
/// Dark mode only — matches the card-game aesthetic described in RM-6.
abstract final class AppTheme {
  /// Returns the single dark [ThemeData] used throughout the app.
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.background,
      secondary: AppColors.primaryVariant,
      onSecondary: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.onBackground,
      error: AppColors.error,
      onError: AppColors.onBackground,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      // Use Flutter's built-in typography — no extra package needed.
      textTheme: const TextTheme(
        // Display styles — card names, screen titles
        displayMedium: TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        // Headline styles — section headers
        headlineMedium: TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w600,
        ),
        // Title styles — list items, card sub-headers
        titleMedium: TextStyle(
          color: AppColors.onBackground,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: AppColors.onSurfaceMuted,
        ),
        // Body styles — descriptions, flavour text
        bodyLarge: TextStyle(color: AppColors.onBackground),
        bodyMedium: TextStyle(color: AppColors.onBackground),
        bodySmall: TextStyle(color: AppColors.onSurfaceMuted),
        // Label styles — chips, badges, buttons
        labelLarge: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
        labelSmall: TextStyle(
          color: AppColors.onSurfaceMuted,
          letterSpacing: 0.4,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shadowColor: Colors.black54,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.onBackground),
      dividerColor: AppColors.surfaceContainer,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(borderSide: BorderSide.none),
        hintStyle: TextStyle(color: AppColors.onSurfaceMuted),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        labelStyle: TextStyle(color: AppColors.onBackground),
        side: BorderSide.none,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          shape: const StadiumBorder(),
        ),
      ),
      // Register dark shimmer palette globally so every Skeletonizer widget
      // picks up dark colours without requiring per-widget configuration.
      extensions: const [
        SkeletonizerConfigData.dark(),
      ],
    );
  }
}
