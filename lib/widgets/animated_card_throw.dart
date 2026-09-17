import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/card_model.dart';
import 'playing_card_widget.dart';

/// Renders a card flying from a player's seat origin to the center trick table.
class AnimatedCardThrow extends StatefulWidget {
  final PlayingCard card;
  final Offset startOffset;
  final Offset endOffset;
  final double endRotation;
  final Duration duration;
  final VoidCallback onCompleted;

  const AnimatedCardThrow({
    super.key,
    required this.card,
    required this.startOffset,
    required this.endOffset,
    this.endRotation = 0.0,
    this.duration = const Duration(milliseconds: 300),
    required this.onCompleted,
  });

  @override
  State<AnimatedCardThrow> createState() => _AnimatedCardThrowState();
}

class _AnimatedCardThrowState extends State<AnimatedCardThrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curve;
  late double _startRotation;

  @override
  void initState() {
    super.initState();
    // Slight random toss rotation variation
    final random = math.Random();
    _startRotation = (random.nextDouble() - 0.5) * 0.35;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onCompleted();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        // Position lerp
        final currentPos = Offset.lerp(widget.startOffset, widget.endOffset, t)!;
        // Rotation lerp
        final currentRot = math.sin(t * math.pi) * 0.15 +
            math.cos(t * math.pi / 2) * _startRotation +
            (1 - math.cos(t * math.pi / 2)) * widget.endRotation;
        // Elevation scale
        final scale = 0.92 + 0.14 * math.sin(t * math.pi);
        // Shadow elevation
        final shadowElevation = 18.0 * math.sin(t * math.pi) + 4.0;

        return Positioned(
          left: currentPos.dx,
          top: currentPos.dy,
          child: Transform.translate(
            offset: const Offset(-30, -42), // Half card size (60x84)
            child: Transform.rotate(
              angle: currentRot,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35 + 0.15 * math.sin(t * math.pi)),
                        blurRadius: shadowElevation,
                        spreadRadius: 1,
                        offset: Offset(0, shadowElevation * 0.5),
                      ),
                    ],
                  ),
                  child: PlayingCardWidget(
                    card: widget.card,
                    width: 60,
                    height: 84,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
