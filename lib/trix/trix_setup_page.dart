import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/players_form.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'trix_game_page.dart';
import 'trix_model.dart';

class TrixSetupPage extends StatefulWidget {
  const TrixSetupPage({super.key});

  @override
  State<TrixSetupPage> createState() => _TrixSetupPageState();
}

class _TrixSetupPageState extends State<TrixSetupPage> {
  late final List<TextEditingController> _names = PlayersForm.controllersFor(context);
  bool _partners = false;
  int _firstKing = 0;

  @override
  void initState() {
    super.initState();
    for (final c in _names) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    final state = AppScope.read(context);
    final names = PlayersForm.namesOf(context, _names);
    await state.rememberNames([for (final c in _names) c.text.trim()]);
    final game = TrixGame(
      id: AppState.newId(),
      created: DateTime.now(),
      players: names,
      partners: _partners,
      firstKing: _firstKing,
    );
    await state.saveGame(game);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => TrixGamePage(gameId: game.id)));
  }

  @override
  Widget build(BuildContext context) {
    final names = PlayersForm.namesOf(context, _names);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(context.tr('newTrix'))),
      body: FeltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              SectionTitle(context.tr('players'), icon: Icons.groups_rounded),
              PlayersForm(
                controllers: _names,
                hints: _partners
                    ? [context.tr('team1'), context.tr('team2'), context.tr('team1'), context.tr('team2')]
                    : null,
              ),
              SectionTitle(context.tr('mode'), icon: Icons.handshake_rounded),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(context.tr('individual')), icon: const Icon(Icons.person_rounded)),
                  ButtonSegment(value: true, label: Text(context.tr('partners')), icon: const Icon(Icons.people_rounded)),
                ],
                selected: {_partners},
                onSelectionChanged: (s) => setState(() => _partners = s.first),
                showSelectedIcon: false,
              ),
              if (_partners)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(context.tr('partnersHint'),
                      style: const TextStyle(color: Felt.muted, fontSize: 13, height: 1.5)),
                ),
              SectionTitle(context.tr('firstKingdom'), icon: Icons.workspace_premium_rounded),
              PlayerPicker(players: names, selected: _firstKing, onSelect: (p) => setState(() => _firstKing = p)),
              const SizedBox(height: 18),
              Panel(
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded, color: Felt.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(context.tr('trixRulesHint'),
                          style: const TextStyle(color: Felt.muted, height: 1.6, fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + MediaQuery.paddingOf(context).bottom),
        child: FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(context.tr('startGame')),
        ),
      ),
    );
  }
}
