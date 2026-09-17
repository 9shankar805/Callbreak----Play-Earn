import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../services/sound_service.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, anim1, anim2) {
        return const Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SettingsDrawer(),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final drawerWidth = (media.size.width * 0.38).clamp(310.0, 360.0);

    return Consumer<GameController>(
      builder: (ctx, game, _) {
        final isMuted = SoundService.instance.isMuted;
        final musicOn = game.musicEnabled;

        return Container(
          width: drawerWidth,
          height: media.size.height,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE7BA),
            border: Border(
              left: BorderSide(color: Color(0xFFDEC39D), width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 20,
                offset: Offset(-4, 0),
              ),
            ],
          ),
          child: SafeArea(
            left: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header Row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          color: Color(0xFF3E1F0D),
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => Navigator.pop(ctx),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: Color(0xFF5A3822),
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFFE4CFB2), height: 1, thickness: 1),

                // ── Scrollable Settings Items ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Sound | Music
                        _buildRow(
                          title: 'Sound | Music',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => game.toggleSound(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Icon(
                                    isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                    color: isMuted ? const Color(0xFFA08775) : const Color(0xFF3E1F0D),
                                    size: 23,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1.2,
                                height: 20,
                                color: const Color(0xFFDEC39D),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => game.toggleMusic(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Icon(
                                    musicOn ? Icons.music_note_rounded : Icons.music_off_rounded,
                                    color: musicOn ? const Color(0xFF3E1F0D) : const Color(0xFFA08775),
                                    size: 23,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 2. Show mini scoreboard
                        _buildRow(
                          title: 'Show mini scoreboard',
                          trailing: _buildCustomSwitch(
                            value: game.showMiniScoreboard,
                            onChanged: (_) => game.toggleMiniScoreboard(),
                          ),
                        ),

                        // 3. Suggest Bid
                        _buildRow(
                          title: 'Suggest Bid',
                          trailing: _buildCustomSwitch(
                            value: game.suggestBid,
                            onChanged: (_) => game.toggleSuggestBid(),
                          ),
                        ),

                        // 4. Highlight valid cards
                        _buildRow(
                          title: 'Highlight valid cards',
                          trailing: _buildCustomSwitch(
                            value: game.highlightValidCards,
                            onChanged: (_) => game.toggleHighlightValidCards(),
                            activeColor: const Color(0xFFBA5233),
                          ),
                        ),

                        // 5. Touch to throw
                        _buildRow(
                          title: 'Touch to throw',
                          trailing: _buildCustomSwitch(
                            value: game.touchToThrow,
                            onChanged: (_) => game.toggleTouchToThrow(),
                            activeColor: const Color(0xFFBA5233),
                          ),
                        ),

                        // 6. Game speed
                        _buildRow(
                          title: 'Game speed',
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD999),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF8B3A22), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: ['Slow', 'Normal', 'Fast'].map((speed) {
                                final isSel = game.gameSpeed == speed;
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => game.setGameSpeed(speed),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSel ? const Color(0xFFBA5233) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      speed,
                                      style: TextStyle(
                                        color: isSel ? Colors.white : const Color(0xFF4A2A18),
                                        fontSize: 11.5,
                                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),

                        // 7. Restart / Quit Game
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            // Show dialog WHILE drawer is still open (ctx is valid)
                            _confirmQuitDialog(ctx, context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: const Text(
                              'Restart / Quit Game',
                              style: TextStyle(
                                color: Color(0xFF3E1F0D),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const Divider(color: Color(0xFFE4CFB2), height: 1, thickness: 1),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // drawerCtx = context inside the drawer route; gameCtx = game screen context
  static void _confirmQuitDialog(BuildContext drawerCtx, BuildContext gameCtx) {
    showDialog(
      context: drawerCtx,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF7E6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE8D4B0), width: 1.5),
        ),
        title: const Text(
          'Leave Match?',
          style: TextStyle(color: Color(0xFF3E1F0D), fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'Are you sure you want to exit to main menu?',
          style: TextStyle(color: Color(0xFF5A3822), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B4526))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              // Close dialog + drawer, then pop game screen back to home
              Navigator.of(dialogCtx).popUntil((route) => route.isFirst);
            },
            child: const Text('Leave', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRow({required String title, required Widget trailing}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF3E1F0D),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
        const Divider(color: Color(0xFFE4CFB2), height: 1, thickness: 1),
      ],
    );
  }

  Widget _buildCustomSwitch({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color activeColor = const Color(0xFFBA5233),
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? activeColor : const Color(0xFFC9C0B5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE4DACD),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
