import 'package:flutter/material.dart';
import '../models/card_model.dart';

/// Renders authentic playing cards from The Public Domain Deck (AustinGabriel / CC0).
/// Supports transparent rounded corners, selection glow, dimming for illegal moves,
/// and vector fallback in case of asset errors.
class PlayingCardWidget extends StatelessWidget {
  final PlayingCard? card; // null = card back
  final bool isLegal;
  final bool isSelected;
  final bool isFaceDown;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final VoidCallback? onPanCancel;

  const PlayingCardWidget({
    super.key,
    this.card,
    this.isLegal = true,
    this.isSelected = false,
    this.isFaceDown = false,
    this.width = 54,
    this.height = 78,
    this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = card;
    final showBack = isFaceDown || c == null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * 0.09),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF00E676).withValues(alpha: 0.85),
                blurRadius: 10,
                spreadRadius: 2.0,
                offset: const Offset(0, -2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 5,
                offset: const Offset(1, 3),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(width * 0.08),
          child: Opacity(
            opacity: (!isLegal && !showBack) ? 0.65 : 1.0,
            child: showBack ? _buildCardBack() : _buildCardFront(c),
          ),
        ),
      ),
    );
  }

  // Authentic Public Domain Deck Card Front
  Widget _buildCardFront(PlayingCard c) {
    return Image.asset(
      c.assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _buildFallbackFace(c),
    );
  }

  // Authentic Public Domain Deck Red Card Back
  Widget _buildCardBack() {
    return Image.asset(
      'assets/cards/back_red.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => _buildFallbackBack(),
    );
  }

  // ── Fallback Renderers (Used only if image asset fails to load) ──

  Widget _buildFallbackBack() {
    return Container(
      padding: const EdgeInsets.all(2.5),
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFC62828),
          borderRadius: BorderRadius.circular(width * 0.08),
        ),
        child: Center(
          child: Text(
            '♠',
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackFace(PlayingCard c) {
    final color = c.suit.color;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(3),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  c.rank.display,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.26,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                Text(
                  c.suit.symbol,
                  style: TextStyle(color: color, fontSize: width * 0.20, height: 1.0),
                ),
              ],
            ),
          ),
          Center(
            child: Text(
              c.suit.symbol,
              style: TextStyle(color: color, fontSize: width * 0.45),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: RotatedBox(
              quarterTurns: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c.rank.display,
                    style: TextStyle(
                      color: color,
                      fontSize: width * 0.26,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    c.suit.symbol,
                    style: TextStyle(color: color, fontSize: width * 0.20, height: 1.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
