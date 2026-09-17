import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/playing_card_widget.dart';

/// Authentic Callbreak dealing animation matching callbreak.com.
/// Features a center deck from which cards rapidly fly outwards
/// to all 4 player seats (Bottom, Right, Top, Left) with sound and rotation.
class DealingAnimationOverlay extends StatefulWidget {
  final VoidCallback onSkip;

  const DealingAnimationOverlay({
    super.key,
    required this.onSkip,
  });

  @override
  State<DealingAnimationOverlay> createState() => _DealingAnimationOverlayState();
}

class _DealingAnimationOverlayState extends State<DealingAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // 4 Dealing streams (0: You/Bottom, 1: Right/bot2, 2: Top/bot3, 3: Left/bot1)
  // We simulate 3 rapid waves of cards dealt in clockwise order
  static const int _cardsPerStream = 3;
  static const int _totalStreams = 4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onSkip,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final center = Offset(w / 2, h / 2 - 10);

          // Target positions for the 4 seats (matching further-back bot locations)
          final targets = [
            Offset(w / 2, h - 50),          // 0: Bottom (You)
            Offset(w - 42, h / 2 - 42),     // 1: Right (bot2)
            Offset(w / 2, 38),              // 2: Top (bot3)
            Offset(42, h / 2 - 42),         // 3: Left (bot1)
          ];

          return Stack(
            children: [
              // Subtle dim background during deal
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.18),
                ),
              ),

              // Center Deck Stack
              Positioned(
                left: center.dx - 26,
                top: center.dy - 36,
                child: _buildCenterDeck(),
              ),

              // Flying cards animated via AnimatedBuilder
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = _controller.value;
                  final flyingCards = <Widget>[];

                  for (int wave = 0; wave < _cardsPerStream; wave++) {
                    for (int seat = 0; seat < _totalStreams; seat++) {
                      // Staggered timing for each card in clockwise rotation
                      final cardIndex = wave * _totalStreams + seat;
                      final startTime = (cardIndex * 0.065).clamp(0.0, 0.65);
                      final endTime = (startTime + 0.35).clamp(0.0, 1.0);

                      if (t >= startTime && t <= endTime) {
                        final progress = ((t - startTime) / (endTime - startTime))
                            .clamp(0.0, 1.0);
                        final curveProgress = Curves.easeOutCubic.transform(progress);

                        final startPos = center;
                        final targetPos = targets[seat];
                        final currentPos = Offset.lerp(startPos, targetPos, curveProgress)!;

                        // Target rotation angle based on seat direction
                        final targetAngle = seat == 1
                            ? math.pi / 2
                            : seat == 3
                                ? -math.pi / 2
                                : 0.0;
                        final currentAngle = targetAngle * curveProgress;
                        final scale = 0.85 + 0.15 * (1.0 - (curveProgress - 0.5).abs() * 0.4);

                        flyingCards.add(
                          Positioned(
                            left: currentPos.dx - 22,
                            top: currentPos.dy - 32,
                            child: Transform.rotate(
                              angle: currentAngle,
                              child: Transform.scale(
                                scale: scale,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: (0.35 * (1 - curveProgress)).clamp(0.0, 0.4),
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(2, 4),
                                      ),
                                    ],
                                  ),
                                  child: const PlayingCardWidget(
                                    card: null, // Card back
                                    width: 44,
                                    height: 64,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  }

                  return Stack(children: flyingCards);
                },
              ),

              // Dealing Banner & Tap to Skip indicator
              Positioned(
                top: 14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xDD1B0B02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFECC478).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD54F)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Dealing Cards...',
                          style: TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 12,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Tap to skip ⏩',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCenterDeck() {
    return Container(
      width: 52,
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Underlying stacked card edges to look like a thick deck
          Positioned(
            top: -4,
            left: -2,
            child: _deckLayer(),
          ),
          Positioned(
            top: -2,
            left: -1,
            child: _deckLayer(),
          ),
          // Topmost card
          const Positioned.fill(
            child: PlayingCardWidget(
              card: null,
              width: 52,
              height: 74,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deckLayer() {
    return Container(
      width: 52,
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xFF8B1E1E),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
      ),
    );
  }
}
