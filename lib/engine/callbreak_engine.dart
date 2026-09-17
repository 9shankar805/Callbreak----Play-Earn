import 'dart:math';
import '../models/card_model.dart';
import '../models/trick_model.dart';

/// Pure game logic — no Flutter, no state, no I/O.
/// Ported faithfully from divi-bry/callbreak engine.js
class CallbreakEngine {
  static const int totalRounds = 5;
  static const int maxBid = 10;
  static const Suit trumpSuit = Suit.spades;

  // ── Deck ────────────────────────────────────────────────────────────────────

  static List<PlayingCard> createDeck() {
    final deck = <PlayingCard>[];
    for (final suit in Suit.values) {
      for (final rank in Rank.values) {
        deck.add(PlayingCard(suit: suit, rank: rank));
      }
    }
    return deck;
  }

  static List<PlayingCard> shuffle(List<PlayingCard> deck, [Random? rng]) {
    final r = rng ?? Random();
    final arr = List<PlayingCard>.from(deck);
    for (int i = arr.length - 1; i > 0; i--) {
      final j = r.nextInt(i + 1);
      final tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
    return arr;
  }

  /// Sort hand matching Callbreak UI: Spades (trump) first, then Hearts, Clubs, Diamonds, high→low
  static List<PlayingCard> sortHand(List<PlayingCard> cards) {
    const order = [Suit.spades, Suit.hearts, Suit.clubs, Suit.diamonds];
    final sorted = List<PlayingCard>.from(cards);
    sorted.sort((a, b) {
      final si = order.indexOf(a.suit) - order.indexOf(b.suit);
      if (si != 0) return si;
      return b.rank.value - a.rank.value; // High to low
    });
    return sorted;
  }

  /// Deal 13 cards to each of 4 seats
  static List<List<PlayingCard>> dealHands([Random? rng]) {
    final deck = shuffle(createDeck(), rng);
    final hands = List.generate(4, (_) => <PlayingCard>[]);
    for (int i = 0; i < 52; i++) {
      hands[i % 4].add(deck[i]);
    }
    return hands.map(sortHand).toList();
  }

  // ── Bidding ──────────────────────────────────────────────────────────────────

  /// Returns legal bid values for the next bidder (1 to maxBid).
  static List<int> legalBids(List<int?> bidsSoFar) {
    return List.generate(maxBid, (i) => i + 1);
  }

  static bool isLegalBid(List<int?> bidsSoFar, int value) {
    return value >= 1 && value <= maxBid;
  }

  // ── Legal moves ──────────────────────────────────────────────────────────────

  /// Returns the subset of hand that is legal to play given trick so far.
  ///
  /// Standard Callbreak Rules:
  /// 1. Leading (empty trick) → any card in hand can be led.
  /// 2. Must follow suit: If you have cards of the led suit, you can play ANY card of that suit.
  /// 3. Void in led suit: If you have NO cards of the led suit, you can play ANY card (trump with Spade or discard).
  static List<PlayingCard> getLegalMoves(
      List<PlayingCard> hand, List<TrickPlay> trick) {
    if (trick.isEmpty) return List.from(hand);

    final leadSuit = trick.first.card.suit;
    final followers = hand.where((c) => c.suit == leadSuit).toList();
    if (followers.isNotEmpty) {
      return followers;
    }
    return List.from(hand);
  }

  static bool isMoveLegal(
      List<PlayingCard> hand, List<TrickPlay> trick, PlayingCard card) {
    return getLegalMoves(hand, trick).contains(card);
  }

  // ── Trick winner ─────────────────────────────────────────────────────────────

  static int determineTrickWinner(List<TrickPlay> trick) {
    if (trick.isEmpty) return 0;
    final leadSuit = trick.first.card.suit;
    final trumps = trick.where((t) => t.card.suit == trumpSuit).toList();
    final pool = trumps.isNotEmpty
        ? trumps
        : trick.where((t) => t.card.suit == leadSuit).toList();
    if (pool.isEmpty) return trick.first.seat;
    var winner = pool.first;
    for (final t in pool) {
      if (t.card.rank.value > winner.card.rank.value) winner = t;
    }
    return winner.seat;
  }

  // ── Scoring ──────────────────────────────────────────────────────────────────

  /// Made bid: +bid + 0.1 per overtrick.  Missed: -bid.
  static List<double> scoreRound(List<int?> bids, List<int> tricksWon) {
    return List.generate(4, (i) {
      final bid = bids[i]!;
      final won = tricksWon[i];
      if (won >= bid) {
        final over = won - bid;
        return _round1dp(bid + over * 0.1);
      }
      return -bid.toDouble();
    });
  }

  static double _round1dp(double v) => (v * 10).round() / 10.0;
}
