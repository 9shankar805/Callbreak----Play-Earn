import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LottieCoinWidget
//
//  Two modes:
//    CoinMode.spin    — looping gold coin flip (for balance displays)
//    CoinMode.reward  — one-shot burst animation (for win/daily-bonus popups)
// ─────────────────────────────────────────────────────────────────────────────

enum CoinMode { spin, reward }

class LottieCoinWidget extends StatefulWidget {
  final CoinMode mode;
  final double size;
  final VoidCallback? onRewardComplete;

  const LottieCoinWidget({
    super.key,
    this.mode = CoinMode.spin,
    this.size = 80,
    this.onRewardComplete,
  });

  @override
  State<LottieCoinWidget> createState() => _LottieCoinWidgetState();
}

class _LottieCoinWidgetState extends State<LottieCoinWidget>
    with TickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _assetPath => widget.mode == CoinMode.spin
      ? 'assets/lottie/coin_spin.json'
      : 'assets/lottie/coin_reward.json';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  widget.size,
      height: widget.size,
      child: Lottie.asset(
        _assetPath,
        controller: _ctrl,
        fit: BoxFit.contain,
        onLoaded: (composition) {
          _ctrl.duration = composition.duration;
          if (widget.mode == CoinMode.spin) {
            _ctrl.repeat();
          } else {
            _ctrl.forward().whenComplete(() {
              widget.onRewardComplete?.call();
            });
          }
        },
        errorBuilder: (_, __, ___) => _FallbackCoin(size: widget.size),
      ),
    );
  }
}

// ── Fallback if Lottie fails (CustomPaint gold coin) ─────────────────────────

class _FallbackCoin extends StatelessWidget {
  final double size;
  const _FallbackCoin({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoldCoinPainter()),
    );
  }
}

class _GoldCoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = size.width  / 2 - 4;

    // Outer glow
    final glowPaint = Paint()
      ..color   = const Color(0xFFFFD700).withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(cx, cy), r + 6, glowPaint);

    // Body gradient simulation — draw concentric circles
    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final gradient = RadialGradient(
      center: const Alignment(-0.3, -0.4),
      radius: 1.0,
      colors: const [Color(0xFFFFF5A0), Color(0xFFFFB300), Color(0xFFB8860B)],
    );
    bodyPaint.shader = gradient.createShader(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
    );
    canvas.drawCircle(Offset(cx, cy), r, bodyPaint);

    // Edge ring
    final edgePaint = Paint()
      ..style       = PaintingStyle.stroke
      ..color       = const Color(0xFFB8860B)
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(cx, cy), r, edgePaint);

    // Inner ring
    final innerPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..color       = const Color(0xFFDAA520).withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(cx, cy), r * 0.78, innerPaint);

    // Spade symbol ♠
    final textPainter = TextPainter(
      text: TextSpan(
        text: '♠',
        style: TextStyle(
          fontSize: r * 0.85,
          color: const Color(0xFF7A5200),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );

    // Highlight
    final hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - r * 0.28, cy - r * 0.35),
        width:  r * 0.5,
        height: r * 0.3,
      ),
      hlPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Convenience: animated coin that bounces on appear ─────────────────────────

class BouncingCoin extends StatefulWidget {
  final double size;
  const BouncingCoin({super.key, this.size = 64});

  @override
  State<BouncingCoin> createState() => _BouncingCoinState();
}

class _BouncingCoinState extends State<BouncingCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: LottieCoinWidget(size: widget.size),
    );
  }
}
