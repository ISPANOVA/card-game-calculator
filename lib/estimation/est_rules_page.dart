import 'package:flutter/material.dart';

import '../core/i18n.dart';
import '../core/store.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'est_model.dart';

/// Every Estimation value, adjustable. Returns the edited rules.
class EstRulesPage extends StatefulWidget {
  final EstRules rules;
  final bool offerDefault;
  const EstRulesPage({super.key, required this.rules, this.offerDefault = false});

  @override
  State<EstRulesPage> createState() => _EstRulesPageState();
}

class _EstRulesPageState extends State<EstRulesPage> {
  late EstRules _r = widget.rules;
  bool _asDefault = true;

  static const _groups = <(String, IconData, List<(String, int, int)>)>[
    ('rulesGame', Icons.repeat_rounded, [('rounds', 1, 40), ('fastRounds', 0, 20), ('minCall', 1, 13)]),
    (
      'rulesWin',
      Icons.trending_up_rounded,
      [('winBase', 0, 100), ('callBonus', 0, 100), ('withBonus', 0, 100), ('onlyWinnerBonus', 0, 100)]
    ),
    (
      'rulesLose',
      Icons.trending_down_rounded,
      [('callPenalty', 0, 100), ('withPenalty', 0, 100), ('onlyLoserPenalty', 0, 100)]
    ),
    ('rulesRisk', Icons.local_fire_department_rounded, [('riskBonus', 0, 100)]),
    ('rulesDash', Icons.remove_circle_outline_rounded, [('dashOver', 0, 100), ('dashUnder', 0, 100)]),
  ];

  int _value(String key) => (_r.toJson()[key] as num).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.tr('rules')),
        actions: [
          TextButton(
            onPressed: () => setState(() => _r = EstRules.defaults),
            child: Text(context.tr('reset')),
          ),
        ],
      ),
      body: FeltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
            children: [
              for (final g in _groups) ...[
                SectionTitle(context.tr(g.$1), icon: g.$2),
                Panel(
                  padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                  child: Column(
                    children: [
                      for (final f in g.$3)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.tr('r_${f.$1}'),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                                    Text(context.tr('d_${f.$1}'),
                                        style: const TextStyle(color: Felt.muted, fontSize: 12, height: 1.4)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              NumberStepper(
                                value: _value(f.$1),
                                min: f.$2,
                                max: f.$3,
                                compact: true,
                                onChanged: (v) => setState(() {
                                  _r = _r.withValue(f.$1, v);
                                  if (_r.fastRounds >= _r.rounds) _r = _r.withValue('fastRounds', _r.rounds - 1);
                                }),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              SectionTitle(context.tr('saaydeh'), icon: Icons.all_inclusive_rounded),
              Panel(
                padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr('r_saaydeh'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(context.tr('d_saaydeh'), style: const TextStyle(color: Felt.muted, fontSize: 12)),
                      value: _r.saaydeh,
                      onChanged: (v) => setState(() => _r = _r.withSaaydeh(v)),
                    ),
                    if (_r.saaydeh)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(context.tr('r_saaydehMultiplier'),
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                            NumberStepper(
                              value: _r.saaydehMultiplier,
                              min: 1,
                              max: 5,
                              compact: true,
                              onChanged: (v) => setState(() => _r = _r.withValue('saaydehMultiplier', v)),
                            ),
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
      bottomNavigationBar: Container(
        color: const Color(0xFF072A1F),
        padding: EdgeInsets.fromLTRB(16, 6, 16, 12 + MediaQuery.paddingOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.offerDefault)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _asDefault,
                onChanged: (v) => setState(() => _asDefault = v ?? false),
                title: Text(context.tr('saveAsDefault'), style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  if (widget.offerDefault && _asDefault) await AppScope.read(context).setDefaultRules(_r);
                  if (context.mounted) Navigator.pop(context, _r);
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(context.tr('apply')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
