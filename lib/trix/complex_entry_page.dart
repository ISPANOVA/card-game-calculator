import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'trix_model.dart';

class ComplexEntryPage extends StatefulWidget {
  final TrixGame game;
  final int kingdom;
  final ComplexHand? initial;
  const ComplexEntryPage({super.key, required this.game, required this.kingdom, this.initial});

  @override
  State<ComplexEntryPage> createState() => _ComplexEntryPageState();
}

class _ComplexEntryPageState extends State<ComplexEntryPage> {
  late int _king = widget.initial?.kingTaker ?? -1;
  late int _kingX2 = widget.initial?.kingDoubledBy ?? -1;
  late bool _kingDoubled = _kingX2 >= 0;
  late final List<int> _queens = List.of(widget.initial?.queenTakers ?? const [-1, -1, -1, -1]);
  late final List<int> _queensX2 = List.of(widget.initial?.queenDoubledBy ?? const [-1, -1, -1, -1]);
  late final List<bool> _queenDoubled = [for (final d in _queensX2) d >= 0];
  late final List<int> _diamonds = List.of(widget.initial?.diamonds ?? const [0, 0, 0, 0]);
  late final List<int> _tricks = List.of(widget.initial?.tricks ?? const [0, 0, 0, 0]);

  ComplexHand get _hand => ComplexHand(
        kingTaker: _king,
        kingDoubledBy: _kingDoubled ? _kingX2 : -1,
        queenTakers: List.of(_queens),
        queenDoubledBy: [for (var q = 0; q < 4; q++) _queenDoubled[q] ? _queensX2[q] : -1],
        diamonds: List.of(_diamonds),
        tricks: List.of(_tricks),
      );

  String? _error() {
    if (_king < 0) return context.tr('errKing');
    if (_queens.any((q) => q < 0)) return context.tr('errQueens');
    if (_kingDoubled && _kingX2 < 0) return context.tr('errDoubler');
    for (var q = 0; q < 4; q++) {
      if (_queenDoubled[q] && _queensX2[q] < 0) return context.tr('errDoubler');
    }
    final d = _diamonds.fold<int>(0, (a, b) => a + b);
    if (d != 13) return context.tr('errDiamonds', {'n': d});
    final t = _tricks.fold<int>(0, (a, b) => a + b);
    if (t != 13) return context.tr('errTricks', {'n': t});
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.game.players;
    final error = _error();
    final owner = players[widget.game.ownerOf(widget.kingdom)];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            Text(context.tr('complex')),
            Text(context.tr('kingdomOwner', {'n': widget.kingdom + 1, 'name': owner}),
                style: const TextStyle(fontSize: 12.5, color: Felt.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: FeltBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
            children: [
              _CardBlock(
                rank: 'K',
                suit: '♥',
                title: context.tr('kingHearts'),
                value: -TrixScoring.king,
                players: players,
                taker: _king,
                onTaker: (p) => setState(() => _king = p),
                doubled: _kingDoubled,
                onDoubled: (v) => setState(() => _kingDoubled = v),
                doubler: _kingX2,
                onDoubler: (p) => setState(() => _kingX2 = p),
              ),
              SectionTitle(context.tr('queens'), icon: Icons.diamond_outlined),
              for (var q = 0; q < 4; q++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CardBlock(
                    rank: 'Q',
                    suit: const ['♠', '♥', '♦', '♣'][q],
                    title: context.tr('queenOf', {'suit': context.tr(const ['spades', 'hearts', 'diamondsSuit', 'clubs'][q])}),
                    value: -TrixScoring.queen,
                    players: players,
                    taker: _queens[q],
                    onTaker: (p) => setState(() => _queens[q] = p),
                    doubled: _queenDoubled[q],
                    onDoubled: (v) => setState(() => _queenDoubled[q] = v),
                    doubler: _queensX2[q],
                    onDoubler: (p) => setState(() => _queensX2[q] = p),
                  ),
                ),
              _CountBlock(
                title: context.tr('diamonds'),
                each: TrixScoring.diamond,
                icon: '♦',
                iconColor: const Color(0xFFFF8A80),
                players: players,
                values: _diamonds,
                onChanged: (p, v) => setState(() => _diamonds[p] = v),
              ),
              const SizedBox(height: 12),
              _CountBlock(
                title: context.tr('tricks'),
                each: TrixScoring.trick,
                icon: '♠',
                iconColor: Felt.ivory,
                players: players,
                values: _tricks,
                onChanged: (p, v) => setState(() => _tricks[p] = v),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SaveBar(
        players: players,
        preview: _hand.scores(),
        error: error,
        label: context.tr('save'),
        onSave: error == null ? () => Navigator.pop(context, TrixRound.complex(widget.kingdom, _hand)) : null,
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final String rank;
  final String suit;
  final String title;
  final int value;
  final List<String> players;
  final int taker;
  final ValueChanged<int> onTaker;
  final bool doubled;
  final ValueChanged<bool> onDoubled;
  final int doubler;
  final ValueChanged<int> onDoubler;

  const _CardBlock({
    required this.rank,
    required this.suit,
    required this.title,
    required this.value,
    required this.players,
    required this.taker,
    required this.onTaker,
    required this.doubled,
    required this.onDoubled,
    required this.doubler,
    required this.onDoubler,
  });

  @override
  Widget build(BuildContext context) {
    final red = suit == '♥' || suit == '♦';
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Felt.ivory,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
                ),
                child: Text('$rank\n$suit',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: red ? const Color(0xFFC62828) : const Color(0xFF1B1B1B))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                    Text(doubled ? '${value * 2} • +${-value}' : '$value',
                        style: const TextStyle(color: Felt.lose, fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
              ),
              FilterChip(
                label: const Text('×2'),
                selected: doubled,
                onSelected: onDoubled,
                showCheckmark: false,
                labelStyle: TextStyle(fontWeight: FontWeight.w900, color: doubled ? Felt.deep : Felt.gold),
                selectedColor: Felt.gold,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                side: BorderSide(color: Felt.gold.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(context.tr('takenBy'), style: const TextStyle(color: Felt.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          PlayerPicker(players: players, selected: taker, onSelect: onTaker),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: AlignmentDirectional.topStart,
            child: doubled
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('doubledBy'),
                            style: const TextStyle(color: Felt.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        PlayerPicker(players: players, selected: doubler, onSelect: onDoubler),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _CountBlock extends StatelessWidget {
  final String title;
  final int each;
  final String icon;
  final Color iconColor;
  final List<String> players;
  final List<int> values;
  final void Function(int player, int value) onChanged;

  const _CountBlock({
    required this.title,
    required this.each,
    required this.icon,
    required this.iconColor,
    required this.players,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final total = values.fold<int>(0, (a, b) => a + b);
    final left = 13 - total;
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 22, color: iconColor)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$title  (−$each)', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
              ),
              RemainingPill(total: total),
            ],
          ),
          const SizedBox(height: 6),
          for (var p = 0; p < 4; p++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: SeatName(players[p], p)),
                  if (left > 0)
                    TextButton(
                      onPressed: () => onChanged(p, values[p] + left),
                      style: TextButton.styleFrom(minimumSize: const Size(44, 36), padding: const EdgeInsets.symmetric(horizontal: 8)),
                      child: Text('+$left'),
                    ),
                  NumberStepper(
                    value: values[p],
                    onChanged: (v) => onChanged(p, v),
                    compact: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
