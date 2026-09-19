import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/card_model.dart';
import '../models/trick_model.dart';
import '../theme/app_theme.dart';
import '../widgets/player_info_widget.dart';
import '../widgets/playing_card_widget.dart';
import '../widgets/settings_drawer.dart';
import '../widgets/dealing_animation_overlay.dart';
import '../widgets/animated_card_throw.dart';
import '../widgets/trick_sweep_overlay.dart';
import 'bidding_screen.dart';
import 'scoreboard_screen.dart';
import '../services/sound_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  PlayingCard? _selectedCard;
  PlayingCard? _draggedCard;
  Offset _dragOffset = Offset.zero;
  final Map<String, Offset> _throwingCards = {};
  List<TrickPlay> _lastObservedTrick = [];

  Offset _seatAvatarPosition(int seat, Size size) {
    switch (seat) {
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

  Offset _trickSlotOffset(int seat) {
    switch (seat) {
      case 0:
        return const Offset(0, 38);
      case 1:
        return const Offset(48, 0);
      case 2:
        return const Offset(0, -38);
      case 3:
        return const Offset(-48, 0);
      default:
        return Offset.zero;
    }
  }

  void _syncTrickThrows(List<TrickPlay> trick, Size size) {
    if (trick.length > _lastObservedTrick.length) {
      for (int i = _lastObservedTrick.length; i < trick.length; i++) {
        final play = trick[i];
        _throwingCards[play.card.id] = _seatAvatarPosition(play.seat, size);
      }
    } else if (trick.isEmpty && _lastObservedTrick.isNotEmpty) {
      _throwingCards.clear();
    }
    _lastObservedTrick = List.from(trick);
  }

  @override
  void initState() {
    super.initState();
    // Force horizontal / landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFC77F35),
        body: Consumer<GameController>(
          builder: (context, game, _) {
            _syncTrickThrows(game.currentTrick, screenSize);

            return Stack(
              children: [
                // ── 1000% Authentic Callbreak Background ──
                Positioned.fill(
                  child: _buildBackground(game),
                ),

                // ── Main Game Table (Landscape) ──
                SafeArea(
                  top: false,
                  bottom: false,
                  left: false,
                  right: false,
                  child: Stack(
                    children: [
                      // ── Top Left: Wooden Notepad Button (2/5 Scoreboard) ──
                      Positioned(
                        top: 6,
                        left: 10,
                        child: GestureDetector(
                          onTap: () => _showScoreboard(context, game),
                          child: _buildTopNotepadButton(game.currentRound),
                        ),
                      ),

                      // ── Top Right: Wooden Settings Button (Screenshot 3) ──
                      Positioned(
                        top: 6,
                        right: 10,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => SettingsDrawer.show(context),
                          child: _buildWoodenSettingsButton(),
                        ),
                      ),

                      // ── Top Player: bot3 (pushed back to top edge) ──
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: CallbreakPlayerAvatar(
                            seat: 2,
                            name: game.players[2].name,
                            avatarPath: game.players[2].avatarPath,
                            flag: game.players[2].flag,
                            bid: game.players[2].bid,
                            tricksWon: game.players[2].tricksWon,
                            isActive: game.turnSeat == 2,
                            isDealer: game.dealer == 2,
                            cardCount: game.players[2].hand.length,
                            activeEmote: game.activeEmotes[2],
                          ),
                        ),
                      ),

                      // ── Left Player: bot1 (pushed back to far left edge) ──
                      Positioned(
                        left: 4,
                        top: 0,
                        bottom: 84,
                        child: IgnorePointer(
                          child: Center(
                            child: CallbreakPlayerAvatar(
                              seat: 3,
                              name: game.players[3].name,
                              avatarPath: game.players[3].avatarPath,
                              flag: game.players[3].flag,
                              bid: game.players[3].bid,
                              tricksWon: game.players[3].tricksWon,
                              isActive: game.turnSeat == 3,
                              isDealer: game.dealer == 3,
                              cardCount: game.players[3].hand.length,
                              activeEmote: game.activeEmotes[3],
                            ),
                          ),
                        ),
                      ),

                      // ── Right Player: bot2 (pushed back to far right edge) ──
                      Positioned(
                        right: 4,
                        top: 0,
                        bottom: 84,
                        child: IgnorePointer(
                          child: Center(
                            child: CallbreakPlayerAvatar(
                              seat: 1,
                              name: game.players[1].name,
                              avatarPath: game.players[1].avatarPath,
                              flag: game.players[1].flag,
                              bid: game.players[1].bid,
                              tricksWon: game.players[1].tricksWon,
                              isActive: game.turnSeat == 1,
                              isDealer: game.dealer == 1,
                              cardCount: game.players[1].hand.length,
                              activeEmote: game.activeEmotes[1],
                            ),
                          ),
                        ),
                      ),

                      // ── Center Table Played Cards ──
                      Center(
                        child: _buildCenterTrickArena(game),
                      ),

                      // ── Bottom Section: Hand Cards + Centered You Avatar ──
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _buildBottomCardsAndAvatar(context, game),
                      ),

                      // ── Mini Scoreboard Strip (when enabled in settings) ──
                      if (game.showMiniScoreboard)
                        Positioned(
                          top: 52,
                          left: 0,
                          right: 0,
                          child: Center(child: _buildMiniScoreboard(game)),
                        ),
                    ],
                  ),
                ),

                // ── Flying Cards in Active Throw Animation ──
                ..._throwingCards.entries.map((entry) {
                  final play = game.currentTrick.firstWhere(
                    (p) => p.card.id == entry.key,
                    orElse: () => TrickPlay(seat: 0, card: PlayingCard.fromWire('0-0')),
                  );
                  final endOffset = Offset(screenSize.width / 2, screenSize.height / 2 - 10) +
                      _trickSlotOffset(play.seat);
                  return AnimatedCardThrow(
                    key: ValueKey('throw_${entry.key}'),
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
                if (game.phase == GamePhase.trickReveal && game.currentTrick.isNotEmpty)
                  Positioned.fill(
                    child: TrickSweepOverlay(
                      trick: game.currentTrick,
                      winnerSeat: game.trickWinnerSeat ?? 0,
                      seatCardOffsets: const {
                        0: Offset(0, 38),
                        1: Offset(48, 0),
                        2: Offset(0, -38),
                        3: Offset(-48, 0),
                      },
                      seatTargetOffsets: {
                        0: Offset(screenSize.width / 2, screenSize.height - 45),
                        1: Offset(screenSize.width - 28, screenSize.height / 2 - 20),
                        2: Offset(screenSize.width / 2, 32),
                        3: Offset(28, screenSize.height / 2 - 20),
                      },
                      onCompleted: () {},
                    ),
                  ),

                // ── Dealing Overlay (callbreak.com Dealing Animation) ──
                if (game.phase == GamePhase.dealing)
                  Positioned.fill(
                    child: DealingAnimationOverlay(
                      onSkip: () => game.finishDealing(),
                    ),
                  ),

                // ── Bidding Modal (Screenshot 3) ──
                if (game.phase == GamePhase.bidding && game.humanPlayer.bid == null)
                  const Positioned(
                    top: 50,
                    bottom: 110,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: BiddingOverlay(),
                    ),
                  ),

                // ── Round End Overlay ──
                if (game.phase == GamePhase.roundEnd)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => _showScoreboard(context, game),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.6),
                        child: ScoreboardSheet(game: game),
                      ),
                    ),
                  ),

                // ── Game Over Overlay ──
                if (game.phase == GamePhase.gameOver)
                  Positioned.fill(
                    child: _buildGameOverDialog(context, game),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Background Widget with Desert Dunes Painting Fallback ──────────────────

  Widget _buildBackground(GameController game) {
    if (game.currentTheme == GameThemeMode.desert) {
      return Image.asset(
        'assets/images/desert_bg.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: _DesertDunesPainter(),
          child: const SizedBox.expand(),
        ),
      );
    } else if (game.currentTheme == GameThemeMode.autumn) {
      return Image.asset(
        'assets/images/autumn_bg.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: _DesertDunesPainter(),
          child: const SizedBox.expand(),
        ),
      );
    } else if (game.currentTheme == GameThemeMode.cricket) {
      return Image.asset(
        'assets/images/cricket_bg.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: _DesertDunesPainter(),
          child: const SizedBox.expand(),
        ),
      );
    } else {
      return Image.asset(
        'assets/images/wood_bg.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CustomPaint(
          painter: _DesertDunesPainter(),
          child: const SizedBox.expand(),
        ),
      );
    }
  }

  // ── Top Left: 3D Wooden Notepad Button (2/5) ────────────────────────────────

  Widget _buildTopNotepadButton(int round) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF9E4E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBF6B44), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 5,
            offset: Offset(0, 2.5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6EB),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 2),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clipboard clip
              Container(
                width: 12,
                height: 3.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B3114),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(height: 1.5),
              Text(
                '${round == 0 ? 1 : round}/5',
                style: const TextStyle(
                  color: Color(0xFF702E14),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mini Scoreboard Strip ─────────────────────────────────────────────────
  Widget _buildMiniScoreboard(GameController game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C160B).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 0.8),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (i) {
          final p = game.players[i];
          final score = game.totalScores[i];
          final isHuman = i == 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isHuman ? 'You' : p.name,
                  style: TextStyle(
                    color: isHuman ? const Color(0xFFF3DE8A) : Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  score.toStringAsFixed(1),
                  style: TextStyle(
                    color: score >= 0 ? const Color(0xFF76FF03) : const Color(0xFFFF5252),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWoodenSettingsButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF9E4E2C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBF6B44), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 5,
            offset: Offset(0, 2.5),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.settings_rounded, color: Color(0xFFFFF6EB), size: 26),
      ),
    );
  }



  // ── Center Trick Cards ─────────────────────────────────────────────────────

  Widget _buildCenterTrickArena(GameController game) {
    if (game.phase == GamePhase.trickReveal) {
      // TrickSweepOverlay takes over during trick completion & collection
      return const SizedBox(width: 260, height: 180);
    }

    final trick = game.currentTrick
        .where((play) => !_throwingCards.containsKey(play.card.id))
        .toList();

    if (trick.isEmpty) {
      return const SizedBox(width: 220, height: 160);
    }

    final offsets = {
      0: const Offset(0, 38),   // You bottom
      1: const Offset(48, 0),   // Dannie right
      2: const Offset(0, -38),  // Meena top
      3: const Offset(-48, 0),  // Lily left
    };

    return SizedBox(
      width: 260,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: trick.map((play) {
          final isWinner = game.trickWinnerSeat == play.seat;
          final offset = offsets[play.seat] ?? Offset.zero;

          return Transform.translate(
            offset: offset,
            child: Container(
              decoration: isWinner
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0xFF76FF03),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                    )
                  : null,
              child: PlayingCardWidget(
                card: play.card,
                width: 60,
                height: 84,
                isSelected: isWinner,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Bottom Section: Horizontal Cards Fan + Centered You Avatar ─────────────

  Widget _buildBottomCardsAndAvatar(BuildContext context, GameController game) {
    final hand = game.humanPlayer.hand;
    final legalMoves = game.legalMoves;
    final isHumanTurn = game.isHumanTurn;

    return SizedBox(
      height: 108,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Center Avatar: YOU (rendered behind cards with IgnorePointer)
          Positioned(
            bottom: 8,
            child: IgnorePointer(
              child: CallbreakPlayerAvatar(
                seat: 0,
                name: game.players[0].name,
                avatarPath: game.players[0].avatarPath,
                flag: game.players[0].flag,
                bid: game.players[0].bid,
                tricksWon: game.players[0].tricksWon,
                isActive: isHumanTurn,
                isDealer: game.dealer == 0,
                isHuman: true,
                cardCount: hand.length,
                activeEmote: game.activeEmotes[0],
              ),
            ),
          ),

          // Hand cards spanning across the bottom (matching Screenshot 3)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _buildHorizontalCardFan(
                context,
                hand: hand,
                legalMoves: legalMoves,
                selectedCard: _selectedCard,
                canPlay: isHumanTurn && game.phase == GamePhase.playing,
                isDealing: game.phase == GamePhase.dealing,
                highlightValidCards: game.highlightValidCards,
                onCardTap: (card) => _onCardTap(context, game, card),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCardFan(
    BuildContext context, {
    required List<PlayingCard> hand,
    required List<PlayingCard> legalMoves,
    required PlayingCard? selectedCard,
    required bool canPlay,
    required bool isDealing,
    required bool highlightValidCards,
    required ValueChanged<PlayingCard> onCardTap,
  }) {
    if (hand.isEmpty) return const SizedBox(height: 94);

    final count = hand.length;
    final screenW = MediaQuery.of(context).size.width;
    const cardW = 64.0;
    const cardH = 94.0;

    // Available width across the landscape screen
    final usableW = (screenW - 24).clamp(460.0, 960.0);
    final spacing = count > 1
        ? ((usableW - cardW) / (count - 1)).clamp(28.0, 56.0)
        : 0.0;
    final totalW = cardW + (count - 1) * spacing;

    // Keep all cards in tree with ValueKey(card.id); order so dragging card is on top
    final renderCards = List<PlayingCard>.from(hand);
    if (_draggedCard != null && renderCards.contains(_draggedCard)) {
      renderCards.remove(_draggedCard);
      renderCards.add(_draggedCard!);
    }

    return SizedBox(
      width: totalW,
      height: cardH + 18,
      child: Stack(
        clipBehavior: Clip.none,
        children: renderCards.map((card) {
          final originalIdx = hand.indexOf(card);
          final isLegal = legalMoves.contains(card);
          final isSelected = selectedCard == card;
          final isDragging = _draggedCard == card;
          final isThrowReady = isDragging && _dragOffset.dy < -25;
          final showHighlight = canPlay && highlightValidCards;
          final currentOffset = isDragging ? _dragOffset : Offset.zero;

          return Positioned(
            key: ValueKey(card.id),
            left: originalIdx * spacing + currentOffset.dx,
            bottom: isDragging
                ? (-currentOffset.dy).clamp(0.0, 350.0)
                : (isSelected ? 16.0 : 0.0),
            child: Transform.scale(
              scale: isThrowReady ? 1.15 : (isDragging ? 1.08 : (isSelected ? 1.05 : 1.0)),
              child: PlayingCardWidget(
                card: card,
                width: cardW,
                height: cardH,
                isFaceDown: isDealing,
                isLegal: showHighlight ? isLegal : true,
                isSelected: isThrowReady || isSelected,
                onTap: () => onCardTap(card),
                onPanStart: (details) => _onCardPanStart(card, details),
                onPanUpdate: (details) => _onCardPanUpdate(card, details),
                onPanEnd: (details) => _onCardPanEnd(context, card, details),
                onPanCancel: _onCardPanCancel,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _onCardPanStart(PlayingCard card, DragStartDetails details) {
    final game = Provider.of<GameController>(context, listen: false);
    if (game.phase != GamePhase.playing || !game.isHumanTurn) return;

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

  void _onCardPanEnd(BuildContext context, PlayingCard card, DragEndDetails details) {
    if (_draggedCard != card) return;
    final game = Provider.of<GameController>(context, listen: false);

    final isThrow = _dragOffset.dy < -25 || details.velocity.pixelsPerSecond.dy < -80;
    if (isThrow && game.phase == GamePhase.playing && game.isHumanTurn) {
      final isLegal = game.legalMoves.contains(card);
      if (isLegal) {
        setState(() {
          _draggedCard = null;
          _dragOffset = Offset.zero;
          _selectedCard = null;
        });
        HapticFeedback.mediumImpact();
        SoundService.instance.playCardSlide();
        game.humanPlayCard(card);
        return;
      } else {
        HapticFeedback.heavyImpact();
        SoundService.instance.playButtonClick();
        final leadSuit = game.currentTrick.isNotEmpty ? game.currentTrick.first.card.suit : null;
        final msg = leadSuit != null
            ? 'Must follow ${leadSuit.name}!'
            : 'Invalid move!';
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(milliseconds: 1000),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    // Snapping back if not thrown or illegal
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

  void _onCardTap(BuildContext context, GameController game, PlayingCard card) {
    // 1. During bidding: allow inspecting/highlighting cards + notify how to play
    if (game.phase == GamePhase.bidding) {
      HapticFeedback.selectionClick();
      SoundService.instance.playCardTap();
      setState(() {
        _selectedCard = (_selectedCard == card) ? null : card;
      });
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your bid and tap the green [✓] button to start playing!'),
          duration: Duration(milliseconds: 1600),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Only allow playing in playing phase
    if (game.phase != GamePhase.playing) return;

    // 3. Check if it's the human's turn
    if (game.turnSeat != 0) {
      HapticFeedback.lightImpact();
      SoundService.instance.playButtonClick();
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wait for ${game.players[game.turnSeat].name} to play!'),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 4. Check move legality
    final isLegal = game.legalMoves.contains(card);
    if (!isLegal) {
      HapticFeedback.heavyImpact();
      SoundService.instance.playButtonClick();
      final leadSuit = game.currentTrick.isNotEmpty ? game.currentTrick.first.card.suit : null;
      final msg = leadSuit != null
          ? 'Must follow ${leadSuit.name}!'
          : 'Invalid move!';
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(milliseconds: 1000),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 5. Valid move: play card immediately in single tap (once mode)
    setState(() {
      _selectedCard = null;
      _draggedCard = null;
      _dragOffset = Offset.zero;
    });
    HapticFeedback.mediumImpact();
    SoundService.instance.playCardSlide();
    game.humanPlayCard(card);
  }

  void _showScoreboard(BuildContext context, GameController game) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => ScoreboardSheet(game: game),
    );
  }

  Widget _buildGameOverDialog(BuildContext context, GameController game) {
    final winners = game.winners;
    final isHumanWin = winners.any((w) => w.seat == 0);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFECCB9E), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x66000000), blurRadius: 28, offset: Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isHumanWin ? '🏆' : '👏', style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 4),
              Text(
                isHumanWin ? 'You Won!' : 'Match Finished',
                style: const TextStyle(
                  color: Color(0xFF3E1F0D),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              ...List.generate(4, (i) {
                final p = game.players[i];
                final score = game.totalScores[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(p.name, style: const TextStyle(color: Color(0xFF3E1F0D), fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(
                        score.toStringAsFixed(1),
                        style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Home', style: TextStyle(color: Color(0xFF3E1F0D))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => game.restartGame(animateDealing: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EB846),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Play Again'),
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
}

// ── Desert Dunes Custom Painter (1000% matching callbreak.com landscape) ─────

class _DesertDunesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8DC0E8), Color(0xFFC0DBF0), Color(0xFFE4EFF8)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.65));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.65), skyPaint);

    // 2. Glowing Sun
    final sunPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0xFFFFF0B8).withValues(alpha: 0.6),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.76, h * 0.42), radius: 90));
    canvas.drawCircle(Offset(w * 0.76, h * 0.42), 90, sunPaint);

    // 3. Distant Dunes Layer (Light Sand)
    final backDune = Paint()..color = const Color(0xFFE5A85A);
    final backPath = Path()
      ..moveTo(0, h * 0.52)
      ..quadraticBezierTo(w * 0.28, h * 0.38, w * 0.54, h * 0.48)
      ..quadraticBezierTo(w * 0.78, h * 0.56, w, h * 0.44)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backPath, backDune);

    // 4. Mid Dunes Layer (Rich Sand)
    final midDune = Paint()..color = const Color(0xFFD9903F);
    final midPath = Path()
      ..moveTo(0, h * 0.60)
      ..quadraticBezierTo(w * 0.32, h * 0.66, w * 0.65, h * 0.52)
      ..quadraticBezierTo(w * 0.88, h * 0.44, w, h * 0.50)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(midPath, midDune);

    // 5. Foreground Dunes Layer (Warm Ochre Sand)
    final foreDune = Paint()..color = const Color(0xFFC7782A);
    final forePath = Path()
      ..moveTo(0, h * 0.68)
      ..quadraticBezierTo(w * 0.38, h * 0.54, w * 0.72, h * 0.64)
      ..quadraticBezierTo(w * 0.90, h * 0.68, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(forePath, foreDune);

    // 6. Camels Silhouette on the ridge
    final camelPaint = Paint()
      ..color = const Color(0xFF7A421A)
      ..style = PaintingStyle.fill;

    _drawCamel(canvas, camelPaint, Offset(w * 0.26, h * 0.64), 0.7);
    _drawCamel(canvas, camelPaint, Offset(w * 0.35, h * 0.62), 0.9);

    // 7. Saguaro Cacti on Left and Right
    final cactusPaint = Paint()
      ..color = const Color(0xFF426830)
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    _drawCactus(canvas, cactusPaint, Offset(w * 0.07, h * 0.68), 44);
    _drawCactus(canvas, cactusPaint, Offset(w * 0.84, h * 0.63), 36);

    // 8. Distant flying birds
    final birdPaint = Paint()
      ..color = const Color(0xFF7A4A28)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    _drawBird(canvas, birdPaint, Offset(w * 0.80, h * 0.40));
    _drawBird(canvas, birdPaint, Offset(w * 0.82, h * 0.37));
    _drawBird(canvas, birdPaint, Offset(w * 0.81, h * 0.43));
  }

  void _drawCamel(Canvas canvas, Paint paint, Offset pos, double scale) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.scale(scale);

    final path = Path()
      // Legs
      ..moveTo(-10, 18)..lineTo(-8, 6)
      ..moveTo(-4, 18)..lineTo(-3, 6)
      ..moveTo(6, 18)..lineTo(5, 6)
      ..moveTo(12, 18)..lineTo(10, 6)
      // Body & Hump
      ..moveTo(-12, 6)
      ..quadraticBezierTo(-8, -4, -2, -10)
      ..quadraticBezierTo(2, -14, 6, -10)
      ..quadraticBezierTo(10, -6, 14, 4)
      ..lineTo(-12, 6)
      // Neck and head
      ..moveTo(-10, 4)
      ..quadraticBezierTo(-16, -2, -18, -14)
      ..lineTo(-22, -16)
      ..lineTo(-20, -12)
      ..quadraticBezierTo(-15, -4, -8, 4);

    final outlinePaint = Paint()
      ..color = paint.color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, outlinePaint);
    canvas.drawCircle(const Offset(2, -6), 8, paint); // hump fill
    canvas.restore();
  }

  void _drawCactus(Canvas canvas, Paint paint, Offset base, double height) {
    final path = Path()
      // Main trunk
      ..moveTo(base.dx, base.dy)
      ..lineTo(base.dx, base.dy - height)
      // Left arm
      ..moveTo(base.dx, base.dy - height * 0.45)
      ..lineTo(base.dx - 12, base.dy - height * 0.45)
      ..lineTo(base.dx - 12, base.dy - height * 0.75)
      // Right arm
      ..moveTo(base.dx, base.dy - height * 0.6)
      ..lineTo(base.dx + 11, base.dy - height * 0.6)
      ..lineTo(base.dx + 11, base.dy - height * 0.88);
    canvas.drawPath(path, paint);
  }

  void _drawBird(Canvas canvas, Paint paint, Offset pos) {
    final path = Path()
      ..moveTo(pos.dx - 7, pos.dy + 3)
      ..quadraticBezierTo(pos.dx - 3, pos.dy - 3, pos.dx, pos.dy)
      ..quadraticBezierTo(pos.dx + 3, pos.dy - 3, pos.dx + 7, pos.dy + 3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
