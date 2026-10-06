import 'package:flutter/material.dart';

import '../home_page.dart';
import 'device.dart';
import 'i18n.dart';
import 'store.dart';
import 'theme.dart';

/// Settings, and about the app and its developer.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    Widget block(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Panel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Felt.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15.5)),
                      const SizedBox(height: 4),
                      Text(body, style: const TextStyle(color: Felt.muted, height: 1.65, fontSize: 13.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    Widget toggle(IconData icon, String title, String sub, bool value, ValueChanged<bool> onChanged) =>
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          secondary: Icon(icon, color: Felt.gold),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(sub, style: const TextStyle(color: Felt.muted, fontSize: 12.5)),
          value: value,
          onChanged: onChanged,
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: FeltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              SectionTitle(context.tr('settings'), icon: Icons.tune_rounded),
              Panel(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const Icon(Icons.translate_rounded, color: Felt.gold),
                      title: Text(context.tr('language'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      trailing: LangToggle(state: state),
                    ),
                    toggle(Icons.volume_up_rounded, context.tr('sounds'), context.tr('soundsSub'), state.sound, (v) {
                      state.setSound(v);
                      if (v) Sfx.tap();
                    }),
                    toggle(Icons.light_mode_rounded, context.tr('keepAwake'), context.tr('keepAwakeSub'), state.keepAwake,
                        state.setKeepAwake),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Center(child: SuitsMark(size: 84)),
              const SizedBox(height: 12),
              const Text('Card Game Calculator',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('${context.tr('version')} $version',
                  textAlign: TextAlign.center, style: const TextStyle(color: Felt.muted)),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: Felt.goldGradient,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Felt.gold.withValues(alpha: 0.3), blurRadius: 20)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Felt.deep),
                        child: const Text('S',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Felt.gold)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('developer'),
                                style: TextStyle(
                                    color: Felt.deep.withValues(alpha: 0.7), fontWeight: FontWeight.w800, fontSize: 13)),
                            const Text('SMRH',
                                style: TextStyle(
                                    color: Felt.deep, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              block(Icons.block_rounded, context.tr('noAdsTitle'), context.tr('noAdsBody')),
              block(Icons.lock_outline_rounded, context.tr('privacyTitle'), context.tr('privacyBody')),
              block(Icons.layers_rounded, context.tr('trixComplex'), context.tr('trixHelp')),
              block(Icons.record_voice_over_rounded, context.tr('estimation'), context.tr('estHelp')),
              const SizedBox(height: 8),
              Text(context.tr('copyright'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Felt.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
