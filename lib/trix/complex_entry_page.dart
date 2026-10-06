import 'package:flutter/material.dart';

import '../core/device.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'trix_model.dart';

/// Complex, entered the way it is counted after the hand:
///  1. the cards — tap who took the King and each Queen (×2 if doubled),
///  2. the diamonds — a 0–13 pad per player,
///  3. the tricks — the same.
/// Each step moves on by itself; numbers that cannot be right are locked.
class ComplexEntryPage extends StatefulWidget {
  final TrixGame game;
  final int kingdom;
  final ComplexHand? initial;
  const ComplexEntryPage({super.key, required this.game, required this.kingdom, this.initial});

  @override
  State<ComplexEntryPage> createState() => _ComplexEntryPageState();
}

/// The five penalty cards: King of hearts, then the Queens ♠ ♥ ♦ ♣.
const _cards = [
  ('K', Suit.heart),
  ('Q', Suit.spade),
  ('Q', Suit.heart),
  ('Q', Suit.diamond),
  ('Q', Suit.club),
];

/// Index of the Queen of diamonds in [_cards] (it is also a diamond).
const _qDiamond = 3;

class _ComplexEntryPageState extends State<ComplexEntryPage> {
  late final List<int> _takers = [
    widget.initial?.kingTaker ?? -1,
    ...(widget.initial?.queenTakers ?? const [-1, -1, -1, -1]),
  ];
  late final List<int> _doublers = [
    widget.initial?.kingDoubledBy ?? -1,
    ...(widget.initial?.queenDoubledBy ?? const [-1, -1, -1, -1]),
  ];
  late final List<bool> _doubled = [for (final d in _doublers) d >= 0];
  late final List<int?> _diamonds = [for (var p = 0; p < 4; p++) widget.initial?.diamonds[p]];
  late final List<int?> _tricks = [for (var p = 0; p < 4; p++) widget.initial?.tricks[p]];

  /// 0: cards, 1: diamonds, 2: tricks.
  int _step = 0;

  /// The card being asked about (-1: none) and whether it is its doubler.
  late int _card = _nextCard(-1);
  bool _askDoubler = false;

  /// The player whose number the pad enters (steps 1–2).
  int _active = -1;

  int get _owner => widget.game.ownerOf(widget.kingdom);
  List<int> get _order => [for (var i = 0; i < 4; i++) (_owner + i) % 4];

  ComplexHand get _hand => ComplexHand(
        kingTaker: _takers[0],
        kingDoubledBy: _doubled[0] ? _doublers[0] : -1,
        queenTakers: _takers.sublist(1),
        queenDoubledBy: [for (var c = 1; c < 5; c++) _doubled[c] ? _doublers[c] : -1],
        diamonds: [for (final d in _diamonds) d ?? 0],
        tricks: [for (final t in _tricks) t ?? 0],
      );

  bool _cardOpen(int c) => _takers[c] < 0 || (_doubled[c] && _doublers[c] < 0);
  bool get _cardsDone => [for (var c = 0; c < 5; c++) _cardOpen(c)].every((open) => !open);
  bool get _diamondsDone => _diamonds.every((d) => d != null);
  bool get _tricksDone => _tricks.every((t) => t != null);

  /// The next card still missing something after [from] (-1: none).
  int _nextCard(int from) =>
      [for (var i = 1; i <= 5; i++) (from + i) % 5].firstWhere(_cardOpen, orElse: () => -1);

  // ------------------------------------------------------------ the rules ---

  int _minDiamonds(int p) => _takers[_qDiamond] == p ? 1 : 0;

  /// Penalty cards [p] took (the Queen of diamonds counts among diamonds).
  int _cardsOf(int p) {
    var n = _diamonds[p] ?? _minDiamonds(p);
    if (_takers[0] == p) n++;
    for (var c = 1; c < 5; c++) {
      if (c != _qDiamond && _takers[c] == p) n++;
    }
    return n;
  }

  /// Every trick holds 4 cards, so whoever took cards took enough tricks.
  int _minTricks(int p) => (_cardsOf(p) + 3) ~/ 4;

  bool _allowed(List<int?> values, int p, int n, int min) {
    if (n < min) return false;
    final others = [for (var q = 0; q < 4; q++) if (q != p) values[q]];
    final sum = others.fold<int>(0, (a, b) => a + (b ?? 0));
    if (sum + n > 13) return false;
    if (others.every((v) => v != null) && sum + n != 13) return false;
    return true;
  }

  String? _error() {
    final players = widget.game.players;
    if (_takers[0] < 0) return context.tr('errKing');
    if (_takers.any((t) => t < 0)) return context.tr('errQueens');
    for (var c = 0; c < 5; c++) {
      if (_doubled[c] && _doublers[c] < 0) return context.tr('errDoubler');
    }
    final d = _diamonds.fold<int>(0, (a, b) => a + (b ?? 0));
    if (!_diamondsDone || d != 13) return context.tr('errDiamonds', {'n': d});
    final t = _tricks.fold<int>(0, (a, b) => a + (b ?? 0));
    if (!_tricksDone || t != 13) return context.tr('errTricks', {'n': t});
    for (var p = 0; p < 4; p++) {
      if (_diamonds[p]! < _minDiamonds(p)) return context.tr('errQDiamond', {'name': players[p]});
      if (_tricks[p]! < _minTricks(p)) return context.tr('errFewTricks', {'name': players[p]});
    }
    return null;
  }

  // ------------------------------------------------------------- actions ---

  void _enterStep(int step) {
    _step = step;
    _askDoubler = false;
    if (step == 0) {
      _card = _nextCard(-1);
    } else {
      final values = step == 1 ? _diamonds : _tricks;
      _active = _order.firstWhere((p) => values[p] == null, orElse: () => -1);
    }
  }

  void _afterCard() {
    _askDoubler = false;
    _card = _nextCard(_card);
    if (_card >= 0) {
      _askDoubler = _takers[_card] >= 0;
    } else if (!_diamondsDone) {
      _enterStep(1);
    }
  }

  void _tapPlayer(int p) {
    Sfx.tap();
    setState(() {
      if (_step > 0) {
        _active = p;
        return;
      }
      if (_card < 0) return;
      if (_askDoubler) {
        _doublers[_card] = p;
        if (_takers[_card] >= 0) {
          _afterCard();
        } else {
          _askDoubler = false;
        }
      } else {
        _takers[_card] = p;
        if (_card == _qDiamond && _diamonds[p] == 0) _diamonds[p] = null;
        if (_doubled[_card] && _doublers[_card] < 0) {
          _askDoubler = true;
        } else {
          _afterCard();
        }
      }
    });
  }

  void _selectCard(int c) {
    Sfx.tap();
    setState(() {
      _card = c;
      _askDoubler = false;
    });
  }

  void _toggleDouble() {
    if (_card < 0) return;
    Sfx.tap();
    setState(() {
      _doubled[_card] = !_doubled[_card];
      if (_doubled[_card]) {
        _askDoubler = true;
      } else {
        _doublers[_card] = -1;
        _askDoubler = false;
      }
    });
  }

  void _pick(int n) {
    final p = _active;
    if (p < 0) return;
    Sfx.tap();
    setState(() {
      final values = _step == 1 ? _diamonds : _tricks;
      values[p] = n;
      final missing = [for (var q = 0; q < 4; q++) if (values[q] == null) q];
      if (missing.length == 1) {
        final rest = 13 - values.fold<int>(0, (a, b) => a + (b ?? 0));
        if (rest >= 0) values[missing.first] = rest;
      }
      _active = _order.firstWhere((q) => values[q] == null, orElse: () => -1);
      // Diamonds done: on to the tricks.
      if (_active < 0 && _step == 1 && !_tricksDone) _enterStep(2);
    });
  }

  // ---------------------------------------------------------------- view ---

  String _cardName(BuildContext context, int c) => c == 0
      ? context.tr('kingHearts')
      : context.tr('queenOf', {'suit': context.tr(const ['spades', 'hearts', 'diamondsSuit', 'clubs'][c - 1])});

  @override
  Widget build(BuildContext context) {
    final players = widget.game.players;
    final hand = _hand;
    final scores = hand.scores();
    final error = _error();

    final bool done;
    final String prompt;
    if (_step == 0) {
      done = _card < 0;
      prompt = done
          ? context.tr(_cardsDone ? 'cardsReady' : 'tapACard')
          : context.tr(_askDoubler ? 'whoDoubled' : 'whoTook', {'card': _cardName(context, _card)});
    } else {
      done = _active < 0;
      prompt = done
          ? context.tr(_step == 1 ? 'diamondsReady' : 'tricksReady')
          : context.tr(_step == 1 ? 'diamondsOf' : 'tricksOf', {'name': players[_active]});
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          children: [
            Text(context.tr('complex')),
            Text(context.tr('kingdomOwner', {'n': widget.kingdom + 1, 'name': players[_owner]}),
                style: const TextStyle(fontSize: 12.5, color: Felt.muted, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: FeltBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
            children: [
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: _SegLabel(context.tr('cards')),
                    icon: _cardsDone ? const Icon(Icons.check_circle_rounded) : null,
                  ),
                  ButtonSegment(
                    value: 1,
                    label: _SegLabel(context.tr('diamonds')),
                    icon: _diamondsDone ? const Icon(Icons.check_circle_rounded) : null,
                  ),
                  ButtonSegment(
                    value: 2,
                    label: _SegLabel(context.tr('tricks')),
                    icon: _tricksDone ? const Icon(Icons.check_circle_rounded) : null,
                  ),
                ],
                selected: {_step},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _enterStep(s.first)),
              ),
              const SizedBox(height: 12),
              // The four players side by side.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var p = 0; p < 4; p++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _HandTile(
                          name: players[p],
                          seat: p,
                          active: _step > 0 && _active == p,
                          pickable: _step == 0 && _card >= 0,
                          big: _step == 0
                              ? signed(scores[p])
                              : ((_step == 1 ? _diamonds[p] : _tricks[p])?.toString() ?? '–'),
                          bigColor: _step == 0 ? scoreColor(scores[p]) : Felt.ivory,
                          score: _step == 0 ? null : scores[p],
                          cards: [for (var c = 0; c < 5; c++) if (_takers[c] == p) c],
                          doubled: [for (var c = 0; c < 5; c++) if (_doubled[c] && _doublers[c] == p) c],
                          onTap: () => _tapPlayer(p),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (done)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 6),
                      child: Icon(Icons.check_circle_rounded, color: Felt.win, size: 20),
                    ),
                  Expanded(
                    child: Text(prompt,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: done ? Felt.win : Felt.ivory)),
                  ),
                  if (_step == 1) RemainingPill(total: _diamonds.fold(0, (a, b) => a + (b ?? 0))),
                  if (_step == 2) RemainingPill(total: _tricks.fold(0, (a, b) => a + (b ?? 0))),
                ],
              ),
              const SizedBox(height: 14),
              if (_step == 0) ...[
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    children: [
                      for (var c = 0; c < 5; c++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: _CardSlot(
                              card: c,
                              active: _card == c,
                              taker: _takers[c] >= 0 ? players[_takers[c]] : null,
                              takerSeat: _takers[c],
                              doubled: _doubled[c],
                              onTap: () => _selectCard(c),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_card >= 0)
                  _DoubleButton(
                    on: _doubled[_card],
                    label: _doubled[_card]
                        ? (_doublers[_card] >= 0
                            ? context.tr('doubledByName', {'name': players[_doublers[_card]]})
                            : context.tr('doubledTapWho'))
                        : context.tr('doubleIt'),
                    onTap: _toggleDouble,
                  ),
                const SizedBox(height: 12),
                Text(context.tr('complexHint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Felt.muted, fontSize: 12.5, height: 1.5)),
              ] else if (_active >= 0)
                NumberPad(
                  selected: (_step == 1 ? _diamonds : _tricks)[_active],
                  allowed: (n) => _step == 1
                      ? _allowed(_diamonds, _active, n, _minDiamonds(_active))
                      : _allowed(_tricks, _active, n, _minTricks(_active)),
                  onPick: _pick,
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SaveBar(
        players: players,
        preview: scores,
        error: _cardsDone && _diamondsDone && _tricksDone ? error : null,
        label: context.tr('save'),
        onSave: error == null ? () => Navigator.pop(context, TrixRound.complex(widget.kingdom, hand)) : null,
      ),
    );
  }
}

class _HandTile extends StatelessWidget {
  final String name;
  final int seat;
  final bool active;
  final bool pickable;
  final String big;
  final Color bigColor;
  final int? score;
  final List<int> cards;
  final List<int> doubled;
  final VoidCallback onTap;

  const _HandTile({
    required this.name,
    required this.seat,
    required this.active,
    required this.pickable,
    required this.big,
    required this.bigColor,
    required this.score,
    required this.cards,
    required this.doubled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Felt.seats[seat];
    final r = BorderRadius.circular(16);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 112),
      decoration: BoxDecoration(
        borderRadius: r,
        color: active ? c.withValues(alpha: 0.2) : Colors.white.withValues(alpha: pickable ? 0.08 : 0.05),
        border: Border.all(
          color: active ? c : (pickable ? c.withValues(alpha: 0.55) : Colors.white12),
          width: active ? 2 : 1.2,
        ),
        boxShadow: active ? [BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 14)] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Column(
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: c)),
                FittedBox(
                  child: Text(big,
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, height: 1.25, color: bigColor)),
                ),
                if (score != null)
                  Text(signed(score!),
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: scoreColor(score!))),
                if (cards.isNotEmpty || doubled.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 2,
                      runSpacing: 2,
                      children: [
                        for (final k in cards) _MiniCard(card: k),
                        for (final k in doubled) _MiniCard(card: k, doubler: true),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tiny card face: taken (ivory) or doubled by this player (gold ×2).
class _MiniCard extends StatelessWidget {
  final int card;
  final bool doubler;
  const _MiniCard({required this.card, this.doubler = false});

  @override
  Widget build(BuildContext context) {
    final (rank, suit) = _cards[card];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: doubler ? Felt.gold.withValues(alpha: 0.2) : Felt.ivory,
        borderRadius: BorderRadius.circular(4),
        border: doubler ? Border.all(color: Felt.gold) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(doubler ? '×2 ' : rank,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  color: doubler ? Felt.gold : (suit.red ? const Color(0xFFC62828) : const Color(0xFF16201B)))),
          SuitIcon(suit, size: 9, color: doubler ? Felt.gold : null),
        ],
      ),
    );
  }
}

class _CardSlot extends StatelessWidget {
  final int card;
  final bool active;
  final String? taker;
  final int takerSeat;
  final bool doubled;
  final VoidCallback onTap;

  const _CardSlot({
    required this.card,
    required this.active,
    required this.taker,
    required this.takerSeat,
    required this.doubled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (rank, suit) = _cards[card];
    final ink = suit.red ? const Color(0xFFC62828) : const Color(0xFF16201B);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: Offset(0, active ? -0.06 : 0),
            child: AspectRatio(
              aspectRatio: 0.7,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Felt.ivory.withValues(alpha: taker == null && !active ? 0.7 : 1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: active ? Felt.gold : Colors.transparent, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: active ? Felt.gold.withValues(alpha: 0.55) : Colors.black.withValues(alpha: 0.3),
                      blurRadius: active ? 16 : 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 5,
                      top: 3,
                      child: Text(rank,
                          style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 16, height: 1.1)),
                    ),
                    Center(
                      child: Padding(padding: const EdgeInsets.only(top: 8), child: SuitIcon(suit, size: 26)),
                    ),
                    if (doubled)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Felt.goldDeep, borderRadius: BorderRadius.circular(6)),
                          child: const Text('×2',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5)),
                        ),
                      ),
                    if (taker != null)
                      const Positioned(
                        left: 3,
                        bottom: 3,
                        child: Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2E9E6A)),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(taker ?? '؟',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: taker == null ? Felt.muted : Felt.seats[takerSeat],
              )),
        ],
      ),
    );
  }
}

class _DoubleButton extends StatelessWidget {
  final bool on;
  final String label;
  final VoidCallback onTap;
  const _DoubleButton({required this.on, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(16);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: on ? Felt.goldGradient : null,
        color: on ? null : Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Felt.gold.withValues(alpha: on ? 1 : 0.4)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: on ? Felt.deep : Felt.gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('×2', style: TextStyle(fontWeight: FontWeight.w900, color: Felt.gold, fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, color: on ? Felt.deep : Felt.ivory)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A segment label that shrinks instead of wrapping.
class _SegLabel extends StatelessWidget {
  final String text;
  const _SegLabel(this.text);

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, softWrap: false));
}
