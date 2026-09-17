import 'package:flutter_test/flutter_test.dart';
import 'package:callbreak/main.dart';
import 'package:callbreak/services/sound_service.dart';

void main() {
  setUpAll(() {
    SoundService.disableAudio = true;
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CallbreakApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PLAY NOW'), findsOneWidget);
  });
}
