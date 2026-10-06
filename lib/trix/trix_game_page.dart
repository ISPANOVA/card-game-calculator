import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/i18n.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'complex_entry_page.dart';
import 'trix_entry_sheet.dart';
import 'trix_model.dart';
import 'trix_setup_page.dart';

class TrixGamePage extends StatelessWidget {
  final String gameId;
  const TrixGamePage({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final found = state.games.whereType<TrixGame>().where((g) => g.id == gameId);
    if (found.isEmpty) return const Scaffold(body: FeltBackground(child: SizedBox.expand()));
    final game = found.first;
    final k = game.currentKingdom;

    Future<void> addOrEdit(TrixContract c, int kingdom, {int? index}) async {
      final existing = index == null ? null : game.rounds[index];
      TrixRound? round;
      if (c == TrixContract.complex) {
        round = await Navigator.push<TrixRound>(
          context,
          MaterialPageRoute(
            builder: (_) => ComplexEntryPage(game: game, kingdom: kingdom, initial: existing?.complex),
          ),
        );
      } else {
        round = await showTrixEntry(context, game: game, kingdom: kingdom, initial: existing?.trixOrder);
      }
      if (round == null) return;
      if (index == null) {
        game.rounds.add(round);
      } else {
        game.rounds[index] = round;
      }
      await state.saveGame(game);
      if (game.finished) HapticFeedback.heavyImpact();
    }

    Future<void> undo() async {
      if (game.rounds.isEmpty) return;
      final ok = await confirm(context, context.tr('undoTitle'), context.tr('undoBody'), ok: context.tr('undo'));
      if (!ok) return;
      game.rounds.removeLast();
      await state.saveGame(game);
    }

    final totals = game.totals;
    final teams = game.partners ? game.teamTotals : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('trixComplex')),
        actions: [
          IconButton(
            tooltip: context.tr('undo'),
            onPressed: game.rounds.isEmpty ? null : undo,
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
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TrixSetupPage()));
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
                WinnerBanner(
                  title: context.tr('winnerIs', {'name': _winnerName(context, game)}),
                  subtitle: context.tr('gameOver'),
                ),
                const SizedBox(height: 14),
              ],
              ScoreBoard(players: game.players, totals: totals, teams: teams),
              SectionTitle(context.tr('kingdoms'), icon: Icons.castle_rounded),
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _KingdomTile(game: game, kingdom: i, current: i == k),
                      ),
                    ),
                ],
              ),
              if (!game.finished) ...[
                const SizedBox(height: 16),
                Panel(
                  glow: Felt.gold,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('kingdomOwner', {'n': k + 1, 'name': game.players[game.ownerOf(k)]}),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5),
                      ),
                      const SizedBox(height: 4),
                      Text(context.tr('chooseContract'), style: const TextStyle(color: Felt.muted, fontSize: 13)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _ContractButton(
                              label: context.tr('trix'),
                              sub: '+500',
                              icon: Icons.stairs_rounded,
                              done: game.played(k, TrixContract.trix),
                              onTap: () => addOrEdit(TrixContract.trix, k),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ContractButton(
                              label: context.tr('complex'),
                              sub: '−500',
                              icon: Icons.layers_rounded,
                              done: game.played(k, TrixContract.complex),
                              onTap: () => addOrEdit(TrixContract.complex, k),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              if (game.rounds.isNotEmpty) ...[
                SectionTitle(context.tr('rounds'), icon: Icons.receipt_long_rounded),
                for (var i = game.rounds.length - 1; i >= 0; i--)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _RoundRow(
                      game: game,
                      round: game.rounds[i],
                      onTap: () => addOrEdit(game.rounds[i].contract, game.rounds[i].kingdom, index: i),
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

  static String _winnerName(BuildContext context, TrixGame g) {
    if (g.partners) {
      final t = g.teamTotals;
      if (t[0] == t[1]) return context.tr('draw');
      final w = t[0] > t[1] ? 0 : 1;
      return '${g.players[w]} + ${g.players[w + 2]}';
    }
    final t = g.totals;
    final best = t.reduce((a, b) => a > b ? a : b);
    return [for (var p = 0; p < 4; p++) if (t[p] == best) g.players[p]].join(' & ');
  }

  static String _summary(BuildContext context, TrixGame g) {
    final b = StringBuffer('${context.tr('trixComplex')} — Card Game Calculator\n');
    final t = g.totals;
    final order = [0, 1, 2, 3]..sort((a, c) => t[c].compareTo(t[a]));
    for (final p in order) {
      b.writeln('${g.players[p]}: ${t[p]}');
    }
    if (g.partners) {
      final tt = g.teamTotals;
      b.writeln('${g.players[0]} + ${g.players[2]}: ${tt[0]}');
      b.writeln('${g.players[1]} + ${g.players[3]}: ${tt[1]}');
    }
    return b.toString();
  }
}

class _KingdomTile extends StatelessWidget {
  final TrixGame game;
  final int kingdom;
  final bool current;
  const _KingdomTile({required this.game, required this.kingdom, required this.current});

  @override
  Widget build(BuildContext context) {
    final owner = game.ownerOf(kingdom);
    final trix = game.played(kingdom, TrixContract.trix);
    final complex = game.played(kingdom, TrixContract.complex);
    final done = trix && complex;
    final c = Felt.seats[owner];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: current ? c.withValues(alpha: 0.16) : Colors.white.withValues(alpha: done ? 0.02 : 0.05),
        border: Border.all(color: current ? c : Colors.white.withValues(alpha: 0.08), width: current ? 1.6 : 1),
      ),
      child: Column(
        children: [
          Icon(done ? Icons.check_circle_rounded : Icons.workspace_premium_rounded,
              size: 20, color: done ? Felt.win : (current ? c : Felt.muted)),
          const SizedBox(height: 4),
          Text(game.players[owner],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: done ? Felt.muted : Felt.ivory)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Dot(on: trix, label: 'T'),
              const SizedBox(width: 4),
              _Dot(on: complex, label: 'C'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool on;
  final String label;
  const _Dot({required this.on, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? Felt.win.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.07),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: on ? Felt.deep : Felt.muted)),
    );
  }
}

class _ContractButton extends StatelessWidget {
  final String label;
  final String sub;
  final IconData icon;
  final bool done;
  final VoidCallback onTap;
  const _ContractButton({
    required this.label,
    required this.sub,
    required this.icon,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return Opacity(
      opacity: done ? 0.45 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: done ? null : Felt.goldGradient,
          color: done ? Colors.white.withValues(alpha: 0.06) : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: r,
            onTap: done ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Icon(done ? Icons.check_rounded : icon, color: done ? Felt.win : Felt.deep, size: 26),
                  const SizedBox(height: 4),
                  Text(label,
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: done ? Felt.ivory : Felt.deep)),
                  Text(sub,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: done ? Felt.muted : Felt.deep.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundRow extends StatelessWidget {
  final TrixGame game;
  final TrixRound round;
  final VoidCallback onTap;
  const _RoundRow({required this.game, required this.round, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = round.scores;
    final isTrix = round.contract == TrixContract.trix;
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      radius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(context.tr(isTrix ? 'trix' : 'complex'),
                  color: isTrix ? Felt.win : Felt.lose, icon: isTrix ? Icons.stairs_rounded : Icons.layers_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('kingdomOwner', {'n': round.kingdom + 1, 'name': game.players[game.ownerOf(round.kingdom)]}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Felt.muted, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
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
                      Text(signed(s[p]),
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: scoreColor(s[p]))),
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
