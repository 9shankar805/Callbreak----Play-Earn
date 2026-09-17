// ─────────────────────────────────────────────────────────────────────────────
//  Wallet & Transaction models
// ─────────────────────────────────────────────────────────────────────────────

enum TxType {
  welcome,       // first-time bonus
  dailyBonus,    // daily streak reward
  gameWin,       // won a staked game
  gameLose,      // entry fee deducted when joining (already spent)
  refund,        // entry fee back if game cancelled
  purchase,      // real-money top-up
  adminCredit,   // promotional credit
  withdraw,      // coins withdrawn to external
  withdrawFee,   // processing fee for withdrawal
}

enum WithdrawStatus {
  pending,    // submitted, awaiting review
  processing, // being sent
  completed,  // successful
  failed,     // rejected / error
  cancelled,  // user cancelled
}

enum PaymentMethod {
  upi('UPI', '📱'),
  bankTransfer('Bank Transfer', '🏦'),
  paytm('Paytm', '💳'),
  usdt('USDT (TRC20)', '🪙');

  final String label;
  final String icon;
  const PaymentMethod(this.label, this.icon);
}

class WithdrawRequest {
  final String id;
  final int amount;          // net amount to user (after fee)
  final int fee;             // processing fee charged
  final int grossAmount;     // total coins deducted
  final PaymentMethod method;
  final String destination;  // e.g. UPI ID / account / wallet address
  final WithdrawStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? referenceId; // external txn ID
  final String? failureNote;

  const WithdrawRequest({
    required this.id,
    required this.amount,
    required this.fee,
    required this.grossAmount,
    required this.method,
    required this.destination,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.referenceId,
    this.failureNote,
  });

  WithdrawRequest copyWith({
    WithdrawStatus? status,
    DateTime? processedAt,
    String? referenceId,
    String? failureNote,
  }) =>
      WithdrawRequest(
        id: id,
        amount: amount,
        fee: fee,
        grossAmount: grossAmount,
        method: method,
        destination: destination,
        status: status ?? this.status,
        createdAt: createdAt,
        processedAt: processedAt ?? this.processedAt,
        referenceId: referenceId ?? this.referenceId,
        failureNote: failureNote ?? this.failureNote,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'fee': fee,
    'grossAmount': grossAmount,
    'method': method.index,
    'destination': destination,
    'status': status.index,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'processedAt': processedAt?.millisecondsSinceEpoch,
    'referenceId': referenceId,
    'failureNote': failureNote,
  };

  factory WithdrawRequest.fromJson(Map<String, dynamic> j) => WithdrawRequest(
    id: j['id'] as String,
    amount: j['amount'] as int,
    fee: (j['fee'] as int?) ?? 0,
    grossAmount: (j['grossAmount'] as int?) ?? (j['amount'] as int),
    method: PaymentMethod.values[(j['method'] as int?) ?? 0],
    destination: j['destination'] as String,
    status: WithdrawStatus.values[(j['status'] as int?) ?? 0],
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
    processedAt: j['processedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(j['processedAt'] as int)
        : null,
    referenceId: j['referenceId'] as String?,
    failureNote: j['failureNote'] as String?,
  );
}

extension TxTypeExt on TxType {
  String get label {
    switch (this) {
      case TxType.welcome:     return 'Welcome Bonus';
      case TxType.dailyBonus:  return 'Daily Bonus';
      case TxType.gameWin:     return 'Game Winnings';
      case TxType.gameLose:    return 'Entry Fee';
      case TxType.refund:      return 'Refund';
      case TxType.purchase:    return 'Top-up';
      case TxType.adminCredit: return 'Bonus Credit';
      case TxType.withdraw:    return 'Withdrawal';
      case TxType.withdrawFee: return 'Withdraw Fee';
    }
  }

  bool get isCredit {
    switch (this) {
      case TxType.welcome:
      case TxType.dailyBonus:
      case TxType.gameWin:
      case TxType.refund:
      case TxType.purchase:
      case TxType.adminCredit:
        return true;
      case TxType.gameLose:
      case TxType.withdraw:
      case TxType.withdrawFee:
        return false;
    }
  }

  String get icon {
    switch (this) {
      case TxType.welcome:     return '🎁';
      case TxType.dailyBonus:  return '📅';
      case TxType.gameWin:     return '🏆';
      case TxType.gameLose:    return '🃏';
      case TxType.refund:      return '↩️';
      case TxType.purchase:    return '💳';
      case TxType.adminCredit: return '⭐';
      case TxType.withdraw:    return '💸';
      case TxType.withdrawFee: return '📝';
    }
  }
}

// ── Transaction ───────────────────────────────────────────────────────────────

class CoinTransaction {
  final String id;
  final TxType type;
  final int amount;        // always positive; direction determined by TxType.isCredit
  final int balanceAfter;
  final DateTime timestamp;
  final String note;       // e.g. room name / opponent names

  const CoinTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.timestamp,
    this.note = '',
  });

  bool get isCredit => type.isCredit;
  int  get signed   => isCredit ? amount : -amount;

  Map<String, dynamic> toJson() => {
        'id':           id,
        'type':         type.index,
        'amount':       amount,
        'balanceAfter': balanceAfter,
        'timestamp':    timestamp.millisecondsSinceEpoch,
        'note':         note,
      };

  factory CoinTransaction.fromJson(Map<String, dynamic> j) => CoinTransaction(
        id:           j['id'] as String,
        type:         TxType.values[j['type'] as int],
        amount:       j['amount'] as int,
        balanceAfter: j['balanceAfter'] as int,
        timestamp:    DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
        note:         (j['note'] as String?) ?? '',
      );
}

// ── Wallet ────────────────────────────────────────────────────────────────────

class WalletModel {
  final int balance;
  final List<CoinTransaction> transactions;
  final int dailyStreakDays;
  final DateTime? lastDailyClaimAt;
  final int totalWon;
  final int totalGamesPlayed;
  final int totalGamesWon;
  final int totalWithdrawn;
  final int totalDeposited;
  final List<WithdrawRequest> withdrawRequests;

  static const int minWithdraw = 500;
  static const int maxWithdraw = 50000;
  static const double withdrawFeePct = 0.02; // 2%

  const WalletModel({
    required this.balance,
    required this.transactions,
    required this.dailyStreakDays,
    this.lastDailyClaimAt,
    this.totalWon = 0,
    this.totalGamesPlayed = 0,
    this.totalGamesWon = 0,
    this.totalWithdrawn = 0,
    this.totalDeposited = 0,
    this.withdrawRequests = const [],
  });

  factory WalletModel.fresh() => const WalletModel(
        balance: 0,
        transactions: [],
        dailyStreakDays: 0,
      );

  bool get canClaimDaily {
    if (lastDailyClaimAt == null) return true;
    final now = DateTime.now();
    final last = lastDailyClaimAt!;
    return now.year != last.year ||
        now.month != last.month ||
        now.day != last.day;
  }

  int get dailyBonusAmount {
    if (dailyStreakDays < 3)  return 50;
    if (dailyStreakDays < 7)  return 100;
    if (dailyStreakDays < 14) return 200;
    if (dailyStreakDays < 30) return 500;
    return 1000;
  }

  double get winRate => totalGamesPlayed == 0
      ? 0
      : (totalGamesWon / totalGamesPlayed * 100);

  bool get hasPendingWithdraw =>
      withdrawRequests.any((r) =>
          r.status == WithdrawStatus.pending ||
          r.status == WithdrawStatus.processing);

  static int calculateWithdrawFee(int netAmount) =>
      (netAmount * withdrawFeePct).round();

  static int grossForNetWithdraw(int netAmount) =>
      netAmount + calculateWithdrawFee(netAmount);

  WalletModel copyWith({
    int? balance,
    List<CoinTransaction>? transactions,
    int? dailyStreakDays,
    DateTime? lastDailyClaimAt,
    int? totalWon,
    int? totalGamesPlayed,
    int? totalGamesWon,
    int? totalWithdrawn,
    int? totalDeposited,
    List<WithdrawRequest>? withdrawRequests,
  }) =>
      WalletModel(
        balance:          balance          ?? this.balance,
        transactions:     transactions     ?? this.transactions,
        dailyStreakDays:  dailyStreakDays  ?? this.dailyStreakDays,
        lastDailyClaimAt: lastDailyClaimAt ?? this.lastDailyClaimAt,
        totalWon:         totalWon         ?? this.totalWon,
        totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
        totalGamesWon:    totalGamesWon    ?? this.totalGamesWon,
        totalWithdrawn:   totalWithdrawn   ?? this.totalWithdrawn,
        totalDeposited:   totalDeposited   ?? this.totalDeposited,
        withdrawRequests: withdrawRequests ?? this.withdrawRequests,
      );

  Map<String, dynamic> toJson() => {
        'balance':          balance,
        'transactions':     transactions.map((t) => t.toJson()).toList(),
        'dailyStreakDays':  dailyStreakDays,
        'lastDailyClaimAt': lastDailyClaimAt?.millisecondsSinceEpoch,
        'totalWon':         totalWon,
        'totalGamesPlayed': totalGamesPlayed,
        'totalGamesWon':    totalGamesWon,
        'totalWithdrawn':   totalWithdrawn,
        'totalDeposited':   totalDeposited,
        'withdrawRequests': withdrawRequests.map((r) => r.toJson()).toList(),
      };

  factory WalletModel.fromJson(Map<String, dynamic> j) => WalletModel(
        balance: j['balance'] as int,
        transactions: (j['transactions'] as List)
            .map((e) => CoinTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyStreakDays:  (j['dailyStreakDays']  as int?) ?? 0,
        lastDailyClaimAt: j['lastDailyClaimAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(j['lastDailyClaimAt'] as int)
            : null,
        totalWon:         (j['totalWon']         as int?) ?? 0,
        totalGamesPlayed: (j['totalGamesPlayed'] as int?) ?? 0,
        totalGamesWon:    (j['totalGamesWon']    as int?) ?? 0,
        totalWithdrawn:   (j['totalWithdrawn']   as int?) ?? 0,
        totalDeposited:   (j['totalDeposited']   as int?) ?? 0,
        withdrawRequests: (j['withdrawRequests'] as List?)
                ?.map((e) => WithdrawRequest.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
