import 'package:flutter/material.dart';

import '../estimation/est_game_page.dart';
import '../estimation/est_model.dart';
import '../estimation/est_round_page.dart';
import '../estimation/est_rules_page.dart';
import '../home_page.dart';
import '../trix/complex_entry_page.dart';
import '../trix/trix_game_page.dart';
import '../trix/trix_model.dart';
import 'store.dart';

/// Store screenshots: a web build made with --dart-define=SHOTS=true opens
/// straight on a page filled with sample games (`?shot=…&lang=…`). Normal
/// builds never include this.
const kShots = bool.fromEnvironment('SHOTS');

Widget demoHome(AppState state, String shot) {
  final ar = state.arabic;
  final names = ar ? ['أحمد', 'كريم', 'يوسف', 'عمر'] : ['Adam', 'Karim', 'Yousef', 'Omar'];
  final trix = TrixGame(
    id: 'demo-trix',
    created: DateTime(2026, 10, 2),
    players: names,
    partners: true,
    rounds: [
      const TrixRound.trix(0, [2, 0, 3, 1]),
      const TrixRound.complex(
        0,
        ComplexHand(
          kingTaker: 1,
          kingDoubledBy: 0,
          queenTakers: [3, 1, 2, 0],
          queenDoubledBy: [-1, -1, 3, -1],
          diamonds: [2, 5, 4, 2],
          tricks: [3, 4, 3, 3],
        ),
      ),
      const TrixRound.trix(1, [0, 2, 1, 3]),
      const TrixRound.complex(
        1,
        ComplexHand(kingTaker: 3, queenTakers: [0, 2, 2, 1], diamonds: [3, 3, 6, 1], tricks: [2, 3, 5, 3]),
      ),
      const TrixRound.trix(2, [1, 0, 2, 3]),
    ],
  );
  final est = EstGame(
    id: 'demo-est',
    created: DateTime(2026, 10, 4),
    players: names,
    rounds: const [
      EstRound(bids: [5, 4, 3, 0], caller: 0, trump: EstTrump.spades, tricks: [5, 4, 4, 0]),
      EstRound(bids: [6, 3, 2, 3], caller: 0, trump: EstTrump.hearts, tricks: [6, 2, 2, 3]),
      EstRound(
          bids: [4, 5, 5, 1],
          caller: 1,
          withs: [false, false, true, false],
          trump: EstTrump.noTrump,
          tricks: [3, 5, 5, 0]),
      EstRound(bids: [5, 4, 3, 2], caller: 0, trump: EstTrump.clubs, tricks: [4, 3, 2, 4]),
      EstRound(bids: [7, 3, 2, 0], caller: 0, risk: [1, 0, 0, 0], trump: EstTrump.diamonds, tricks: [7, 3, 3, 0]),
    ],
  );
  final finished = EstGame(
    id: 'demo-done',
    created: DateTime(2026, 9, 28),
    players: names,
    rounds: [
      for (var i = 0; i < 18; i++) EstRound(bids: const [5, 4, 3, 0], caller: 0, tricks: [5, 4 - i % 2, 4 + i % 2, 0]),
    ],
  );
  state.games
    ..clear()
    ..addAll([est, trix, finished]);

  switch (shot) {
    case 'trix':
      return TrixGamePage(gameId: trix.id);
    case 'complex':
      return ComplexEntryPage(
        game: trix,
        kingdom: 2,
        initial: const ComplexHand(
          kingTaker: 2,
          kingDoubledBy: 1,
          queenTakers: [0, 3, 1, 1],
          diamonds: [3, 2, 5, 3],
          tricks: [4, 3, 3, 3],
        ),
      );
    case 'est':
      return EstGamePage(gameId: est.id);
    case 'round':
      return EstRoundPage(
        game: est,
        initial: const EstRound(
          bids: [3, 6, 2, 0],
          caller: 1,
          dashCalls: [false, false, false, true],
          risk: [0, 1, 0, 0],
          trump: EstTrump.noTrump,
          tricks: [3, 6, 4, 0],
        ),
      );
    case 'rules':
      return EstRulesPage(rules: state.estRules, offerDefault: true);
    default:
      return const HomePage();
  }
}
