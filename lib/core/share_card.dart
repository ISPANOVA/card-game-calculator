import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../estimation/est_model.dart';
import '../trix/trix_model.dart';
import 'device.dart';
import 'i18n.dart';
import 'store.dart';
import 'theme.dart';

/// Shows the result card and shares it as an image (WhatsApp and the rest).
Future<void> shareGame(BuildContext context, Object game) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ShareDialog(game: game),
  );
}

class _ShareDialog extends StatefulWidget {
  final Object game;
  const _ShareDialog({required this.game});

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      if (!mounted) return;
      final ok = await Device.shareImage(data.buffer.asUint8List(), '${context.tr('shareText')} — © SMRH');
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('shareFailed'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: const Color(0xFF0B3527),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _key,
                    child: ResultCard(game: widget.game),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close'))),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: _busy
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.share_rounded),
                    label: Text(context.tr('shareResult')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The picture that gets shared: who won, everybody's score, © SMRH.
class ResultCard extends StatelessWidget {
  final Object game;
  const ResultCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    final trix = g is TrixGame;
    final players = AppState.playersOf(g);
    final totals = AppState.totalsOf(g);
    final order = [0, 1, 2, 3]..sort((a, b) => totals[b].compareTo(totals[a]));
    final finished = AppState.finishedOf(g);
    final d = AppState.createdOf(g);
    final teams = g is TrixGame && g.partners ? g.teamTotals : null;
    final progress = g is TrixGame
        ? context.tr('kingdomOf', {'n': (g.currentKingdom + 1).clamp(1, 4)})
        : context.tr('roundOf', {'n': (g as EstGame).rounds.length, 'of': g.rules.rounds});
    const medals = [Color(0xFFE2C275), Color(0xFFCFD8DC), Color(0xFFD7A26C), Color(0xFF8FA89A)];

    String winner;
    if (teams != null) {
      winner = teams[0] == teams[1]
          ? context.tr('draw')
          : (teams[0] > teams[1] ? '${players[0]} + ${players[2]}' : '${players[1]} + ${players[3]}');
    } else {
      winner = [for (final p in order) if (totals[p] == totals[order.first]) players[p]].join(' & ');
    }

    return Container(
      width: 360,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.3,
          colors: [Felt.light, Felt.base, Felt.deep],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -24,
            child: Opacity(opacity: 0.06, child: SuitIcon(Suit.spade, size: 150, color: Colors.white)),
          ),
          Positioned(
            left: -26,
            bottom: 40,
            child: Opacity(opacity: 0.06, child: SuitIcon(Suit.heart, size: 120, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SuitsMark(size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr(trix ? 'trixComplex' : 'estimation'),
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Felt.ivory)),
                          Text('${d.day}/${d.month}/${d.year} • ${finished ? context.tr('finished') : progress}',
                              style: const TextStyle(fontSize: 12.5, color: Felt.muted, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: Felt.goldGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(color: Felt.gold.withValues(alpha: 0.35), blurRadius: 20)],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Felt.deep, size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr(finished ? 'theWinner' : 'leading'),
                                style: TextStyle(
                                    fontSize: 12.5, fontWeight: FontWeight.w800, color: Felt.deep.withValues(alpha: 0.7))),
                            Text(winner,
                                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Felt.deep)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (teams != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var t = 0; t < 2; t++)
                        Expanded(
                          child: Container(
                            margin: EdgeInsetsDirectional.only(end: t == 0 ? 6 : 0, start: t == 1 ? 6 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              children: [
                                Text('${players[t]} + ${players[t + 2]}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: Felt.muted, fontWeight: FontWeight.w700)),
                                Text(numText(teams[t]),
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Felt.ivory)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                for (var i = 0; i < 4; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: i == 0 ? 0.11 : 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: i == 0 ? Felt.gold.withValues(alpha: 0.6) : Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: medals[i]),
                          child: Text('${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: Felt.deep, fontSize: 14)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(players[order[i]],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800, color: Felt.seats[order[i]])),
                        ),
                        if (i == 0) const Icon(Icons.workspace_premium_rounded, color: Felt.gold, size: 20),
                        const SizedBox(width: 6),
                        Text(numText(totals[order[i]]),
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: i == 0 ? Felt.gold : Felt.ivory)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Card Game Calculator',
                        style: TextStyle(fontSize: 11.5, color: Felt.muted.withValues(alpha: 0.9), fontWeight: FontWeight.w700)),
                    Text('  •  ', style: TextStyle(fontSize: 11.5, color: Felt.muted.withValues(alpha: 0.6))),
                    const Text('© SMRH',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 12, color: Felt.gold, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
