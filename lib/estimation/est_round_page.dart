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
  late final List<int> _bids = List.of(_init?.bids ?? const [0, 0, 0, 0]);
  late int _caller = _init?.caller ?? -1;
  late bool _callerManual = (_init?.caller ?? -1) >= 0;
  late final List<bool> _withs = List.of(_init?.withs ?? const [false, false, false, false]);
  late final List<bool> _dashCalls = List.of(_init?.dashCalls ?? const [false, false, false, false]);
  late final List<int> _risk = List.of(_init?.risk ?? const [0, 0, 0, 0]);
  late EstTrump _trump = _init?.trump ?? EstTrump.none;
  late final List<int> _tricks = List.of(_init?.tricks ?? const [0, 0, 0, 0]);

  int get _roundIndex => widget.index ?? widget.game.rounds.length;
  bool get _fast => widget.game.isFast(_roundIndex);
  EstRules get _rules => widget.game.rules;

  EstRound get _round => EstRound(
        bids: List.of(_bids),
        caller: _caller,
        withs: [for (var p = 0; p < 4; p++) _withs[p] && _caller >= 0 && p != _caller && _bids[p] == _bids[_caller]],
        dashCalls: [for (var p = 0; p < 4; p++) _dashCalls[p] && _bids[p] == 0],
        risk: List.of(_risk),
        trump: _trump,
        tricks: List.of(_tricks),
      );

  /// The multiplier this round is played at (Sa'aydeh from the rounds before).
  int get _multiplier {
    final before = EstGame(
      id: '',
      created: widget.game.created,
      players: widget.game.players,
      rules: _rules,
      rounds: widget.game.rounds.sublist(0, _roundIndex.clamp(0, widget.game.rounds.length)),
    );
    return before.nextMultiplier;
  }

  void _setBid(int p, int v) {
    setState(() {
      _bids[p] = v;
      if (!_callerManual) {
        final top = _bids.reduce((a, b) => a > b ? a : b);
        final tops = [for (var i = 0; i < 4; i++) if (_bids[i] == top) i];
        _caller = (tops.length == 1 && top >= _rules.minCall) ? tops.first : -1;
      }
    });
  }

  String? _bidError(List<String> problems) {
    if (!_fast && _caller < 0) return context.tr('e_noCaller');
    for (final code in ['bids13', 'minCall', 'callerMax', 'with', 'dash', 'bids']) {
      if (problems.contains(code)) return context.tr('e_$code', {'n': _rules.minCall});
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.game.players;
    final round = _round;
    final problems = round.problems(_rules);
    final bidError = _bidError(problems);
    final trickTotal = _tricks.fold<int>(0, (a, b) => a + b);
    final error = bidError ?? (problems.contains('tricks') ? context.tr('errTricks', {'n': trickTotal}) : null);
    final mult = _multiplier;
    final allLost = trickTotal == 13 && round.allLost && _rules.saaydeh;
    final preview = allLost ? const [0, 0, 0, 0] : [for (final v in round.baseScores(_rules)) v * mult];
    final total = round.totalBids;
    final editingSaved = widget.index != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('roundN', {'n': _roundIndex + 1})),
        actions: [
          if (_fast) const Padding(padding: EdgeInsetsDirectional.only(end: 6), child: Center(child: Pill('⚡'))),
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
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
            children: [
              SectionTitle(
                context.tr('bids'),
                icon: Icons.record_voice_over_rounded,
                trailing: total == 0
                    ? null
                    : Pill(
                        total == 13
                            ? '= 13'
                            : (total > 13 ? '${context.tr('over')} +${total - 13}' : '${context.tr('under')} −${13 - total}'),
                        color: total == 13 ? Felt.lose : (total > 13 ? Felt.seats[2] : Felt.seats[1]),
                        filled: true,
                      ),
              ),
              for (var p = 0; p < 4; p++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BidCard(
                    name: players[p],
                    seat: p,
                    bid: _bids[p],
                    isCaller: _caller == p,
                    canWith: _caller >= 0 && _caller != p && _bids[p] == _bids[_caller],
                    isWith: _withs[p],
                    dashCall: _dashCalls[p],
                    risk: _risk[p],
                    onBid: (v) => _setBid(p, v),
                    onCaller: () => setState(() {
                      _callerManual = true;
                      _caller = _caller == p ? -1 : p;
                    }),
                    onWith: () => setState(() => _withs[p] = !_withs[p]),
                    onDash: () => setState(() => _dashCalls[p] = !_dashCalls[p]),
                    onRisk: () => setState(() => _risk[p] = (_risk[p] + 1) % 4),
                  ),
                ),
              SectionTitle(context.tr('trump'), icon: Icons.style_rounded),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in trumpSymbols.entries)
                    ChoiceChip(
                      label: Text(e.value,
                          style: TextStyle(
                            fontSize: e.key == EstTrump.noTrump ? 14 : 20,
                            fontWeight: FontWeight.w900,
                            color: _trump == e.key
                                ? Felt.deep
                                : (e.key == EstTrump.hearts || e.key == EstTrump.diamonds
                                    ? const Color(0xFFFF8A80)
                                    : Felt.ivory),
                          )),
                      selected: _trump == e.key,
                      showCheckmark: false,
                      selectedColor: Felt.gold,
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      side: BorderSide(color: Felt.gold.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (_) => setState(() => _trump = _trump == e.key ? EstTrump.none : e.key),
                    ),
                ],
              ),
              SectionTitle(
                context.tr('tricksTaken'),
                icon: Icons.back_hand_rounded,
                trailing: RemainingPill(total: trickTotal),
              ),
              Panel(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                child: Column(
                  children: [
                    for (var p = 0; p < 4; p++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Expanded(child: SeatName(players[p], p)),
                            Text(context.tr('bidN', {'n': _bids[p]}),
                                style: const TextStyle(color: Felt.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 22,
                              child: trickTotal == 13
                                  ? Icon(
                                      _tricks[p] == _bids[p] ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 18,
                                      color: _tricks[p] == _bids[p] ? Felt.win : Felt.lose,
                                    )
                                  : null,
                            ),
                            NumberStepper(
                              value: _tricks[p],
                              compact: true,
                              onChanged: (v) => setState(() => _tricks[p] = v),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
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
        preview: trickTotal == 13 ? preview : null,
        error: error,
        label: context.tr('saveRound'),
        onSave: error == null
            ? () {
                HapticFeedback.mediumImpact();
                Navigator.pop(context, EstEntry(round, true));
              }
            : null,
        extra: editingSaved
            ? null
            : OutlinedButton(
                onPressed: bidError == null ? () => Navigator.pop(context, EstEntry(round, false)) : null,
                child: Text(context.tr('saveBids')),
              ),
      ),
    );
  }
}

class _BidCard extends StatelessWidget {
  final String name;
  final int seat;
  final int bid;
  final bool isCaller;
  final bool canWith;
  final bool isWith;
  final bool dashCall;
  final int risk;
  final ValueChanged<int> onBid;
  final VoidCallback onCaller;
  final VoidCallback onWith;
  final VoidCallback onDash;
  final VoidCallback onRisk;

  const _BidCard({
    required this.name,
    required this.seat,
    required this.bid,
    required this.isCaller,
    required this.canWith,
    required this.isWith,
    required this.dashCall,
    required this.risk,
    required this.onBid,
    required this.onCaller,
    required this.onWith,
    required this.onDash,
    required this.onRisk,
  });

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      glow: isCaller ? Felt.gold : null,
      radius: 18,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: SeatName(name, seat, size: 16)),
              if (bid == 0) ...[Pill(context.tr('dash'), color: Felt.seats[1]), const SizedBox(width: 8)],
              NumberStepper(value: bid, onChanged: onBid, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _Toggle(label: context.tr('call'), icon: Icons.campaign_rounded, on: isCaller, onTap: onCaller),
              if (canWith) _Toggle(label: context.tr('with'), icon: Icons.handshake_rounded, on: isWith, onTap: onWith),
              if (bid == 0)
                _Toggle(label: context.tr('dashCall'), icon: Icons.remove_circle_rounded, on: dashCall, onTap: onDash),
              _Toggle(
                label: risk == 0 ? context.tr('risk') : '${context.tr('risk')} ×$risk',
                icon: Icons.local_fire_department_rounded,
                on: risk > 0,
                onTap: onRisk,
                color: Felt.seats[2],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;
  final Color color;
  const _Toggle({required this.label, required this.icon, required this.on, required this.onTap, this.color = Felt.gold});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(12);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: r,
        color: on ? color : Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: on ? 1 : 0.3)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: on ? Felt.deep : color),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: on ? Felt.deep : Felt.ivory)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
