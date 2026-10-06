import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import 'trix_model.dart';

/// Tap the players in the order they finished.
Future<TrixRound?> showTrixEntry(
  BuildContext context, {
  required TrixGame game,
  required int kingdom,
  List<int>? initial,
}) {
  return showModalBottomSheet<TrixRound>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TrixEntry(game: game, kingdom: kingdom, initial: initial),
  );
}

class _TrixEntry extends StatefulWidget {
  final TrixGame game;
  final int kingdom;
  final List<int>? initial;
  const _TrixEntry({required this.game, required this.kingdom, this.initial});

  @override
  State<_TrixEntry> createState() => _TrixEntryState();
}

class _TrixEntryState extends State<_TrixEntry> {
  late final List<int> _order = List.of(widget.initial ?? const []);

  void _tap(int p) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_order.contains(p)) {
        _order.removeRange(_order.indexOf(p), _order.length);
      } else {
        _order.add(p);
        if (_order.length == 3) {
          _order.add([0, 1, 2, 3].firstWhere((x) => !_order.contains(x)));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.game.players;
    const medals = [Color(0xFFE2C275), Color(0xFFCFD8DC), Color(0xFFD7A26C), Color(0xFF8FA89A)];
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.tr('trix'),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(context.tr('trixTapOrder'),
              textAlign: TextAlign.center, style: const TextStyle(color: Felt.muted, height: 1.5)),
          const SizedBox(height: 12),
          Text(
            _order.length >= 4
                ? context.tr('trixDone')
                : context.tr('trixWho', {'place': context.tr('place${_order.length + 1}')}),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, color: _order.length >= 4 ? Felt.win : Felt.gold),
          ),
          const SizedBox(height: 16),
          for (var p = 0; p < 4; p++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlayerRow(
                name: players[p],
                seat: p,
                place: _order.indexOf(p),
                medal: _order.contains(p) ? medals[_order.indexOf(p)] : null,
                onTap: () => _tap(p),
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              OutlinedButton(
                onPressed: _order.isEmpty ? null : () => setState(_order.clear),
                child: Text(context.tr('clear')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _order.length == 4
                      ? () => Navigator.pop(context, TrixRound.trix(widget.kingdom, List.of(_order)))
                      : null,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(context.tr('save')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String name;
  final int seat;
  final int place;
  final Color? medal;
  final VoidCallback onTap;
  const _PlayerRow({required this.name, required this.seat, required this.place, required this.medal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final on = place >= 0;
    final r = BorderRadius.circular(18);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: r,
        color: on ? medal!.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: on ? medal! : Colors.white.withValues(alpha: 0.1), width: on ? 1.6 : 1),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? medal : Colors.white.withValues(alpha: 0.06),
                  ),
                  child: on
                      ? Text('${place + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Felt.deep))
                      : Icon(Icons.touch_app_rounded, size: 18, color: Felt.seats[seat]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5)),
                ),
                if (on)
                  Text(diffText(TrixScoring.trixPlaces[place]),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Felt.win)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
