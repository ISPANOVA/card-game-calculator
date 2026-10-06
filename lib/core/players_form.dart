import 'package:flutter/material.dart';

import 'i18n.dart';
import 'store.dart';
import 'theme.dart';

/// Four name fields, filled with the last names used.
class PlayersForm extends StatefulWidget {
  final List<TextEditingController> controllers;
  final List<String>? hints;
  const PlayersForm({super.key, required this.controllers, this.hints});

  static List<TextEditingController> controllersFor(BuildContext context) {
    final last = AppScope.read(context).lastNames;
    return [for (var i = 0; i < 4; i++) TextEditingController(text: i < last.length ? last[i] : '')];
  }

  /// The names typed, with "Player N" for any left empty.
  static List<String> namesOf(BuildContext context, List<TextEditingController> cs) => [
        for (var i = 0; i < 4; i++)
          cs[i].text.trim().isEmpty ? context.tr('playerN', {'n': i + 1}) : cs[i].text.trim(),
      ];

  @override
  State<PlayersForm> createState() => _PlayersFormState();
}

class _PlayersFormState extends State<PlayersForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: widget.controllers[i],
              textInputAction: i < 3 ? TextInputAction.next : TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              maxLength: 16,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              decoration: InputDecoration(
                counterText: '',
                hintText: context.tr('playerN', {'n': i + 1}),
                hintStyle: TextStyle(color: Felt.muted.withValues(alpha: 0.6)),
                helperText: widget.hints?[i],
                helperStyle: const TextStyle(color: Felt.muted),
                prefixIcon: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Felt.seats[i].withValues(alpha: 0.2),
                    child: Text('${i + 1}', style: TextStyle(color: Felt.seats[i], fontWeight: FontWeight.w900)),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ),
      ],
    );
  }
}
