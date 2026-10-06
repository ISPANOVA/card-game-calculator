import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'device.dart';
import 'i18n.dart';
import 'theme.dart';

/// "Sa'aydeh!" — everybody missed: a big pulsing ×N for a moment.
Future<void> showSaaydeh(BuildContext context, int multiplier) {
  Sfx.saaydeh();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'saaydeh',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => _Saaydeh(multiplier: multiplier),
    transitionBuilder: (ctx, a, _, child) => FadeTransition(opacity: a, child: child),
  );
}

class _Saaydeh extends StatefulWidget {
  final int multiplier;
  const _Saaydeh({required this.multiplier});

  @override
  State<_Saaydeh> createState() => _SaaydehState();
}

class _SaaydehState extends State<_Saaydeh> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))
    ..forward();
  Timer? _close;

  @override
  void initState() {
    super.initState();
    _close = Timer(const Duration(milliseconds: 2100), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _close?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF7CC4FF);
    return Center(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final pop = Curves.elasticOut.transform((t * 1.6).clamp(0.0, 1.0));
          final glow = 0.5 + 0.5 * math.sin(t * math.pi * 6);
          return Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: (1 - pop) * 0.6,
                  child: Icon(Icons.all_inclusive_rounded, size: 72, color: blue.withValues(alpha: 0.9)),
                ),
                const SizedBox(height: 6),
                Transform.scale(
                  scale: 0.4 + 0.6 * pop,
                  child: Text(
                    context.tr('saaydeh'),
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: blue.withValues(alpha: 0.6 + 0.4 * glow), blurRadius: 30)],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Transform.scale(
                  scale: 0.6 + 0.6 * Curves.easeOutBack.transform(((t - 0.25) * 2).clamp(0.0, 1.0)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: Felt.goldGradient,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [BoxShadow(color: Felt.gold.withValues(alpha: 0.4 + 0.4 * glow), blurRadius: 26)],
                    ),
                    child: Text('×${widget.multiplier}',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Felt.deep)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(context.tr('saaydehNext', {'n': widget.multiplier}),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The end of a game: cards rain down, the winner gets the crown.
Future<void> showCelebration(
  BuildContext context, {
  required String winner,
  required String subtitle,
  VoidCallback? onShare,
  VoidCallback? onRematch,
}) {
  Sfx.win();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'win',
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, _) => _Celebration(winner: winner, subtitle: subtitle, onShare: onShare, onRematch: onRematch),
    transitionBuilder: (ctx, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: child),
    ),
  );
}

class _Celebration extends StatefulWidget {
  final String winner;
  final String subtitle;
  final VoidCallback? onShare;
  final VoidCallback? onRematch;
  const _Celebration({required this.winner, required this.subtitle, this.onShare, this.onRematch});

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))
    ..forward();
  late final List<_Piece> _pieces = _Piece.scatter(46);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _RainPainter(_pieces, _c)),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: const Color(0xFF0D3A2A),
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Felt.gold.withValues(alpha: 0.7), width: 1.5),
                  boxShadow: [BoxShadow(color: Felt.gold.withValues(alpha: 0.3), blurRadius: 40)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: CurvedAnimation(parent: _c, curve: const Interval(0, 0.25, curve: Curves.elasticOut)),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: Felt.goldGradient,
                          boxShadow: [BoxShadow(color: Felt.gold.withValues(alpha: 0.5), blurRadius: 30)],
                        ),
                        child: const Icon(Icons.emoji_events_rounded, size: 48, color: Felt.deep),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(context.tr('congrats'),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Felt.muted)),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Felt.gold, size: 26),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(widget.winner,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Felt.ivory)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(widget.subtitle,
                        textAlign: TextAlign.center, style: const TextStyle(color: Felt.muted, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 18),
                    if (widget.onShare != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onShare!();
                          },
                          icon: const Icon(Icons.share_rounded),
                          label: Text(context.tr('shareResult')),
                        ),
                      ),
                    if (widget.onRematch != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onRematch!();
                          },
                          icon: const Icon(Icons.replay_rounded),
                          label: Text(context.tr('rematch')),
                        ),
                      ),
                    ],
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.tr('close'))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One falling card or suit.
class _Piece {
  final double x, delay, speed, spin, sway, size;
  final Suit suit;
  final bool card;
  const _Piece(this.x, this.delay, this.speed, this.spin, this.sway, this.size, this.suit, this.card);

  static List<_Piece> scatter(int n) {
    final r = math.Random();
    return [
      for (var i = 0; i < n; i++)
        _Piece(
          r.nextDouble(),
          r.nextDouble() * 0.45,
          0.7 + r.nextDouble() * 0.6,
          (r.nextDouble() - 0.5) * 8,
          r.nextDouble() * 2 * math.pi,
          16 + r.nextDouble() * 18,
          Suit.values[r.nextInt(4)],
          r.nextDouble() < 0.45,
        ),
    ];
  }
}

class _RainPainter extends CustomPainter {
  final List<_Piece> pieces;
  final Animation<double> t;
  _RainPainter(this.pieces, this.t) : super(repaint: t);

  static const _red = Color(0xFFE53935);

  @override
  void paint(Canvas canvas, Size size) {
    final card = Paint()..color = Felt.ivory;
    final edge = Paint()
      ..color = Felt.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final p in pieces) {
      final local = ((t.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0) * p.speed;
      if (local <= 0) continue;
      final y = -40 + local * (size.height + 80);
      final x = p.x * size.width + math.sin(p.sway + local * 6) * 24;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local);
      final color = p.suit.red ? _red : (p.card ? const Color(0xFF16201B) : Felt.gold);
      if (p.card) {
        final w = p.size, h = p.size * 1.4;
        final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), const Radius.circular(3));
        canvas.drawRRect(r, card);
        canvas.drawRRect(r, edge);
        canvas.translate(-w * 0.3, -w * 0.3);
        canvas.scale(w * 0.6 / 100);
      } else {
        canvas.translate(-p.size / 2, -p.size / 2);
        canvas.scale(p.size / 100);
      }
      canvas.drawPath(p.suit.path, Paint()..color = color);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) => false;
}
