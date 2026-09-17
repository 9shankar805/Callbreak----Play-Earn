import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../services/wallet_service.dart';

/// Streak-based daily bonus claim card.
/// Drop this anywhere — home screen, wallet screen, etc.
class DailyBonusWidget extends StatefulWidget {
  const DailyBonusWidget({super.key});

  @override
  State<DailyBonusWidget> createState() => _DailyBonusWidgetState();
}

class _DailyBonusWidgetState extends State<DailyBonusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  bool _claiming = false;

  static const List<_StreakDay> _streakDays = [
    _StreakDay(day: 1,  coins: 50,   label: 'Day 1'),
    _StreakDay(day: 2,  coins: 50,   label: 'Day 2'),
    _StreakDay(day: 3,  coins: 100,  label: 'Day 3'),
    _StreakDay(day: 7,  coins: 200,  label: 'Day 7'),
    _StreakDay(day: 14, coins: 500,  label: 'Day 14'),
    _StreakDay(day: 30, coins: 1000, label: 'Day 30'),
  ];

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _claim(WalletService wallet) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final earned = await wallet.claimDailyBonus();
    if (!mounted) return;
    setState(() => _claiming = false);

    if (earned > 0) {
      SoundService.instance.playCoin();
      _showClaimPopup(earned);
    }
  }

  void _showClaimPopup(int coins) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF3E1F0D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.headerGold, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              const Text(
                'Daily Bonus!',
                style: TextStyle(
                  color: AppTheme.headerGold,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 6),
                  Text(
                    '+$coins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.confirmGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Awesome!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
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
    return Consumer<WalletService>(
      builder: (_, wallet, __) {
        final canClaim = wallet.wallet.canClaimDaily;
        final streak   = wallet.wallet.dailyStreakDays;
        final bonus    = wallet.wallet.dailyBonusAmount;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3E1F0D).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: canClaim
                  ? AppTheme.headerGold
                  : Colors.white12,
              width: canClaim ? 2 : 1,
            ),
            boxShadow: canClaim
                ? [BoxShadow(
                    color: AppTheme.headerGold.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: canClaim
                      ? AppTheme.headerGold.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Row(
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Bonus',
                            style: TextStyle(
                              color: AppTheme.headerGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            streak == 0
                                ? 'Start your streak!'
                                : '$streak-day streak 🔥',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canClaim)
                      _buildClaimButton(wallet, bonus)
                    else
                      _buildCountdown(wallet),
                  ],
                ),
              ),

              // Streak milestones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _streakDays.map((s) {
                    final reached = streak >= s.day;
                    final isCurrent = streak < s.day &&
                        (_streakDays.indexOf(s) == 0 ||
                            streak >=
                                _streakDays[_streakDays.indexOf(s) - 1].day);
                    return _StreakBadge(
                      day:        s,
                      reached:    reached,
                      isCurrent:  isCurrent,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClaimButton(WalletService wallet, int bonus) {
    return GestureDetector(
      onTap: () => _claim(wallet),
      child: AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.headerGold,
                  const Color(0xFFFFD485),
                  AppTheme.headerGold,
                ],
                stops: [
                  (_shimmerCtrl.value - 0.3).clamp(0.0, 1.0),
                  _shimmerCtrl.value.clamp(0.0, 1.0),
                  (_shimmerCtrl.value + 0.3).clamp(0.0, 1.0),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: _claiming
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Claim 🪙$bonus',
                    style: const TextStyle(
                      color: Color(0xFF2C160B),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCountdown(WalletService wallet) {
    final last = wallet.wallet.lastDailyClaimAt;
    if (last == null) return const SizedBox.shrink();
    final next   = DateTime(last.year, last.month, last.day + 1);
    final diff   = next.difference(DateTime.now());
    final hours  = diff.inHours;
    final mins   = diff.inMinutes % 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${hours}h ${mins}m',
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StreakDay {
  final int day;
  final int coins;
  final String label;
  const _StreakDay({required this.day, required this.coins, required this.label});
}

class _StreakBadge extends StatelessWidget {
  final _StreakDay day;
  final bool reached;
  final bool isCurrent;

  const _StreakBadge({
    required this.day,
    required this.reached,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached
                ? AppTheme.headerGold
                : isCurrent
                    ? AppTheme.headerGold.withValues(alpha: 0.2)
                    : Colors.white10,
            border: Border.all(
              color: reached
                  ? AppTheme.headerGold
                  : isCurrent
                      ? AppTheme.headerGold.withValues(alpha: 0.6)
                      : Colors.white12,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              reached ? '✓' : '🪙',
              style: TextStyle(
                fontSize: reached ? 14 : 12,
                color: reached ? const Color(0xFF2C160B) : Colors.white54,
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          day.label,
          style: TextStyle(
            color: reached
                ? AppTheme.headerGold
                : Colors.white30,
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '+${day.coins}',
          style: TextStyle(
            color: reached ? Colors.white70 : Colors.white24,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
