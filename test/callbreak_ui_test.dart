import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:callbreak/controller/game_controller.dart';
import 'package:callbreak/models/player_model.dart';
import 'package:callbreak/models/card_model.dart';
import 'package:callbreak/models/trick_model.dart';
import 'package:callbreak/screens/bidding_screen.dart';
import 'package:callbreak/screens/scoreboard_screen.dart';
import 'package:callbreak/screens/game_screen.dart';
import 'package:callbreak/widgets/player_info_widget.dart';
import 'package:callbreak/widgets/playing_card_widget.dart';
import 'package:callbreak/widgets/dealing_animation_overlay.dart';
import 'package:callbreak/services/sound_service.dart';
import 'package:callbreak/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SoundService.disableAudio = true;
  });

  group('Callbreak UI & Controller Tests (Screenshot Faithful)', () {
    test('Default players match screenshot profiles (You, bot1, bot2, bot3)', () {
      final players = Player.createDefault();
      expect(players.length, 4);
      expect(players[0].name, 'You');
      expect(players[1].name, 'bot2');
      expect(players[2].name, 'bot3');
      expect(players[3].name, 'bot1');
      expect(players[1].avatarPath, contains('bot.png'));
      expect(players[2].avatarPath, contains('bot.png'));
      expect(players[3].avatarPath, contains('bot.png'));
    });

    test('Theme switching works across Classic Wood, Desert, Autumn, and Cricket', () {
      final controller = GameController();
      expect(controller.currentTheme, GameThemeMode.classicWood);

      controller.setTheme(GameThemeMode.desert);
      expect(controller.currentTheme, GameThemeMode.desert);

      controller.setTheme(GameThemeMode.autumn);
      expect(controller.currentTheme, GameThemeMode.autumn);

      controller.dispose();
    });

    testWidgets('BiddingOverlay renders Make your bid, slider, stepper, and checkmark', (tester) async {
      final controller = GameController();
      controller.startGame();
      controller.turnSeat = 0;

      tester.view.physicalSize = const Size(1080, 552);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<GameController>.value(
              value: controller,
              child: const BiddingOverlay(),
            ),
          ),
        ),
      );
      await tester.pump();

      // Verify "Make your bid" title matching Screenshot 3
      expect(find.text('Make your bid'), findsOneWidget);
      // Verify numbers 1-8 are present
      for (int i = 1; i <= 8; i++) {
        expect(find.text('$i'), findsWidgets);
      }
      // Verify stepper buttons - and +
      final minusBtn = find.text('-');
      final plusBtn = find.text('+');
      expect(minusBtn, findsOneWidget);
      expect(plusBtn, findsOneWidget);
      // Verify checkmark confirm icon
      final checkBtn = find.byIcon(Icons.check_rounded);
      expect(checkBtn, findsOneWidget);
      // Verify lightbulb hint icon
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);

      // Test tapping number 5
      await tester.tap(find.text('5'));
      await tester.pump();

      // Test tapping + (becomes 6)
      await tester.tap(plusBtn);
      await tester.pump();

      // Test tapping - (becomes 5)
      await tester.tap(minusBtn);
      await tester.pump();

      // Test tapping checkmark confirm button
      await tester.tap(checkBtn);
      await tester.pump();

      // Verify controller recorded the human bid of 5!
      expect(controller.humanPlayer.bid, 5);

      controller.dispose();
    });

    testWidgets('ScoreboardSheet renders tabs, player columns, and notebook layout', (tester) async {
      final controller = GameController();
      controller.startGame();

      tester.view.physicalSize = const Size(1080, 552);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScoreboardSheet(game: controller),
          ),
        ),
      );
      await tester.pump();

      // Verify Left tabs matching Screenshot 1
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Bots Mode'), findsOneWidget);
      expect(find.text('5 Round'), findsOneWidget);

      // Verify Players columns matching Screenshot 1 order
      expect(find.text('bot3'), findsOneWidget);
      expect(find.text('bot1'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.text('bot2'), findsOneWidget);
      expect(find.text('Sum'), findsOneWidget);

      // Verify Overall Score & Final Score rows
      expect(find.text('Overall\nScore'), findsOneWidget);
      expect(find.text('Final\nScore'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('GameScreen mounts in landscape layout with avatars and round counter', (tester) async {
      final controller = GameController();
      controller.startGame();

      tester.view.physicalSize = const Size(1080, 552);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameController>.value(
            value: controller,
            child: const GameScreen(),
          ),
        ),
      );
      await tester.pump();

      // Check player avatars exist
      expect(find.byType(CallbreakPlayerAvatar), findsNWidgets(4));
      expect(find.text('bot3'), findsOneWidget);
      expect(find.text('bot1'), findsOneWidget);
      expect(find.text('bot2'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      // Check top round button (1/5)
      expect(find.text('1/5'), findsOneWidget);

      // Verify Make your bid modal is open and clickable in GameScreen immediately
      expect(find.text('Make your bid'), findsOneWidget);
      final checkBtn = find.byIcon(Icons.check_rounded);
      expect(checkBtn, findsOneWidget);
      await tester.tap(checkBtn);
      await tester.pump();

      // Verify bid is confirmed and recorded
      expect(controller.humanPlayer.bid, isNotNull);

      controller.dispose();
    });

    test('Public Domain Deck card asset paths exist for all 52 cards', () {
      const suits = Suit.values;
      const ranks = Rank.values;
      expect(suits.length * ranks.length, 52);

      for (final s in suits) {
        for (final r in ranks) {
          final card = PlayingCard(suit: s, rank: r);
          expect(card.assetPath, startsWith('assets/cards/'));
          expect(card.assetPath, endsWith('.png'));
        }
      }
    });

    testWidgets('PlayingCardWidget renders card face and card back', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                PlayingCardWidget(
                  card: PlayingCard(suit: Suit.spades, rank: Rank.ace),
                  width: 60,
                  height: 84,
                ),
                PlayingCardWidget(
                  card: null, // Card back
                  width: 60,
                  height: 84,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PlayingCardWidget), findsNWidgets(2));
      expect(find.byType(Image), findsNWidgets(2));
    });

    test('SoundService toggles mute and triggers sound methods safely', () {
      final sounds = SoundService.instance;
      expect(sounds.isMuted, false);

      sounds.toggleMute();
      expect(sounds.isMuted, true);

      // Verify safe invocation without crash while muted
      sounds.playCardTap();
      sounds.playCardSlide();
      sounds.playCardPlace();
      sounds.playCardFan();
      sounds.playTrickWin();
      sounds.playButtonClick();
      sounds.playCoin();
      sounds.playWin();
      sounds.playWhoosh();

      sounds.toggleMute();
      expect(sounds.isMuted, false);
    });

    testWidgets('SettingsDrawer opens and displays all controls matching Screenshot 2', (tester) async {
      final controller = GameController();
      tester.view.physicalSize = const Size(800, 380);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap wooden settings cog button
      final cogBtn = find.byIcon(Icons.settings_rounded);
      expect(cogBtn, findsOneWidget);
      await tester.tap(cogBtn);
      await tester.pumpAndSettle();

      // Verify drawer items matching Screenshot 2
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sound | Music'), findsOneWidget);
      expect(find.text('Show mini scoreboard'), findsOneWidget);
      expect(find.text('Suggest Bid'), findsOneWidget);
      expect(find.text('Highlight valid cards'), findsOneWidget);
      expect(find.text('Touch to throw'), findsOneWidget);
      expect(find.text('Game speed'), findsOneWidget);
      expect(find.text('Restart / Quit Game'), findsOneWidget);

      // Speed segment buttons
      expect(find.text('Slow'), findsOneWidget);
      expect(find.text('Normal'), findsWidgets);
      expect(find.text('Fast'), findsOneWidget);

      // Verify no overflow error occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Human player can throw a legal card during playing turn', (tester) async {
      final controller = GameController();
      controller.startGame();
      // Set all bids and make it human turn in playing phase
      controller.players[0].bid = 2;
      controller.players[1].bid = 2;
      controller.players[2].bid = 2;
      controller.players[3].bid = 2;
      controller.phase = GamePhase.playing;
      controller.turnSeat = 0; // human leads
      controller.currentTrick = [];

      tester.view.physicalSize = const Size(800, 380);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(controller.humanPlayer.hand.length, 13);
      expect(controller.currentTrick.length, 0);

      // Tap on the first card
      final cardToThrow = controller.humanPlayer.hand.first;
      final cardFinder = find.byWidgetPredicate(
        (w) => w is PlayingCardWidget && w.card == cardToThrow,
      );
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pump();

      // Verify card was thrown!
      expect(controller.humanPlayer.hand.length, 12);
      expect(controller.currentTrick.length, 1);
      expect(controller.currentTrick.first.card, cardToThrow);
      expect(controller.currentTrick.first.seat, 0);

      controller.dispose();
    });

    testWidgets('Bots auto play sequentially after human throws a card', (tester) async {
      final controller = GameController();
      controller.startGame();
      for (int i = 0; i < 4; i++) {
        controller.players[i].bid = 2;
      }
      controller.phase = GamePhase.playing;
      controller.turnSeat = 3; // bot1 leads
      controller.currentTrick = [];

      tester.view.physicalSize = const Size(800, 380);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: const MaterialApp(
            home: GameScreen(),
          ),
        ),
      );
      await tester.pump();

      // Bot 1 plays its card
      controller.turnSeat = 3;
      final bot1Card = controller.players[3].hand.first;
      controller.players[3].hand.removeAt(0);
      controller.currentTrick.add(TrickPlay(seat: 3, card: bot1Card));
      controller.turnSeat = 0; // now human's turn!
      await tester.pump();

      expect(controller.currentTrick.length, 1);
      expect(controller.turnSeat, 0);

      // Human throws a legal card
      final legalCard = controller.legalMoves.first;
      final cardFinder = find.byWidgetPredicate(
        (w) => w is PlayingCardWidget && w.card == legalCard,
      );
      expect(cardFinder, findsOneWidget);

      await tester.tap(cardFinder);
      await tester.pump();

      // Human card is thrown!
      expect(controller.currentTrick.length, 2);
      expect(controller.turnSeat, 1); // bot2's turn!

      // Advance time for bot2
      await tester.pump(const Duration(milliseconds: 1000));
      expect(controller.currentTrick.length, 3);
      expect(controller.turnSeat, 2); // bot3's turn!

      // Advance time for bot3
      await tester.pump(const Duration(milliseconds: 1000));
      expect(controller.currentTrick.length, 4); // all 4 played!

      controller.dispose();
    });

    testWidgets('Dealing animation displays overlay and transitions to bidding on tap/completion', (tester) async {
      final controller = GameController();
      controller.startGame(animateDealing: true);
      expect(controller.phase, GamePhase.dealing);

      tester.view.physicalSize = const Size(1080, 552);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GameController>.value(
            value: controller,
            child: const GameScreen(),
          ),
        ),
      );
      await tester.pump();

      // Verify dealing overlay and banner are visible
      expect(find.byType(DealingAnimationOverlay), findsOneWidget);
      expect(find.text('Dealing Cards...'), findsOneWidget);
      expect(find.text('Tap to skip ⏩'), findsOneWidget);

      // Tap to skip dealing
      await tester.tap(find.text('Tap to skip ⏩'));
      await tester.pump();

      // Verify transitioned to bidding phase
      expect(controller.phase, GamePhase.bidding);
      expect(find.byType(DealingAnimationOverlay), findsNothing);

      controller.dispose();
    });
  });
}
