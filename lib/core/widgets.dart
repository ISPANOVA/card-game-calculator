import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'i18n.dart';
import 'theme.dart';

/// − value + with a big readable number.
class NumberStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final Color color;
  final bool compact;

  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 13,
    this.color = Felt.gold,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 40.0;
    Widget btn(IconData icon, int delta) {
      final enabled = delta < 0 ? value > min : value < max;
      return SizedBox(
        width: size,
        height: size,
        child: IconButton.filledTonal(
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: color.withValues(alpha: 0.14),
            foregroundColor: color,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.04),
          ),
          iconSize: compact ? 18 : 20,
          onPressed: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(value + delta);
                }
              : null,
          icon: Icon(icon),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_rounded, -1),
        SizedBox(
          width: compact ? 34 : 42,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: compact ? 19 : 22, fontWeight: FontWeight.w900, color: Felt.ivory),
          ),
        ),
        btn(Icons.add_rounded, 1),
      ],
    );
  }
}

/// A row of player chips to pick one seat (or none when [allowNone]).
class PlayerPicker extends StatelessWidget {
  final List<String> players;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool allowNone;
  final String? noneLabel;
  final Set<int> disabled;

  const PlayerPicker({
    super.key,
    required this.players,
    required this.selected,
    required this.onSelect,
    this.allowNone = false,
    this.noneLabel,
    this.disabled = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (allowNone)
          _Chip(
            label: noneLabel ?? context.tr('none'),
            color: Felt.muted,
            selected: selected < 0,
            onTap: () => onSelect(-1),
          ),
        for (var p = 0; p < players.length; p++)
          _Chip(
            label: players[p],
            color: Felt.seats[p],
            selected: selected == p,
            onTap: disabled.contains(p) ? null : () => onSelect(p),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _Chip({required this.label, required this.color, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? color : Colors.white.withValues(alpha: off ? 0.02 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? color : color.withValues(alpha: off ? 0.1 : 0.35)),
        boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? Felt.deep : (off ? Felt.muted.withValues(alpha: 0.4) : Felt.ivory),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A coloured dot + the player's name.
class SeatName extends StatelessWidget {
  final String name;
  final int seat;
  final double size;
  const SeatName(this.name, this.seat, {super.key, this.size = 15});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: Felt.seats[seat % 4], shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: size, color: Felt.ivory)),
        ),
      ],
    );
  }
}

/// Totals for four seats, leader crowned. With [teams], the two partner
/// totals are shown above.
class ScoreBoard extends StatelessWidget {
  final List<String> players;
  final List<int> totals;
  final List<int>? teams;
  final bool lowestWins;

  const ScoreBoard({super.key, required this.players, required this.totals, this.teams, this.lowestWins = false});

  @override
  Widget build(BuildContext context) {
    final best = totals.reduce((a, b) => lowestWins ? (a < b ? a : b) : (a > b ? a : b));
    final anyScore = totals.any((t) => t != 0);
    return Panel(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      child: Column(
        children: [
          if (teams != null) ...[
            Row(
              children: [
                for (var t = 0; t < 2; t++)
                  Expanded(
                    child: _TeamTile(
                      label: '${players[t]} + ${players[t + 2]}',
                      total: teams![t],
                      leading: anyScore && teams![t] == (teams![0] > teams![1] ? teams![0] : teams![1]),
                      color: Felt.seats[t],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              for (var p = 0; p < 4; p++)
                Expanded(
                  child: _SeatTotal(
                    name: players[p],
                    seat: p,
                    total: totals[p],
                    leader: anyScore && totals[p] == best,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  final String label;
  final int total;
  final bool leading;
  final Color color;
  const _TeamTile({required this.label, required this.total, required this.leading, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: leading ? Felt.gold.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: leading ? Felt.gold.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Felt.muted)),
          const SizedBox(height: 2),
          FittedBox(
            child: Text(numText(total),
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w900, color: leading ? Felt.gold : Felt.ivory, height: 1.2)),
          ),
        ],
      ),
    );
  }
}

class _SeatTotal extends StatelessWidget {
  final String name;
  final int seat;
  final int total;
  final bool leader;
  const _SeatTotal({required this.name, required this.seat, required this.total, required this.leader});

  @override
  Widget build(BuildContext context) {
    final c = Felt.seats[seat];
    return Column(
      children: [
        SizedBox(
          height: 20,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: leader ? 1 : 0,
            child: const Icon(Icons.workspace_premium_rounded, color: Felt.gold, size: 20),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.withValues(alpha: 0.18),
            border: Border.all(color: c, width: leader ? 2.2 : 1.2),
          ),
          child: Text(
            name.isEmpty ? '?' : name.characters.first.toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.w900, color: c, fontSize: 17),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Felt.muted)),
        ),
        TweenAnimationBuilder<double>(
          tween: Tween(end: total.toDouble()),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => FittedBox(
            child: Text(
              numText(v.round()),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: leader ? Felt.gold : Felt.ivory),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown when a game ends.
class WinnerBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  const WinnerBanner({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: Felt.goldGradient,
        boxShadow: [BoxShadow(color: Felt.gold.withValues(alpha: 0.35), blurRadius: 24)],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Felt.deep, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Felt.deep)),
                Text(subtitle,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Felt.deep.withValues(alpha: 0.75))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirm(BuildContext context, String title, String body, {String? ok}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(88, 44), backgroundColor: Felt.red, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok ?? ctx.tr('delete')),
        ),
      ],
    ),
  );
  return r == true;
}

/// A bar pinned at the bottom of entry pages: live preview + save.
class SaveBar extends StatelessWidget {
  final List<String> players;
  final List<int>? preview;
  final String? error;
  final String label;
  final VoidCallback? onSave;
  final Widget? extra;

  const SaveBar({
    super.key,
    required this.players,
    required this.preview,
    required this.label,
    required this.onSave,
    this.error,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF072A1F),
        border: Border(top: BorderSide(color: Felt.gold.withValues(alpha: 0.25))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, -6))],
      ),
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preview != null)
            Row(
              children: [
                for (var p = 0; p < 4; p++)
                  Expanded(
                    child: Column(
                      children: [
                        Text(players[p],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Felt.muted, fontWeight: FontWeight.w700)),
                        Text(signed(preview![p]),
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: scoreColor(preview![p]))),
                      ],
                    ),
                  ),
              ],
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Felt.lose),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(error!,
                        style: const TextStyle(color: Felt.lose, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (extra != null) ...[extra!, const SizedBox(width: 10)],
              Expanded(
                child: FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(label),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "13 left" counter for diamonds / tricks.
class RemainingPill extends StatelessWidget {
  final int total;
  final int of;
  const RemainingPill({super.key, required this.total, this.of = 13});

  @override
  Widget build(BuildContext context) {
    final left = of - total;
    if (left == 0) return Pill(context.tr('complete'), color: Felt.win, icon: Icons.check_circle_rounded);
    return Pill(
      left > 0 ? context.tr('left', {'n': left}) : context.tr('tooMany', {'n': -left}),
      color: left > 0 ? Felt.gold : Felt.lose,
    );
  }
}
