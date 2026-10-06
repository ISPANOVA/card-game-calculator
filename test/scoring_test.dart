import 'package:card_game_calculator/estimation/est_model.dart';
import 'package:card_game_calculator/trix/trix_model.dart';
import 'package:flutter_test/flutter_test.dart';

int sum(List<int> l) => l.fold(0, (a, b) => a + b);

void main() {
  group('Complex', () {
    test('plain hand adds up to -500', () {
      const h = ComplexHand(
        kingTaker: 0,
        queenTakers: [1, 2, 3, 0],
        diamonds: [4, 3, 3, 3],
        tricks: [4, 3, 3, 3],
      );
      expect(h.problems(), isEmpty);
      final s = h.scores();
      expect(sum(s), -500);
      expect(s[0], -40 - 60 - 75 - 25);
    });

    test('doubled king: taker -150, doubler +75', () {
      const h = ComplexHand(
        kingTaker: 1,
        kingDoubledBy: 2,
        queenTakers: [0, 0, 0, 0],
        diamonds: [13, 0, 0, 0],
        tricks: [13, 0, 0, 0],
      );
      final s = h.scores();
      expect(s[1], -150);
      expect(s[2], 75);
    });

    test('doubling your own card only costs you', () {
      const h = ComplexHand(
        kingTaker: 3,
        kingDoubledBy: 3,
        queenTakers: [0, 0, 0, 0],
        diamonds: [13, 0, 0, 0],
        tricks: [13, 0, 0, 0],
      );
      expect(h.scores()[3], -150);
    });

    test('bad sums are reported', () {
      const h = ComplexHand(kingTaker: 0, queenTakers: [0, 0, 0, 0], diamonds: [1, 1, 1, 1], tricks: [13, 0, 0, 0]);
      expect(h.problems(), contains('diamonds'));
    });
  });

  group('Trix', () {
    test('places 200/150/100/50', () {
      expect(trixScores([2, 0, 3, 1]), [150, 50, 200, 100]);
    });

    test('game flow and totals', () {
      final g = TrixGame(id: 'x', created: DateTime(2026), players: ['a', 'b', 'c', 'd'], partners: true, firstKing: 1);
      expect(g.ownerOf(0), 1);
      expect(g.ownerOf(3), 0);
      for (var k = 0; k < 4; k++) {
        g.rounds.add(TrixRound.trix(k, [0, 1, 2, 3]));
        expect(g.finished, false);
        g.rounds.add(TrixRound.complex(
            k, const ComplexHand(kingTaker: 1, queenTakers: [1, 1, 1, 1], diamonds: [0, 13, 0, 0], tricks: [0, 13, 0, 0])));
      }
      expect(g.finished, true);
      expect(g.totals, [800, 600 - 2000, 400, 200]);
      expect(g.teamTotals, [1200, -1200]);
      final back = TrixGame.fromJson(g.toJson());
      expect(back.totals, g.totals);
    });
  });

  group('Estimation', () {
    const r = EstRules.defaults;

    test('caller and with win', () {
      const round = EstRound(
        bids: [5, 5, 2, 0],
        caller: 0,
        withs: [false, true, false, false],
        tricks: [5, 5, 3, 0],
      );
      expect(round.problems(r), isEmpty);
      expect(round.over, false);
      final s = round.baseScores(r);
      expect(s[0], 10 + 5 + 10);
      expect(s[1], 10 + 5 + 10);
      expect(s[2], -1 - 10); // the only loser
      expect(s[3], 33); // dash in an under round
    });

    test('only winner / only loser', () {
      const round = EstRound(bids: [6, 4, 3, 2], caller: 0, tricks: [6, 3, 2, 2]);
      // winners: 0 and 3 -> neither bonus
      expect(round.baseScores(r), [26, -1, -1, 12]);
      const lone = EstRound(bids: [6, 4, 3, 2], caller: 0, tricks: [6, 2, 2, 3]);
      expect(lone.baseScores(r)[0], 10 + 6 + 10 + 10);
      const oneLoser = EstRound(bids: [6, 4, 2, 2], caller: 0, tricks: [5, 4, 2, 2]);
      expect(oneLoser.baseScores(r)[0], -1 - 10 - 10);
    });

    test('dash call fails in an over round', () {
      const round = EstRound(
        bids: [7, 4, 3, 0],
        caller: 0,
        dashCalls: [false, false, false, true],
        tricks: [7, 4, 1, 1],
      );
      expect(round.over, true);
      expect(round.baseScores(r)[3], -25);
    });

    test('risk adds and takes 10 a level', () {
      const win = EstRound(bids: [5, 4, 3, 2], caller: 0, risk: [2, 0, 0, 0], tricks: [5, 4, 2, 2]);
      expect(win.baseScores(r)[0], 10 + 5 + 10 + 20);
    });

    test("sa'aydeh: all lose -> 0, next round doubled", () {
      final g = EstGame(id: 'e', created: DateTime(2026), players: ['a', 'b', 'c', 'd']);
      g.rounds.add(const EstRound(bids: [5, 4, 3, 2], caller: 0, tricks: [4, 3, 2, 4]));
      expect(g.results.first.saaydeh, true);
      expect(g.totals, [0, 0, 0, 0]);
      expect(g.nextMultiplier, 2);
      g.rounds.add(const EstRound(bids: [5, 4, 3, 2], caller: 0, tricks: [5, 4, 2, 2]));
      expect(g.results[1].multiplier, 2);
      expect(g.totals[0], (10 + 5 + 10) * 2);
      expect(g.nextMultiplier, 1);
      final back = EstGame.fromJson(g.toJson());
      expect(back.totals, g.totals);
    });

    test('validation', () {
      const bad = EstRound(bids: [5, 4, 2, 2], caller: 1, tricks: [5, 4, 2, 1]);
      final p = bad.problems(r);
      expect(p, containsAll(['bids13', 'tricks', 'callerMax']));
    });

    test('rules round-trip and edit', () {
      final edited = r.withValue('dashUnder', 30).withSaaydeh(false);
      final back = EstRules.fromJson(edited.toJson());
      expect(back.dashUnder, 30);
      expect(back.saaydeh, false);
      expect(back.rounds, 18);
    });
  });
}
