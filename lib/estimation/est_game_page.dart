import 'package:flutter/material.dart';

import '../core/celebrate.dart';
import '../core/device.dart';
import '../core/game_actions.dart';
import '../core/i18n.dart';
import '../core/score_chart.dart';
import '../core/share_card.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'est_model.dart';
import 'est_round_page.dart';

class EstGamePage extends StatelessWidget {
  final String gameId;
  const EstGamePage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final found = state.games.whereType<EstGame>().where((g) => g.id == gameId);
    if (found.isEmpty) return const Scaffold(body: FeltBackground(child: SizedBox.expand()));
    final game = found.first;
    final results = game.results;
    final totals = game.totals;
    final next = game.rounds.length;
    final mult = game.nextMultiplier;

    Future<void> open({int? index}) async {
      final entry = await Navigator.push<EstEntry>(
        context,
        MaterialPageRoute(
          builder: (_) => EstRoundPage(
            game: game,
            index: index,
            initial: index == null ? game.draft : game.rounds[index],
          ),
        ),
      );
      if (entry == null) return;
      final wasFinished = game.finished;
      if (index != null) {
        game.rounds[index] = entry.round;
      } else if (entry.complete) {
        game.rounds.add(entry.round);
        game.draft = null;
      } else {
        game.draft = entry.round;
      }
      await state.saveGame(game);
      if (!entry.complete) {
        Sfx.tap();
        return;
      }
      Sfx.chips();
      if (!context.mounted) return;
      final i = index ?? game.rounds.length - 1;
      if (game.rules.saaydeh && game.results[i].saaydeh && i == game.rounds.length - 1 && !game.finished) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!context.mounted) return;
        await showSaaydeh(context, game.nextMultiplier);
      }
      if (!wasFinished && game.finished) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!context.mounted) return;
        await showCelebration(
          context,
          winner: _winner(game),
          subtitle: context.tr('estimation'),
          onShare: () => shareGame(context, game),
          onRematch: () => rematch(context, game),
        );
      }
    }

    Future<void> undo() async {
      final ok = await confirm(context, context.tr('undoTitle'), context.tr('undoBody'), ok: context.tr('undo'));
      if (!ok) return;
      if (game.draft != null) {
        game.draft = null;
      } else if (game.rounds.isNotEmpty) {
        game.rounds.removeLast();
      }
      await state.saveGame(game);
    }

    final draft = game.draft;
    return KeepAwake(
      on: state.keepAwake,
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('estimation')),
        actions: gameBarActions(
          context,
          game,
          onUndo: game.rounds.isEmpty && draft == null ? null : undo,
          summary: _summary(context, game),
        ),
      ),
      body: FeltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (game.finished) ...[
                WinnerBanner(title: context.tr('winnerIs', {'name': _winner(game)}), subtitle: context.tr('gameOver')),
                const SizedBox(height: 10),
                FinishedActions(game: game),
                const SizedBox(height: 14),
              ],
              ScoreBoard(players: game.players, totals: totals),
              const SizedBox(height: 14),
              if (!game.finished)
                Panel(
                  glow: Felt.gold,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(context.tr('roundOf', {'n': next + 1, 'of': game.rules.rounds}),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                          ),
                          if (game.isFast(next)) ...[
                            Pill(context.tr('fast'), icon: Icons.bolt_rounded, color: Felt.seats[2]),
                            const SizedBox(width: 6),
                          ],
                          if (mult > 1) Pill('${context.tr('saaydeh')} ×$mult', color: Felt.seats[1], filled: true),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _TurnRow(
                        dealer: game.players[game.dealerOf(next)],
                        first: game.players[game.firstBidderOf(next)],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: next / game.rules.rounds,
                          minHeight: 6,
                          color: Felt.gold,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      if (draft != null) ...[
                        const SizedBox(height: 12),
                        _DraftView(game: game, draft: draft),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: open,
                        icon: Icon(draft == null ? Icons.record_voice_over_rounded : Icons.back_hand_rounded),
                        label: Text(context.tr(draft == null ? 'enterBids' : 'enterTricks')),
                      ),
                    ],
                  ),
                ),
              if (game.rounds.length >= 2) ...[
                SectionTitle(context.tr('scoreTrend'), icon: Icons.show_chart_rounded),
                ScoreChart(players: game.players, rounds: [for (final r in results) r.scores]),
              ],
              if (game.rounds.isNotEmpty) ...[
                SectionTitle(context.tr('rounds'), icon: Icons.receipt_long_rounded),
                for (var i = game.rounds.length - 1; i >= 0; i--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EstRoundRow(
                      game: game,
                      index: i,
                      result: results[i],
                      onTap: () => open(index: i),
                    ),
                  ),
                Text(context.tr('tapToEdit'),
                    textAlign: TextAlign.center, style: const TextStyle(color: Felt.muted, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  static String _winner(EstGame g) {
    final t = g.totals;
    final best = t.reduce((a, b) => a > b ? a : b);
    return [for (var p = 0; p < 4; p++) if (t[p] == best) g.players[p]].join(' & ');
  }

  static String _summary(BuildContext context, EstGame g) {
    final b = StringBuffer('${context.tr('estimation')} — Card Game Calculator\n');
    final t = g.totals;
    final order = [0, 1, 2, 3]..sort((a, c) => t[c].compareTo(t[a]));
    for (final p in order) {
      b.writeln('${g.players[p]}: ${t[p]}');
    }
    b.writeln(context.tr('roundOf', {'n': g.rounds.length, 'of': g.rules.rounds}));
    return b.toString();
  }
}

/// Who deals the next round and who bids first.
class _TurnRow extends StatelessWidget {
  final String dealer;
  final String first;
  const _TurnRow({required this.dealer, required this.first});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, String name) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Felt.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 11.5, color: Felt.muted, fontWeight: FontWeight.w700)),
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return Row(
      children: [
        item(Icons.style_rounded, context.tr('dealer'), dealer),
        const SizedBox(width: 8),
        item(Icons.record_voice_over_rounded, context.tr('firstBidder'), first),
      ],
    );
  }
}

class _DraftView extends StatelessWidget {
  final EstGame game;
  final EstRound draft;
  const _DraftView({required this.game, required this.draft});

  @override
  Widget build(BuildContext context) {
    final total = draft.totalBids;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(context.tr('bids'), style: const TextStyle(color: Felt.muted, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (draft.trump != EstTrump.none) ...[
                TrumpPill(draft.trump),
                const SizedBox(width: 6),
              ],
              Pill('${context.tr(total > 13 ? 'over' : 'under')} ${diffText(total - 13)}',
                  color: total > 13 ? Felt.seats[2] : Felt.seats[1]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var p = 0; p < 4; p++)
                Expanded(
                  child: Column(
                    children: [
                      Text(game.players[p],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Felt.muted, fontWeight: FontWeight.w700)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (draft.caller == p) const Icon(Icons.campaign_rounded, size: 16, color: Felt.gold),
                          Text(draft.bids[p] == 0 ? '—' : '${draft.bids[p]}',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: draft.caller == p ? Felt.gold : Felt.ivory)),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstRoundRow extends StatelessWidget {
  final EstGame game;
  final int index;
  final EstRoundResult result;
  final VoidCallback onTap;
  const _EstRoundRow({required this.game, required this.index, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = game.rounds[index];
    final total = r.totalBids;
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      radius: 18,
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Text(context.tr('roundN', {'n': index + 1}), style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              if (game.isFast(index)) ...[const Icon(Icons.bolt_rounded, size: 16, color: Felt.gold), const SizedBox(width: 4)],
              Pill(diffText(total - 13), color: total > 13 ? Felt.seats[2] : Felt.seats[1]),
              if (r.trump != EstTrump.none) ...[const SizedBox(width: 6), TrumpPill(r.trump)],
              const Spacer(),
              if (result.saaydeh) Pill(context.tr('saaydeh'), color: Felt.seats[1], filled: true),
              if (!result.saaydeh && result.multiplier > 1) Pill('×${result.multiplier}', color: Felt.seats[1], filled: true),
              const SizedBox(width: 6),
              const Icon(Icons.edit_rounded, size: 16, color: Felt.muted),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var p = 0; p < 4; p++)
                Expanded(
                  child: Column(
                    children: [
                      Text(game.players[p],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: Felt.muted, fontWeight: FontWeight.w600)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (r.caller == p) const Icon(Icons.campaign_rounded, size: 13, color: Felt.gold),
                          if (r.withs[p]) const Icon(Icons.handshake_rounded, size: 13, color: Felt.gold),
                          Text('${r.tricks[p]}/${r.bids[p]}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: r.won(p) ? Felt.win : Felt.lose)),
                        ],
                      ),
                      Text(signed(result.scores[p]),
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: scoreColor(result.scores[p]))),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
