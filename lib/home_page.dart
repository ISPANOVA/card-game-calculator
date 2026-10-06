import 'package:flutter/material.dart';

import 'core/about_page.dart';
import 'core/i18n.dart';
import 'core/store.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'estimation/est_game_page.dart';
import 'estimation/est_model.dart';
import 'estimation/est_setup_page.dart';
import 'trix/trix_game_page.dart';
import 'trix/trix_model.dart';
import 'trix/trix_setup_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final ongoing = state.games.where((g) => !AppState.finishedOf(g)).toList();
    final done = state.games.where(AppState.finishedOf).toList();
    return Scaffold(
      body: FeltBackground(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                sliver: SliverToBoxAdapter(child: _Header(state: state)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                sliver: SliverList.list(children: [
                  _GameCard(
                    title: context.tr('trixComplex'),
                    subtitle: context.tr('trixDesc'),
                    art: const _CardFan(cards: [('K', '♥'), ('Q', '♠'), ('A', '♦')]),
                    colors: const [Color(0xFF1B6B4B), Color(0xFF0C3F2C)],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrixSetupPage())),
                  ),
                  const SizedBox(height: 14),
                  _GameCard(
                    title: context.tr('estimation'),
                    subtitle: context.tr('estDesc'),
                    art: const _CardFan(cards: [('7', '♣'), ('J', '♥'), ('10', '♠')]),
                    colors: const [Color(0xFF3A2D63), Color(0xFF1A1438)],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EstSetupPage())),
                  ),
                ]),
              ),
              if (ongoing.isNotEmpty)
                _GamesSection(title: context.tr('continueGames'), icon: Icons.play_circle_rounded, games: ongoing),
              if (done.isNotEmpty) _GamesSection(title: context.tr('history'), icon: Icons.history_rounded, games: done),
              if (state.games.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Icon(Icons.style_rounded, size: 48, color: Felt.gold.withValues(alpha: 0.5)),
                        const SizedBox(height: 10),
                        Text(context.tr('noGames'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Felt.muted, height: 1.6, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppState state;
  const _Header({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SuitsMark(size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Card Game',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Felt.ivory, height: 1.1)),
              ShaderMask(
                shaderCallback: (r) => Felt.goldGradient.createShader(r),
                child: const Text('Calculator',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
              ),
            ],
          ),
        ),
        _LangToggle(state: state),
        const SizedBox(width: 6),
        IconButton(
          tooltip: context.tr('about'),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
          icon: const Icon(Icons.info_outline_rounded, color: Felt.muted),
        ),
      ],
    );
  }
}

class _LangToggle extends StatelessWidget {
  final AppState state;
  const _LangToggle({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Felt.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final l in const [('ar', 'ع'), ('en', 'EN')])
            GestureDetector(
              onTap: () => state.setLang(l.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: state.lang == l.$1 ? Felt.gold : Colors.transparent,
                ),
                child: Text(l.$2,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: state.lang == l.$1 ? Felt.deep : Felt.muted)),
              ),
            ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget art;
  final List<Color> colors;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.art,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(26);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        border: Border.all(color: Felt.gold.withValues(alpha: 0.45)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 22, offset: const Offset(0, 10))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: SizedBox(
            height: 156,
            child: Stack(
              children: [
                PositionedDirectional(end: 8, top: 14, bottom: 14, width: 132, child: art),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 140, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: Felt.ivory)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Felt.muted, height: 1.45, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(gradient: Felt.goldGradient, borderRadius: BorderRadius.circular(99)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 18, color: Felt.deep),
                            const SizedBox(width: 4),
                            Text(context.tr('newGame'),
                                style: const TextStyle(color: Felt.deep, fontWeight: FontWeight.w900, fontSize: 13.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three playing cards fanned out.
class _CardFan extends StatelessWidget {
  final List<(String, String)> cards;
  const _CardFan({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(builder: (context, c) {
        final h = c.maxHeight * 0.86;
        final w = h * 0.68;
        return Stack(
          alignment: Alignment.center,
          children: [
            for (var i = 0; i < cards.length; i++)
              Transform.translate(
                offset: Offset((i - 1) * w * 0.42, (i - 1).abs() * 6.0),
                child: Transform.rotate(
                  angle: (i - 1) * 0.22,
                  child: _MiniCard(rank: cards[i].$1, suit: cards[i].$2, width: w, height: h),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String rank;
  final String suit;
  final double width;
  final double height;
  const _MiniCard({required this.rank, required this.suit, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final red = suit == '♥' || suit == '♦';
    final color = red ? const Color(0xFFC62828) : const Color(0xFF1B1B1B);
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Felt.ivory,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          Text('$rank\n$suit',
              style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: width * 0.2, height: 1.05)),
          Center(child: Text(suit, style: TextStyle(color: color, fontSize: width * 0.5))),
        ],
      ),
    );
  }
}

class _GamesSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Object> games;
  const _GamesSection({required this.title, required this.icon, required this.games});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      sliver: SliverList.list(children: [
        SectionTitle(title, icon: icon),
        for (final g in games) ...[_GameTile(game: g), const SizedBox(height: 10)],
      ]),
    );
  }
}

class _GameTile extends StatelessWidget {
  final Object game;
  const _GameTile({required this.game});

  @override
  Widget build(BuildContext context) {
    final trix = game is TrixGame;
    final players = AppState.playersOf(game);
    final totals = AppState.totalsOf(game);
    var lead = 0;
    for (var p = 1; p < 4; p++) {
      if (totals[p] > totals[lead]) lead = p;
    }
    final finished = AppState.finishedOf(game);
    final g = game;
    final progress = g is TrixGame
        ? context.tr('kingdomOf', {'n': (g.currentKingdom + 1).clamp(1, 4)})
        : context.tr('roundOf', {'n': (g as EstGame).rounds.length, 'of': g.rules.rounds});
    final d = AppState.createdOf(game);
    final date = '${d.day}/${d.month}/${d.year}';
    return Dismissible(
      key: ValueKey(AppState.idOf(game)),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(color: Felt.red.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.delete_outline_rounded, color: Felt.lose),
      ),
      confirmDismiss: (_) => confirm(context, context.tr('deleteGame'), context.tr('deleteGameBody')),
      onDismissed: (_) => AppScope.read(context).deleteGame(AppState.idOf(game)),
      child: Panel(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => trix ? TrixGamePage(gameId: AppState.idOf(game)) : EstGamePage(gameId: AppState.idOf(game)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: (trix ? const Color(0xFF1B6B4B) : const Color(0xFF3A2D63)),
                border: Border.all(color: Felt.gold.withValues(alpha: 0.4)),
              ),
              child: Text(trix ? '♥' : '♠',
                  style: TextStyle(fontSize: 24, color: trix ? const Color(0xFFFF8A80) : Felt.ivory)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(context.tr(trix ? 'trixComplex' : 'estimation'),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                      ),
                      const SizedBox(width: 8),
                      Text(date, style: const TextStyle(fontSize: 12, color: Felt.muted)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(players.join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: Felt.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Pill(finished ? context.tr('finished') : progress,
                          color: finished ? Felt.win : Felt.gold, icon: finished ? Icons.flag_rounded : null),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${finished ? '🏆 ' : ''}${players[lead]} ${totals[lead]}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Felt.ivory),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Felt.muted),
          ],
        ),
      ),
    );
  }
}
