import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../estimation/est_game_page.dart';
import '../estimation/est_model.dart';
import '../trix/trix_game_page.dart';
import '../trix/trix_model.dart';
import 'device.dart';
import 'i18n.dart';
import 'share_card.dart';
import 'store.dart';
import 'table_mode.dart';
import 'theme.dart';

/// Opens a game's page.
Widget gamePage(Object game) =>
    game is TrixGame ? TrixGamePage(gameId: game.id) : EstGamePage(gameId: (game as EstGame).id);

/// Same players, same settings, a fresh game — the first turn moves on one seat.
Future<void> rematch(BuildContext context, Object game) async {
  final state = AppScope.read(context);
  final Object next;
  if (game is TrixGame) {
    next = TrixGame(
      id: AppState.newId(),
      created: DateTime.now(),
      players: List.of(game.players),
      partners: game.partners,
      firstKing: (game.firstKing + 1) % 4,
    );
  } else {
    final g = game as EstGame;
    next = EstGame(
      id: AppState.newId(),
      created: DateTime.now(),
      players: List.of(g.players),
      rules: g.rules,
      firstDealer: (g.firstDealer + 1) % 4,
    );
  }
  await state.saveGame(next);
  Sfx.shuffle();
  if (!context.mounted) return;
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => gamePage(next)));
}

/// The app-bar buttons every game page shares.
List<Widget> gameBarActions(BuildContext context, Object game, {required VoidCallback? onUndo, required String summary}) {
  return [
    IconButton(
      tooltip: context.tr('undo'),
      onPressed: onUndo,
      icon: const Icon(Icons.undo_rounded),
    ),
    IconButton(
      tooltip: context.tr('tableMode'),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TableModePage(gameId: AppState.idOf(game))),
      ),
      icon: const Icon(Icons.screen_rotation_rounded),
    ),
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (v) async {
        switch (v) {
          case 'share':
            await shareGame(context, game);
          case 'copy':
            await Clipboard.setData(ClipboardData(text: summary));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('copied'))));
            }
          case 'rematch':
            await rematch(context, game);
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'share', child: _MenuRow(Icons.share_rounded, ctx.tr('shareResult'))),
        PopupMenuItem(value: 'copy', child: _MenuRow(Icons.copy_rounded, ctx.tr('copyResults'))),
        PopupMenuItem(value: 'rematch', child: _MenuRow(Icons.replay_rounded, ctx.tr('rematch'))),
      ],
    ),
  ];
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MenuRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: Felt.gold),
          const SizedBox(width: 12),
          Text(text),
        ],
      );
}

/// Under the winner banner: share the result, or play again.
class FinishedActions extends StatelessWidget {
  final Object game;
  const FinishedActions({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () => shareGame(context, game),
            icon: const Icon(Icons.share_rounded),
            label: Text(context.tr('shareResult')),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => rematch(context, game),
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52)),
            icon: const Icon(Icons.replay_rounded),
            label: FittedBox(fit: BoxFit.scaleDown, child: Text(context.tr('rematch'))),
          ),
        ),
      ],
    );
  }
}
