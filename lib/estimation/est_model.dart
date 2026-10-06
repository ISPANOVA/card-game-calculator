/// Estimation (Egyptian rules, as played on Jawaker), with every value
/// adjustable in [EstRules].
///
/// Each round every player bids how many of the 13 tricks he will take; the
/// bids may not add up to 13, so a round is "over" (more than 13) or "under".
/// The highest bidder is the caller (he names trump); a player who bids the
/// same as the caller may say "with". A bid of zero is a dash; a dash said
/// before bidding is a dash call. Players who hit their bid exactly win,
/// the others lose. If everybody loses (Sa'aydeh) the round counts nothing
/// and the next round counts double.
library;

class EstRules {
  /// Total rounds in a game, of which the last [fastRounds] are fast.
  final int rounds;
  final int fastRounds;

  /// A winner scores [winBase] + the tricks he took.
  final int winBase;
  final int callBonus;
  final int withBonus;

  /// Per risk level, added on a win and taken on a loss.
  final int riskBonus;
  final int onlyWinnerBonus;
  final int onlyLoserPenalty;
  final int callPenalty;
  final int withPenalty;

  /// A successful dash in an over / under round (a failed dash call loses
  /// the same).
  final int dashOver;
  final int dashUnder;

  /// The smallest bid that can win the call.
  final int minCall;
  final bool saaydeh;
  final int saaydehMultiplier;

  const EstRules({
    this.rounds = 18,
    this.fastRounds = 5,
    this.winBase = 10,
    this.callBonus = 10,
    this.withBonus = 10,
    this.riskBonus = 10,
    this.onlyWinnerBonus = 10,
    this.onlyLoserPenalty = 10,
    this.callPenalty = 10,
    this.withPenalty = 10,
    this.dashOver = 25,
    this.dashUnder = 33,
    this.minCall = 4,
    this.saaydeh = true,
    this.saaydehMultiplier = 2,
  });

  static const defaults = EstRules();

  int get normalRounds => rounds - fastRounds;

  /// Editable integer fields, by key (for the rules page).
  static const keys = [
    'rounds',
    'fastRounds',
    'winBase',
    'callBonus',
    'withBonus',
    'riskBonus',
    'onlyWinnerBonus',
    'onlyLoserPenalty',
    'callPenalty',
    'withPenalty',
    'dashOver',
    'dashUnder',
    'minCall',
    'saaydehMultiplier',
  ];

  Map<String, dynamic> toJson() => {
        'rounds': rounds,
        'fastRounds': fastRounds,
        'winBase': winBase,
        'callBonus': callBonus,
        'withBonus': withBonus,
        'riskBonus': riskBonus,
        'onlyWinnerBonus': onlyWinnerBonus,
        'onlyLoserPenalty': onlyLoserPenalty,
        'callPenalty': callPenalty,
        'withPenalty': withPenalty,
        'dashOver': dashOver,
        'dashUnder': dashUnder,
        'minCall': minCall,
        'saaydeh': saaydeh,
        'saaydehMultiplier': saaydehMultiplier,
      };

  factory EstRules.fromJson(Map<String, dynamic>? j) {
    if (j == null) return defaults;
    int v(String k, int d) => (j[k] as num?)?.toInt() ?? d;
    const d = defaults;
    return EstRules(
      rounds: v('rounds', d.rounds),
      fastRounds: v('fastRounds', d.fastRounds),
      winBase: v('winBase', d.winBase),
      callBonus: v('callBonus', d.callBonus),
      withBonus: v('withBonus', d.withBonus),
      riskBonus: v('riskBonus', d.riskBonus),
      onlyWinnerBonus: v('onlyWinnerBonus', d.onlyWinnerBonus),
      onlyLoserPenalty: v('onlyLoserPenalty', d.onlyLoserPenalty),
      callPenalty: v('callPenalty', d.callPenalty),
      withPenalty: v('withPenalty', d.withPenalty),
      dashOver: v('dashOver', d.dashOver),
      dashUnder: v('dashUnder', d.dashUnder),
      minCall: v('minCall', d.minCall),
      saaydeh: j['saaydeh'] is bool ? j['saaydeh'] as bool : d.saaydeh,
      saaydehMultiplier: v('saaydehMultiplier', d.saaydehMultiplier),
    );
  }

  /// A copy with the integer field [key] set to [value].
  EstRules withValue(String key, int value) {
    final m = toJson()..[key] = value;
    return EstRules.fromJson(m);
  }

  EstRules withSaaydeh(bool on) => EstRules.fromJson(toJson()..['saaydeh'] = on);
}

/// Trump suit the caller named (for the record only).
enum EstTrump { none, spades, hearts, diamonds, clubs, noTrump }

class EstRound {
  final List<int> bids;

  /// The player who won the call (-1: none, e.g. a fast round).
  final int caller;

  /// Players who said "with" (bid the same as the caller).
  final List<bool> withs;

  /// Players who called dash before the bidding.
  final List<bool> dashCalls;

  /// Risk level 0–3 per player.
  final List<int> risk;
  final EstTrump trump;

  /// Tricks each player took (13 in all).
  final List<int> tricks;

  const EstRound({
    required this.bids,
    this.caller = -1,
    this.withs = const [false, false, false, false],
    this.dashCalls = const [false, false, false, false],
    this.risk = const [0, 0, 0, 0],
    this.trump = EstTrump.none,
    required this.tricks,
  });

  int get totalBids => bids.fold(0, (a, b) => a + b);
  bool get over => totalBids > 13;
  int get diff => totalBids - 13;

  bool won(int p) => tricks[p] == bids[p];
  int get winners => [for (var p = 0; p < 4; p++) won(p)].where((w) => w).length;
  bool get allLost => winners == 0;

  /// Problems with the round as entered (empty = valid).
  List<String> problems(EstRules rules) {
    final out = <String>[];
    if (bids.length != 4 || tricks.length != 4) return ['size'];
    if (bids.any((b) => b < 0 || b > 13)) out.add('bids');
    if (totalBids == 13) out.add('bids13');
    if (tricks.any((t) => t < 0 || t > 13) || tricks.fold<int>(0, (a, b) => a + b) != 13) out.add('tricks');
    if (caller >= 0) {
      if (bids[caller] < rules.minCall) out.add('minCall');
      if (bids.asMap().entries.any((e) => e.key != caller && e.value > bids[caller])) out.add('callerMax');
    }
    for (var p = 0; p < 4; p++) {
      if (withs[p] && (caller < 0 || p == caller || bids[p] != bids[caller])) out.add('with');
      if (dashCalls[p] && bids[p] != 0) out.add('dash');
    }
    return out.toSet().toList();
  }

  /// Scores before any Sa'aydeh multiplier.
  List<int> baseScores(EstRules r) {
    final s = [0, 0, 0, 0];
    final w = winners;
    final dash = over ? r.dashOver : r.dashUnder;
    for (var p = 0; p < 4; p++) {
      final isCaller = p == caller;
      final isWith = withs[p] && !isCaller;
      final lvl = risk[p];
      if (bids[p] == 0) {
        if (won(p)) {
          s[p] = dash;
        } else {
          s[p] = dashCalls[p] ? -dash : -(tricks[p]);
        }
        if (won(p) && w == 1) s[p] += r.onlyWinnerBonus;
        if (!won(p) && w == 3) s[p] -= r.onlyLoserPenalty;
        continue;
      }
      if (won(p)) {
        var v = r.winBase + tricks[p];
        if (isCaller) v += r.callBonus;
        if (isWith) v += r.withBonus;
        v += r.riskBonus * lvl;
        if (w == 1) v += r.onlyWinnerBonus;
        s[p] = v;
      } else {
        var v = -(tricks[p] - bids[p]).abs();
        if (isCaller) v -= r.callPenalty;
        if (isWith) v -= r.withPenalty;
        v -= r.riskBonus * lvl;
        if (w == 3) v -= r.onlyLoserPenalty;
        s[p] = v;
      }
    }
    return s;
  }

  Map<String, dynamic> toJson() => {
        'bids': bids,
        'caller': caller,
        'withs': withs,
        'dashCalls': dashCalls,
        'risk': risk,
        'trump': trump.name,
        'tricks': tricks,
      };

  factory EstRound.fromJson(Map<String, dynamic> j) => EstRound(
        bids: List<int>.from(j['bids'] as List),
        caller: (j['caller'] ?? -1) as int,
        withs: List<bool>.from((j['withs'] ?? const [false, false, false, false]) as List),
        dashCalls: List<bool>.from((j['dashCalls'] ?? const [false, false, false, false]) as List),
        risk: List<int>.from((j['risk'] ?? const [0, 0, 0, 0]) as List),
        trump: EstTrump.values.firstWhere((t) => t.name == j['trump'], orElse: () => EstTrump.none),
        tricks: List<int>.from(j['tricks'] as List),
      );
}

/// A round's result once Sa'aydeh is applied.
class EstRoundResult {
  final List<int> scores;
  final int multiplier;
  final bool saaydeh;
  const EstRoundResult(this.scores, this.multiplier, this.saaydeh);
}

class EstGame {
  final String id;
  final DateTime created;
  final List<String> players;
  final EstRules rules;
  final List<EstRound> rounds;

  /// Bids of the round being played, saved before its tricks are known.
  EstRound? draft;

  EstGame({
    required this.id,
    required this.created,
    required this.players,
    this.rules = EstRules.defaults,
    List<EstRound>? rounds,
    this.draft,
  }) : rounds = rounds ?? [];

  bool isFast(int roundIndex) => roundIndex >= rules.normalRounds;
  bool get finished => rounds.length >= rules.rounds;

  /// The multiplier the next round will be played at.
  int get nextMultiplier => _walk().$2;

  List<EstRoundResult> get results => _walk().$1;

  (List<EstRoundResult>, int) _walk() {
    final out = <EstRoundResult>[];
    var mult = 1;
    for (final r in rounds) {
      if (rules.saaydeh && r.allLost) {
        out.add(EstRoundResult(const [0, 0, 0, 0], mult, true));
        mult *= rules.saaydehMultiplier;
      } else {
        out.add(EstRoundResult([for (final v in r.baseScores(rules)) v * mult], mult, false));
        mult = 1;
      }
    }
    return (out, mult);
  }

  List<int> get totals {
    final t = [0, 0, 0, 0];
    for (final r in results) {
      for (var p = 0; p < 4; p++) {
        t[p] += r.scores[p];
      }
    }
    return t;
  }

  Map<String, dynamic> toJson() => {
        'type': 'estimation',
        'id': id,
        'created': created.toIso8601String(),
        'players': players,
        'rules': rules.toJson(),
        'rounds': [for (final r in rounds) r.toJson()],
        if (draft != null) 'draft': draft!.toJson(),
      };

  factory EstGame.fromJson(Map<String, dynamic> j) => EstGame(
        id: j['id'] as String,
        created: DateTime.parse(j['created'] as String),
        players: List<String>.from(j['players'] as List),
        rules: EstRules.fromJson(j['rules'] == null ? null : Map<String, dynamic>.from(j['rules'] as Map)),
        rounds: [
          for (final r in (j['rounds'] as List)) EstRound.fromJson(Map<String, dynamic>.from(r as Map)),
        ],
        draft: j['draft'] == null ? null : EstRound.fromJson(Map<String, dynamic>.from(j['draft'] as Map)),
      );
}
