import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/card_model.dart';
import '../../models/trick_model.dart';
import '../../widgets/playing_card_widget.dart';
import '../../widgets/animated_card_throw.dart';
import '../../widgets/trick_sweep_overlay.dart';
import '../../services/sound_service.dart';
import '../controller/online_game_controller.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key});

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  PlayingCard? _selectedCard;
  PlayingCard? _draggedCard;
  Offset _dragOffset = Offset.zero;
  final Map<String, Offset> _throwingCards = {};
  List<TrickPlay> _lastObservedTrick = [];

  static const List<String> _emotes = ['👍', '😂', '😮', '🔥', '💀', '🤝'];

  Offset _seatAvatarPosition(int displayPos, Size size) {
    switch (displayPos) {
      case 0:
        return Offset(size.width / 2, size.height - 45); // You
      case 1:
        return Offset(size.width - 28, size.height / 2 - 20); // Right
      case 2:
        return Offset(size.width / 2, 32); // Top
      case 3:
        return Offset(28, size.height / 2 - 20); // Left
      default:
        return Offset(size.width / 2, size.height / 2);
    }
  }

  Offset _trickSlotOffset(int displayPos) {
    switch (displayPos) {
      case 0:
        return const Offset(0, 30);
      case 1:
        return const Offset(30, 0);
      case 2:
        return const Offset(0, -30);
      case 3:
        return const Offset(-30, 0);
      default:
        return Offset.zero;
    }
  }

  void _syncTrickThrows(OnlineGameController ctrl, Size size) {
    final trick = ctrl.currentTrick;
    if (trick.length > _lastObservedTrick.length) {
      for (int i = _lastObservedTrick.length; i < trick.length; i++) {
        final play = trick[i];
        final displayPos = ctrl.displayPosition(play.seat);
        _throwingCards[play.card.id] = _seatAvatarPosition(displayPos, size);
      }
    } else if (trick.isEmpty && _lastObservedTrick.isNotEmpty) {
      _throwingCards.clear();
    }
    _lastObservedTrick = List.from(trick);
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // ── Card tap handling ──────────────────────────────────────────────────────

  void _onCardTap(BuildContext context, OnlineGameController ctrl, PlayingCard card) {
    if (ctrl.phase != OnlinePhase.playing) return;

    final isLegal = ctrl.legalMoves.contains(card);
    if (!isLegal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Must follow the led suit'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Single tap throws immediately in once mode
    setState(() {
      _selectedCard = null;
      _draggedCard = null;
      _dragOffset = Offset.zero;
    });
    HapticFeedback.mediumImpact();
    SoundService.instance.playCardSlide();
    ctrl.playCard(card);
  }

  void _showScoreboard(BuildContext context, OnlineGameController ctrl) {
    // Build a mock GameController-shaped read for the existing ScoreboardSheet.
    // We push the data via a thin adapter instead of changing ScoreboardSheet.
    showDialog(
      context: context,
      builder: (_) => _OnlineScoreboardDialog(ctrl: ctrl),
    );
  }

  void _showEmotePicker(BuildContext context, OnlineGameController ctrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF3E1F0D),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _emotes
              .map((e) => GestureDetector(
                    onTap: () {
                      ctrl.sendEmote(e);
                      Navigator.pop(context);
                    },
                    child: Text(e, style: const TextStyle(fontSize: 32)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Consumer<OnlineGameController>(
          builder: (context, ctrl, _) {
            _syncTrickThrows(ctrl, screenSize);

            return Stack(
              children: [
                // Background
                Positioned.fill(child: _buildBackground()),

                // Game table
                SafeArea(
                  top: false,
                  bottom: false,
                  left: false,
                  right: false,
                  child: Stack(
                    children: [
                      // Scoreboard button
                      Positioned(
                        top: 6, left: 10,
                        child: GestureDetector(
                          onTap: () => _showScoreboard(context, ctrl),
                          child: _buildTopNotepadButton(ctrl.currentRound),
                        ),
                      ),

                      // Emote button
                      Positioned(
                        top: 6, right: 10,
                        child: GestureDetector(
                          onTap: () => _showEmotePicker(context, ctrl),
                          child: _buildWoodenButton(Icons.emoji_emotions_outlined),
                        ),
                      ),

                      // ── Players at their positions ─────────────────────
                      // Top (display position 2 → server seat: (localSeat+2)%4)
                      Positioned(
                        top: 6, left: 0, right: 0,
                        child: Center(
                          child: _buildOpponentStrip(ctrl, displayPos: 2),
                        ),
                      ),

                      // Left (display position 3)
                      Positioned(
                        left: 4,
                        top: 0, bottom: 0,
                        child: Center(
                          child: _buildOpponentStrip(ctrl, displayPos: 3),
                        ),
                      ),

                      // Right (display position 1)
                      Positioned(
                        right: 4,
                        top: 0, bottom: 0,
                        child: Center(
                          child: _buildOpponentStrip(ctrl, displayPos: 1),
                        ),
                      ),

                      // Center trick arena
                      Positioned.fill(
                        child: Center(child: _buildTrickArena(ctrl)),
                      ),

                      // Bottom — your hand
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: _buildBottomArea(context, ctrl),
                      ),

                      // Emotes floating
                      ..._buildEmoteOverlays(ctrl),

                      // Status bar
                      Positioned(
                        top: 6, left: 0, right: 0,
                        child: Center(
                          child: _buildStatusPill(ctrl.statusMessage),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Flying Cards in Active Throw Animation ──
                ..._throwingCards.entries.map((entry) {
                  final play = ctrl.currentTrick.firstWhere(
                    (p) => p.card.id == entry.key,
                    orElse: () => TrickPlay(seat: 0, card: PlayingCard.fromWire('0-0')),
                  );
                  final displayPos = ctrl.displayPosition(play.seat);
                  final endOffset = Offset(screenSize.width / 2, screenSize.height / 2 - 10) +
                      _trickSlotOffset(displayPos);
                  return AnimatedCardThrow(
                    key: ValueKey('online_throw_${entry.key}'),
                    card: play.card,
                    startOffset: entry.value,
                    endOffset: endOffset,
                    onCompleted: () {
                      if (mounted) {
                        setState(() {
                          _throwingCards.remove(entry.key);
                        });
                      }
                    },
                  );
                }),

                // ── Trick Collection Sweep Animation Overlay ──
                if (ctrl.phase == OnlinePhase.trickReveal && ctrl.currentTrick.isNotEmpty)
                  Positioned.fill(
                    child: TrickSweepOverlay(
                      trick: ctrl.currentTrick,
                      winnerSeat: ctrl.trickWinnerSeat ?? 0,
                      seatCardOffsets: {
                        ctrl.localSeat: const Offset(0, 30),
                        (ctrl.localSeat + 1) % 4: const Offset(30, 0),
                        (ctrl.localSeat + 2) % 4: const Offset(0, -30),
                        (ctrl.localSeat + 3) % 4: const Offset(-30, 0),
                      },
                      seatTargetOffsets: {
                        ctrl.localSeat: Offset(screenSize.width / 2, screenSize.height - 45),
                        (ctrl.localSeat + 1) % 4: Offset(screenSize.width - 28, screenSize.height / 2 - 20),
                        (ctrl.localSeat + 2) % 4: Offset(screenSize.width / 2, 32),
                        (ctrl.localSeat + 3) % 4: Offset(28, screenSize.height / 2 - 20),
                      },
                      onCompleted: () {},
                    ),
                  ),

                // Bidding overlay
                if (ctrl.phase == OnlinePhase.bidding)
                  _OnlineBiddingOverlay(ctrl: ctrl),

                // Round end dimmer
                if (ctrl.phase == OnlinePhase.roundEnd)
                  _buildRoundEndOverlay(context, ctrl),

                // Game over
                if (ctrl.phase == OnlinePhase.gameOver)
                  _buildGameOverOverlay(context, ctrl),

                // Error / disconnected
                if (ctrl.phase == OnlinePhase.error ||
                    ctrl.phase == OnlinePhase.disconnected)
                  _buildErrorOverlay(context, ctrl),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Background ─────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Image.asset(
      'assets/images/wood_bg.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B6B1B), Color(0xFF2E8B2E), Color(0xFF1B6B1B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  // ── Opponent strip ─────────────────────────────────────────────────────────

  Widget _buildOpponentStrip(OnlineGameController ctrl, {required int displayPos}) {
    final serverSeat = (ctrl.localSeat + displayPos) % 4;
    if (serverSeat >= ctrl.players.length) return const SizedBox.shrink();
    final player = ctrl.players[serverSeat];
    final bid     = player.bid;
    final tricks  = player.tricksWon;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 1.5),
            ),
            child: ClipOval(
              child: Image.asset(
                player.avatarPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white54, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              Text(
                bid == null ? 'Bidding…' : '$tricks / $bid',
                style: TextStyle(
                  color: bid == null
                      ? Colors.white38
                      : (tricks >= bid
                          ? AppTheme.activeTurnNeon
                          : Colors.white60),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          // Face-down card count
          const SizedBox(width: 8),
          Row(
            children: List.generate(
              (ctrl.players[serverSeat].hand.isEmpty ? 0 : 3).clamp(0, 3),
              (_) => Container(
                width: 12, height: 18,
                margin: const EdgeInsets.only(left: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFB71C1C),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white30, width: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Trick arena ────────────────────────────────────────────────────────────

  Widget _buildTrickArena(OnlineGameController ctrl) {
    if (ctrl.phase == OnlinePhase.trickReveal) {
      return const SizedBox(width: 180, height: 180);
    }

    const cardW = 52.0, cardH = 74.0;
    const offsets = [
      Offset(0, 30),   // seat 0 = bottom — slightly down
      Offset(30, 0),   // seat 1 = right
      Offset(0, -30),  // seat 2 = top
      Offset(-30, 0),  // seat 3 = left
    ];

    final visibleTrick = ctrl.currentTrick
        .where((tp) => !_throwingCards.containsKey(tp.card.id))
        .toList();

    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: visibleTrick.map((tp) {
          final displayPos = ctrl.displayPosition(tp.seat);
          final offset     = offsets[displayPos];
          final isWinner   = tp.seat == ctrl.trickWinnerSeat;
          return Transform.translate(
            offset: offset,
            child: PlayingCardWidget(
              card:       tp.card,
              width:      cardW,
              height:     cardH,
              isLegal:    true,
              isSelected: isWinner,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bottom area — your hand ────────────────────────────────────────────────

  Widget _buildBottomArea(BuildContext context, OnlineGameController ctrl) {
    return Container(
      height: 110,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Your info strip
          Positioned(
            bottom: 4, left: 8,
            child: _buildYourInfo(ctrl),
          ),

          // Your hand
          Positioned(
            bottom: 8, left: 60, right: 60,
            child: _buildHandFan(context, ctrl),
          ),
        ],
      ),
    );
  }

  Widget _buildYourInfo(OnlineGameController ctrl) {
    final me = ctrl.localPlayer;
    if (me == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: ctrl.isMyTurn
                ? AppTheme.activeTurnNeon
                : Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: ctrl.isMyTurn
                      ? AppTheme.activeTurnNeon
                      : AppTheme.headerGold,
                  width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                me.avatarPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, color: Colors.white54, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(me.name,
                  style: const TextStyle(
                      color: AppTheme.headerGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              Text(
                me.bid == null ? 'You' : '${me.tricksWon} / ${me.bid}',
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHandFan(BuildContext context, OnlineGameController ctrl) {
    const cardW = 58.0, cardH = 88.0;
    if (ctrl.myHand.isEmpty) return const SizedBox(height: cardH);

    return LayoutBuilder(builder: (_, constraints) {
      final usable  = constraints.maxWidth.clamp(200.0, 900.0);
      final count   = ctrl.myHand.length;
      final spacing = ((usable - cardW) / count.clamp(1, 13)).clamp(22.0, 52.0);
      final totalW  = cardW + spacing * (count - 1);

      // Keep all cards in tree with ValueKey(card.id); order so dragging card is on top
      final renderCards = List<PlayingCard>.from(ctrl.myHand);
      if (_draggedCard != null && renderCards.contains(_draggedCard)) {
        renderCards.remove(_draggedCard);
        renderCards.add(_draggedCard!);
      }

      return SizedBox(
        height: cardH + 18,
        width: totalW,
        child: Stack(
          clipBehavior: Clip.none,
          children: renderCards.map((card) {
            final originalIdx = ctrl.myHand.indexOf(card);
            final isLegal = ctrl.legalMoves.contains(card);
            final isSel = _selectedCard == card;
            final isDragging = _draggedCard == card;
            final isThrowReady = isDragging && _dragOffset.dy < -25;
            final currentOffset = isDragging ? _dragOffset : Offset.zero;

            return Positioned(
              key: ValueKey(card.id),
              left: originalIdx * spacing + currentOffset.dx,
              bottom: isDragging
                  ? (-currentOffset.dy).clamp(0.0, 350.0)
                  : (isSel ? 16.0 : 0.0),
              child: Transform.scale(
                scale: isThrowReady ? 1.15 : (isDragging ? 1.08 : (isSel ? 1.05 : 1.0)),
                child: PlayingCardWidget(
                  card: card,
                  width: cardW,
                  height: cardH,
                  isLegal: ctrl.phase == OnlinePhase.playing ? isLegal : true,
                  isSelected: isThrowReady || isSel,
                  onTap: () => _onCardTap(context, ctrl, card),
                  onPanStart: (details) => _onCardPanStart(ctrl, card, details),
                  onPanUpdate: (details) => _onCardPanUpdate(card, details),
                  onPanEnd: (details) => _onCardPanEnd(context, ctrl, card, details),
                  onPanCancel: _onCardPanCancel,
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  void _onCardPanStart(OnlineGameController ctrl, PlayingCard card, DragStartDetails details) {
    if (ctrl.phase != OnlinePhase.playing || !ctrl.isMyTurn) return;

    setState(() {
      _draggedCard = card;
      _dragOffset = Offset.zero;
    });
    HapticFeedback.selectionClick();
  }

  void _onCardPanUpdate(PlayingCard card, DragUpdateDetails details) {
    if (_draggedCard != card) return;
    setState(() {
      _dragOffset = Offset(
        (_dragOffset.dx + details.delta.dx).clamp(-180.0, 180.0),
        (_dragOffset.dy + details.delta.dy).clamp(-350.0, 10.0),
      );
    });
  }

  void _onCardPanEnd(BuildContext context, OnlineGameController ctrl, PlayingCard card, DragEndDetails details) {
    if (_draggedCard != card) return;

    final isThrow = _dragOffset.dy < -25 || details.velocity.pixelsPerSecond.dy < -80;
    if (isThrow && ctrl.phase == OnlinePhase.playing && ctrl.isMyTurn) {
      final isLegal = ctrl.legalMoves.contains(card);
      if (isLegal) {
        setState(() {
          _draggedCard = null;
          _dragOffset = Offset.zero;
          _selectedCard = null;
        });
        HapticFeedback.mediumImpact();
        SoundService.instance.playCardSlide();
        ctrl.playCard(card);
        return;
      } else {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Must follow the led suit'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    setState(() {
      _draggedCard = null;
      _dragOffset = Offset.zero;
    });
  }

  void _onCardPanCancel() {
    setState(() {
      _draggedCard = null;
      _dragOffset = Offset.zero;
    });
  }

  // ── Emote overlays ─────────────────────────────────────────────────────────

  List<Widget> _buildEmoteOverlays(OnlineGameController ctrl) {
    if (ctrl.activeEmotes.isEmpty) return [];
    return ctrl.activeEmotes.entries.map((entry) {
      final displayPos = ctrl.displayPosition(entry.key);
      final positions  = <int, AlignmentGeometry>{
        0: Alignment.bottomCenter,
        1: Alignment.centerRight,
        2: Alignment.topCenter,
        3: Alignment.centerLeft,
      };
      return Positioned.fill(
        child: Align(
          alignment: positions[displayPos] ?? Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(80),
            child: Text(entry.value, style: const TextStyle(fontSize: 36)),
          ),
        ),
      );
    }).toList();
  }

  // ── Status pill ────────────────────────────────────────────────────────────

  Widget _buildStatusPill(String msg) {
    if (msg.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(msg,
          style: const TextStyle(
              color: Colors.white70, fontSize: 11, letterSpacing: 0.5)),
    );
  }

  // ── Notepad / button helpers ───────────────────────────────────────────────

  Widget _buildTopNotepadButton(int round) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF3E1F0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.headerGold.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$round / 5',
        style: const TextStyle(
            color: AppTheme.headerGold,
            fontSize: 12,
            fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildWoodenButton(IconData icon) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF3E1F0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.headerGold.withValues(alpha: 0.5)),
      ),
      child: Icon(icon, color: AppTheme.headerGold, size: 18),
    );
  }

  // ── Round end overlay ──────────────────────────────────────────────────────

  Widget _buildRoundEndOverlay(BuildContext context, OnlineGameController ctrl) {
    if (ctrl.roundHistory.isEmpty) return const SizedBox.shrink();
    // ignore: unused_local_variable
    final result = ctrl.roundHistory.last;
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: _OnlineScoreboardDialog(ctrl: ctrl, isOverlay: true),
      ),
    );
  }

  // ── Game over overlay ──────────────────────────────────────────────────────

  Widget _buildGameOverOverlay(BuildContext context, OnlineGameController ctrl) {
    final winnerSeat = ctrl.totalScores.indexOf(
        ctrl.totalScores.reduce((a, b) => a > b ? a : b));
    final isWinner = winnerSeat == ctrl.localSeat;

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF3E1F0D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.headerGold, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isWinner ? '🏆 You Won!' : '😔 Game Over',
                style: TextStyle(
                  color: isWinner ? AppTheme.headerGold : Colors.white70,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              // Scores
              ...List.generate(ctrl.players.length, (i) {
                final score = ctrl.totalScores[i];
                final isMe  = i == ctrl.localSeat;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ctrl.players[i].name,
                          style: TextStyle(
                            color: isMe ? AppTheme.headerGold : Colors.white70,
                            fontWeight: isMe ? FontWeight.w800 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        score >= 0
                            ? '+${score.toStringAsFixed(1)}'
                            : score.toStringAsFixed(1),
                        style: TextStyle(
                          color: score >= 0
                              ? AppTheme.scorePositive
                              : AppTheme.scoreNegative,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ctrl.disconnect();
                        Navigator.popUntil(context, (r) => r.isFirst);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Center(
                          child: Text('Home',
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error overlay ──────────────────────────────────────────────────────────

  Widget _buildErrorOverlay(BuildContext context, OnlineGameController ctrl) {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              ctrl.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                ctrl.disconnect();
                Navigator.popUntil(context, (r) => r.isFirst);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.confirmGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Go Home',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Online Bidding Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _OnlineBiddingOverlay extends StatefulWidget {
  final OnlineGameController ctrl;
  const _OnlineBiddingOverlay({required this.ctrl});

  @override
  State<_OnlineBiddingOverlay> createState() => _OnlineBiddingOverlayState();
}

class _OnlineBiddingOverlayState extends State<_OnlineBiddingOverlay>
    with SingleTickerProviderStateMixin {
  late int _bid;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _bid = widget.ctrl.suggestedBid.clamp(1, 8);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack);
    _fadeAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.creamCardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.creamBorder, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Make your bid',
                  style: TextStyle(
                      color: AppTheme.textDarkBrown,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              // Number row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(8, (i) {
                  final v  = i + 1;
                  final sel = v == _bid;
                  return GestureDetector(
                    onTap: () => setState(() => _bid = v),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 30, height: 30,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.woodDark
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: sel
                                ? AppTheme.headerGold
                                : AppTheme.woodLight),
                      ),
                      child: Center(
                        child: Text('$v',
                            style: TextStyle(
                                color: sel
                                    ? AppTheme.headerGold
                                    : AppTheme.textDarkBrown,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Stepper + confirm
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepBtn('-', () {
                    if (_bid > 1) setState(() => _bid--);
                  }),
                  const SizedBox(width: 10),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.woodDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.headerGold),
                    ),
                    child: Center(
                      child: Text('$_bid',
                          style: const TextStyle(
                              color: AppTheme.headerGold,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _stepBtn('+', () {
                    if (_bid < 8) setState(() => _bid++);
                  }),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => widget.ctrl.placeBid(_bid),
                    child: Container(
                      width: 52, height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.confirmGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '💡 Suggested: ${widget.ctrl.suggestedBid}',
                style: const TextStyle(color: AppTheme.woodMid, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  Widget _stepBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.woodLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.woodLight),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.textDarkBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Online Scoreboard Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _OnlineScoreboardDialog extends StatelessWidget {
  final OnlineGameController ctrl;
  final bool isOverlay;
  const _OnlineScoreboardDialog({required this.ctrl, this.isOverlay = false});

  @override
  Widget build(BuildContext context) {
    final colOrder = [
      (ctrl.localSeat + 2) % 4, // top
      (ctrl.localSeat + 3) % 4, // left
      ctrl.localSeat,           // you (highlighted)
      (ctrl.localSeat + 1) % 4, // right
    ];

    return Dialog(
      backgroundColor: AppTheme.creamCardBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 380),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.woodDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('SCOREBOARD',
                        style: TextStyle(
                            color: AppTheme.headerGold,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                    child: const Icon(Icons.close, color: Colors.white54, size: 20),
                  ),
                ],
              ),
            ),
            // Table
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Table(
                  border: TableBorder.all(
                      color: AppTheme.creamBorder, width: 0.8),
                  columnWidths: const {
                    0: FixedColumnWidth(36),
                  },
                  children: [
                    // Header row
                    TableRow(
                      decoration: const BoxDecoration(color: AppTheme.woodDark),
                      children: [
                        _cell('Rd', header: true),
                        ...colOrder.map((s) => _cell(
                              s < ctrl.players.length
                                  ? ctrl.players[s].name
                                  : 'P${s + 1}',
                              header: true,
                              highlight: s == ctrl.localSeat,
                            )),
                      ],
                    ),
                    // Round rows
                    ...List.generate(5, (ri) {
                      final hasResult = ri < ctrl.roundHistory.length;
                      final result = hasResult ? ctrl.roundHistory[ri] : null;
                      return TableRow(
                        decoration: BoxDecoration(
                            color: ri.isEven
                                ? Colors.white
                                : const Color(0xFFFFF7E6)),
                        children: [
                          _cell('${ri + 1}'),
                          ...colOrder.map((s) {
                            if (result == null) {
                              return _cell('–');
                            }
                            final bid    = result.bids[s];
                            final tricks = result.tricksWon[s];
                            final score  = result.scores[s];
                            return _cell(
                              '$bid/$tricks  (${score >= 0 ? '+' : ''}${score.toStringAsFixed(1)})',
                              highlight: s == ctrl.localSeat,
                              positive: score >= 0,
                            );
                          }),
                        ],
                      );
                    }),
                    // Total row
                    TableRow(
                      decoration: const BoxDecoration(
                          color: AppTheme.scoreGreenRow),
                      children: [
                        _cell('Σ', header: true),
                        ...colOrder.map((s) {
                          final total = s < ctrl.totalScores.length
                              ? ctrl.totalScores[s]
                              : 0.0;
                          return _cell(
                            total.toStringAsFixed(1),
                            header: true,
                            highlight: s == ctrl.localSeat,
                            positive: total >= 0,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text,
      {bool header = false, bool highlight = false, bool? positive}) {
    Color textColor = AppTheme.textDarkBrown;
    if (header && highlight) textColor = AppTheme.headerGold;
    if (positive == true)  textColor = AppTheme.scorePositive;
    if (positive == false) textColor = AppTheme.scoreNegative;

    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Container(
        color: highlight && !header ? const Color(0xFFF7EAC4) : null,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: header ? FontWeight.w800 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
