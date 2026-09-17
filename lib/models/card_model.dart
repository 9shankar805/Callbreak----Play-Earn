import 'package:flutter/material.dart';

enum Suit { clubs, diamonds, hearts, spades }

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

extension SuitExt on Suit {
  String get symbol {
    switch (this) {
      case Suit.clubs: return '♣';
      case Suit.diamonds: return '♦';
      case Suit.hearts: return '♥';
      case Suit.spades: return '♠';
    }
  }

  String get letter {
    switch (this) {
      case Suit.clubs: return 'C';
      case Suit.diamonds: return 'D';
      case Suit.hearts: return 'H';
      case Suit.spades: return 'S';
    }
  }

  String get name {
    switch (this) {
      case Suit.clubs: return 'Clubs';
      case Suit.diamonds: return 'Diamonds';
      case Suit.hearts: return 'Hearts';
      case Suit.spades: return 'Spades';
    }
  }

  Color get color {
    switch (this) {
      case Suit.clubs: return const Color(0xFF1a1a2e);
      case Suit.diamonds: return const Color(0xFFe63946);
      case Suit.hearts: return const Color(0xFFe63946);
      case Suit.spades: return const Color(0xFF1a1a2e);
    }
  }

  bool get isRed => this == Suit.diamonds || this == Suit.hearts;
}

extension RankExt on Rank {
  int get value {
    switch (this) {
      case Rank.two: return 2;
      case Rank.three: return 3;
      case Rank.four: return 4;
      case Rank.five: return 5;
      case Rank.six: return 6;
      case Rank.seven: return 7;
      case Rank.eight: return 8;
      case Rank.nine: return 9;
      case Rank.ten: return 10;
      case Rank.jack: return 11;
      case Rank.queen: return 12;
      case Rank.king: return 13;
      case Rank.ace: return 14;
    }
  }

  String get display {
    switch (this) {
      case Rank.two: return '2';
      case Rank.three: return '3';
      case Rank.four: return '4';
      case Rank.five: return '5';
      case Rank.six: return '6';
      case Rank.seven: return '7';
      case Rank.eight: return '8';
      case Rank.nine: return '9';
      case Rank.ten: return '10';
      case Rank.jack: return 'J';
      case Rank.queen: return 'Q';
      case Rank.king: return 'K';
      case Rank.ace: return 'A';
    }
  }
}

class PlayingCard {
  final Suit suit;
  final Rank rank;

  const PlayingCard({required this.suit, required this.rank});

  String get id => '${rank.display}${suit.letter}';

  String get assetPath => 'assets/cards/${id.toLowerCase()}.png';

  bool get isTrump => suit == Suit.spades;

  // ── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'suit': suit.index,
        'rank': rank.index,
      };

  factory PlayingCard.fromJson(Map<String, dynamic> j) => PlayingCard(
        suit: Suit.values[j['suit'] as int],
        rank: Rank.values[j['rank'] as int],
      );

  /// Compact string encoding used in WebSocket messages, e.g. "S-12" (spades queen).
  String get wire => '${suit.index}-${rank.index}';

  static PlayingCard fromWire(String s) {
    final parts = s.split('-');
    return PlayingCard(
      suit: Suit.values[int.parse(parts[0])],
      rank: Rank.values[int.parse(parts[1])],
    );
  }

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) =>
      other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);
}
