import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/card_model.dart';
import '../../models/player_model.dart';
import '../../models/trick_model.dart';
import '../../engine/callbreak_engine.dart';
import '../../services/sound_service.dart';
import '../../wallet/models/stake_level.dart';
import '../../wallet/services/wallet_service.dart';
import '../protocol/messages.dart';

// ── Connection state ──────────────────────────────────────────────────────────

enum OnlinePhase {
  idle,
  connecting,
  inQueue,         // waiting for matchmaking
  waitingRoom,     // private room — not yet full
  gameStart,       // server confirmed 4 players
  dealing,         // cards just received, brief pause
  bidding,         // human must bid
  waitingBid,      // waiting for other players to bid
  playing,         // human must play a card
  waitingPlay,     // waiting for other players
  trickReveal,     // trick just finished — brief pause
  roundEnd,
  gameOver,
  disconnected,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────

class OnlineGameController extends ChangeNotifier {
  // ── Config — change this to your deployed server URL ─────────────────────
  static const String _serverUrl = String.fromEnvironment(
    'WS_SERVER',
    defaultValue: 'ws://localhost:8080/ws',
  );

  // ── Connection ────────────────────────────────────────────────────────────
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  bool _disposed = false;

  // ── Public state ──────────────────────────────────────────────────────────
  OnlinePhase phase = OnlinePhase.idle;
  String errorMessage = '';
  String statusMessage = '';

  /// Your assigned seat (0–3).  Set on game_start.
  int localSeat = 0;

  /// Seats info received from waiting / game_start  {seat, name, avatar, empty}.
  List<Map<String, dynamic>> lobbySeats = [];

  /// Room code for private rooms.
  String roomCode = '';

  /// Stake level for this session.
  StakeLevel stake = StakeLevel.free;

  /// Matchmaking queue position.
  int queuePosition = 0;

  // ── In-game state ─────────────────────────────────────────────────────────
  List<Player> players = [];        // length 4, index == seat
  int currentRound = 0;
  int dealer = 0;

  List<PlayingCard> myHand = [];
  List<PlayingCard> legalMoves = [];
  PlayingCard? selectedCard;

  List<TrickPlay> currentTrick = [];
  int? trickWinnerSeat;

  List<double> totalScores = [0, 0, 0, 0];
  List<RoundResult> roundHistory = [];

  /// Suggested bid sent by server.
  int suggestedBid = 1;

  /// Emotes: seat → emoji string, auto-cleared after 3 s.
  final Map<int, String> activeEmotes = {};

  // ── Reveal timer ─────────────────────────────────────────────────────────
  Timer? _revealTimer;

  // ── Connect / disconnect ──────────────────────────────────────────────────

  Future<void> connect() async {
    if (_channel != null) return;
    phase = OnlinePhase.connecting;
    notifyListeners();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      await _channel!.ready;
      _sub = _channel!.stream.listen(
        _onRawMessage,
        onError: _onWsError,
        onDone:  _onWsDone,
        cancelOnError: true,
      );
    } catch (e) {
      _setError('Cannot reach server. Check your connection.');
    }
  }

  void disconnect() {
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    phase = OnlinePhase.idle;
    if (!_disposed) notifyListeners();
  }

  // ── Lobby actions ─────────────────────────────────────────────────────────

  void joinQueue(String displayName, String avatarPath, StakeLevel s) {
    stake = s;
    _send(encodeJoinQueue(displayName, avatarPath));
    phase = OnlinePhase.inQueue;
    notifyListeners();
  }

  void createPrivateRoom(String displayName, String avatarPath, [StakeLevel s = StakeLevel.free]) {
    stake = s;
    _send(encodeCreatePrivate(displayName, avatarPath));
  }

  void joinPrivateRoom(String displayName, String avatarPath, String code, [StakeLevel s = StakeLevel.free]) {
    stake = s;
    _send(encodeJoinPrivate(displayName, avatarPath, code.toUpperCase()));
  }

  // ── Game actions ──────────────────────────────────────────────────────────

  void placeBid(int bid) {
    if (phase != OnlinePhase.bidding) return;
    _send(encodePlaceBid(bid));
    phase = OnlinePhase.waitingBid;
    SoundService.instance.playWhoosh();
    notifyListeners();
  }

  void playCard(PlayingCard card) {
    if (phase != OnlinePhase.playing) return;
    if (!legalMoves.contains(card)) return;
    selectedCard = card;
    _send(encodePlayCard(card.wire));
    phase = OnlinePhase.waitingPlay;
    SoundService.instance.playCardSlide();
    notifyListeners();
  }

  void selectCard(PlayingCard card) {
    if (phase != OnlinePhase.playing) return;
    selectedCard = (selectedCard == card) ? null : card;
    SoundService.instance.playCardTap();
    notifyListeners();
  }

  void sendEmote(String emote) {
    _send(encodeSendEmote(emote));
  }

  // ── Message handler ───────────────────────────────────────────────────────

  void _onRawMessage(dynamic raw) {
    if (raw is! String) return;
    final event = parseServerMessage(raw);
    _handleEvent(event);
  }

  void _handleEvent(ServerEvent event) {
    switch (event.runtimeType) {
      case const (QueuedEvent):
        final e = event as QueuedEvent;
        queuePosition = e.position;
        phase = OnlinePhase.inQueue;
        statusMessage = 'Finding players… position #$queuePosition';

      case const (RoomCreatedEvent):
        final e = event as RoomCreatedEvent;
        roomCode = e.roomCode;
        phase = OnlinePhase.waitingRoom;
        statusMessage = 'Room created: ${e.roomCode}';

      case const (WaitingEvent):
        final e = event as WaitingEvent;
        lobbySeats = e.seats;
        phase = OnlinePhase.waitingRoom;
        final filled = e.seats.where((s) => s['empty'] != true).length;
        statusMessage = 'Waiting for players… $filled/4';

      case const (GameStartEvent):
        final e = event as GameStartEvent;
        localSeat = e.yourSeat;
        dealer    = e.dealer;
        lobbySeats = e.seats;
        _initPlayers(e.seats);
        phase = OnlinePhase.gameStart;
        statusMessage = 'Game starting!';
        SoundService.instance.playCardFan();
        // Deduct entry fee now that game is confirmed
        if (stake != StakeLevel.free) {
          WalletService().deductEntryFee(stake,
              roomNote: e.seats
                  .where((s) => s['seat'] != localSeat && s['empty'] != true)
                  .map((s) => s['name'] as String? ?? '')
                  .join(', '));
        }

      case const (DealHandEvent):
        final e = event as DealHandEvent;
        currentRound = e.round;
        dealer       = e.dealer;
        myHand = e.hand
            .map((j) => PlayingCard.fromJson(j))
            .toList();
        myHand = CallbreakEngine.sortHand(myHand);
        // Reset per-round state
        for (final p in players) {
          p.bid = null;
          p.tricksWon = 0;
        }
        currentTrick = [];
        trickWinnerSeat = null;
        selectedCard = null;
        legalMoves = [];
        phase = OnlinePhase.dealing;
        statusMessage = 'Round $currentRound — cards dealt';
        SoundService.instance.playCardFan();

      case const (BidPlacedEvent):
        final e = event as BidPlacedEvent;
        if (e.seat < players.length) players[e.seat].bid = e.bid;
        statusMessage = '${_name(e.seat)} bid ${e.bid}';
        // Stay in waitingBid; your_turn_bid will move us to bidding

      case const (YourTurnBidEvent):
        final e = event as YourTurnBidEvent;
        suggestedBid = e.suggestedBid;
        phase = OnlinePhase.bidding;
        statusMessage = 'Your turn to bid';

      case const (CardPlayedEvent):
        final e = event as CardPlayedEvent;
        final card = PlayingCard.fromWire(e.cardWire);
        currentTrick = [...currentTrick, TrickPlay(seat: e.seat, card: card)];
        // Remove from local hand if it's ours
        if (e.seat == localSeat) {
          myHand.removeWhere((c) => c == card);
          selectedCard = null;
        }
        statusMessage = '${_name(e.seat)} played ${card.id}';
        SoundService.instance.playCardSlide();
        if (phase == OnlinePhase.waitingPlay) {
          phase = OnlinePhase.waitingPlay; // stay until your_turn or trick_complete
        }

      case const (YourTurnPlayEvent):
        final e = event as YourTurnPlayEvent;
        legalMoves = e.legalMoves.map(PlayingCard.fromWire).toList();
        phase = OnlinePhase.playing;
        statusMessage = 'Your turn to play';

      case const (TrickCompleteEvent):
        final e = event as TrickCompleteEvent;
        trickWinnerSeat = e.winnerSeat;
        for (int i = 0; i < players.length; i++) {
          players[i].tricksWon = e.tricksWon[i];
        }
        phase = OnlinePhase.trickReveal;
        statusMessage = '${_name(e.winnerSeat)} wins the trick!';
        SoundService.instance.playTrickWin();
        _revealTimer?.cancel();
        _revealTimer = Timer(const Duration(milliseconds: 1200), () {
          if (!_disposed) {
            currentTrick = [];
            trickWinnerSeat = null;
            if (phase == OnlinePhase.trickReveal) {
              phase = OnlinePhase.waitingPlay;
            }
            notifyListeners();
          }
        });

      case const (RoundEndEvent):
        final e = event as RoundEndEvent;
        final result = RoundResult.fromJson(e.result);
        roundHistory.add(result);
        totalScores = List<double>.from(result.totalScores);
        phase = OnlinePhase.roundEnd;
        statusMessage = 'Round $currentRound complete!';
        SoundService.instance.playWin();

      case const (GameOverEvent):
        final e = event as GameOverEvent;
        final result = RoundResult.fromJson(e.result);
        if (roundHistory.isEmpty || roundHistory.last.round != result.round) {
          roundHistory.add(result);
        }
        totalScores = List<double>.from(result.totalScores);
        phase = OnlinePhase.gameOver;
        statusMessage = '${_name(e.winnerSeat)} wins the game!';

        // Wallet: credit winnings or record loss
        if (stake != StakeLevel.free) {
          final opponents = players
              .where((p) => p.seat != localSeat)
              .map((p) => p.name)
              .join(', ');
          if (e.winnerSeat == localSeat) {
            WalletService().creditWinnings(stake, opponents: opponents);
            SoundService.instance.playWin();
          } else {
            WalletService().recordLoss(stake);
            SoundService.instance.playLose();
          }
        } else {
          SoundService.instance.playWin();
        }

      case const (EmoteEvent):
        final e = event as EmoteEvent;
        activeEmotes[e.seat] = e.emote;
        Timer(const Duration(seconds: 3), () {
          if (!_disposed && activeEmotes[e.seat] == e.emote) {
            activeEmotes.remove(e.seat);
            notifyListeners();
          }
        });

      case const (PingEvent):
        _send(encodePong());
        return; // no UI update needed

      case const (ErrorEvent):
        final e = event as ErrorEvent;
        errorMessage = e.message;
        phase = OnlinePhase.error;

      default:
        return;
    }

    if (!_disposed) notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _initPlayers(List<Map<String, dynamic>> seats) {
    players = List.generate(4, (i) {
      final s = seats.firstWhere(
        (e) => e['seat'] == i,
        orElse: () => {'seat': i, 'empty': true, 'name': 'Player ${i + 1}', 'avatar': ''},
      );
      return Player(
        seat:       i,
        name:       (s['name'] as String?) ?? 'Player ${i + 1}',
        type:       i == localSeat ? PlayerType.human : PlayerType.bot,
        avatarPath: (s['avatar'] as String?) ?? '',
      );
    });
    totalScores = [0, 0, 0, 0];
    roundHistory = [];
  }

  String _name(int seat) =>
      seat < players.length ? players[seat].name : 'Player ${seat + 1}';

  void _send(String msg) {
    try {
      _channel?.sink.add(msg);
    } catch (_) {}
  }

  void _onWsError(dynamic err) {
    _setError('Connection error: $err');
  }

  void _onWsDone() {
    if (phase != OnlinePhase.gameOver) {
      _setError('Disconnected from server.');
    }
    phase = OnlinePhase.disconnected;
    if (!_disposed) notifyListeners();
  }

  void _setError(String msg) {
    errorMessage = msg;
    phase = OnlinePhase.error;
    if (!_disposed) notifyListeners();
  }

  // ── Computed helpers for UI ───────────────────────────────────────────────

  bool get isMyTurn =>
      phase == OnlinePhase.playing || phase == OnlinePhase.bidding;

  Player? get localPlayer =>
      players.isNotEmpty ? players[localSeat] : null;

  /// Maps server seat → display position relative to localSeat.
  /// Position 0 = bottom (you), 1 = right, 2 = top, 3 = left.
  int displayPosition(int serverSeat) =>
      (serverSeat - localSeat + 4) % 4;

  @override
  void dispose() {
    _disposed = true;
    _revealTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
