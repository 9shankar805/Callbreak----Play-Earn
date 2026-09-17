import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../widgets/daily_bonus_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.woodDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/wood_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.woodDark),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
          SafeArea(
            child: Consumer<WalletService>(
              builder: (_, wallet, __) => Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          _buildBalanceCard(context, wallet),
                          const SizedBox(height: 14),
                          const DailyBonusWidget(),
                          const SizedBox(height: 14),
                          _buildStatsRow(wallet),
                          const SizedBox(height: 14),
                          _buildWithdrawHistory(wallet),
                          const SizedBox(height: 14),
                          _buildTransactionList(wallet),
                          const SizedBox(height: 24),
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
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.woodDark.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: AppTheme.headerGold.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              SoundService.instance.playButtonClick();
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back_ios_rounded,
                color: AppTheme.headerGold, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'MY WALLET',
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

  // ── Balance card ───────────────────────────────────────────────────────────

  Widget _buildBalanceCard(BuildContext context, WalletService wallet) {
    final w = wallet.wallet;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C3317), Color(0xFF3E1F0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.headerGold.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.headerGold.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'COIN BALANCE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('🪙', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 8),
              Text(
                _formatBalance(wallet.balance),
                style: const TextStyle(
                  color: AppTheme.headerGold,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${w.dailyStreakDays}-day streak 🔥  •  Deposited: 🪙${_formatBalance(w.totalDeposited)}  •  Withdrawn: 🪙${_formatBalance(w.totalWithdrawn)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.add_card_rounded,
                  label: 'DEPOSIT',
                  bgColor: AppTheme.confirmGreen,
                  onTap: () => _showDepositDialog(context, wallet),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.arrow_outward_rounded,
                  label: 'WITHDRAW',
                  bgColor: const Color(0xFFD32F2F),
                  onTap: () => _showWithdrawDialog(context, wallet),
                  disabled: w.hasPendingWithdraw,
                  disabledHint: w.hasPendingWithdraw ? 'Pending' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color bgColor,
    required VoidCallback onTap,
    bool disabled = false,
    String? disabledHint,
  }) {
    return GestureDetector(
      onTap: disabled ? null : () { SoundService.instance.playButtonClick(); onTap(); },
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                disabledHint ?? label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Deposit Dialog ─────────────────────────────────────────────────────────

  void _showDepositDialog(BuildContext context, WalletService wallet) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _DepositDialog(
        onConfirm: (amount) async {
          final ok = await wallet.depositCoins(amount);
          if (ok && context.mounted) {
            HapticFeedback.mediumImpact();
            SoundService.instance.playCoin();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Deposited 🪙$amount successfully'),
                backgroundColor: AppTheme.confirmGreen,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1400),
              ),
            );
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Withdraw Dialog ────────────────────────────────────────────────────────

  void _showWithdrawDialog(BuildContext context, WalletService wallet) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _WithdrawDialog(
        balance: wallet.balance,
        onConfirm: (amount, method, destination) async {
          final req = await wallet.requestWithdraw(
            netAmount: amount,
            method: method,
            destination: destination,
          );
          if (context.mounted) {
            if (req != null) {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Withdrawal submitted for 🪙${req.amount} — processing…'),
                  backgroundColor: const Color(0xFF1565C0),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(milliseconds: 1800),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Withdrawal failed — check amount, balance, or destination'),
                  backgroundColor: Color(0xFFD32F2F),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(milliseconds: 1600),
                ),
              );
            }
            Navigator.pop(ctx);
          }
        },
      ),
    );
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Widget _buildStatsRow(WalletService wallet) {
    final w = wallet.wallet;
    return Row(
      children: [
        _statCard('🎮', 'Games', '${w.totalGamesPlayed}'),
        const SizedBox(width: 8),
        _statCard('🏆', 'Wins', '${w.totalGamesWon}'),
        const SizedBox(width: 8),
        _statCard('📊', 'Win Rate', '${w.winRate.toStringAsFixed(0)}%'),
        const SizedBox(width: 8),
        _statCard('🪙', 'Total Won', _formatBalance(w.totalWon)),
      ],
    );
  }

  Widget _statCard(String icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3E1F0D).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.headerGold,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  // ── Withdraw history ───────────────────────────────────────────────────────

  Widget _buildWithdrawHistory(WalletService wallet) {
    final requests = wallet.recentWithdrawRequests;
    if (requests.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'WITHDRAWAL HISTORY',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3E1F0D).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 0),
            itemBuilder: (_, i) => _WithdrawRow(
              request: requests[i],
              onCancel: (id) async {
                final ok = await wallet.cancelWithdraw(id);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('↩️ Withdrawal cancelled — coins refunded'),
                      backgroundColor: Color(0xFFEF6C00),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(milliseconds: 1400),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Transaction list ───────────────────────────────────────────────────────

  Widget _buildTransactionList(WalletService wallet) {
    final txs = wallet.recentTransactions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECENT TRANSACTIONS',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (txs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF3E1F0D).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Text(
                'No transactions yet.\nPlay a game to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3E1F0D).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: txs.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white10, height: 0),
              itemBuilder: (_, i) => _TxRow(tx: txs[i]),
            ),
          ),
      ],
    );
  }

  String _formatBalance(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

// ── Deposit Dialog ──────────────────────────────────────────────────────────

class _DepositDialog extends StatefulWidget {
  final ValueChanged<int> onConfirm;
  const _DepositDialog({required this.onConfirm});

  @override
  State<_DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<_DepositDialog> {
  static const List<int> _presets = [500, 1000, 2500, 5000, 10000, 25000];
  int _selected = 1000;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF7E6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE8D4B0), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Buy Coins',
                  style: TextStyle(
                    color: Color(0xFF3E1F0D),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close_rounded, color: Color(0xFF6E4A32)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Add coins to your wallet to enter stake rooms',
              style: TextStyle(color: Color(0xFF7A4522), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _presets.map((p) {
                final sel = _selected == p;
                return GestureDetector(
                  onTap: () => setState(() => _selected = p),
                  child: Container(
                    width: (MediaQuery.of(context).size.width / 2) - 60,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF3E1F0D) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? AppTheme.headerGold : const Color(0xFFE8D4B0),
                        width: sel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text('🪙$p',
                            style: TextStyle(
                              color: sel ? AppTheme.headerGold : const Color(0xFF3E1F0D),
                              fontSize: 18, fontWeight: FontWeight.w900,
                            )),
                        const SizedBox(height: 2),
                        Text('\$${(p / 100).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: sel ? Colors.white70 : const Color(0xFF7A4522),
                              fontSize: 11, fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => widget.onConfirm(_selected),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.confirmGreen,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.confirmGreen.withValues(alpha: 0.35),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_card_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Buy 🪙$_selected for \$${(_selected / 100).toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Withdraw Dialog ─────────────────────────────────────────────────────────

class _WithdrawDialog extends StatefulWidget {
  final int balance;
  final Function(int amount, PaymentMethod method, String destination) onConfirm;

  const _WithdrawDialog({required this.balance, required this.onConfirm});

  @override
  State<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<_WithdrawDialog> {
  static const List<int> _presets = [500, 1000, 2500, 5000, 10000, 25000];
  int _netAmount = 500;
  PaymentMethod _method = PaymentMethod.upi;
  final _destCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _destCtrl.dispose();
    super.dispose();
  }

  int get _fee => WalletModel.calculateWithdrawFee(_netAmount);
  int get _gross => _netAmount + _fee;
  bool get _canAfford => widget.balance >= _gross;
  bool get _amountInRange =>
      _netAmount >= WalletModel.minWithdraw &&
      _netAmount <= WalletModel.maxWithdraw;

  String get _hintText {
    switch (_method) {
      case PaymentMethod.upi:          return 'e.g. yourname@upi';
      case PaymentMethod.bankTransfer: return 'Account Number & IFSC';
      case PaymentMethod.paytm:        return 'Paytm mobile number';
      case PaymentMethod.usdt:         return 'TRC20 wallet address';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF7E6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE8D4B0), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Withdraw Coins',
                      style: TextStyle(
                        color: Color(0xFF3E1F0D),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close_rounded, color: Color(0xFF6E4A32)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Available balance: 🪙${widget.balance}  •  Min: 🪙${WalletModel.minWithdraw}',
                  style: const TextStyle(color: Color(0xFF7A4522), fontSize: 12),
                ),
                const SizedBox(height: 14),
                const Text(
                  'AMOUNT',
                  style: TextStyle(
                    color: Color(0xFF7A4522),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((p) {
                    final gross = p + WalletModel.calculateWithdrawFee(p);
                    final sel = _netAmount == p;
                    final affordable = widget.balance >= gross;
                    return GestureDetector(
                      onTap: affordable
                          ? () => setState(() => _netAmount = p)
                          : null,
                      child: Opacity(
                        opacity: affordable ? 1.0 : 0.35,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFFD32F2F)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.headerGold
                                  : const Color(0xFFE8D4B0),
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            '🪙$p',
                            style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF3E1F0D),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E1F0D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('You receive', '🪙$_netAmount', AppTheme.headerGold),
                      const SizedBox(height: 6),
                      _summaryRow(
                        'Fee (${(WalletModel.withdrawFeePct * 100).toStringAsFixed(0)}%)',
                        '🪙$_fee',
                        Colors.white60,
                      ),
                      const Divider(color: Colors.white12, height: 16),
                      _summaryRow('Total deducted', '🪙$_gross', Colors.white),
                      const SizedBox(height: 8),
                      if (!_canAfford)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '❌ Insufficient balance for this amount',
                            style: TextStyle(color: Color(0xFFEF5350), fontSize: 11),
                          ),
                        )
                      else if (!_amountInRange)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '❌ Amount must be between 🪙${WalletModel.minWithdraw} — 🪙${WalletModel.maxWithdraw}',
                            style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PAYMENT METHOD',
                  style: TextStyle(
                    color: Color(0xFF7A4522),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PaymentMethod.values.map((m) {
                    final sel = _method == m;
                    return GestureDetector(
                      onTap: () => setState(() => _method = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? const Color(0xFF3E1F0D) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? AppTheme.headerGold
                                : const Color(0xFFE8D4B0),
                            width: sel ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(m.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Text(
                              m.label,
                              style: TextStyle(
                                color: sel
                                    ? AppTheme.headerGold
                                    : const Color(0xFF3E1F0D),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_method.label} DETAILS',
                  style: const TextStyle(
                    color: Color(0xFF7A4522),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _destCtrl,
                  style: const TextStyle(
                    color: Color(0xFF3E1F0D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: _hintText,
                    hintStyle: const TextStyle(color: Color(0xFFBA7A42), fontSize: 12),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8D4B0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE8D4B0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.headerGold, width: 2),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your ${_method.label} details';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    if (!_formKey.currentState!.validate()) return;
                    if (!_canAfford || !_amountInRange) return;
                    widget.onConfirm(_netAmount, _method, _destCtrl.text.trim());
                  },
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (_canAfford && _amountInRange)
                          ? const Color(0xFFD32F2F)
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        if (_canAfford && _amountInRange)
                          BoxShadow(
                            color: const Color(0xFFD32F2F).withValues(alpha: 0.35),
                            blurRadius: 12, offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_outward_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Withdraw 🪙$_netAmount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    '⏱ Processing: 5s demo · In-app simulation only',
                    style: TextStyle(color: Color(0xFFBA7A42), fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(value, style: TextStyle(
          color: valueColor, fontSize: 13, fontWeight: FontWeight.w800,
        )),
      ],
    );
  }
}

// ── Withdraw Row ────────────────────────────────────────────────────────────

class _WithdrawRow extends StatelessWidget {
  final WithdrawRequest request;
  final ValueChanged<String> onCancel;

  const _WithdrawRow({required this.request, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel, statusIcon) = _statusInfo(request.status);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(request.method.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '🪙${request.amount}',
                      style: const TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '$statusIcon $statusLabel',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${request.method.label} · ${request.destination}',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (request.referenceId != null)
                  Text(
                    'Ref: ${request.referenceId}',
                    style: const TextStyle(color: Colors.white30, fontSize: 9),
                  ),
                if (request.failureNote != null)
                  Text(
                    '⚠ ${request.failureNote}',
                    style: const TextStyle(color: Color(0xFFEF5350), fontSize: 10),
                  ),
                Text(
                  _timeAgo(request.createdAt),
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
          ),
          if (request.status == WithdrawStatus.pending)
            GestureDetector(
              onTap: () => onCancel(request.id),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF5D2E0D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }

  (Color, String, String) _statusInfo(WithdrawStatus s) {
    switch (s) {
      case WithdrawStatus.pending:
        return (const Color(0xFFFFB74D), 'Pending', '⏳');
      case WithdrawStatus.processing:
        return (const Color(0xFF42A5F5), 'Processing', '⚙️');
      case WithdrawStatus.completed:
        return (const Color(0xFF66BB6A), 'Done', '✅');
      case WithdrawStatus.failed:
        return (const Color(0xFFEF5350), 'Failed', '❌');
      case WithdrawStatus.cancelled:
        return (const Color(0xFF9E9E9E), 'Cancelled', '↩️');
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Transaction row ────────────────────────────────────────────────────────

class _TxRow extends StatelessWidget {
  final CoinTransaction tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.isCredit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Text(tx.type.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.type.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (tx.note.isNotEmpty)
                  Text(
                    tx.note,
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                Text(
                  _timeAgo(tx.timestamp),
                  style: const TextStyle(color: Colors.white24, fontSize: 9),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${tx.amount}🪙',
                style: TextStyle(
                  color: isCredit
                      ? AppTheme.scorePositive
                      : AppTheme.scoreNegative,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${tx.balanceAfter}🪙',
                style: const TextStyle(color: Colors.white30, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
