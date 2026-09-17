import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
//  Client-side mirror of the server wire protocol.
//  Every WS frame is a JSON object with a "type" field.
// ─────────────────────────────────────────────────────────────────────────────

class MsgType {
  // client → server
  static const joinQueue     = 'join_queue';
  static const createPrivate = 'create_private';
  static const joinPrivate   = 'join_private';
  static const placeBid      = 'place_bid';
  static const playCard      = 'play_card';
  static const sendEmote     = 'send_emote';
  static const pong          = 'pong';

  // server → client
  static const queued        = 'queued';
  static const roomCreated   = 'room_created';
  static const waiting       = 'waiting';
  static const gameStart     = 'game_start';
  static const dealHand      = 'deal_hand';
  static const bidPlaced     = 'bid_placed';
  static const yourTurnBid   = 'your_turn_bid';
  static const cardPlayed    = 'card_played';
  static const yourTurnPlay  = 'your_turn_play';
  static const trickComplete = 'trick_complete';
  static const roundEnd      = 'round_end';
  static const gameOver      = 'game_over';
  static const emote         = 'emote';
  static const error         = 'error';
  static const ping          = 'ping';
}

// ── Outgoing (client → server) builders ──────────────────────────────────────

String encodeJoinQueue(String displayName, String avatarPath) =>
    jsonEncode({'type': MsgType.joinQueue, 'displayName': displayName, 'avatarPath': avatarPath});

String encodeCreatePrivate(String displayName, String avatarPath) =>
    jsonEncode({'type': MsgType.createPrivate, 'displayName': displayName, 'avatarPath': avatarPath});

String encodeJoinPrivate(String displayName, String avatarPath, String roomCode) =>
    jsonEncode({'type': MsgType.joinPrivate, 'displayName': displayName, 'avatarPath': avatarPath, 'roomCode': roomCode});

String encodePlaceBid(int bid) =>
    jsonEncode({'type': MsgType.placeBid, 'bid': bid});

String encodePlayCard(String cardWire) =>
    jsonEncode({'type': MsgType.playCard, 'card': cardWire});

String encodeSendEmote(String emote) =>
    jsonEncode({'type': MsgType.sendEmote, 'emote': emote});

String encodePong() =>
    jsonEncode({'type': MsgType.pong});

// ── Incoming (server → client) parsed events ─────────────────────────────────

/// Base class for all parsed server messages.
abstract class ServerEvent {
  const ServerEvent();
}

class QueuedEvent extends ServerEvent {
  final int position;
  const QueuedEvent(this.position);
}

class RoomCreatedEvent extends ServerEvent {
  final String roomCode;
  const RoomCreatedEvent(this.roomCode);
}

class WaitingEvent extends ServerEvent {
  /// List of seat maps: {seat, empty, name?, avatar?}
  final List<Map<String, dynamic>> seats;
  const WaitingEvent(this.seats);
}

class GameStartEvent extends ServerEvent {
  final List<Map<String, dynamic>> seats;
  final int dealer;
  final int yourSeat;
  const GameStartEvent({required this.seats, required this.dealer, required this.yourSeat});
}

class DealHandEvent extends ServerEvent {
  /// Raw card JSON list [{suit, rank}, ...]
  final List<Map<String, dynamic>> hand;
  final int dealer;
  final int round;
  const DealHandEvent({required this.hand, required this.dealer, required this.round});
}

class BidPlacedEvent extends ServerEvent {
  final int seat;
  final int bid;
  const BidPlacedEvent({required this.seat, required this.bid});
}

class YourTurnBidEvent extends ServerEvent {
  final int suggestedBid;
  const YourTurnBidEvent(this.suggestedBid);
}

class CardPlayedEvent extends ServerEvent {
  final int seat;
  final String cardWire;
  const CardPlayedEvent({required this.seat, required this.cardWire});
}

class YourTurnPlayEvent extends ServerEvent {
  final List<String> legalMoves; // wire strings
  const YourTurnPlayEvent(this.legalMoves);
}

class TrickCompleteEvent extends ServerEvent {
  final List<Map<String, dynamic>> plays; // [{seat, card wire}]
  final int winnerSeat;
  final List<int> tricksWon;
  const TrickCompleteEvent({
    required this.plays,
    required this.winnerSeat,
    required this.tricksWon,
  });
}

class RoundEndEvent extends ServerEvent {
  final Map<String, dynamic> result;
  const RoundEndEvent(this.result);
}

class GameOverEvent extends ServerEvent {
  final Map<String, dynamic> result;
  final int winnerSeat;
  const GameOverEvent({required this.result, required this.winnerSeat});
}

class EmoteEvent extends ServerEvent {
  final int seat;
  final String emote;
  const EmoteEvent({required this.seat, required this.emote});
}

class ErrorEvent extends ServerEvent {
  final String message;
  const ErrorEvent(this.message);
}

class PingEvent extends ServerEvent {
  const PingEvent();
}

class UnknownEvent extends ServerEvent {
  final String type;
  const UnknownEvent(this.type);
}

// ── Parser ────────────────────────────────────────────────────────────────────

ServerEvent parseServerMessage(String raw) {
  try {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    final type = m['type'] as String? ?? '';

    switch (type) {
      case MsgType.queued:
        return QueuedEvent(m['position'] as int);

      case MsgType.roomCreated:
        return RoomCreatedEvent(m['roomCode'] as String);

      case MsgType.waiting:
        final seats = (m['seats'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return WaitingEvent(seats);

      case MsgType.gameStart:
        final seats = (m['seats'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return GameStartEvent(
          seats:    seats,
          dealer:   m['dealer'] as int,
          yourSeat: m['yourSeat'] as int,
        );

      case MsgType.dealHand:
        final hand = (m['hand'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return DealHandEvent(
          hand:   hand,
          dealer: m['dealer'] as int,
          round:  m['round'] as int,
        );

      case MsgType.bidPlaced:
        return BidPlacedEvent(
          seat: m['seat'] as int,
          bid:  m['bid']  as int,
        );

      case MsgType.yourTurnBid:
        return YourTurnBidEvent(m['suggestedBid'] as int);

      case MsgType.cardPlayed:
        return CardPlayedEvent(
          seat:     m['seat'] as int,
          cardWire: m['card'] as String,
        );

      case MsgType.yourTurnPlay:
        return YourTurnPlayEvent(
            List<String>.from(m['legalMoves'] as List));

      case MsgType.trickComplete:
        final plays = (m['plays'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return TrickCompleteEvent(
          plays:      plays,
          winnerSeat: m['winnerSeat'] as int,
          tricksWon:  List<int>.from(m['tricksWon'] as List),
        );

      case MsgType.roundEnd:
        return RoundEndEvent(
            Map<String, dynamic>.from(m['result'] as Map));

      case MsgType.gameOver:
        return GameOverEvent(
          result:     Map<String, dynamic>.from(m['result'] as Map),
          winnerSeat: m['winnerSeat'] as int,
        );

      case MsgType.emote:
        return EmoteEvent(
          seat:  m['seat']  as int,
          emote: m['emote'] as String,
        );

      case MsgType.error:
        return ErrorEvent(m['message'] as String? ?? 'Unknown error');

      case MsgType.ping:
        return const PingEvent();

      default:
        return UnknownEvent(type);
    }
  } catch (e) {
    return ErrorEvent('Parse error: $e');
  }
}
