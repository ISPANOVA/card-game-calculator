import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../estimation/est_model.dart';
import '../trix/trix_model.dart';
import 'device.dart';
import 'i18n.dart';
import 'store.dart';
import 'theme.dart';

/// The phone on its side in the middle of the table: big totals for all.
class TableModePage extends StatefulWidget {
  final String gameId;
  const TableModePage({super.key, required this.gameId});

  @override
  State<TableModePage> createState() => _TableModePageState();
}

class _TableModePageState extends State<TableModePage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final found = state.games.where((g) => AppState.idOf(g) == widget.gameId);
    if (found.isEmpty) return const Scaffold(body: FeltBackground(child: SizedBox.expand()));
    final game = found.first;
    final players = AppState.playersOf(game);
    final totals = AppState.totalsOf(game);
    final best = totals.reduce((a, b) => a > b ? a : b);
    final any = totals.any((t) => t != 0);
    final teams = game is TrixGame && game.partners ? game.teamTotals : null;

    String status;
    if (game is TrixGame) {
      status = game.finished
          ? context.tr('gameOver')
          : context.tr('kingdomOwner', {'n': game.currentKingdom + 1, 'name': players[game.ownerOf(game.currentKingdom)]});
    } else {
      final g = game as EstGame;
      final next = g.rounds.length;
      status = g.finished
          ? context.tr('gameOver')
          : '${context.tr('roundOf', {'n': next + 1, 'of': g.rules.rounds})}  •  '
              '${context.tr('dealer')}: ${players[g.dealerOf(next)]}';
    }

    return KeepAwake(
      on: state.keepAwake,
      child: Scaffold(
        body: FeltBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Felt.muted),
                      ),
                      Expanded(
                        child: Text(status,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Felt.gold)),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  if (teams != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          for (var t = 0; t < 2; t++)
                            Expanded(
                              child: Text('${players[t]} + ${players[t + 2]}:  ${numText(teams[t])}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: teams[t] >= teams[1 - t] && teams[t] != teams[1 - t] ? Felt.gold : Felt.ivory)),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        for (var p = 0; p < 4; p++)
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: Felt.seats[p].withValues(alpha: any && totals[p] == best ? 0.2 : 0.08),
                                border: Border.all(
                                  color: Felt.seats[p].withValues(alpha: any && totals[p] == best ? 1 : 0.4),
                                  width: any && totals[p] == best ? 2.5 : 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 34,
                                    child: any && totals[p] == best
                                        ? const Icon(Icons.workspace_premium_rounded, color: Felt.gold, size: 32)
                                        : null,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(players[p],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Felt.seats[p])),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: FittedBox(
                                        child: Text(numText(totals[p]),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: any && totals[p] == best ? Felt.gold : Felt.ivory)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
