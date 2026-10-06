import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'i18n.dart';
import 'theme.dart';

/// Each player's running total, round after round.
class ScoreChart extends StatelessWidget {
  final List<String> players;

  /// Score of each round, per player.
  final List<List<int>> rounds;
  const ScoreChart({super.key, required this.players, required this.rounds});

  @override
  Widget build(BuildContext context) {
    final running = <List<int>>[
      [0, 0, 0, 0],
    ];
    for (final r in rounds) {
      final last = running.last;
      running.add([for (var p = 0; p < 4; p++) last[p] + r[p]]);
    }
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, t, _) => CustomPaint(
                  size: Size.infinite,
                  painter: _ChartPainter(running, t),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (var p = 0; p < 4; p++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 4,
                      decoration: BoxDecoration(color: Felt.seats[p], borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 5),
                    Text(players[p], style: const TextStyle(fontSize: 12, color: Felt.muted, fontWeight: FontWeight.w700)),
                  ],
                ),
              Text(context.tr('chartRounds', {'n': rounds.length}),
                  style: TextStyle(fontSize: 11.5, color: Felt.muted.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<List<int>> running;
  final double t;
  _ChartPainter(this.running, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final all = [for (final r in running) ...r];
    var lo = all.reduce(math.min).toDouble();
    var hi = all.reduce(math.max).toDouble();
    if (hi - lo < 10) {
      hi += 5;
      lo -= 5;
    }
    const left = 34.0, bottom = 6.0, top = 6.0;
    final w = size.width - left - 4, h = size.height - top - bottom;
    double x(int i) => left + w * i / math.max(1, running.length - 1);
    double y(num v) => top + h * (1 - (v - lo) / (hi - lo));

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    final label = TextStyle(color: Felt.muted.withValues(alpha: 0.8), fontSize: 10, fontFamily: AppFonts.body);
    for (final v in [hi, (hi + lo) / 2, lo]) {
      canvas.drawLine(Offset(left, y(v)), Offset(size.width, y(v)), grid);
      final tp = TextPainter(text: TextSpan(text: '${v.round()}', style: label), textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(left - tp.width - 6, y(v) - tp.height / 2));
      tp.dispose();
    }
    if (lo < 0 && hi > 0) {
      canvas.drawLine(Offset(left, y(0)), Offset(size.width, y(0)),
          Paint()
            ..color = Felt.gold.withValues(alpha: 0.35)
            ..strokeWidth = 1.2);
    }

    final shown = (running.length - 1) * t;
    for (var p = 0; p < 4; p++) {
      final path = Path()..moveTo(x(0), y(running[0][p]));
      var end = Offset(x(0), y(running[0][p]));
      for (var i = 1; i < running.length; i++) {
        if (i - 1 > shown) break;
        final f = (shown - (i - 1)).clamp(0.0, 1.0);
        final a = Offset(x(i - 1), y(running[i - 1][p]));
        final b = Offset(x(i), y(running[i][p]));
        end = Offset.lerp(a, b, f)!;
        path.lineTo(end.dx, end.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = Felt.seats[p]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(end, 4, Paint()..color = Felt.seats[p]);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => old.t != t || old.running != running;
}
