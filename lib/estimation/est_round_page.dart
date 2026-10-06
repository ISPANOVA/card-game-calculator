import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/i18n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'est_model.dart';

/// What the round page hands back: the bids only ([complete] false), or the
/// whole round.
class EstEntry {
  final EstRound round;
  final bool complete;
  const EstEntry(this.round, this.complete);
}

const trumpSymbols = {
  EstTrump.spades: '♠',
  EstTrump.hearts: '♥',
  EstTrump.diamonds: '♦',
  EstTrump.clubs: '♣',
  EstTrump.noTrump: 'NT',
};

/// Risk the last bidder takes on: one level for every trick the bids are
/// away from 13 beyond the first (13±2 risk, ±3 double, ±4 or more triple).
int riskFor(int totalBids) => ((totalBids - 13).abs() - 1).clamp(0, 3);

/// Entering a round the way it is played: pick who has the call and his
/// number, then the others in turn tap theirs on a 0–13 pad. Numbers the
/// rules forbid are locked. Then the tricks, the same way.
class EstRoundPage extends StatefulWidget {
  final EstGame game;

  /// Index of the round being edited; null for the next round.
  final int? index;
  final EstRound? initial;
  const EstRoundPage({super.key, required this.game, this.index, this.initial});

  @override
  State<EstRoundPage> createState() => _EstRoundPageState();
}

class _EstRoundPageState extends State<EstRoundPage> {
  late final EstRound? _init = widget.initial;
  late final List<int?> _bids = [for (var p = 0; p < 4; p++) _init?.bids[p]];
  late int _caller = _init?.caller ?? -1;
  late final List<bool> _dashCalls = List.of(_init?.dashCalls ?? const [false, false, false, false]);
  late EstTrump _trump = _init?.trump ?? EstTrump.none;

  /// Tricks are only known for a saved round (a draft has none yet).
  late final List<int?> _tricks = [for (var p = 0; p < 4; p++) widget.index != null ? _init?.tricks[p] : null];

  /// 0: bids, 1: tricks.
  late int _phase = _bidsDone ? 1 : 0;

  /// The player whose number the pad is entering (-1: none).
  late int _active = _phase == 0 ? (_caller >= 0 ? _nextBidder() : -1) : _nextTricks();

  EstRules get _rules => widget.game.rules;
  int get _roundIndex => widget.index ?? widget.game.rounds.length;

  /// Bidding order: the caller, then round the table.
  List<int> get _order => _caller < 0 ? const [0, 1, 2, 3] : [for (var i = 0; i < 4; i++) (_caller + i) % 4];

  bool get _bidsDone => _caller >= 0 && _bids.every((b) => b != null);
  int get _bidTotal => _bids.fold(0, (a, b) => a + (b ?? 0));
  int get _lastBidder => (_caller + 3) % 4;

  int _nextBidder() => _order.firstWhere((p) => _bids[p] == null, orElse: () => -1);
  int _nextTricks() => _order.firstWhere((p) => _tricks[p] == null, orElse: () => -1);

  int get _multiplier => EstGame(
        id: '',
        created: widget.game.created,
        players: widget.game.players,
        rules: _rules,
        rounds: widget.game.rounds.sublist(0, _roundIndex.clamp(0, widget.game.rounds.length)),
      ).nextMultiplier;

  EstRound _round() {
    final bids = [for (final b in _bids) b ?? 0];
    final total = bids.fold<int>(0, (a, b) => a + b);
    return EstRound(
      bids: bids,
      caller: _caller,
      withs: [for (var p = 0; p < 4; p++) p != _caller && _caller >= 0 && _bids[p] != null && bids[p] == bids[_caller]],
      dashCalls: [for (var p = 0; p < 4; p++) _dashCalls[p] && bids[p] == 0],
      risk: [for (var p = 0; p < 4; p++) _bidsDone && p == _lastBidder ? riskFor(total) : 0],
      trump: _trump,
      tricks: [for (final t in _tricks) t ?? 0],
    );
  }

  bool get _bidsValid => _bidsDone && _round().problems(_rules).where((e) => e != 'tricks').isEmpty;

  // ------------------------------------------------------------ the rules ---

  /// Whether [p] may bid [n].
  bool _bidAllowed(int p, int n) {
    final others = [for (var q = 0; q < 4; q++) if (q != p) _bids[q]];
    if (p == _caller) {
      if (n < _rules.minCall) return false;
      // Nobody may have bid more than the call.
      if (others.any((b) => b != null && b > n)) return false;
    } else {
      if (_caller < 0 || _bids[_caller] == null) return false;
      if (n > _bids[_caller]!) return false;
      if (n == 0) {
        final dashes = [for (var q = 0; q < 4; q++) if (q != p && _bids[q] == 0) q].length;
        if (dashes >= 2) return false;
      }
    }
    // The last number in may not bring the total to 13.
    if (others.every((b) => b != null) && others.fold<int>(0, (a, b) => a + b!) + n == 13) return false;
    return true;
  }

  bool _tricksAllowed(int p, int n) {
    final others = [for (var q = 0; q < 4; q++) if (q != p) _tricks[q]];
    final taken = others.fold<int>(0, (a, b) => a + (b ?? 0));
    if (taken + n > 13) return false;
    if (others.every((t) => t != null) && taken + n != 13) return false;
    return true;
  }

  // ------------------------------------------------------------- actions ---

  void _tapPlayer(int p) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_phase == 0 && _caller < 0) {
        _caller = p;
        _dashCalls[p] = false;
      }
      _active = p;
    });
  }

  void _pick(int n) {
    final p = _active;
    if (p < 0) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_phase == 0) {
        _bids[p] = n;
        if (n != 0) _dashCalls[p] = false;
        // A lower call can leave someone's bid above it: clear those.
        if (p == _caller) {
          for (var q = 0; q < 4; q++) {
            if (q != p && _bids[q] != null && _bids[q]! > n) _bids[q] = null;
          }
        }
        _active = _nextBidder();
      } else {
        _tricks[p] = n;
        final missing = [for (var q = 0; q < 4; q++) if (_tricks[q] == null) q];
        if (missing.length == 1) {
          final rest = 13 - _tricks.fold<int>(0, (a, b) => a + (b ?? 0));
          if (rest >= 0) _tricks[missing.first] = rest;
        }
        _active = _nextTricks();
      }
    });
  }

  void _dashCall() {
    final p = _active;
    if (p < 0 || p == _caller) return;
    HapticFeedback.selectionClick();
    setState(() {
      _dashCalls[p] = true;
      _bids[p] = 0;
      _active = _nextBidder();
    });
  }

  void _changeCaller() {
    setState(() {
      _caller = -1;
      for (var p = 0; p < 4; p++) {
        _bids[p] = null;
        _dashCalls[p] = false;
      }
      _active = -1;
    });
  }

  void _setPhase(int phase) {
    setState(() {
      _phase = phase;
      _active = phase == 0 ? (_caller >= 0 ? _nextBidder() : -1) : _nextTricks();
    });
  }

  // ---------------------------------------------------------------- view ---

  @override
  Widget build(BuildContext context) {
    final players = widget.game.players;
    final round = _round();
    final mult = _multiplier;
    final total = _bidTotal;
    final tricksDone = _tricks.every((t) => t != null);
    final allLost = tricksDone && round.allLost && _rules.saaydeh;
    final preview = !tricksDone
        ? null
        : (allLost ? const [0, 0, 0, 0] : [for (final v in round.baseScores(_rules)) v * mult]);
    final fast = widget.game.isFast(_roundIndex);
    final editingSaved = widget.index != null;
    final bidsValid = _bidsValid;

    String? prompt;
    if (_phase == 0) {
      if (_caller < 0) {
        prompt = context.tr('whoCalls');
      } else if (_active >= 0) {
        prompt = context.tr(_active == _caller ? 'callHowMany' : 'howMany', {'name': players[_active]});
      }
    } else if (_active >= 0) {
      prompt = context.tr('tricksHowMany', {'name': players[_active]});
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('roundN', {'n': _roundIndex + 1})),
        actions: [
          if (fast) const Padding(padding: EdgeInsetsDirectional.only(end: 6), child: Center(child: Pill('⚡'))),
          if (mult > 1)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 12),
              child: Center(child: Pill('×$mult', color: Felt.seats[1], filled: true)),
            ),
        ],
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
                      value: 0, label: Text(context.tr('bids')), icon: const Icon(Icons.record_voice_over_rounded)),
                  ButtonSegment(
                    value: 1,
                    label: Text(context.tr('tricks')),
                    icon: const Icon(Icons.back_hand_rounded),
                    enabled: bidsValid,
                  ),
                ],
                selected: {_phase},
                showSelectedIcon: false,
                onSelectionChanged: (s) => _setPhase(s.first),
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
                        child: _PlayerTile(
                          name: players[p],
                          seat: p,
                          active: _active == p,
                          bid: _bids[p],
                          tricks: _tricks[p],
                          showTricks: _phase == 1,
                          isCaller: _caller == p,
                          isWith: round.withs[p],
                          dashCall: round.dashCalls[p],
                          risk: round.risk[p],
                          onTap: () => _tapPlayer(p),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(prompt ?? context.tr(_phase == 0 ? 'bidsReady' : 'tricksReady'),
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16, color: prompt == null ? Felt.win : Felt.ivory)),
                  ),
                  if (_phase == 0 && _bidsDone)
                    Pill('${context.tr(total > 13 ? 'over' : 'under')} ${diffText(total - 13)}',
                        color: total > 13 ? Felt.seats[2] : Felt.seats[1], filled: true),
                  if (_phase == 1) RemainingPill(total: _tricks.fold(0, (a, b) => a + (b ?? 0))),
                ],
              ),
              const SizedBox(height: 10),
              if (_active >= 0)
                _NumberPad(
                  selected: _phase == 0 ? _bids[_active] : _tricks[_active],
                  allowed: (n) => _phase == 0 ? _bidAllowed(_active, n) : _tricksAllowed(_active, n),
                  onPick: _pick,
                ),
              if (_phase == 0 && _active >= 0 && _active != _caller && _bidAllowed(_active, 0)) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _dashCall,
                  icon: const Icon(Icons.remove_circle_rounded),
                  label: Text(context.tr('dashCall')),
                ),
              ],
              if (_phase == 0 && _caller >= 0) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(context.tr('trump'),
                        style: const TextStyle(color: Felt.muted, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final e in trumpSymbols.entries)
                            _TrumpChip(
                              symbol: e.value,
                              red: e.key == EstTrump.hearts || e.key == EstTrump.diamonds,
                              selected: _trump == e.key,
                              onTap: () => setState(() => _trump = _trump == e.key ? EstTrump.none : e.key),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: _changeCaller,
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(context.tr('changeCall')),
                  ),
                ),
              ],
              if (allLost)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Panel(
                    glow: Felt.seats[1],
                    child: Row(
                      children: [
                        Icon(Icons.all_inclusive_rounded, color: Felt.seats[1]),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(context.tr('saaydehNow', {'n': mult * _rules.saaydehMultiplier}),
                              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SaveBar(
        players: players,
        preview: _phase == 1 ? preview : null,
        label: context.tr(_phase == 0 ? 'nextTricks' : 'saveRound'),
        onSave: _phase == 0
            ? (bidsValid ? () => _setPhase(1) : null)
            : (tricksDone && round.problems(_rules).isEmpty
                ? () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context, EstEntry(round, true));
                  }
                : null),
        extra: editingSaved || !bidsValid
            ? null
            : OutlinedButton(
                onPressed: () => Navigator.pop(context, EstEntry(round, false)),
                child: Text(context.tr('saveBids')),
              ),
      ),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  final String name;
  final int seat;
  final bool active;
  final int? bid;
  final int? tricks;
  final bool showTricks;
  final bool isCaller;
  final bool isWith;
  final bool dashCall;
  final int risk;
  final VoidCallback onTap;

  const _PlayerTile({
    required this.name,
    required this.seat,
    required this.active,
    required this.bid,
    required this.tricks,
    required this.showTricks,
    required this.isCaller,
    required this.isWith,
    required this.dashCall,
    required this.risk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Felt.seats[seat];
    final won = showTricks && tricks != null && bid != null ? tricks == bid : null;
    final badges = <(String, Color)>[
      if (isCaller) (context.tr('call'), Felt.gold),
      if (isWith) (context.tr('with'), Felt.gold),
      if (dashCall) (context.tr('dashCall'), Felt.seats[1]) else if (bid == 0) (context.tr('dash'), Felt.seats[1]),
      if (risk > 0) (risk == 1 ? context.tr('risk') : '${context.tr('risk')} ×$risk', Felt.seats[2]),
    ];
    final r = BorderRadius.circular(16);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      constraints: const BoxConstraints(minHeight: 124),
      decoration: BoxDecoration(
        borderRadius: r,
        color: active ? c.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: active ? c : (isCaller ? Felt.gold.withValues(alpha: 0.6) : Colors.white12),
          width: active ? 2 : 1,
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
                if (showTricks) ...[
                  Text(tricks == null ? '–' : '$tricks',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                          color: won == null ? Felt.ivory : (won ? Felt.win : Felt.lose))),
                  Text(context.tr('bidN', {'n': bid ?? '–'}),
                      style: const TextStyle(fontSize: 11.5, color: Felt.muted, fontWeight: FontWeight.w700)),
                ] else
                  Text(bid == null ? '–' : '$bid',
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900, height: 1.2, color: isCaller ? Felt.gold : Felt.ivory)),
                for (final b in badges)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: b.$2.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(b.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: b.$2)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 0–13 in two rows of seven; numbers the rules forbid are locked.
class _NumberPad extends StatelessWidget {
  final int? selected;
  final bool Function(int) allowed;
  final ValueChanged<int> onPick;
  const _NumberPad({required this.selected, required this.allowed, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(builder: (context, c) {
        const gap = 6.0;
        final size = ((c.maxWidth - gap * 6) / 7).clamp(30.0, 64.0);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var n = 0; n <= 13; n++)
              _NumKey(n: n, size: size, selected: selected == n, enabled: allowed(n), onTap: () => onPick(n)),
          ],
        );
      }),
    );
  }
}

class _NumKey extends StatelessWidget {
  final int n;
  final double size;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  const _NumKey({required this.n, required this.size, required this.selected, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(14);
    return SizedBox(
      width: size,
      height: size * 1.05,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: r,
          gradient: selected ? Felt.goldGradient : null,
          color: selected ? null : Colors.white.withValues(alpha: enabled ? 0.08 : 0.02),
          border: Border.all(color: enabled || selected ? Felt.gold.withValues(alpha: selected ? 1 : 0.3) : Colors.white10),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: r,
            onTap: enabled ? onTap : null,
            child: Center(
              child: enabled || selected
                  ? Text('$n',
                      style: TextStyle(
                          fontSize: size * 0.42, fontWeight: FontWeight.w900, color: selected ? Felt.deep : Felt.ivory))
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Text('$n',
                            style: TextStyle(
                                fontSize: size * 0.38, fontWeight: FontWeight.w800, color: Felt.muted.withValues(alpha: 0.25))),
                        Icon(Icons.lock_rounded, size: size * 0.3, color: Felt.muted.withValues(alpha: 0.45)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrumpChip extends StatelessWidget {
  final String symbol;
  final bool red;
  final bool selected;
  final VoidCallback onTap;
  const _TrumpChip({required this.symbol, required this.red, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Felt.gold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Felt.gold.withValues(alpha: selected ? 1 : 0.3)),
        ),
        child: Text(symbol,
            style: TextStyle(
              fontSize: symbol == 'NT' ? 13 : 19,
              fontWeight: FontWeight.w900,
              color: selected ? Felt.deep : (red ? const Color(0xFFFF8A80) : Felt.ivory),
            )),
      ),
    );
  }
}
