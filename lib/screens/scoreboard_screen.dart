import 'package:flutter/material.dart';
import '../controller/game_controller.dart';
import '../models/trick_model.dart';

class ScoreboardSheet extends StatelessWidget {
  final GameController game;
  const ScoreboardSheet({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = (size.width * 0.84).clamp(560.0, 720.0);
    final dialogHeight = (size.height * 0.88).clamp(320.0, 390.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: SizedBox(
          width: dialogWidth,
          height: dialogHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Scoreboard Modal Container
              Container(
                width: dialogWidth,
                height: dialogHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDECBB0), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 28,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left Tabs + Binder Holes
                    _buildLeftTabs(),

                    // Main Scoreboard Table
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Date & Time Row at top left
                            const Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                '9 Sep, 2026\n12:15',
                                style: TextStyle(
                                  color: Color(0xFF6E5240),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Columns Header Row
                            _buildHeaderRow(),
                            const SizedBox(height: 4),
                            const Divider(color: Color(0xFFDEC39D), height: 1, thickness: 1.2),

                            // Scrollable table rows
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: Column(
                                  children: [
                                    for (int r = 1; r <= 5; r++) ...[
                                      _buildRoundRow(r),
                                      if (r < 5) _buildDottedDivider(),
                                    ],
                                    const SizedBox(height: 6),
                                    const Divider(color: Color(0xFFDEC39D), height: 1, thickness: 1.5),
                                    const SizedBox(height: 4),
                                    _buildOverallScoreRow(),
                                    const SizedBox(height: 4),
                                    const Divider(color: Color(0xFFDEC39D), height: 1, thickness: 1.5),
                                    const SizedBox(height: 4),
                                    _buildFinalScoreRow(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cute 3D Red/Orange Close Button at top-right (Screenshot 1)
              Positioned(
                top: -10,
                right: -10,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8583B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE88A72), width: 1.8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Left Vertical Tabs (Normal, Bots Mode, 5 Round + Binder Holes) ─────────

  Widget _buildLeftTabs() {
    return Container(
      width: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFF0DFC5),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(15)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPillTab('Normal', isSelected: false),
              const SizedBox(height: 5),
              _buildPillTab('Bots Mode', isSelected: false),
              const SizedBox(height: 5),
              _buildPillTab('5 Round', isSelected: true),
            ],
          ),
          // 3 Binder Hole punches
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < 3; i++)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF381F10),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab(String title, {required bool isSelected}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2C160B) : const Color(0xFF7A4526),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFF5DDCC),
            fontSize: 9,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ── Header Row (bot3, bot1, You with golden highlight, bot2, Sum) ─────────

  Widget _buildHeaderRow() {
    // Columns match Screenshot 1: bot3, bot1, You (highlighted), bot2, Sum
    final seats = [2, 3, 0, 1];

    return Row(
      children: [
        const SizedBox(
          width: 70,
          child: Text(
            'Rounds',
            style: TextStyle(
              color: Color(0xFF3E1F0D),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (int seat in seats) ...[
          Expanded(
            child: Container(
              color: seat == 0 ? const Color(0xFFF7EAC4) : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _buildPlayerHeader(seat),
            ),
          ),
        ],
        const SizedBox(
          width: 50,
          child: Text(
            'Sum',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF3E1F0D),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerHeader(int seat) {
    final p = game.players[seat];
    final isYou = p.isHuman;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 3),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  p.avatarPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.smart_toy_outlined, size: 20),
                ),
              ),
            ),
            if (isYou)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              p.name,
              style: TextStyle(
                color: const Color(0xFF2C160B),
                fontSize: 11,
                fontWeight: isYou ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            const SizedBox(width: 3),
            const Text('♠', style: TextStyle(color: Color(0xFF2C160B), fontSize: 10)),
          ],
        ),
      ],
    );
  }

  // ── Round Row ──────────────────────────────────────────────────────────────

  Widget _buildRoundRow(int roundNumber) {
    final isDone = game.roundHistory.length >= roundNumber;
    final rData = isDone ? game.roundHistory[roundNumber - 1] : null;
    final isCurrent = game.currentRound == roundNumber;

    // Mapping: bot3(2), bot1(3), You(0), bot2(1)
    final seats = [2, 3, 0, 1];

    int sumBids = 0;
    if (rData != null) {
      sumBids = rData.bids.fold(0, (acc, b) => acc + b);
    } else if (isCurrent) {
      sumBids = game.players.fold(0, (acc, p) => acc + (p.bid ?? 0));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '(R$roundNumber)',
              style: const TextStyle(
                color: Color(0xFF5A3822),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (int seat in seats) ...[
            Expanded(
              child: Container(
                color: seat == 0 ? const Color(0xFFF7EAC4) : Colors.transparent,
                alignment: Alignment.center,
                child: Text(
                  _formatRowScore(rData, seat, isCurrent),
                  style: TextStyle(
                    color: const Color(0xFF2C160B),
                    fontSize: 12,
                    fontWeight: seat == 0 ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          SizedBox(
            width: 50,
            child: Text(
              sumBids > 0 ? '$sumBids' : '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3E1F0D),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatRowScore(RoundResult? rData, int seat, bool isCurrent) {
    if (rData != null) {
      final bid = rData.bids[seat];
      final won = rData.tricksWon[seat];
      return '$bid / $won';
    }
    if (isCurrent && game.players[seat].bid != null) {
      final bid = game.players[seat].bid!;
      final won = game.players[seat].tricksWon;
      return '$bid / $won';
    }
    return '';
  }

  // ── Overall Score Row ──────────────────────────────────────────────────────

  Widget _buildOverallScoreRow() {
    final seats = [2, 3, 0, 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const SizedBox(
            width: 70,
            child: Text(
              'Overall\nScore',
              style: TextStyle(
                color: Color(0xFF2C160B),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          for (int seat in seats) ...[
            Expanded(
              child: Container(
                color: seat == 0 ? const Color(0xFFF7EAC4) : Colors.transparent,
                alignment: Alignment.center,
                child: Text(
                  game.totalScores[seat].toStringAsFixed(1),
                  style: TextStyle(
                    color: seat == 0 ? const Color(0xFF2E7D32) : const Color(0xFF2C160B),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  // ── Final Score Row ────────────────────────────────────────────────────────

  Widget _buildFinalScoreRow() {
    final seats = [2, 3, 0, 1];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const SizedBox(
            width: 70,
            child: Text(
              'Final\nScore',
              style: TextStyle(
                color: Color(0xFF9E8A7A),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          for (int seat in seats) ...[
            Expanded(
              child: Container(
                color: seat == 0 ? const Color(0xFFF7EAC4) : Colors.transparent,
                alignment: Alignment.center,
                child: Text(
                  game.phase == GamePhase.gameOver
                      ? game.totalScores[seat].toStringAsFixed(1)
                      : '',
                  style: const TextStyle(
                    color: Color(0xFF2C160B),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 50),
        ],
      ),
    );
  }

  Widget _buildDottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const dashWidth = 3.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFE2C9A6)),
              ),
            );
          }),
        );
      },
    );
  }
}
