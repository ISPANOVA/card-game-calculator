import 'package:flutter/material.dart';

import '../estimation/est_model.dart';
import '../trix/trix_model.dart';
import 'i18n.dart';
import 'store.dart';
import 'theme.dart';

class _Row {
  final String name;
  int games = 0;
  int wins = 0;
  _Row(this.name);
  double get rate => games == 0 ? 0 : wins / games;
}

/// The group's numbers across every saved game.
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final games = AppScope.of(context).games;
    final rows = <String, _Row>{};
    _Row row(String n) => rows.putIfAbsent(n.trim(), () => _Row(n.trim()));

    final kings = <String, int>{};
    final doubles = <String, int>{};
    final calls = <String, int>{};
    final dashes = <String, int>{};
    void add(Map<String, int> m, String n) => m[n.trim()] = (m[n.trim()] ?? 0) + 1;
    (String, int)? bestTrix;
    (String, int)? bestEst;
    var finishedCount = 0;

    for (final g in games) {
      final players = AppState.playersOf(g);
      final totals = AppState.totalsOf(g);
      if (g is TrixGame) {
        for (final r in g.rounds) {
          final h = r.complex;
          if (h == null) continue;
          add(kings, players[h.kingTaker]);
          if (h.kingDoubledBy >= 0) add(doubles, players[h.kingDoubledBy]);
          for (final d in h.queenDoubledBy) {
            if (d >= 0) add(doubles, players[d]);
          }
        }
      } else if (g is EstGame) {
        for (final r in g.rounds) {
          if (r.caller >= 0 && r.won(r.caller)) add(calls, players[r.caller]);
          for (var p = 0; p < 4; p++) {
            if (r.bids[p] == 0 && r.won(p)) add(dashes, players[p]);
          }
        }
      }
      if (!AppState.finishedOf(g)) continue;
      finishedCount++;
      final best = totals.reduce((a, b) => a > b ? a : b);
      final top = [for (var p = 0; p < 4; p++) if (totals[p] == best) p].first;
      if (g is TrixGame) {
        if (bestTrix == null || best > bestTrix.$2) bestTrix = (players[top], best);
      } else {
        if (bestEst == null || best > bestEst.$2) bestEst = (players[top], best);
      }
      for (final n in players) {
        row(n).games++;
      }
      if (g is TrixGame && g.partners) {
        final t = g.teamTotals;
        if (t[0] != t[1]) {
          final w = t[0] > t[1] ? 0 : 1;
          row(players[w]).wins++;
          row(players[w + 2]).wins++;
        }
      } else {
        for (var p = 0; p < 4; p++) {
          if (totals[p] == best) row(players[p]).wins++;
        }
      }
    }

    final ranking = rows.values.toList()
      ..sort((a, b) => b.wins != a.wins ? b.wins.compareTo(a.wins) : b.rate.compareTo(a.rate));

    (String, int)? most(Map<String, int> m) {
      if (m.isEmpty) return null;
      final e = m.entries.reduce((a, b) => b.value > a.value ? b : a);
      return (e.key, e.value);
    }

    final facts = <(IconData, String, (String, int)?, String)>[
      (Icons.workspace_premium_rounded, context.tr('factKing'), most(kings), 'factTimes'),
      (Icons.close_fullscreen_rounded, context.tr('factDoubler'), most(doubles), 'factTimes'),
      (Icons.campaign_rounded, context.tr('factCaller'), most(calls), 'factTimes'),
      (Icons.remove_circle_rounded, context.tr('factDash'), most(dashes), 'factTimes'),
      (Icons.stairs_rounded, context.tr('factBestTrix'), bestTrix, 'factPoints'),
      (Icons.trending_up_rounded, context.tr('factBestEst'), bestEst, 'factPoints'),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(context.tr('stats'))),
      body: FeltBackground(
        child: SafeArea(
          child: games.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(context.tr('statsEmpty'),
                        textAlign: TextAlign.center, style: const TextStyle(color: Felt.muted, height: 1.6)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    SectionTitle(context.tr('statsRanking', {'n': finishedCount}), icon: Icons.leaderboard_rounded),
                    if (ranking.isEmpty)
                      Text(context.tr('statsNoFinished'), style: const TextStyle(color: Felt.muted))
                    else
                      Panel(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Column(
                          children: [
                            for (var i = 0; i < ranking.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      child: i < 3
                                          ? Icon(Icons.emoji_events_rounded,
                                              color: const [Felt.gold, Color(0xFFCFD8DC), Color(0xFFD7A26C)][i], size: 22)
                                          : Text('${i + 1}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(color: Felt.muted, fontWeight: FontWeight.w800)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(ranking[i].name,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                                    ),
                                    Text(context.tr('winsOf', {'w': ranking[i].wins, 'g': ranking[i].games}),
                                        style: const TextStyle(color: Felt.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                    const SizedBox(width: 10),
                                    Pill('${(ranking[i].rate * 100).round()}%', color: i == 0 ? Felt.gold : Felt.muted),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    SectionTitle(context.tr('funFacts'), icon: Icons.auto_awesome_rounded),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.25,
                      children: [
                        for (final f in facts)
                          Panel(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(f.$1, color: Felt.gold, size: 22),
                                const SizedBox(height: 6),
                                Text(f.$2,
                                    maxLines: 2,
                                    style: const TextStyle(color: Felt.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text(f.$3?.$1 ?? '—',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                if (f.$3 != null)
                                  Text(context.tr(f.$4, {'n': f.$3!.$2}),
                                      style: const TextStyle(color: Felt.gold, fontSize: 12.5, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
