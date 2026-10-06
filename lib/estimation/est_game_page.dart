import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/i18n.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'est_model.dart';
import 'est_round_page.dart';
import 'est_setup_page.dart';

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
      if (index != null) {
        game.rounds[index] = entry.round;
      } else if (entry.complete) {
        game.rounds.add(entry.round);
        game.draft = null;
      } else {
        game.draft = entry.round;
      }
      await state.saveGame(game);
      if (game.finished) HapticFeedback.heavyImpact();
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('estimation')),
        actions: [
          IconButton(
            tooltip: context.tr('undo'),
            onPressed: game.rounds.isEmpty && draft == null ? null : undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) async {
              if (v == 'copy') {
                await Clipboard.setData(ClipboardData(text: _summary(context, game)));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('copied'))));
                }
              } else if (v == 'new') {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EstSetupPage()));
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'copy', child: Text(ctx.tr('copyResults'))),
              PopupMenuItem(value: 'new', child: Text(ctx.tr('newGame'))),
            ],
          ),
        ],
      ),
      body: FeltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (game.finished) ...[
                WinnerBanner(title: context.tr('winnerIs', {'name': _winner(game)}), subtitle: context.tr('gameOver')),
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
              if (trumpSymbols[draft.trump] != null) ...[
                Pill(trumpSymbols[draft.trump]!),
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
              if (trumpSymbols[r.trump] != null) ...[const SizedBox(width: 6), Pill(trumpSymbols[r.trump]!)],
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
