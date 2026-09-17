import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../services/sound_service.dart';

class BiddingOverlay extends StatefulWidget {
  const BiddingOverlay({super.key});

  @override
  State<BiddingOverlay> createState() => _BiddingOverlayState();
}

class _BiddingOverlayState extends State<BiddingOverlay>
    with SingleTickerProviderStateMixin {
  int _selectedBid = 1;
  bool _initialized = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    return Consumer<GameController>(
      builder: (context, game, _) {
        // Only auto-set hint bid on first show if suggestBid setting is ON
        if (!_initialized) {
          _selectedBid = game.suggestBid
              ? game.hintBid.clamp(1, 8)
              : 1;
          _initialized = true;
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildMakeACallDialog(context, game),
          ),
        );
      },
    );
  }

  Widget _buildMakeACallDialog(BuildContext context, GameController game) {
    const minBid = 1;
    const maxBid = 8;

    return Align(
      alignment: const Alignment(0, -0.06),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 412,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5ED),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEADBCC),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title: Centered bold Make your bid (Screenshot 3)
              const Text(
                'Make your bid',
                style: TextStyle(
                  color: Color(0xFF4A2411),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),

              // Numbers 1 to 8 and ... above track (Full width clickable columns)
              Row(
                children: [
                  ...List.generate(8, (i) {
                    final num = i + 1;
                    final isSelected = num == _selectedBid;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          SoundService.instance.playButtonClick();
                          setState(() => _selectedBid = num);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          alignment: Alignment.center,
                          child: Text(
                            '$num',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF3E1F0D)
                                  : const Color(0xFF7D6E66),
                              fontSize: isSelected ? 14.5 : 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      alignment: Alignment.center,
                      child: const Text(
                        '...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7D6E66),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Slider Track (100% Clickable & Draggable across compact 26px height)
              LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;
                  const knobWidth = 32.0;
                  final usableTrack = trackWidth - knobWidth;
                  final stepWidth = usableTrack / 7;
                  final knobLeft = ((_selectedBid - 1) * stepWidth).clamp(0.0, usableTrack);

                  void updateFromPosition(double localDx) {
                    final fraction = (localDx / trackWidth).clamp(0.0, 1.0);
                    final newBid = (fraction * 7).round() + 1;
                    final clamped = newBid.clamp(minBid, maxBid);
                    if (clamped != _selectedBid) {
                      SoundService.instance.playButtonClick();
                      setState(() => _selectedBid = clamped);
                    }
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) => updateFromPosition(details.localPosition.dx),
                    onPanDown: (details) => updateFromPosition(details.localPosition.dx),
                    onPanUpdate: (details) => updateFromPosition(details.localPosition.dx),
                    onHorizontalDragDown: (details) => updateFromPosition(details.localPosition.dx),
                    onHorizontalDragUpdate: (details) => updateFromPosition(details.localPosition.dx),
                    child: Container(
                      height: 26,
                      width: trackWidth,
                      color: Colors.transparent, // Intercepts taps & clicks
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // Track groove
                          Container(
                            height: 5,
                            width: trackWidth,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCD4C7),
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          // Custom Slider Knob with ||| (matching Screenshot 3)
                          Positioned(
                            left: knobLeft,
                            child: Container(
                              width: knobWidth,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B3A22),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFA65C45), width: 1.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(width: 1.8, height: 10, color: const Color(0xFFD49984)),
                                  const SizedBox(width: 2.5),
                                  Container(width: 1.8, height: 10, color: const Color(0xFFD49984)),
                                  const SizedBox(width: 2.5),
                                  Container(width: 1.8, height: 10, color: const Color(0xFFD49984)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6),

              // Controls row (Bulb + Tooltip, [-] Count [+], Confirm [✓])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lightbulb button + tooltip — only shown when suggestBid is ON
                  if (game.suggestBid)
                    SizedBox(
                      width: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              SoundService.instance.playButtonClick();
                              final hint = game.hintBid.clamp(minBid, maxBid);
                              setState(() => _selectedBid = hint);
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF8B3A22),
                                border: Border.all(color: const Color(0xFFA65C45), width: 1.2),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1.5)),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Color(0xFFFFF2A8),
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDEED9),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: const Color(0xFFE5CDB0), width: 0.8),
                              ),
                              child: const Text(
                                'Toggle Suggested Bid',
                                style: TextStyle(
                                  color: Color(0xFF5A3822),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox(width: 90), // Keep layout balanced when hidden

                  // - Bid + Stepper in center
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Minus button
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_selectedBid > minBid) {
                              SoundService.instance.playButtonClick();
                              setState(() => _selectedBid--);
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFA65C45),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBF7A65), width: 1.0),
                              boxShadow: const [
                                BoxShadow(color: Color(0x28000000), blurRadius: 2.5, offset: Offset(0, 1.5)),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '-',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Selected bid number display
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$_selectedBid',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF2A1206),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Plus button
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_selectedBid < maxBid) {
                              SoundService.instance.playButtonClick();
                              setState(() => _selectedBid++);
                            }
                          },
                          child: Container(
                            width: 38,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B3A22),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA65C45), width: 1.0),
                              boxShadow: const [
                                BoxShadow(color: Color(0x28000000), blurRadius: 2.5, offset: Offset(0, 1.5)),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Confirm button (Green rounded checkmark button - 100% responsive)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        game.humanBid(_selectedBid);
                      },
                      child: Container(
                        width: 56,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EB846),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF43C95A), width: 1.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332EB846),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
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
}
