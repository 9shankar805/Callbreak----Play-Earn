import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/trick_model.dart';
import 'playing_card_widget.dart';

/// An authentic trick collection sweep animation:
/// 1. Highlights the winning card with a glowing gold aura.
/// 2. Gathers all 4 played cards into a neat center stack.
/// 3. Sweeps the stack swiftly into the winner's seat avatar / tricks pile.
class TrickSweepOverlay extends StatefulWidget {
  final List<TrickPlay> trick;
  final int winnerSeat;
  final Map<int, Offset> seatCardOffsets; // Center table offsets for each seat
  final Map<int, Offset> seatTargetOffsets; // Screen coordinates for each seat's avatar
  final Duration duration;
  final VoidCallback onCompleted;

  const TrickSweepOverlay({
    super.key,
    required this.trick,
    required this.winnerSeat,
    required this.seatCardOffsets,
    required this.seatTargetOffsets,
    this.duration = const Duration(milliseconds: 950),
    required this.onCompleted,
  });

  @override
  State<TrickSweepOverlay> createState() => _TrickSweepOverlayState();
}

class _TrickSweepOverlayState extends State<TrickSweepOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _controller.forward().then((_) {
      if (mounted) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2 - 10,
    );

    final winnerTarget = widget.seatTargetOffsets[widget.winnerSeat] ?? center;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;

        // Stage 1: Winner highlight (0.0 to 0.35)
        // Stage 2: Gather to center stack (0.35 to 0.60)
        // Stage 3: Sweep to winner avatar (0.60 to 1.0)
        return IgnorePointer(
          child: Stack(
            children: widget.trick.map((play) {
              final isWinner = play.seat == widget.winnerSeat;
              final seatTableOffset = widget.seatCardOffsets[play.seat] ?? Offset.zero;
              final startPos = center + seatTableOffset;

              Offset currentPos;
              double scale = 1.0;
              double opacity = 1.0;
              double rotation = 0.0;

              if (t <= 0.35) {
                // Phase 1: Sitting at table with winner highlight
                currentPos = startPos;
                if (isWinner) {
                  // Pulse scale
                  scale = 1.0 + 0.12 * math.sin(t / 0.35 * math.pi);
                }
              } else if (t <= 0.60) {
                // Phase 2: Gather cards to center
                final gatherProgress = Curves.easeInOutCubic.transform((t - 0.35) / 0.25);
                currentPos = Offset.lerp(startPos, center, gatherProgress)!;
                // Slight stagger rotation as they stack
                rotation = (play.seat - 1.5) * 0.08 * gatherProgress;
              } else {
                // Phase 3: Sweep toward winner avatar
                final sweepProgress = Curves.easeInCubic.transform((t - 0.60) / 0.40);
                currentPos = Offset.lerp(center, winnerTarget, sweepProgress)!;
                scale = 1.0 - (0.65 * sweepProgress);
                opacity = (1.0 - (sweepProgress * 1.2)).clamp(0.0, 1.0);
                rotation = (play.seat - 1.5) * 0.15 + sweepProgress * 0.4;
              }

              if (opacity <= 0.0) return const SizedBox.shrink();

              return Positioned(
                left: currentPos.dx,
                top: currentPos.dy,
                child: Transform.translate(
                  offset: const Offset(-30, -42), // Half card dimensions (60x84)
                  child: Transform.rotate(
                    angle: rotation,
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          decoration: (isWinner && t <= 0.60)
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700)
                                          .withValues(alpha: 0.85),
                                      blurRadius: 20,
                                      spreadRadius: 3,
                                    ),
                                    const BoxShadow(
                                      color: Color(0xFF76FF03),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                )
                              : BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              PlayingCardWidget(
                                card: play.card,
                                width: 60,
                                height: 84,
                                isSelected: isWinner && t <= 0.35,
                              ),
                              if (isWinner && t <= 0.55)
                                Positioned(
                                  top: -10,
                                  right: -10,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFB300),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x66000000),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      '👑',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
