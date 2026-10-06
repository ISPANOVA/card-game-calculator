import 'package:card_game_calculator/core/store.dart';
import 'package:card_game_calculator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Real fonts, so text takes the room it takes on a phone.
  setUpAll(() async {
    final tajawal = FontLoader('Tajawal');
    for (final w in ['Medium', 'Bold', 'ExtraBold', 'Black']) {
      tajawal.addFont(rootBundle.load('assets/fonts/Tajawal-$w.ttf'));
    }
    await tajawal.load();
    await (FontLoader('ReemKufi')..addFont(rootBundle.load('assets/fonts/ReemKufi-Bold.ttf'))).load();
  });

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
      expect(find.textContaining('+200'), findsWidgets);
      // Complex page opens and lays out.
      await tester.tap(find.byIcon(Icons.layers_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('K'), findsOneWidget);
      final p = lang == 'ar' ? 'لاعب' : 'Player';
      // Player 1 takes the King and all four Queens.
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('$p 1').first);
        await tester.pumpAndSettle();
      }
      // Diamonds: 13 for player 1, none for the others (the last fills in).
      await tester.tap(find.text('13').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('0').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('0').last);
      await tester.pumpAndSettle();
      // Tricks: the same.
      await tester.tap(find.text('13').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('0').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('0').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.check_rounded).last);
      await tester.pumpAndSettle();
      expect(find.textContaining('-500'), findsWidgets);
    });

    testWidgets('plays an Estimation round ($lang)', (tester) async {
      await boot(tester, lang);
      await tester.tap(find.text(lang == 'ar' ? 'إستيميشن' : 'Estimation').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.record_voice_over_rounded).last);
      await tester.pumpAndSettle();
      // Player 1 has the call with 5; then the others tap their numbers.
      final p = lang == 'ar' ? 'لاعب' : 'Player';
      await tester.tap(find.text('$p 1').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('5').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('$p 2 —'), findsOneWidget);
      // Above the call is locked.
      await tester.tap(find.text('4').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('3').last);
      await tester.pumpAndSettle();
      // 5+4+3 = 12: the last player may not take 1.
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      await tester.tap(find.text('0').last);
      await tester.pumpAndSettle();
      expect(find.textContaining(lang == 'ar' ? 'الطلبات كاملة' : 'All bids in'), findsOneWidget);
      expect(find.text(lang == 'ar' ? 'جولة 1' : 'Round 1'), findsOneWidget);
    });
  }
}
