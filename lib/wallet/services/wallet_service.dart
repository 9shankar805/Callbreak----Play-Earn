import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet_model.dart';
import '../models/stake_level.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  WalletService — single source of truth for the local player's coin wallet.
//
//  All mutations go through this service. State is persisted to
//  SharedPreferences so it survives app restarts.
//
//  For a real-money future: replace _save/_load with Firestore calls.
// ─────────────────────────────────────────────────────────────────────────────

class WalletService extends ChangeNotifier {
  static final WalletService _instance = WalletService._();
  factory WalletService() => _instance;
  WalletService._();

  static const _key         = 'wallet_v1';
  static const _welcomeCoins = 500;    // new player starting balance
  static const _maxTxHistory = 50;     // keep last 50 transactions

  final _uuid = const Uuid();

  WalletModel _wallet = WalletModel.fresh();
  bool _loaded = false;

  WalletModel get wallet   => _wallet;
  int  get balance         => _wallet.balance;
  bool get isLoaded        => _loaded;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_key);

    if (raw == null) {
      // First launch — give welcome bonus.
      _wallet = WalletModel.fresh();
      await _credit(
        type:   TxType.welcome,
        amount: _welcomeCoins,
        note:   'Welcome to Callbreak! 🎉',
      );
    } else {
      try {
        _wallet = WalletModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _wallet = WalletModel.fresh();
      }
    }

    _loaded = true;
    notifyListeners();
  }

  // ── Daily bonus ────────────────────────────────────────────────────────────

  /// Returns the coins awarded, or 0 if not claimable yet.
  Future<int> claimDailyBonus() async {
    if (!_wallet.canClaimDaily) return 0;

    final now      = DateTime.now();
    final lastClaim = _wallet.lastDailyClaimAt;
    final isConsecutive = lastClaim != null &&
        now.difference(lastClaim).inHours < 48;

    final newStreak = isConsecutive ? _wallet.dailyStreakDays + 1 : 1;
    _wallet = _wallet.copyWith(
      dailyStreakDays:  newStreak,
      lastDailyClaimAt: now,
    );

    final amount = _wallet.dailyBonusAmount;
    await _credit(
      type:   TxType.dailyBonus,
      amount: amount,
      note:   '$newStreak-day streak bonus',
    );
    return amount;
  }

  // ── Game economy ───────────────────────────────────────────────────────────

  /// Deduct entry fee when player joins a staked room.
  /// Returns false if insufficient balance.
  Future<bool> deductEntryFee(StakeLevel stake, {String roomNote = ''}) async {
    if (stake == StakeLevel.free) return true;
    if (_wallet.balance < stake.entryFee) return false;

    await _debit(
      type:   TxType.gameLose,
      amount: stake.entryFee,
      note:   roomNote.isEmpty
          ? '${stake.label} room entry'
          : '${stake.label} room — $roomNote',
    );
    return true;
  }

  /// Credit winnings when the local player wins a staked game.
  Future<void> creditWinnings(StakeLevel stake, {String opponents = ''}) async {
    if (stake == StakeLevel.free) return;

    _wallet = _wallet.copyWith(
      totalGamesPlayed: _wallet.totalGamesPlayed + 1,
      totalGamesWon:    _wallet.totalGamesWon + 1,
      totalWon:         _wallet.totalWon + stake.winnerPayout,
    );

    await _credit(
      type:   TxType.gameWin,
      amount: stake.winnerPayout,
      note:   opponents.isEmpty
          ? '${stake.label} room win 🏆'
          : 'Beat $opponents — ${stake.label} 🏆',
    );
  }

  /// Record a loss (entry fee already deducted on join; just update stats).
  Future<void> recordLoss(StakeLevel stake) async {
    if (stake == StakeLevel.free) return;
    _wallet = _wallet.copyWith(
      totalGamesPlayed: _wallet.totalGamesPlayed + 1,
    );
    await _save();
    notifyListeners();
  }

  /// Refund entry fee (e.g. opponent disconnected before game started).
  Future<void> refundEntryFee(StakeLevel stake, {String note = ''}) async {
    if (stake == StakeLevel.free) return;
    await _credit(
      type:   TxType.refund,
      amount: stake.entryFee,
      note:   note.isEmpty ? '${stake.label} room refund' : note,
    );
  }

  // ── Admin / promo ──────────────────────────────────────────────────────────

  Future<void> adminCredit(int amount, String note) async {
    await _credit(type: TxType.adminCredit, amount: amount, note: note);
  }

  // ── Deposit ────────────────────────────────────────────────────────────────

  /// Simulate purchasing coins. Returns true on success.
  Future<bool> depositCoins(int amount, {String note = ''}) async {
    if (amount <= 0) return false;
    _wallet = _wallet.copyWith(
      totalDeposited: _wallet.totalDeposited + amount,
    );
    await _credit(
      type: TxType.purchase,
      amount: amount,
      note: note.isEmpty ? 'Top-up 🪙$amount' : note,
    );
    return true;
  }

  // ── Withdrawal ─────────────────────────────────────────────────────────────

  /// Submit a withdrawal request. Coins are debited immediately (held pending).
  /// Returns the WithdrawRequest on success, or null on validation failure.
  Future<WithdrawRequest?> requestWithdraw({
    required int netAmount,
    required PaymentMethod method,
    required String destination,
  }) async {
    if (netAmount < WalletModel.minWithdraw) return null;
    if (netAmount > WalletModel.maxWithdraw) return null;
    if (destination.trim().isEmpty) return null;
    if (_wallet.hasPendingWithdraw) return null;

    final fee = WalletModel.calculateWithdrawFee(netAmount);
    final gross = netAmount + fee;

    if (_wallet.balance < gross) return null;

    final request = WithdrawRequest(
      id: _uuid.v4(),
      amount: netAmount,
      fee: fee,
      grossAmount: gross,
      method: method,
      destination: destination.trim(),
      status: WithdrawStatus.pending,
      createdAt: DateTime.now(),
    );

    // Deduct gross (net + fee) from balance + log transactions
    final balAfterDebit = _wallet.balance - gross;
    final withdrawTx = CoinTransaction(
      id: _uuid.v4(),
      type: TxType.withdraw,
      amount: netAmount,
      balanceAfter: balAfterDebit + fee,
      timestamp: DateTime.now(),
      note: '${method.label} withdrawal to ${destination.trim()}',
    );
    final feeTx = CoinTransaction(
      id: _uuid.v4(),
      type: TxType.withdrawFee,
      amount: fee,
      balanceAfter: balAfterDebit,
      timestamp: DateTime.now(),
      note: 'Processing fee (${(WalletModel.withdrawFeePct * 100).toStringAsFixed(0)}%)',
    );

    var txs = [..._wallet.transactions, withdrawTx, feeTx];
    if (txs.length > _maxTxHistory) {
      txs = txs.sublist(txs.length - _maxTxHistory);
    }

    _wallet = _wallet.copyWith(
      balance: balAfterDebit,
      transactions: txs,
      totalWithdrawn: _wallet.totalWithdrawn + netAmount,
      withdrawRequests: [..._wallet.withdrawRequests, request],
    );
    await _save();
    notifyListeners();

    // Simulate async processing pipeline: pending -> processing -> completed
    unawaited(_simulateWithdrawProcessing(request.id));

    return request;
  }

  /// Cancel a pending withdrawal — refunds gross (net + fee) back to balance.
  Future<bool> cancelWithdraw(String requestId) async {
    final idx = _wallet.withdrawRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) return false;
    final req = _wallet.withdrawRequests[idx];
    if (req.status != WithdrawStatus.pending) return false;

    final cancelled = req.copyWith(status: WithdrawStatus.cancelled);
    final refund = req.grossAmount;

    final newBalance = _wallet.balance + refund;
    final refundTx = CoinTransaction(
      id: _uuid.v4(),
      type: TxType.refund,
      amount: refund,
      balanceAfter: newBalance,
      timestamp: DateTime.now(),
      note: 'Withdraw cancelled — ${req.method.label}',
    );

    var txs = [..._wallet.transactions, refundTx];
    if (txs.length > _maxTxHistory) {
      txs = txs.sublist(txs.length - _maxTxHistory);
    }

    final updatedRequests = List<WithdrawRequest>.from(_wallet.withdrawRequests);
    updatedRequests[idx] = cancelled;

    _wallet = _wallet.copyWith(
      balance: newBalance,
      transactions: txs,
      totalWithdrawn: _wallet.totalWithdrawn - req.amount,
      withdrawRequests: updatedRequests,
    );
    await _save();
    notifyListeners();
    return true;
  }

  /// Simulate backend withdrawal pipeline — in real app replace with API call.
  Future<void> _simulateWithdrawProcessing(String requestId) async {
    await Future.delayed(const Duration(seconds: 2));
    if (!_loaded) return;

    final idx = _wallet.withdrawRequests.indexWhere((r) => r.id == requestId);
    if (idx < 0) return;
    final req = _wallet.withdrawRequests[idx];
    if (req.status != WithdrawStatus.pending) return;

    // Move to processing
    final updatedRequests1 = List<WithdrawRequest>.from(_wallet.withdrawRequests);
    updatedRequests1[idx] = req.copyWith(status: WithdrawStatus.processing);
    _wallet = _wallet.copyWith(withdrawRequests: updatedRequests1);
    await _save();
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));
    if (!_loaded) return;

    final idx2 = _wallet.withdrawRequests.indexWhere((r) => r.id == requestId);
    if (idx2 < 0) return;
    final req2 = _wallet.withdrawRequests[idx2];
    if (req2.status != WithdrawStatus.processing) return;

    // 90% chance of success simulation
    final success = DateTime.now().millisecondsSinceEpoch % 10 != 0;
    final finalStatus = success ? WithdrawStatus.completed : WithdrawStatus.failed;
    final updatedRequests2 = List<WithdrawRequest>.from(_wallet.withdrawRequests);
    updatedRequests2[idx2] = req2.copyWith(
      status: finalStatus,
      processedAt: DateTime.now(),
      referenceId: success ? 'TXN_${_uuid.v4().substring(0, 8).toUpperCase()}' : null,
      failureNote: success
          ? null
          : 'Destination unverified. Please check account details.',
    );

    int newBalance = _wallet.balance;
    final newTxs = List<CoinTransaction>.from(_wallet.transactions);
    int newTotalWithdrawn = _wallet.totalWithdrawn;

    if (!success) {
      // Failed withdrawal: refund gross (net + fee)
      final refund = req2.grossAmount;
      newBalance += refund;
      newTotalWithdrawn -= req2.amount;
      final refundTx = CoinTransaction(
        id: _uuid.v4(),
        type: TxType.refund,
        amount: refund,
        balanceAfter: newBalance,
        timestamp: DateTime.now(),
        note: 'Withdraw failed refund — ${req2.method.label}',
      );
      newTxs.add(refundTx);
    }

    if (newTxs.length > _maxTxHistory) {
      newTxs.removeRange(0, newTxs.length - _maxTxHistory);
    }

    _wallet = _wallet.copyWith(
      balance: newBalance,
      transactions: newTxs,
      totalWithdrawn: newTotalWithdrawn,
      withdrawRequests: updatedRequests2,
    );
    await _save();
    notifyListeners();
  }

  List<WithdrawRequest> get recentWithdrawRequests =>
      _wallet.withdrawRequests.reversed.take(10).toList();

  // ── Computed helpers ───────────────────────────────────────────────────────

  bool canAfford(StakeLevel stake) =>
      stake == StakeLevel.free || _wallet.balance >= stake.entryFee;

  List<CoinTransaction> get recentTransactions =>
      _wallet.transactions.reversed.take(20).toList();

  // ── Private mutations ──────────────────────────────────────────────────────

  Future<void> _credit({
    required TxType type,
    required int amount,
    String note = '',
  }) async {
    final newBalance = _wallet.balance + amount;
    final tx = CoinTransaction(
      id:           _uuid.v4(),
      type:         type,
      amount:       amount,
      balanceAfter: newBalance,
      timestamp:    DateTime.now(),
      note:         note,
    );    _wallet = _wallet.copyWith(
      balance:      newBalance,
      transactions: _trimmedTxList(tx),
    );
    await _save();
    notifyListeners();
  }
  Future<void> _debit({
    required TxType type,
    required int amount,
    String note = '',
  }) async {
    final newBalance = (_wallet.balance - amount).clamp(0, 999999999);
    final tx = CoinTransaction(
      id:           _uuid.v4(),
      type:         type,
      amount:       amount,
      balanceAfter: newBalance,
      timestamp:    DateTime.now(),
      note:         note,
    );
    _wallet = _wallet.copyWith(
      balance:      newBalance,
      transactions: _trimmedTxList(tx),
    );
    await _save();
    notifyListeners();
  }

  List<CoinTransaction> _trimmedTxList(CoinTransaction newTx) {
    final list = [..._wallet.transactions, newTx];
    if (list.length > _maxTxHistory) {
      return list.sublist(list.length - _maxTxHistory);
    }
    return list;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_wallet.toJson()));
  }
}
