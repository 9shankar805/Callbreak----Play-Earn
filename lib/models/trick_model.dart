import 'card_model.dart';

class TrickPlay {
  final int seat;
  final PlayingCard card;

  const TrickPlay({required this.seat, required this.card});

  Map<String, dynamic> toJson() => {'seat': seat, 'card': card.toJson()};

  factory TrickPlay.fromJson(Map<String, dynamic> j) => TrickPlay(
        seat: j['seat'] as int,
        card: PlayingCard.fromJson(j['card'] as Map<String, dynamic>),
      );
}

class CompletedTrick {
  final List<TrickPlay> plays;
  final int winnerSeat;

  const CompletedTrick({required this.plays, required this.winnerSeat});

  PlayingCard get winningCard =>
      plays.firstWhere((p) => p.seat == winnerSeat).card;

  Map<String, dynamic> toJson() => {
        'plays': plays.map((p) => p.toJson()).toList(),
        'winnerSeat': winnerSeat,
      };

  factory CompletedTrick.fromJson(Map<String, dynamic> j) => CompletedTrick(
        plays: (j['plays'] as List)
            .map((e) => TrickPlay.fromJson(e as Map<String, dynamic>))
            .toList(),
        winnerSeat: j['winnerSeat'] as int,
      );
}

class RoundResult {
  final int round;
  final List<int> bids;
  final List<int> tricksWon;
  final List<double> scores;
  final List<double> totalScores;

  const RoundResult({
    required this.round,
    required this.bids,
    required this.tricksWon,
    required this.scores,
    required this.totalScores,
  });

  Map<String, dynamic> toJson() => {
        'round': round,
        'bids': bids,
        'tricksWon': tricksWon,
        'scores': scores,
        'totalScores': totalScores,
      };

  factory RoundResult.fromJson(Map<String, dynamic> j) => RoundResult(
        round: j['round'] as int,
        bids: List<int>.from(j['bids'] as List),
        tricksWon: List<int>.from(j['tricksWon'] as List),
        scores: (j['scores'] as List).map((e) => (e as num).toDouble()).toList(),
        totalScores: (j['totalScores'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
      );
}
