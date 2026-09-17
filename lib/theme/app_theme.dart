import 'package:flutter/material.dart';

enum GameThemeMode {
  desert('Desert Dunes', 'assets/images/desert_bg.png'),
  autumn('Autumn Forest', 'assets/images/autumn_bg.png'),
  cricket('Cricket Stadium', 'assets/images/cricket_bg.png'),
  classicWood('Classic Wood', 'assets/images/wood_bg.png');

  final String label;
  final String assetPath;
  const GameThemeMode(this.label, this.assetPath);
}

class AppTheme {
  // Callbreak.com signature palette
  static const Color headerGold    = Color(0xFFF5BB68);
  static const Color headerBorder  = Color(0xFFFED875);
  static const Color woodDark     = Color(0xFF3E1F0D);
  static const Color woodMid      = Color(0xFF7A4522);
  static const Color woodLight    = Color(0xFFBA7A42);

  // Modals & Panels (Bidding & Scoreboard)
  static const Color creamCardBg   = Color(0xFFFFF7E6);
  static const Color creamBorder   = Color(0xFFE8D4B0);
  static const Color textDarkBrown = Color(0xFF4A2A18);
  static const Color scoreGreenRow = Color(0xFFEDF7BE);
  static const Color scoreGreenText = Color(0xFF388E3C);
  static const Color goldAccent   = Color(0xFFF5BB68);

  // Action Buttons
  static const Color confirmGreen = Color(0xFF2EB846);
  static const Color activeTurnNeon = Color(0xFF76FF03);
  static const Color darkPillBg   = Color(0xFF2D160C);

  // Card colors
  static const Color cardFace     = Color(0xFFFFFFFF);
  static const Color cardBack     = Color(0xFFB71C1C); // Red patterned card back
  static const Color redSuit      = Color(0xFFD32F2F);
  static const Color blackSuit    = Color(0xFF1E1E24);

  // Status & Scores
  static const Color scorePositive = Color(0xFF2E7D32);
  static const Color scoreNegative = Color(0xFFD32F2F);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: headerGold,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: woodDark,
  );
}

