import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/trick_model.dart';
import '../engine/callbreak_engine.dart';
import '../ai/bot_ai.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';

enum GamePhase {
  idle,
  dealing,
  bidding,
  playing,
  trickReveal,
  roundEnd,
  gameOver,
}

class GameController extends ChangeNotifier {
  static const int totalRounds = 5;

  // ── Speed-aware delay getters (respect gameSpeed setting) ──────────────────
  double get _speedMultiplier {
    switch (gameSpeed) {
      case 'Slow': return 1.8;
      case 'Fast': return 0.45;
      default:     return 1.0; // Normal
    }
  }

  Duration get botBidDelay      => Duration(milliseconds: (700  * _speedMultiplier).round());
  Duration get botPlayDelay     => Duration(milliseconds: (900  * _speedMultiplier).round());
  Duration get trickRevealDelay => Duration(milliseconds: (1200 * _speedMultiplier).round());
  Duration get roundEndDelay    => Duration(milliseconds: (3000 * _speedMultiplier).round());
  Duration get dealingDelay     => Duration(milliseconds: (1400 * _speedMultiplier).round());

  // ── State ────────────────────────────────────────────────────────────────────
  List<Player> players = Player.createDefault();
  GamePhase phase = GamePhase.idle;
  int currentRound = 0;
  int dealer = 2; // seat 2 (bot3) is dealer for round 1 (matching Screenshot 3)
  int turnSeat = 0;

  List<TrickPlay> currentTrick = [];
  List<CompletedTrick> tricksLog = [];
  int? trickWinnerSeat; // set during reveal phase

  List<double> totalScores = [0, 0, 0, 0];
  List<RoundResult> roundHistory = [];

  String statusMessage = '';
  GameThemeMode currentTheme = GameThemeMode.classicWood;
  final Map<int, String> activeEmotes = {};
  bool _disposed = false;
  Timer? _dealingTimer;

  // Settings from official UI
  bool showMiniScoreboard = false;
  bool suggestBid = true;
  bool highlightValidCards = true;
  bool touchToThrow = true;
  String gameSpeed = 'Normal'; // 'Slow', 'Normal', 'Fast'
  bool musicEnabled = true;

  void setTheme(GameThemeMode theme) {
    currentTheme = theme;
    SoundService.instance.playButtonClick();
    notifyListeners();
  }

  void toggleSound() {
    SoundService.instance.toggleMute();
    notifyListeners();
  }

  void toggleMusic() {
    musicEnabled = !musicEnabled;
    SoundService.instance.playButtonClick();
    notifyListeners();
  }

  void toggleMiniScoreboard() {
    showMiniScoreboard = !showMiniScoreboard;
    SoundService.instance.playButtonClick();
    notifyListeners();
  }

  void toggleSuggestBid() {
    suggestBid = !suggestBid;
    SoundService.instance.playButtonClick();
    notifyListeners();
  }

  void toggleHighlightValidCards() {
    highlightValidCards = !highlightValidCards;
    SoundService.instance.playButtonClick();
    notifyListeners();
  }

  void toggleTouchToThrow() {
    touchToThrow = !touchToThrow;
    SoundService.instance.playButtonClick();
    notifyListeners();
  }

  void setGameSpeed(String speed) {
    gameSpeed = speed;
    SoundService.instance.playButtonClick();
    notifyListeners();
  }

  void setHumanAvatar(String avatarPath) {
    if (players.isNotEmpty) {
      players[0].avatarPath = avatarPath;
      SoundService.instance.playCardTap();
      notifyListeners();
    }
  }

  void setHumanName(String name) {
    if (players.isNotEmpty) {
      players[0].name = name;
      notifyListeners();
    }
  }

  void sendEmote(int seat, String emote) {
    activeEmotes[seat] = emote;
    notifyListeners();
    Timer(const Duration(seconds: 3), () {
      if (!_disposed && activeEmotes[seat] == emote) {
        activeEmotes.remove(seat);
        notifyListeners();
      }
    });
  }

  int get hintBid {
    return BotAI.estimateWins(humanPlayer.hand).clamp(1, 8);
  }

  // ── Public helpers ───────────────────────────────────────────────────────────
  Player get humanPlayer => players[0];
  Player get currentPlayer => players[turnSeat];

  List<int?> get currentBids => players.map((p) => p.bid).toList();
  List<int> get currentTricksWon => players.map((p) => p.tricksWon).toList();

  List<PlayingCard> get legalMoves {
    if (phase != GamePhase.playing || turnSeat != 0) return [];
    return CallbreakEngine.getLegalMoves(humanPlayer.hand, currentTrick);
  }

  List<int> get legalBids {
    if (phase != GamePhase.bidding || turnSeat != 0) return [];
    return CallbreakEngine.legalBids(currentBids);
  }

  bool get isHumanTurn =>
      (phase == GamePhase.bidding || phase == GamePhase.playing) &&
      turnSeat == 0;

  // ── Game flow ────────────────────────────────────────────────────────────────

  void startGame({bool animateDealing = false}) {
    SoundService.instance.startTableMusic();
    players = Player.createDefault();
    totalScores = [0, 0, 0, 0];
    roundHistory = [];
    currentRound = 0;
    dealer = 2; // seat 2 (bot3) is dealer for round 1
    phase = GamePhase.idle;
    _startRound(animateDealing: animateDealing);
  }

  void _startRound({bool animateDealing = false}) {
    currentRound++;
    final hands = CallbreakEngine.dealHands();
    for (int i = 0; i < 4; i++) {
      players[i].hand = List.from(hands[i]);
      players[i].bid = null;
      players[i].tricksWon = 0;
    }
    currentTrick = [];
    tricksLog = [];
    trickWinnerSeat = null;

    if (animateDealing) {
      phase = GamePhase.dealing;
      statusMessage = 'Dealing cards...';
      SoundService.instance.playCardFan();
      notifyListeners();

      _dealingTimer?.cancel();
      _dealingTimer = Timer(dealingDelay, () {
        if (!_disposed && phase == GamePhase.dealing) {
          finishDealing();
        }
      });
    } else {
      finishDealing();
    }
  }

  /// Completes dealing immediately (or when skipped by user tap)
  void finishDealing() {
    _dealingTimer?.cancel();
    _dealingTimer = null;
    phase = GamePhase.bidding;
    turnSeat = (dealer + 1) % 4; // bidding starts left of dealer
    statusMessage = 'Round $currentRound — Place your bids';
    SoundService.instance.playCardFan();
    notifyListeners();
    _advanceBotBid();
  }

  // ── Bidding ──────────────────────────────────────────────────────────────────

  void humanBid(int value) {
    if (phase != GamePhase.bidding) return;
    players[0].bid = value;
    SoundService.instance.playWhoosh();
    if (turnSeat == 0) {
      _advanceBidTurn();
    } else {
      notifyListeners();
    }
  }

  void _advanceBotBid() {
    if (phase != GamePhase.bidding) return;
    if (turnSeat == 0) {
      if (players[0].bid != null) {
        _advanceBidTurn();
      }
      return; // wait for human
    }
    _scheduleBotAction(botBidDelay, () {
      final bot = players[turnSeat];
      bot.bid = BotAI.chooseBid(bot.hand, currentBids);
      _advanceBidTurn();
    });
  }

  void _advanceBidTurn() {
    final allBid = players.every((p) => p.bid != null);
    if (allBid) {
      phase = GamePhase.playing;
      turnSeat = (dealer + 1) % 4; // player after dealer leads first trick
      statusMessage = 'Playing — ${players[turnSeat].name}\'s turn';
      notifyListeners();
      _advanceBotPlay();
    } else {
      turnSeat = (turnSeat + 1) % 4;
      notifyListeners();
      if (turnSeat == 0 && players[0].bid != null) {
        _advanceBidTurn();
      } else {
        _advanceBotBid();
      }
    }
  }

  // ── Playing ──────────────────────────────────────────────────────────────────

  void humanPlayCard(PlayingCard card) {
    if (phase != GamePhase.playing || turnSeat != 0) return;
    if (!CallbreakEngine.isMoveLegal(humanPlayer.hand, currentTrick, card)) return;
    _playCard(0, card);
  }

  void _advanceBotPlay() {
    if (phase != GamePhase.playing) return;
    if (turnSeat == 0) return; // wait for human
    _scheduleBotAction(botPlayDelay, () {
      final bot = players[turnSeat];
      final card = BotAI.chooseCard(
        hand: bot.hand,
        currentTrick: currentTrick,
        bid: bot.bid ?? 1,
        tricksWon: bot.tricksWon,
      );
      _playCard(turnSeat, card);
    });
  }

  void _playCard(int seat, PlayingCard card) {
    players[seat].hand.removeWhere((c) => c == card);
    currentTrick = [...currentTrick, TrickPlay(seat: seat, card: card)];
    SoundService.instance.playCardSlide();

    if (currentTrick.length == 4) {
      // All 4 played — reveal then resolve
      phase = GamePhase.trickReveal;
      trickWinnerSeat = CallbreakEngine.determineTrickWinner(currentTrick);
      statusMessage = '${players[trickWinnerSeat!].name} wins the trick!';
      notifyListeners();
      _scheduleBotAction(trickRevealDelay, _finishTrick);
    } else {
      turnSeat = (turnSeat + 1) % 4;
      statusMessage = '${players[turnSeat].name}\'s turn';
      notifyListeners();
      _advanceBotPlay();
    }
  }

  void _finishTrick() {
    final winner = trickWinnerSeat!;
    players[winner].tricksWon++;
    SoundService.instance.playTrickWin();
    tricksLog.add(CompletedTrick(
      plays: List.from(currentTrick),
      winnerSeat: winner,
    ));
    currentTrick = [];
    trickWinnerSeat = null;
    phase = GamePhase.playing;
    turnSeat = winner;

    // Check if round is over (all hands empty)
    if (players[0].hand.isEmpty) {
      _finishRound();
    } else {
      statusMessage = '${players[turnSeat].name}\'s turn';
      notifyListeners();
      _advanceBotPlay();
    }
  }

  void _finishRound() {
    final scores = CallbreakEngine.scoreRound(currentBids, currentTricksWon);
    for (int i = 0; i < 4; i++) {
      totalScores[i] = _round1dp(totalScores[i] + scores[i]);
    }
    roundHistory.add(RoundResult(
      round: currentRound,
      bids: currentBids.map((b) => b ?? 0).toList(),
      tricksWon: List.from(currentTricksWon),
      scores: scores,
      totalScores: List.from(totalScores),
    ));
    phase = GamePhase.roundEnd;
    statusMessage = 'Round $currentRound complete!';
    SoundService.instance.playWin();
    notifyListeners();

    if (currentRound >= totalRounds) {
      _scheduleBotAction(roundEndDelay, () {
        phase = GamePhase.gameOver;
        statusMessage = 'Game Over!';
        SoundService.instance.stopMusic();
        // Play win or lose sound based on whether human player won
        final maxScore = totalScores.reduce(max);
        if (totalScores[0] == maxScore) {
          SoundService.instance.playWin();
        } else {
          SoundService.instance.playLose();
        }
        notifyListeners();
      });
    } else {
      _scheduleBotAction(roundEndDelay, () {
        dealer = (dealer + 1) % 4;
        _startRound(animateDealing: true);
      });
    }
  }

  // ── Utilities ────────────────────────────────────────────────────────────────

  void restartGame({bool animateDealing = false}) =>
      startGame(animateDealing: animateDealing);

  double _round1dp(double v) => (v * 10).round() / 10.0;

  Timer? _pendingTimer;

  void _scheduleBotAction(Duration delay, VoidCallback action) {
    _pendingTimer?.cancel();
    _pendingTimer = Timer(delay, () {
      if (!_disposed) action();
    });
  }

  /// Seat label relative to human (seat 0 = bottom)
  String seatLabel(int seat) => players[seat].name;

  /// Winner(s) of the game — highest total score
  List<Player> get winners {
    final maxScore = totalScores.reduce(max);
    return players.where((p) => totalScores[p.seat] == maxScore).toList();
  }

  @override
  void dispose() {
    _disposed = true;
    _dealingTimer?.cancel();
    _pendingTimer?.cancel();
    super.dispose();
  }
}
