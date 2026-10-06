/// Trix Complex: four kingdoms; in each, the kingdom's owner plays two
/// contracts — Trix and Complex (all the penalties of Ltoosh at once).
///
/// Complex penalties: King of hearts −75, each Queen −25, each Diamond −10,
/// each trick −15 (−500 in all). A doubled King/Queen costs its taker twice
/// as much, and the player who doubled it gains its normal value (unless he
/// took it himself). Trix: the players finish 1st..4th for +200, +150, +100,
/// +50 (+500 in all). So every kingdom adds up to zero.
library;

enum TrixContract { trix, complex }

class TrixScoring {
  static const king = 75;
  static const queen = 25;
  static const diamond = 10;
  static const trick = 15;
  static const trixPlaces = [200, 150, 100, 50];
}

/// What happened in one Complex hand.
class ComplexHand {
  /// Who took the King of hearts.
  final int kingTaker;

  /// Who doubled the King (-1: not doubled).
  final int kingDoubledBy;

  /// Who took each Queen (♠ ♥ ♦ ♣).
  final List<int> queenTakers;

  /// Who doubled each Queen (-1: not doubled).
  final List<int> queenDoubledBy;

  /// Diamonds taken by each player (13 in all).
  final List<int> diamonds;

  /// Tricks taken by each player (13 in all).
  final List<int> tricks;

  const ComplexHand({
    required this.kingTaker,
    this.kingDoubledBy = -1,
    required this.queenTakers,
    this.queenDoubledBy = const [-1, -1, -1, -1],
    required this.diamonds,
    required this.tricks,
  });

  /// Problems with the hand as entered (empty = valid).
  List<String> problems() {
    final out = <String>[];
    if (kingTaker < 0 || kingTaker > 3) out.add('king');
    if (queenTakers.length != 4 || queenTakers.any((t) => t < 0 || t > 3)) out.add('queens');
    if (diamonds.fold<int>(0, (a, b) => a + b) != 13) out.add('diamonds');
    if (tricks.fold<int>(0, (a, b) => a + b) != 13) out.add('tricks');
    return out;
  }

  List<int> scores() {
    final s = [0, 0, 0, 0];
    for (var p = 0; p < 4; p++) {
      s[p] -= diamonds[p] * TrixScoring.diamond;
      s[p] -= tricks[p] * TrixScoring.trick;
    }
    void card(int taker, int doubledBy, int value) {
      if (taker < 0) return;
      if (doubledBy >= 0) {
        s[taker] -= value * 2;
        if (doubledBy != taker) s[doubledBy] += value;
      } else {
        s[taker] -= value;
      }
    }

    card(kingTaker, kingDoubledBy, TrixScoring.king);
    for (var q = 0; q < queenTakers.length; q++) {
      card(queenTakers[q], q < queenDoubledBy.length ? queenDoubledBy[q] : -1, TrixScoring.queen);
    }
    return s;
  }

  Map<String, dynamic> toJson() => {
        'kingTaker': kingTaker,
        'kingDoubledBy': kingDoubledBy,
        'queenTakers': queenTakers,
        'queenDoubledBy': queenDoubledBy,
        'diamonds': diamonds,
        'tricks': tricks,
      };

  factory ComplexHand.fromJson(Map<String, dynamic> j) => ComplexHand(
        kingTaker: j['kingTaker'] as int,
        kingDoubledBy: (j['kingDoubledBy'] ?? -1) as int,
        queenTakers: List<int>.from(j['queenTakers'] as List),
        queenDoubledBy: List<int>.from((j['queenDoubledBy'] ?? const [-1, -1, -1, -1]) as List),
        diamonds: List<int>.from(j['diamonds'] as List),
        tricks: List<int>.from(j['tricks'] as List),
      );
}

/// The finishing order of a Trix hand: player indices, first out first.
List<int> trixScores(List<int> order) {
  final s = [0, 0, 0, 0];
  for (var i = 0; i < order.length && i < 4; i++) {
    s[order[i]] += TrixScoring.trixPlaces[i];
  }
  return s;
}

class TrixRound {
  final int kingdom;
  final TrixContract contract;
  final ComplexHand? complex;
  final List<int>? trixOrder;

  const TrixRound.complex(this.kingdom, ComplexHand hand)
      : contract = TrixContract.complex,
        complex = hand,
        trixOrder = null;

  const TrixRound.trix(this.kingdom, List<int> order)
      : contract = TrixContract.trix,
        complex = null,
        trixOrder = order;

  List<int> get scores => contract == TrixContract.complex ? complex!.scores() : trixScores(trixOrder!);

  Map<String, dynamic> toJson() => {
        'kingdom': kingdom,
        'contract': contract.name,
        if (complex != null) 'complex': complex!.toJson(),
        if (trixOrder != null) 'trixOrder': trixOrder,
      };

  factory TrixRound.fromJson(Map<String, dynamic> j) {
    final kingdom = j['kingdom'] as int;
    return j['contract'] == 'complex'
        ? TrixRound.complex(kingdom, ComplexHand.fromJson(Map<String, dynamic>.from(j['complex'] as Map)))
        : TrixRound.trix(kingdom, List<int>.from(j['trixOrder'] as List));
  }
}

class TrixGame {
  final String id;
  final DateTime created;
  final List<String> players;

  /// Partners: players 1 & 3 against 2 & 4 (sitting opposite each other).
  final bool partners;

  /// Owner of the first kingdom; the kingdoms go round the table from there.
  final int firstKing;
  final List<TrixRound> rounds;

  TrixGame({
    required this.id,
    required this.created,
    required this.players,
    required this.partners,
    this.firstKing = 0,
    List<TrixRound>? rounds,
  }) : rounds = rounds ?? [];

  static const kingdoms = 4;

  int ownerOf(int kingdom) => (firstKing + kingdom) % 4;

  bool played(int kingdom, TrixContract c) => rounds.any((r) => r.kingdom == kingdom && r.contract == c);

  /// The kingdom being played (4 when the game is over).
  int get currentKingdom {
    for (var k = 0; k < kingdoms; k++) {
      if (!played(k, TrixContract.trix) || !played(k, TrixContract.complex)) return k;
    }
    return kingdoms;
  }

  bool get finished => currentKingdom >= kingdoms;

  List<int> get totals {
    final t = [0, 0, 0, 0];
    for (final r in rounds) {
      final s = r.scores;
      for (var p = 0; p < 4; p++) {
        t[p] += s[p];
      }
    }
    return t;
  }

  /// Team totals in partner games: [players 1+3, players 2+4].
  List<int> get teamTotals {
    final t = totals;
    return [t[0] + t[2], t[1] + t[3]];
  }

  Map<String, dynamic> toJson() => {
        'type': 'trix',
        'id': id,
        'created': created.toIso8601String(),
        'players': players,
        'partners': partners,
        'firstKing': firstKing,
        'rounds': [for (final r in rounds) r.toJson()],
      };

  factory TrixGame.fromJson(Map<String, dynamic> j) => TrixGame(
        id: j['id'] as String,
        created: DateTime.parse(j['created'] as String),
        players: List<String>.from(j['players'] as List),
        partners: j['partners'] == true,
        firstKing: (j['firstKing'] ?? 0) as int,
        rounds: [
          for (final r in (j['rounds'] as List)) TrixRound.fromJson(Map<String, dynamic>.from(r as Map)),
        ],
      );
}
