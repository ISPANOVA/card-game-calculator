import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/demo.dart';
import 'core/device.dart';
import 'core/store.dart';
import 'core/theme.dart';
import 'home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Felt.deep,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  if (!kShots) await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final state = await AppState.load();
  if (kShots) state.lang = Uri.base.queryParameters['lang'] == 'en' ? 'en' : 'ar';
  runApp(CardGameCalculator(state: state));
  Sfx.init();
}

class CardGameCalculator extends StatelessWidget {
  final AppState state;
  const CardGameCalculator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => MaterialApp(
          title: 'Card Game Calculator',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(state.arabic),
          locale: state.locale,
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: kShots ? demoHome(state, Uri.base.queryParameters['shot'] ?? 'home') : const HomePage(),
        ),
      ),
    );
  }
}
