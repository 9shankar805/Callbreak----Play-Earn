import 'card_model.dart';

enum PlayerType { human, bot }

class Player {
  final int seat;
  String name;
  final PlayerType type;
  String avatarPath;
  String flag;
  final bool hasSpadeBadge;
  List<PlayingCard> hand;
  int? bid;
  int tricksWon;

  static const List<String> availableAvatars = [
    'assets/images/avatars/you.png',
    'assets/images/avatars/avatar_1.png',
    'assets/images/avatars/avatar_2.png',
    'assets/images/avatars/avatar_3.png',
    'assets/images/avatars/avatar_4.png',
    'assets/images/avatars/avatar_5.png',
    'assets/images/avatars/avatar_6.png',
    'assets/images/avatars/avatar_7.png',
    'assets/images/avatars/avatar_8.png',
    'assets/images/avatars/dannie.png',
    'assets/images/avatars/meena.png',
    'assets/images/avatars/lily.png',
  ];

  Player({
    required this.seat,
    required this.name,
    required this.type,
    required this.avatarPath,
    this.flag = '🇮🇳',
    this.hasSpadeBadge = false,
    this.hand = const [],
    this.bid,
    this.tricksWon = 0,
  });

  bool get isHuman => type == PlayerType.human;
  bool get isBot => type == PlayerType.bot;

  // ── Serialization (network-safe — never includes full hand) ──────────────────

  /// Public view: what other players can see (name, seat, bid, tricks — NOT hand).
  Map<String, dynamic> toPublicJson() => {
        'seat': seat,
        'name': name,
        'type': type.index,
        'avatarPath': avatarPath,
        'flag': flag,
        'bid': bid,
        'tricksWon': tricksWon,
      };

  /// Private view: includes the player's own hand.
  Map<String, dynamic> toPrivateJson() => {
        ...toPublicJson(),
        'hand': hand.map((c) => c.toJson()).toList(),
      };

  factory Player.fromPublicJson(Map<String, dynamic> j) => Player(
        seat: j['seat'] as int,
        name: j['name'] as String,
        type: PlayerType.values[j['type'] as int],
        avatarPath: (j['avatarPath'] as String?) ?? 'assets/images/avatars/you.png',
        flag: (j['flag'] as String?) ?? '🇮🇳',
        bid: j['bid'] as int?,
        tricksWon: (j['tricksWon'] as int?) ?? 0,
      );

  factory Player.fromPrivateJson(Map<String, dynamic> j) {
    final p = Player.fromPublicJson(j);
    if (j['hand'] != null) {
      p.hand = (j['hand'] as List)
          .map((e) => PlayingCard.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return p;
  }

  // Seat positions matching screenshot:
  // 0: Bottom (You)
  // 1: Right (bot2)
  // 2: Top (bot3)
  // 3: Left (bot1)
  static List<Player> createDefault() => [
    Player(
      seat: 0,
      name: 'You',
      type: PlayerType.human,
      avatarPath: 'assets/images/avatars/you.png',
      hasSpadeBadge: true,
    ),
    Player(
      seat: 1,
      name: 'bot2',
      type: PlayerType.bot,
      avatarPath: 'assets/images/avatars/bot.png',
      hasSpadeBadge: true,
    ),
    Player(
      seat: 2,
      name: 'bot3',
      type: PlayerType.bot,
      avatarPath: 'assets/images/avatars/bot.png',
      hasSpadeBadge: true,
    ),
    Player(
      seat: 3,
      name: 'bot1',
      type: PlayerType.bot,
      avatarPath: 'assets/images/avatars/bot.png',
      hasSpadeBadge: true,
    ),
  ];
}

