import 'package:card_game_calculator/core/store.dart';
import 'package:card_game_calculator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> boot(WidgetTester tester, String lang) async {
    SharedPreferences.setMockInitialValues({'lang': lang});
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final state = await AppState.load();
    await tester.pumpWidget(CardGameCalculator(state: state));
    await tester.pumpAndSettle();
  }

  for (final lang in ['ar', 'en']) {
    testWidgets('plays a Trix game ($lang)', (tester) async {
      await boot(tester, lang);
      expect(find.text('Calculator'), findsOneWidget);
      await tester.tap(find.text(lang == 'ar' ? 'تريكس كومبليكس' : 'Trix Complex').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();
      // Trix: tap three players, the fourth is filled in.
      await tester.tap(find.byIcon(Icons.stairs_rounded).first);
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.touch_app_rounded).first);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byIcon(Icons.check_rounded).last);
      await tester.pumpAndSettle();
      expect(find.text('+200'), findsWidgets);
      // Complex page opens and lays out.
      await tester.tap(find.byIcon(Icons.layers_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('K\n♥'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('plays an Estimation round ($lang)', (tester) async {
      await boot(tester, lang);
      await tester.tap(find.text(lang == 'ar' ? 'إستيميشن' : 'Estimation').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.record_voice_over_rounded).last);
      await tester.pumpAndSettle();
      // Player 1 bids 5: the call goes to them.
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.add_rounded).first);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text(lang == 'ar' ? 'جولة 1' : 'Round 1'), findsOneWidget);
    });
  }
}
