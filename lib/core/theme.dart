import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Card-table colours: green baize, gold trim, ivory cards.
class Felt {
  Felt._();

  static const deep = Color(0xFF04211A);
  static const base = Color(0xFF0A3324);
  static const light = Color(0xFF125A3E);
  static const gold = Color(0xFFE2C275);
  static const goldDeep = Color(0xFFB08A3A);
  static const ivory = Color(0xFFF7F0DC);
  static const muted = Color(0xFFB9CDBF);
  static const red = Color(0xFFE5534B);
  static const win = Color(0xFF63D99E);
  static const lose = Color(0xFFFF7B72);

  /// One colour per seat, used for chips and scoreboard accents.
  static const seats = [Color(0xFFE2C275), Color(0xFF7CC4FF), Color(0xFFFF9E80), Color(0xFFB79CFF)];

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3DFA2), Color(0xFFE2C275), Color(0xFFB08A3A)],
  );
}

class AppFonts {
  static const body = 'Tajawal';
  static const display = 'ReemKufi';
}

ThemeData buildTheme(bool arabic) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Felt.base,
    brightness: Brightness.dark,
    primary: Felt.gold,
    onPrimary: Felt.deep,
    secondary: Felt.gold,
    surface: Felt.base,
    onSurface: Felt.ivory,
    error: Felt.red,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: AppFonts.body);
  return base.copyWith(
    scaffoldBackgroundColor: Felt.deep,
    textTheme: base.textTheme.apply(bodyColor: Felt.ivory, displayColor: Felt.ivory, fontFamily: AppFonts.body),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: Felt.ivory,
      titleTextStyle: TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w800, fontSize: 19, color: Felt.ivory),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Felt.gold,
        foregroundColor: Felt.deep,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
        disabledForegroundColor: Felt.muted.withValues(alpha: 0.6),
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Felt.gold,
        side: BorderSide(color: Felt.gold.withValues(alpha: 0.5)),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Felt.gold,
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Felt.gold, width: 1.4),
      ),
      labelStyle: const TextStyle(color: Felt.muted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Felt.deep : Felt.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Felt.gold : Colors.white.withValues(alpha: 0.10)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF0D3A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w800, fontSize: 19, color: Felt.ivory),
      contentTextStyle: const TextStyle(fontFamily: AppFonts.body, fontSize: 15, height: 1.6, color: Felt.muted),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF0B3527),
      showDragHandle: true,
      dragHandleColor: Felt.muted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Felt.ivory,
      contentTextStyle: const TextStyle(fontFamily: AppFonts.body, color: Felt.deep, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: Felt.gold,
        selectedForegroundColor: Felt.deep,
        foregroundColor: Felt.ivory,
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        side: BorderSide(color: Felt.gold.withValues(alpha: 0.4)),
        minimumSize: const Size(0, 48),
        textStyle: const TextStyle(fontFamily: AppFonts.body, fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08), space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}

/// The green baize behind every page, with faint suits scattered over it.
class FeltBackground extends StatelessWidget {
  final Widget child;
  const FeltBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.25,
          colors: [Felt.light, Felt.base, Felt.deep],
          stops: [0, 0.55, 1],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _SuitsPainter()))),
          child,
        ],
      ),
    );
  }
}

class _SuitsPainter extends CustomPainter {
  const _SuitsPainter();

  static const _suits = ['♠', '♥', '♦', '♣'];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    const step = 92.0;
    var i = 0;
    for (var y = 20.0; y < size.height; y += step) {
      for (var x = (i.isEven ? 16.0 : 62.0); x < size.width; x += step) {
        final tp = TextPainter(
          text: TextSpan(
            text: _suits[(i + (x ~/ step)) % 4],
            style: TextStyle(fontSize: 22 + rnd.nextDouble() * 8, color: Colors.white.withValues(alpha: 0.028)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate((rnd.nextDouble() - 0.5) * 0.6);
        tp.paint(canvas, Offset.zero);
        canvas.restore();
        tp.dispose();
      }
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A soft glass panel with a thin gold edge.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? glow;
  final double radius;

  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.glow,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.085), Colors.white.withValues(alpha: 0.035)],
        ),
        border: Border.all(color: (glow ?? Felt.gold).withValues(alpha: glow == null ? 0.18 : 0.6), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 8)),
          if (glow != null) BoxShadow(color: glow!.withValues(alpha: 0.18), blurRadius: 24),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A small heading above a group of fields.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final IconData? icon;
  const SectionTitle(this.text, {super.key, this.trailing, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 18, 4, 10),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: Felt.gold), const SizedBox(width: 8)],
          Expanded(
            child: Text(text,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5, color: Felt.gold, letterSpacing: 0.2)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A rounded pill used for small status labels.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool filled;
  const Pill(this.text, {super.key, this.color = Felt.gold, this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Felt.deep : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: filled ? 1 : 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// The app's mark: the four suits on a gold disc.
class SuitsMark extends StatelessWidget {
  final double size;
  const SuitsMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final s = size * 0.27;
    Widget suit(String c, Color col) =>
        Text(c, style: TextStyle(fontSize: s, height: 1, color: col, fontFamily: 'Roboto'));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Felt.goldGradient,
        boxShadow: [BoxShadow(color: Felt.gold.withValues(alpha: 0.35), blurRadius: size * 0.35)],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [suit('♠', Felt.deep), suit('♥', const Color(0xFFB3261E))]),
            Row(mainAxisSize: MainAxisSize.min, children: [suit('♦', const Color(0xFFB3261E)), suit('♣', Felt.deep)]),
          ],
        ),
      ),
    );
  }
}

/// Signed score text: green when positive, red when negative.
String signed(int v) => v > 0 ? '+$v' : '$v';

Color scoreColor(int v) => v > 0 ? Felt.win : (v < 0 ? Felt.lose : Felt.muted);
