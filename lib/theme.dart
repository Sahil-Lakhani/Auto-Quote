import 'package:flutter/material.dart';

// Modern Vibrant Color Palette
const kBackgroundColor = Color.fromARGB(255, 250, 250, 251); // soft off-white
const kCardColor = Color(0xFFFFFFFF); // clean white
const kInputFillColor = Color(0xFFF9FAFB); // subtle grey
const kPrimaryTextColor = Color(0xFF1E293B); // slate dark
const kSecondaryTextColor = Color(0xFF64748B); // slate grey
const kAccentColor = Color(0xFF6366F1); // indigo
const kSuccessColor = Color(0xFF10B981); // emerald
const kWarningColor = Color(0xFFF59E0B); // amber
const kToggleOffColor = Color(0xFFCBD5E1); // muted cool gray

final appTheme = ThemeData(
  scaffoldBackgroundColor: kBackgroundColor,
  cardColor: kCardColor,
  primaryColor: kAccentColor,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: kAccentColor,
    secondary: kAccentColor,
    surface: kBackgroundColor,
    error: kWarningColor,
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: kPrimaryTextColor),
    bodyMedium: TextStyle(color: kPrimaryTextColor),
    bodySmall: TextStyle(color: kSecondaryTextColor),
    titleLarge: TextStyle(
      color: kPrimaryTextColor,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    color: kCardColor,
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    shadowColor: Colors.black.withValues(alpha: 0.08),
    // shadowColor: Colors.black.withOpacity(0.08),
    // Keeps cards truly white under Material 3 (disables elevation tint)
    surfaceTintColor: Colors.transparent,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return kAccentColor;
      return Colors.white;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return kAccentColor.withValues(alpha: 0.6);
      }
      return kToggleOffColor;
    }),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kInputFillColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: kSecondaryTextColor.withValues(alpha: 0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: kSecondaryTextColor.withValues(alpha: 0.2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: kAccentColor, width: 2),
    ),
    hintStyle: const TextStyle(color: kSecondaryTextColor),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kCardColor,
    foregroundColor: kPrimaryTextColor,
    elevation: 1,
    iconTheme: IconThemeData(color: kAccentColor),
    titleTextStyle: TextStyle(
      color: kPrimaryTextColor,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kAccentColor,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);
