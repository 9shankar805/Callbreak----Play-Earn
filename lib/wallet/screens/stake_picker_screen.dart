import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../online/controller/online_game_controller.dart';
import '../../online/screens/lobby_screen.dart';
import '../models/stake_level.dart';
import '../services/wallet_service.dart';
import '../widgets/lottie_coin_widget.dart';

class StakePickerScreen extends StatefulWidget {
  const StakePickerScreen({super.key});

  @override
  State<StakePickerScreen> createState() => _StakePickerScreenState();
}

class _StakePickerScreenState extends State<StakePickerScreen>
    with SingleTickerProviderStateMixin {
  StakeLevel _selected = StakeLevel.bronze;
  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  void _onStakeTap(StakeLevel stake) {
    SoundService.instance.playButtonClick();
    setState(() => _selected = stake);
  }

  void _onPlay(BuildContext context, WalletService wallet) {
    if (!wallet.canAfford(_selected)) {
      _showInsufficientFunds(context, wallet);
      return;
    }
    SoundService.instance.playCardFan();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => ChangeNotifierProvider(
          create: (_) => OnlineGameController(),
          child: LobbyScreen(stake: _selected),
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showInsufficientFunds(BuildContext context, WalletService wallet) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF3E1F0D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.headerGold),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😔', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 10),
              const Text(
                'Not enough coins',
                style: TextStyle(
                  color: AppTheme.headerGold,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need ${_selected.entryFee}🪙 to enter this room.\nYou have ${wallet.balance}🪙.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text(
                'Claim your daily bonus or play a free room to earn more coins!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 11),
                  decoration: BoxDecoration(
                    color: AppTheme.confirmGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/wood_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.woodDark),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),

          SafeArea(
            child: SlideTransition(
              position: _slideAnim,
              child: Consumer<WalletService>(
                builder: (_, wallet, __) => Column(
                  children: [
                    _buildHeader(context, wallet),
                    Expanded(child: _buildBody(context, wallet)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, WalletService wallet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              SoundService.instance.playButtonClick();
              Navigator.pop(context);
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.black38,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'CHOOSE YOUR TABLE',
            style: TextStyle(
              color: AppTheme.headerGold,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Balance pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D160C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.headerGold.withValues(alpha: 0.6)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 5),
                Text(
                  '${wallet.balance}',
                  style: const TextStyle(
                    color: AppTheme.headerGold,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, WalletService wallet) {
    return LayoutBuilder(builder: (_, constraints) {
      return Row(
        children: [
          // Left — coin animation + description
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LottieCoinWidget(size: constraints.maxHeight * 0.38),
                  const SizedBox(height: 16),
                  Text(
                    _selected.label,
                    style: TextStyle(
                      color: _selected.color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPotInfo(wallet),
                ],
              ),
            ),
          ),

          // Right — stake cards
          Expanded(
            flex: 6,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: StakeLevel.values
                          .map((s) => _StakeCard(
                                stake:    s,
                                selected: _selected == s,
                                canAfford: wallet.canAfford(s),
                                onTap:   () => _onStakeTap(s),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Play button
                  GestureDetector(
                    onTap: () => _onPlay(context, wallet),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: wallet.canAfford(_selected)
                              ? [
                                  const Color(0xFF2EB846),
                                  const Color(0xFF1A7030)
                                ]
                              : [Colors.grey.shade700, Colors.grey.shade900],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: wallet.canAfford(_selected)
                              ? const Color(0xFF76FF03)
                              : Colors.white24,
                          width: 1.5,
                        ),
                        boxShadow: wallet.canAfford(_selected)
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF2EB846)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            wallet.canAfford(_selected)
                                ? Icons.play_arrow_rounded
                                : Icons.lock_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            wallet.canAfford(_selected)
                                ? 'PLAY ${_selected.label.toUpperCase()}'
                                : 'NOT ENOUGH COINS',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPotInfo(WalletService wallet) {
    if (_selected == StakeLevel.free) {
      return const Text(
        'No coins at risk.\nGreat for practice!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white54, fontSize: 12),
      );
    }
    final canAfford = wallet.canAfford(_selected);
    return Column(
      children: [
        _infoRow('Entry', '${_selected.entryFee}🪙', Colors.white60),
        _infoRow('Total Pot', '${_selected.totalPot}🪙', Colors.white70),
        _infoRow('Win', '+${_selected.netGain}🪙',
            AppTheme.scorePositive),
        const SizedBox(height: 6),
        if (!canAfford)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.scoreNegative.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.scoreNegative.withValues(alpha: 0.4)),
            ),
            child: Text(
              'Need ${_selected.entryFee - wallet.balance} more 🪙',
              style: const TextStyle(
                  color: AppTheme.scoreNegative, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _infoRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$label: ',
              style:
                  const TextStyle(color: Colors.white38, fontSize: 11)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── Stake card ─────────────────────────────────────────────────────────────

class _StakeCard extends StatelessWidget {
  final StakeLevel stake;
  final bool selected;
  final bool canAfford;
  final VoidCallback onTap;

  const _StakeCard({
    required this.stake,
    required this.selected,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected
              ? stake.bgColor
              : Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? stake.color
                : canAfford
                    ? Colors.white24
                    : Colors.white12,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: stake.color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Text(stake.emoji,
                  style: TextStyle(
                      fontSize: selected ? 22 : 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stake.label,
                      style: TextStyle(
                        color: selected ? stake.color : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      stake == StakeLevel.free
                          ? 'Free to play'
                          : '${stake.entryFee}🪙 entry',
                      style: TextStyle(
                        color: canAfford
                            ? Colors.white38
                            : AppTheme.scoreNegative
                                .withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: stake.color, size: 16),
              if (!canAfford && stake != StakeLevel.free)
                Icon(Icons.lock_rounded,
                    color: Colors.white24, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
