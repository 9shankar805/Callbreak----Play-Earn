import 'dart:math' as math;
import 'package:flutter/material.dart';

class CallbreakPlayerAvatar extends StatelessWidget {
  final int seat;
  final String name;
  final String avatarPath;
  final String flag;
  final int? bid;
  final int tricksWon;
  final bool isActive;
  final bool isDealer;
  final bool isHuman;
  final int cardCount;
  final String? activeEmote;
  final VoidCallback? onEmoteTap;

  const CallbreakPlayerAvatar({
    super.key,
    this.seat = 0,
    required this.name,
    required this.avatarPath,
    required this.flag,
    required this.bid,
    required this.tricksWon,
    required this.isActive,
    this.isDealer = false,
    this.isHuman = false,
    this.cardCount = 13,
    this.activeEmote,
    this.onEmoteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isHuman) {
      return _buildHumanWidget();
    }

    if (seat == 2) {
      // ── Top Bot: bot3 (opposite to You) ──
      // Horizontal capsule bar running behind avatar (matching "You" & Screenshot layout)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Fanned cards behind bot avatar
              if (cardCount > 0)
                _buildFannedCardsBehind(),

              // Dark capsule bar running behind avatar
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C160B).withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12, width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Left side: bot3 ♠
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          '♠',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(width: 58), // Spacer for centered avatar
                    // Right side: Trick score / bid pill
                    _buildTrickScorePill(),
                  ],
                ),
              ),

              // Centered Avatar Circle
              _buildAvatarCircle(),

              // Dealer 'D' coin
              if (isDealer)
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: _buildDealerCoin(),
                ),

              // Emote bubble if active
              if (activeEmote != null)
                Positioned(
                  bottom: -28,
                  child: _buildEmoteBubble(activeEmote!),
                ),
            ],
          ),
        ],
      );
    }

    // ── Left (bot1, seat 3) & Right (bot2, seat 1) Bots ──
    // Name pill on top, Trick Score Pill on bottom (same like You)
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name pill (above avatar)
        _buildNamePill(),
        const SizedBox(height: 2),

        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Fanned cards behind bot avatars
            if (cardCount > 0)
              _buildFannedCardsBehind(),

            // Avatar Circle
            _buildAvatarCircle(),

            // Dealer 'D' coin
            if (isDealer)
              Positioned(
                right: -2,
                bottom: 2,
                child: _buildDealerCoin(),
              ),

            // Trick Score Pill attached to bottom of circle (same like You)
            if (bid != null || isActive)
              Positioned(
                bottom: -8,
                child: _buildTrickScorePill(),
              ),

            // Emote bubble if active
            if (activeEmote != null)
              Positioned(
                top: -28,
                child: _buildEmoteBubble(activeEmote!),
              ),
          ],
        ),
      ],
    );
  }

  // ── Human Player Widget (with combined bottom pill bar) ───────────────────────

  Widget _buildHumanWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Dark capsule bar running behind avatar (matching Screenshot 3)
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF2C160B).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left side: green dot + You + spade
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF76FF03),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        '♠',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(width: 68), // Spacer for centered avatar
                  // Right side: | 💎 100
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 1, height: 12, color: Colors.white24),
                      const SizedBox(width: 5),
                      const Text('💎', style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 3),
                      const Text(
                        '100',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Centered Avatar
            _buildAvatarCircle(),

            // Dealer coin
            if (isDealer)
              Positioned(
                right: 4,
                bottom: 0,
                child: _buildDealerCoin(),
              ),

            // Trick Score Pill attached to bottom of circle (matching bots: bid/tricksWon)
            if (bid != null || isActive)
              Positioned(
                bottom: -8,
                child: _buildTrickScorePill(),
              ),

            // Emote bubble if active
            if (activeEmote != null)
              Positioned(
                top: -28,
                child: _buildEmoteBubble(activeEmote!),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDealerCoin() {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE5B54E),
        border: Border.all(color: const Color(0xFF6B4515), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x44000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: const Center(
        child: Text(
          'D',
          style: TextStyle(
            color: Color(0xFF3E1F0D),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCircle() {
    final avatarSize = isHuman ? 54.0 : 48.0;

    return _ActiveTurnRing(
      isActive: isActive,
      isHuman: isHuman,
      size: avatarSize,
      child: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isHuman ? const Color(0xFFFAF5ED) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? const Color(0xFFFFD54F).withValues(alpha: 0.5)
                  : const Color(0x3D000000),
              blurRadius: isActive ? 10 : 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ring (Gold ring for You, crisp white for Bots)
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHuman ? const Color(0xFFF3DE8A) : Colors.white,
                  width: isHuman ? 2.4 : 2.0,
                ),
              ),
            ),
            // Avatar Image
            ClipOval(
              child: Image.asset(
                avatarPath,
                width: avatarSize - 4.8,
                height: avatarSize - 4.8,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF4A2A18),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Professional card fan matching callbreak.com — wider arc, bigger cards, proper directional spread
  Widget _buildFannedCardsBehind() {
    final count = cardCount.clamp(1, 13);

    // Card dimensions matching callbreak.com visible card size
    const cardWidth = 24.0;
    const cardHeight = 36.0;

    // Outer container size — big enough to hold full arc
    const boxSize = 110.0;

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: List.generate(count, (i) {
          final t = count == 1
              ? 0.0
              : (i - (count - 1) / 2.0) / ((count - 1) / 2.0); // -1.0 to +1.0

          double x = 0.0;
          double y = 0.0;
          double rotation = 0.0;

          if (seat == 2) {
            // ── Top Bot: horizontal cards in wide arc below avatar ──
            // Cards lie FLAT (horizontal) like left/right bots, not standing up (which causes V shape)
            const spread = 0.62;
            final theta = t * spread;
            const radius = 42.0;
            const baseY = 30.0; // base distance below avatar center
            x = radius * math.sin(theta);                // spread left-right
            y = baseY + radius * (1 - math.cos(theta));  // gentle downward arc
            rotation = theta + (math.pi / 2);            // horizontal orientation — matches left/right bots
          } else if (seat == 3) {
            // ── Left Bot (bot1): wide arc fanning RIGHTWARD toward table ──
            const spread = 0.68;
            final theta = t * spread;
            const radius = 36.0;
            x = radius * math.cos(theta);
            y = radius * math.sin(theta);
            rotation = theta + (math.pi / 2.0);
          } else if (seat == 1) {
            // ── Right Bot (bot2): wide arc fanning LEFTWARD toward table ──
            const spread = 0.68;
            final theta = t * spread;
            const radius = 36.0;
            x = -radius * math.cos(theta);
            y = radius * math.sin(theta);
            rotation = -theta - (math.pi / 2.0);
          } else {
            const spread = 0.60;
            final theta = t * spread;
            x = 34.0 * math.sin(theta);
            y = 34.0 * math.cos(theta);
            rotation = theta;
          }

          return Transform.translate(
            offset: Offset(x, y),
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.5),
                  border: Border.all(color: const Color(0xFFD9CBBF), width: 0.8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 3.5,
                      offset: Offset(0, 1.5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/cards/back_red.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFC62828),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Trick score capsule (matching Screenshot 3: "1/0" for bot1, empty capsule for pending)
  Widget _buildTrickScorePill() {
    return _AnimatedTrickPill(
      bid: bid,
      tricksWon: tricksWon,
      isActive: isActive,
    );
  }

  // Name tag with name and spade badge (Screenshot 3: bot1 ♠, bot2 ♠, bot3 ♠)
  Widget _buildNamePill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2A160C).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white12,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '♠',
            style: TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildEmoteBubble(String emote) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Text(emote, style: const TextStyle(fontSize: 16)),
    );
  }
}

/// Dynamic rotating and pulsing turn indicator ring surrounding the active player's avatar
class _ActiveTurnRing extends StatefulWidget {
  final bool isActive;
  final bool isHuman;
  final double size;
  final Widget child;

  const _ActiveTurnRing({
    required this.isActive,
    required this.isHuman,
    required this.size,
    required this.child,
  });

  @override
  State<_ActiveTurnRing> createState() => _ActiveTurnRingState();
}

class _ActiveTurnRingState extends State<_ActiveTurnRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _ActiveTurnRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final pulse = math.sin(t * math.pi * 2);
        final glowAlpha = (0.45 + 0.35 * pulse).clamp(0.2, 0.85);

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer golden pulse aura
            Container(
              width: widget.size + 8 + 4 * pulse,
              height: widget.size + 8 + 4 * pulse,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54F).withValues(alpha: glowAlpha),
                    blurRadius: 12 + 6 * pulse,
                    spreadRadius: 2 + 2 * pulse,
                  ),
                ],
              ),
            ),
            // Rotating gradient border
            Transform.rotate(
              angle: t * 2 * math.pi,
              child: Container(
                width: widget.size + 6,
                height: widget.size + 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Color(0xFFFFD54F),
                      Color(0xFFFFB300),
                      Color(0xFFFFF9C4),
                      Color(0xFFFFD54F),
                    ],
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
      child: widget.child,
    );
  }
}

/// Animated trick score pill with scale bounce on score increment
class _AnimatedTrickPill extends StatefulWidget {
  final int? bid;
  final int tricksWon;
  final bool isActive;

  const _AnimatedTrickPill({
    required this.bid,
    required this.tricksWon,
    required this.isActive,
  });

  @override
  State<_AnimatedTrickPill> createState() => _AnimatedTrickPillState();
}

class _AnimatedTrickPillState extends State<_AnimatedTrickPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _bumpController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _bumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_bumpController);
  }

  @override
  void didUpdateWidget(covariant _AnimatedTrickPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tricksWon > oldWidget.tricksWon) {
      _bumpController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasBid = widget.bid != null;
    final isMet = hasBid && widget.tricksWon >= widget.bid!;

    return AnimatedBuilder(
      animation: _bumpController,
      builder: (context, child) {
        final scale = _bumpController.isAnimating ? _scaleAnimation.value : 1.0;
        final isBumping = _bumpController.isAnimating;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: 48,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isBumping
                  ? const Color(0xFFF57F17)
                  : (isMet
                      ? const Color(0xFF1B4D20).withValues(alpha: 0.95)
                      : const Color(0xFF2C160B).withValues(alpha: 0.92)),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: isBumping
                    ? const Color(0xFFFFEB3B)
                    : (isMet
                        ? const Color(0xFF76FF03)
                        : (widget.isActive ? const Color(0xFFFFD54F) : Colors.white12)),
                width: isBumping || isMet || widget.isActive ? 1.4 : 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: isBumping
                      ? const Color(0xFFFFD54F).withValues(alpha: 0.8)
                      : const Color(0x40000000),
                  blurRadius: isBumping ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: hasBid
                ? Text(
                    '${widget.bid}/${widget.tricksWon}',
                    style: TextStyle(
                      color: isBumping
                          ? Colors.white
                          : (isMet ? const Color(0xFF76FF03) : Colors.white),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  )
                : (widget.isActive
                    ? const Text(
                        'Bid...',
                        style: TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const SizedBox.shrink()),
          ),
        );
      },
    );
  }
}

