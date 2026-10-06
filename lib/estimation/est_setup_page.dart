import 'package:flutter/material.dart';

import '../core/device.dart';
import '../core/i18n.dart';
import '../core/players_form.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'est_game_page.dart';
import 'est_model.dart';
import 'est_rules_page.dart';

class EstSetupPage extends StatefulWidget {
  const EstSetupPage({super.key});

  @override
  State<EstSetupPage> createState() => _EstSetupPageState();
}

class _EstSetupPageState extends State<EstSetupPage> {
  late final List<TextEditingController> _names = PlayersForm.controllersFor(context);
  late EstRules _rules = AppScope.read(context).estRules;
  int _dealer = 0;

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
    final game = EstGame(
      id: AppState.newId(),
      created: DateTime.now(),
      players: names,
      rules: _rules,
      firstDealer: _dealer,
    );
    await state.saveGame(game);
    Sfx.shuffle();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EstGamePage(gameId: game.id)));
  }

  Future<void> _editRules() async {
    final r = await Navigator.push<EstRules>(
      context,
      MaterialPageRoute(builder: (_) => EstRulesPage(rules: _rules, offerDefault: true)),
    );
    if (r != null) setState(() => _rules = r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _rules;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(context.tr('newEst'))),
      body: FeltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              SectionTitle(context.tr('playersInOrder'), icon: Icons.groups_rounded),
              PlayersForm(controllers: _names),
              SectionTitle(context.tr('firstDealer'), icon: Icons.style_rounded),
              PlayerPicker(
                players: PlayersForm.namesOf(context, _names),
                selected: _dealer,
                onSelect: (p) => setState(() => _dealer = p),
              ),
              SectionTitle(
                context.tr('rules'),
                icon: Icons.rule_rounded,
                trailing: TextButton.icon(
                  onPressed: _editRules,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(context.tr('edit')),
                ),
              ),
              Panel(
                onTap: _editRules,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Pill(context.tr('nRounds', {'n': r.rounds}), icon: Icons.repeat_rounded),
                    Pill(context.tr('nFast', {'n': r.fastRounds}), icon: Icons.bolt_rounded),
                    Pill('${context.tr('win')} ${r.winBase}+', color: Felt.win),
                    Pill('${context.tr('call')} ±${r.callBonus}'),
                    Pill('${context.tr('with')} ±${r.withBonus}'),
                    Pill('${context.tr('risk')} ±${r.riskBonus}'),
                    Pill('${context.tr('dash')} ${r.dashOver}/${r.dashUnder}'),
                    Pill('${context.tr('onlyWinner')} ${diffText(r.onlyWinnerBonus)}', color: Felt.win),
                    Pill('${context.tr('onlyLoser')} ${diffText(-r.onlyLoserPenalty)}', color: Felt.lose),
                    Pill(r.saaydeh ? '${context.tr('saaydeh')} ×${r.saaydehMultiplier}' : context.tr('noSaaydeh'),
                        color: Felt.seats[1]),
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
