import 'package:flutter/material.dart';

import 'i18n.dart';
import 'theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const version = '1.0.0';

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: Text(context.tr('about'))),
      body: FeltBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              const Center(child: SuitsMark(size: 84)),
              const SizedBox(height: 12),
              const Text('Card Game Calculator',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text('${context.tr('version')} $version',
                  textAlign: TextAlign.center, style: const TextStyle(color: Felt.muted)),
              const SizedBox(height: 20),
              block(Icons.block_rounded, context.tr('noAdsTitle'), context.tr('noAdsBody')),
              block(Icons.lock_outline_rounded, context.tr('privacyTitle'), context.tr('privacyBody')),
              block(Icons.layers_rounded, context.tr('trixComplex'), context.tr('trixHelp')),
              block(Icons.record_voice_over_rounded, context.tr('estimation'), context.tr('estHelp')),
            ],
          ),
        ),
      ),
    );
  }
}
