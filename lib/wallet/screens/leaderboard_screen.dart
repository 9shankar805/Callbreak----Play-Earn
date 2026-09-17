import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../services/wallet_service.dart';
import '../widgets/lottie_coin_widget.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  LeaderboardScreen
//
//  Local leaderboard — tracks the player's own stats across sessions.
//  When you add a real backend, replace _mockEntries with a Firestore fetch.
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderEntry {
  final String name;
  final String avatar;
  final int coinsWon;
  final int gamesPlayed;
  final int wins;
  final String flag;

  const _LeaderEntry({
    required this.name,
    required this.avatar,
    required this.coinsWon,
    required this.gamesPlayed,
    required this.wins,
    this.flag = '🇮🇳',
  });

  double get winRate =>
      gamesPlayed == 0 ? 0 : (wins / gamesPlayed * 100);
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // Simulated top-10 leaderboard entries (replace with Firestore later)
  List<_LeaderEntry> _buildMockEntries(WalletService wallet) {
    final me = _LeaderEntry(
      name:        'You',
      avatar:      'assets/images/avatars/you.png',
      coinsWon:    wallet.wallet.totalWon,
      gamesPlayed: wallet.wallet.totalGamesPlayed,
      wins:        wallet.wallet.totalGamesWon,
      flag:        '🇮🇳',
    );

    // Fixed mock opponents
    const opponents = [
      _LeaderEntry(name: 'Arjun',   avatar: 'assets/images/avatars/avatar_1.png', coinsWon: 12400, gamesPlayed: 48, wins: 31, flag: '🇮🇳'),
      _LeaderEntry(name: 'Priya',   avatar: 'assets/images/avatars/avatar_2.png', coinsWon: 10200, gamesPlayed: 42, wins: 27, flag: '🇳🇵'),
      _LeaderEntry(name: 'Ramesh',  avatar: 'assets/images/avatars/avatar_3.png', coinsWon: 9800,  gamesPlayed: 55, wins: 24, flag: '🇮🇳'),
      _LeaderEntry(name: 'Sunita',  avatar: 'assets/images/avatars/avatar_4.png', coinsWon: 8500,  gamesPlayed: 38, wins: 22, flag: '🇮🇳'),
      _LeaderEntry(name: 'Dannie',  avatar: 'assets/images/avatars/dannie.png',   coinsWon: 7200,  gamesPlayed: 31, wins: 18, flag: '🇧🇩'),
      _LeaderEntry(name: 'Meena',   avatar: 'assets/images/avatars/meena.png',    coinsWon: 6800,  gamesPlayed: 29, wins: 16, flag: '🇮🇳'),
      _LeaderEntry(name: 'Lily',    avatar: 'assets/images/avatars/lily.png',     coinsWon: 5500,  gamesPlayed: 25, wins: 14, flag: '🇳🇵'),
      _LeaderEntry(name: 'Vikram',  avatar: 'assets/images/avatars/avatar_5.png', coinsWon: 4200,  gamesPlayed: 20, wins: 10, flag: '🇮🇳'),
      _LeaderEntry(name: 'Kavita',  avatar: 'assets/images/avatars/avatar_6.png', coinsWon: 3100,  gamesPlayed: 18, wins: 8,  flag: '🇮🇳'),
    ];

    final all = [...opponents, me];
    all.sort((a, b) => b.coinsWon.compareTo(a.coinsWon));
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/wood_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.woodDark),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.6)),
          ),
          SafeArea(
            child: Consumer<WalletService>(
              builder: (_, wallet, __) {
                final entries = _buildMockEntries(wallet);
                final myRank  = entries.indexWhere((e) => e.name == 'You') + 1;
                return Column(
                  children: [
                    _buildHeader(context),
                    _buildMyRankBanner(wallet, myRank),
                    _buildTabs(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabCtrl,
                        children: [
                          _buildCoinsTab(entries),
                          _buildWinRateTab(entries),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
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
            '🏆  LEADERBOARD',
            style: TextStyle(
              color: AppTheme.headerGold,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── My rank banner ─────────────────────────────────────────────────────────

  Widget _buildMyRankBanner(WalletService wallet, int myRank) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3317), Color(0xFF3E1F0D)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.headerGold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          LottieCoinWidget(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR STATS',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        letterSpacing: 2)),
                const SizedBox(height: 2),
                Text(
                  '${wallet.wallet.totalWon}🪙 won  •  '
                  '${wallet.wallet.totalGamesWon}/${wallet.wallet.totalGamesPlayed} wins',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '#$myRank',
                style: TextStyle(
                  color: _rankColor(myRank),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Text('RANK',
                  style: TextStyle(color: Colors.white38, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tabs ───────────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: AppTheme.headerGold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.headerGold),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppTheme.headerGold,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 12),
        tabs: const [
          Tab(text: '🪙  Coins Won'),
          Tab(text: '📊  Win Rate'),
        ],
      ),
    );
  }

  // ── Coins tab ──────────────────────────────────────────────────────────────

  Widget _buildCoinsTab(List<_LeaderEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (_, i) => _LeaderRow(
        rank:    i + 1,
        entry:   entries[i],
        isMe:    entries[i].name == 'You',
        valueLabel: '${entries[i].coinsWon}🪙',
      ),
    );
  }

  // ── Win rate tab ───────────────────────────────────────────────────────────

  Widget _buildWinRateTab(List<_LeaderEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) => b.winRate.compareTo(a.winRate));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _LeaderRow(
        rank:       i + 1,
        entry:      sorted[i],
        isMe:       sorted[i].name == 'You',
        valueLabel: '${sorted[i].winRate.toStringAsFixed(0)}%',
      ),
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white54;
  }
}

// ── Row widget ─────────────────────────────────────────────────────────────

class _LeaderRow extends StatelessWidget {
  final int rank;
  final _LeaderEntry entry;
  final bool isMe;
  final String valueLabel;

  const _LeaderRow({
    required this.rank,
    required this.entry,
    required this.isMe,
    required this.valueLabel,
  });

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.white38;
  }

  String get _rankIcon {
    if (rank == 1) return '🥇';
    if (rank == 2) return '🥈';
    if (rank == 3) return '🥉';
    return '$rank';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? AppTheme.headerGold.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppTheme.headerGold.withValues(alpha: 0.5)
              : Colors.white12,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: rank <= 3
                ? Text(_rankIcon,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20))
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _rankColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isMe
                    ? AppTheme.activeTurnNeon
                    : Colors.white24,
                width: isMe ? 2 : 1,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                entry.avatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.person, color: Colors.white38, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Name + flag + games
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.flag,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.name,
                      style: TextStyle(
                        color: isMe
                            ? AppTheme.headerGold
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.headerGold
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('YOU',
                            style: TextStyle(
                              color: AppTheme.headerGold,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            )),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${entry.wins}W / ${entry.gamesPlayed}G',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 9),
                ),
              ],
            ),
          ),

          // Value
          Text(
            valueLabel,
            style: TextStyle(
              color: isMe ? AppTheme.headerGold : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
