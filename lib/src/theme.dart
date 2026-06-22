import 'package:flutter/material.dart';

const pearl = Color(0xFFF6F8FC);
const frost = Color(0xFFFFFFFF);
const blueMist = Color(0xFFE6F2FF);
const azure = Color(0xFF1E8FF5);
const deepBlue = Color(0xFF3155C6);
const gold = Color(0xFFD6A547);
const ink = Color(0xFF1A2332);
const mutedInk = Color(0xFF566378);

ThemeData buildMiniNanheTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: azure,
    brightness: Brightness.light,
    surface: frost,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: pearl,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: ink,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: ink, height: 1.4),
      bodySmall: TextStyle(color: mutedInk, height: 1.35),
      labelLarge: TextStyle(fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: frost,
      indicatorColor: blueMist,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected) ? deepBlue : mutedInk,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ),
  );
}
