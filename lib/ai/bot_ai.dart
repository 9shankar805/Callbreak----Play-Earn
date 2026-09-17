import '../models/card_model.dart';
import '../models/trick_model.dart';
import '../engine/callbreak_engine.dart';

/// Bot AI — smart bidding + smart card play.
class BotAI {
  // ── Bidding ──────────────────────────────────────────────────────────────────

  /// Estimate how many tricks this hand can win.
  static int estimateWins(List<PlayingCard> hand) {
    int estimate = 0;
    final spades = hand.where((c) => c.suit == Suit.spades).toList();
    for (final c in spades) {
      if (c.rank == Rank.ace) {
        estimate += 1;
      } else if (c.rank == Rank.king) {
        estimate += 1;
      } else if (c.rank == Rank.queen) {
        estimate += 1;
      } else if (c.rank.value >= Rank.ten.value) {
        estimate += 1;
      }
    }
    if (spades.length >= 4) estimate += 1;
    for (final suit in [Suit.clubs, Suit.hearts, Suit.diamonds]) {
      final suitCards = hand.where((c) => c.suit == suit).toList();
      final hasAce = suitCards.any((c) => c.rank == Rank.ace);
      final hasKing = suitCards.any((c) => c.rank == Rank.king);
      if (hasAce) estimate += 1;
      if (hasKing && !hasAce) estimate += 1;
    }
    return estimate.clamp(1, CallbreakEngine.maxBid);
  }

  /// Pick the best legal bid for a bot.
  static int chooseBid(List<PlayingCard> hand, List<int?> bidsSoFar) {
    final estimate = estimateWins(hand);
    final legal = CallbreakEngine.legalBids(bidsSoFar);
    int best = legal.first;
    int bestDiff = (estimate - best).abs();
    for (final v in legal) {
      final diff = (estimate - v).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = v;
      }
    }
    return best;
  }

  // ── Card play ────────────────────────────────────────────────────────────────

  /// Choose which card a bot plays.
  static PlayingCard chooseCard({
    required List<PlayingCard> hand,
    required List<TrickPlay> currentTrick,
    required int bid,
    required int tricksWon,
  }) {
    final legal = CallbreakEngine.getLegalMoves(hand, currentTrick);
    if (legal.length == 1) return legal.first;
    final needMore = tricksWon < bid;
    if (currentTrick.isEmpty) {
      return _lead(legal, needMore);
    } else {
      return _follow(legal, currentTrick, needMore);
    }
  }

  /// Leading strategy: lead high if need tricks, otherwise dump low.
  static PlayingCard _lead(List<PlayingCard> legal, bool needMore) {
    if (needMore) {
      final trumps = legal.where((c) => c.isTrump).toList()
        ..sort((a, b) => b.rank.value - a.rank.value);
      if (trumps.isNotEmpty && trumps.first.rank.value >= Rank.queen.value) {
        return trumps.first;
      }
      final highCards = legal
          .where((c) => !c.isTrump && c.rank.value >= Rank.king.value)
          .toList()
        ..sort((a, b) => b.rank.value - a.rank.value);
      if (highCards.isNotEmpty) return highCards.first;
      return (List<PlayingCard>.from(legal)
            ..sort((a, b) => b.rank.value - a.rank.value))
          .first;
    } else {
      return (List<PlayingCard>.from(legal)
            ..sort((a, b) => a.rank.value - b.rank.value))
          .first;
    }
  }

  /// Following strategy: win cheaply if needed, otherwise dump lowest.
  static PlayingCard _follow(
      List<PlayingCard> legal, List<TrickPlay> trick, bool needMore) {
    // Which of our legal cards would currently win the trick?
    final canWin = legal.where((card) {
      final hypo = [...trick, TrickPlay(seat: 999, card: card)];
      return CallbreakEngine.determineTrickWinner(hypo) == 999;
    }).toList();

    if (needMore && canWin.isNotEmpty) {
      // Win with the cheapest winning card
      canWin.sort((a, b) => a.rank.value - b.rank.value);
      return canWin.first;
    } else {
      // Discard lowest, prefer non-trump
      final sorted = List<PlayingCard>.from(legal)
        ..sort((a, b) => a.rank.value - b.rank.value);
      final nonTrump = sorted.where((c) => !c.isTrump).toList();
      return nonTrump.isNotEmpty ? nonTrump.first : sorted.first;
    }
  }
}
