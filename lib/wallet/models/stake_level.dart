import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Stake levels — defines room tiers, entry fees, and pot structure.
//
//  Economy design:
//    entry × 4 players = total pot
//    winner gets pot × (1 - platformCut)
//    platform keeps pot × platformCut  (15%)
//    so: win = entry × 4 × 0.85  →  net gain = entry × 2.4
// ─────────────────────────────────────────────────────────────────────────────

const double kPlatformCut = 0.15; // 15% rake — industry standard

enum StakeLevel {
  free,
  bronze,
  silver,
  gold,
  platinum,
}

extension StakeLevelExt on StakeLevel {
  String get label {
    switch (this) {
      case StakeLevel.free:     return 'Free';
      case StakeLevel.bronze:   return 'Bronze';
      case StakeLevel.silver:   return 'Silver';
      case StakeLevel.gold:     return 'Gold';
      case StakeLevel.platinum: return 'Platinum';
    }
  }

  /// Coins required to join this room.
  int get entryFee {
    switch (this) {
      case StakeLevel.free:     return 0;
      case StakeLevel.bronze:   return 50;
      case StakeLevel.silver:   return 200;
      case StakeLevel.gold:     return 500;
      case StakeLevel.platinum: return 2000;
    }
  }

  /// Total pot (4 × entry).
  int get totalPot => entryFee * 4;

  /// Coins winner receives after platform cut.
  int get winnerPayout =>
      (totalPot * (1 - kPlatformCut)).floor();

  /// Net gain for winner (payout − own entry).
  int get netGain => winnerPayout - entryFee;

  /// Minimum balance required to enter (2× entry as safety buffer).
  int get minBalance => entryFee * 2;

  String get emoji {
    switch (this) {
      case StakeLevel.free:     return '🆓';
      case StakeLevel.bronze:   return '🥉';
      case StakeLevel.silver:   return '🥈';
      case StakeLevel.gold:     return '🥇';
      case StakeLevel.platinum: return '💎';
    }
  }

  Color get color {
    switch (this) {
      case StakeLevel.free:     return const Color(0xFF78909C);
      case StakeLevel.bronze:   return const Color(0xFFCD7F32);
      case StakeLevel.silver:   return const Color(0xFF9E9E9E);
      case StakeLevel.gold:     return const Color(0xFFFFB300);
      case StakeLevel.platinum: return const Color(0xFF00BCD4);
    }
  }

  Color get bgColor {
    switch (this) {
      case StakeLevel.free:     return const Color(0xFF263238);
      case StakeLevel.bronze:   return const Color(0xFF3E2200);
      case StakeLevel.silver:   return const Color(0xFF2E2E2E);
      case StakeLevel.gold:     return const Color(0xFF3D2E00);
      case StakeLevel.platinum: return const Color(0xFF003040);
    }
  }

  String get description {
    if (this == StakeLevel.free) {
      return 'Practice for free — no coins at stake';
    }
    return 'Entry: $entryFee coins  •  Win: $winnerPayout coins  •  Net +$netGain coins';
  }

  /// Wire string for WebSocket protocol.
  String get wire => index.toString();

  static StakeLevel fromWire(String s) =>
      StakeLevel.values[int.parse(s)];
}
