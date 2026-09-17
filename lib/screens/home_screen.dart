import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controller/game_controller.dart';
import '../models/player_model.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import '../wallet/services/wallet_service.dart';
import '../wallet/screens/wallet_screen.dart';
import '../wallet/screens/stake_picker_screen.dart';
import '../wallet/screens/leaderboard_screen.dart';
import '../wallet/widgets/lottie_coin_widget.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _startGame(BuildContext context) {
    HapticFeedback.mediumImpact();
    SoundService.instance.playCardFan();
    context.read<GameController>().startGame(animateDealing: true);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const GameScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _goOnline(BuildContext context) {
    HapticFeedback.mediumImpact();
    SoundService.instance.playButtonClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const StakePickerScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _goWallet(BuildContext context) {
    SoundService.instance.playButtonClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const WalletScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _goLeaderboard(BuildContext context) {
    SoundService.instance.playButtonClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => ChangeNotifierProvider.value(
          value: WalletService(),
          child: const LeaderboardScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/wood_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2C160B), Color(0xFF5C3317), Color(0xFF2C160B)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.4)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 550;
                  final contentMaxWidth = wide ? 480.0 : double.infinity;
                  final horizontalPadding = wide ? 32.0 : 24.0;
                  final logoW = wide ? 72.0 : 52.0;
                  final logoH = wide ? 96.0 : 70.0;
                  final titleW = wide ? 400.0 : double.infinity;
                  final playNowH = wide ? 62.0 : 56.0;
                  final playOnlineH = wide ? 56.0 : 50.0;
                  final taglineSize = wide ? 14.0 : 12.0;
                  final playNowSize = wide ? 22.0 : 19.0;
                  final playOnlineSize = wide ? 18.0 : 16.0;
                  final playNowIcon = wide ? 32.0 : 28.0;
                  final playOnlineIcon = wide ? 24.0 : 20.0;

                  return Column(
                    children: [
                      _buildTopBar(context),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          child: Center(
                            child: SizedBox(
                              width: contentMaxWidth,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: wide ? 24 : 18),
                                  Image.asset(
                                    'assets/images/ace_spade.png',
                                    width: logoW, height: logoH, fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.spoke_rounded,
                                      size: wide ? 64 : 48,
                                      color: AppTheme.headerGold,
                                    ),
                                  ),
                                  SizedBox(height: wide ? 12 : 8),
                                  SizedBox(
                                    width: titleW,
                                    child: Image.asset(
                                      'assets/images/hero_title.png',
                                      width: titleW, fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Text(
                                        'CALLBREAK',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppTheme.headerGold,
                                          fontSize: wide ? 38 : 30,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: wide ? 10 : 6),
                                  Text(
                                    'The ultimate trick-taking card game',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFF2D6),
                                      fontSize: taglineSize,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(height: wide ? 32 : 24),
                                  AnimatedBuilder(
                                    animation: _pulse,
                                    builder: (_, child) =>
                                        Transform.scale(scale: _pulse.value, child: child),
                                    child: GestureDetector(
                                      onTap: () => _startGame(context),
                                      child: Container(
                                        width: double.infinity,
                                        height: playNowH,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFFE89945), Color(0xFFAC5619)],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius: BorderRadius.circular(playNowH / 2),
                                          border: Border.all(color: const Color(0xFFFFD485), width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFE89945).withValues(alpha: 0.5),
                                              blurRadius: 20, offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.play_arrow_rounded,
                                                color: Colors.white, size: playNowIcon),
                                            SizedBox(width: wide ? 10 : 8),
                                            Text('PLAY NOW', style: TextStyle(
                                              color: Colors.white,
                                              fontSize: playNowSize,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            )),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: wide ? 18 : 14),
                                  GestureDetector(
                                    onTap: () => _goOnline(context),
                                    child: Container(
                                      width: double.infinity,
                                      height: playOnlineH,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(playOnlineH / 2),
                                        border: Border.all(color: const Color(0xFF76FF03), width: 2),
                                        color: const Color(0xFF76FF03).withValues(alpha: 0.07),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.wifi_rounded,
                                              color: Color(0xFF76FF03), size: playOnlineIcon),
                                          SizedBox(width: wide ? 12 : 10),
                                          Text('PLAY ONLINE', style: TextStyle(
                                            color: Color(0xFF76FF03),
                                            fontSize: playOnlineSize,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          )),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: wide ? 32 : 24),
                                  _buildPlayerAvatarsRow(context),
                                  SizedBox(height: wide ? 24 : 18),
                                  _buildDailyBonusBanner(context),
                                  SizedBox(height: wide ? 20 : 16),
                                  _buildThemeSelector(context),
                                  SizedBox(height: wide ? 24 : 16),
                                  Text(
                                    '♠ Spades Always Trump  •  5 Rounds  •  Offline AI Bots',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: wide ? 12 : 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: wide ? 24 : 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Consumer<WalletService>(
      builder: (_, wallet, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          border: Border(
            bottom: BorderSide(
              color: AppTheme.headerGold.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _goWallet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D160C),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.headerGold.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BouncingCoin(size: 22),
                    const SizedBox(width: 5),
                    Text(
                      _formatCoins(wallet.balance),
                      style: const TextStyle(
                        color: AppTheme.headerGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.add_circle_outline,
                        color: AppTheme.headerGold.withValues(alpha: 0.7),
                        size: 13),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (wallet.wallet.canClaimDaily)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3E1F0D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.headerGold),
                ),
                child: const Text(
                  '📅 Daily!',
                  style: TextStyle(
                      color: AppTheme.headerGold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            const Spacer(),
            GestureDetector(
              onTap: () => _goLeaderboard(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Text('🏆', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4),
                    Text('Leaderboard',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _goWallet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Text('💰', style: TextStyle(fontSize: 13)),
                    SizedBox(width: 4),
                    Text('Wallet',
                        style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBonusBanner(BuildContext context) {
    return Consumer<WalletService>(
      builder: (_, wallet, __) {
        final canClaim = wallet.wallet.canClaimDaily;
        final streak = wallet.wallet.dailyStreakDays;
        final bonus = wallet.wallet.dailyBonusAmount;

        return GestureDetector(
          onTap: () => _goWallet(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: canClaim
                  ? AppTheme.headerGold.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: canClaim ? AppTheme.headerGold : Colors.white12,
                width: canClaim ? 1.5 : 1,
              ),
              boxShadow: canClaim
                  ? [BoxShadow(
                      color: AppTheme.headerGold.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )]
                  : [],
            ),
            child: Row(
              children: [
                Text(canClaim ? '🎁' : '📅', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        canClaim ? 'Claim your daily bonus!' : 'Daily Bonus',
                        style: TextStyle(
                          color: canClaim
                              ? AppTheme.headerGold
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        streak == 0
                            ? 'Start your streak today'
                            : '$streak-day streak 🔥  Next bonus: 🪙$bonus',
                        style: TextStyle(
                          color: canClaim
                              ? Colors.white70
                              : Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: canClaim
                        ? AppTheme.confirmGreen
                        : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    canClaim ? 'Claim 🪙$bonus' : 'Open',
                    style: TextStyle(
                      color: canClaim ? Colors.white : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

  String _formatCoins(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<GameController>(
      builder: (_, game, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              const Text(
                'Theme: ',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              ...GameThemeMode.values.map((t) {
                final isSel = game.currentTheme == t;
                return GestureDetector(
                  onTap: () => game.setTheme(t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.headerGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: isSel ? AppTheme.headerBorder : Colors.white24,
                      ),
                    ),
                    child: Text(
                      t.label,
                      style: TextStyle(
                        color: isSel ? const Color(0xFF2C160B) : Colors.white60,
                        fontSize: 10.5,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerAvatarsRow(BuildContext context) {
    return Consumer<GameController>(
      builder: (ctx, game, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: game.players.map((p) {
            final isHuman = p.isHuman;
            return GestureDetector(
              onTap: isHuman ? () => _showAvatarPickerModal(context, game) : null,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHuman ? const Color(0xFF76FF03) : Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isHuman ? const Color(0x6676FF03) : const Color(0x33000000),
                                blurRadius: isHuman ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            image: DecorationImage(
                              image: AssetImage(p.avatarPath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (isHuman)
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFF3E1F0D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 10,
                                color: Color(0xFFF5BB68),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.name,
                      style: TextStyle(
                        color: isHuman ? const Color(0xFF76FF03) : const Color(0xFFFFF2D6),
                        fontSize: 11,
                        fontWeight: isHuman ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAvatarPickerModal(BuildContext context, GameController game) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFFFFF7E6),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE8D4B0), width: 2),
        ),
        child: Container(
          width: 480,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height - 20,
          ),
          padding: const EdgeInsets.all(18),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Choose Your Avatar',
                      style: TextStyle(
                        color: Color(0xFF3E1F0D),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close_rounded, color: Color(0xFF6E4A32)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select from open-source GitHub portrait pack:',
                  style: TextStyle(color: Color(0xFF7A4522), fontSize: 12),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: Player.availableAvatars.map((av) {
                    final isSelected = game.humanPlayer.avatarPath == av;
                    return GestureDetector(
                      onTap: () {
                        game.setHumanAvatar(av);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF76FF03) : const Color(0xFFBA7A42),
                            width: isSelected ? 3.5 : 1.5,
                          ),
                          boxShadow: [
                            if (isSelected)
                              const BoxShadow(
                                color: Color(0x9976FF03),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(av, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
