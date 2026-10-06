import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The Android side of the app (MainActivity): screen on, sounds, sharing.
/// Every call is best-effort — on other platforms and in tests it does nothing.
class Device {
  Device._();

  static const _channel = MethodChannel('cgc/app');

  static Future<bool> _call(String method, [Map<String, Object?>? args]) async {
    if (kIsWeb) return false;
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> keepAwake(bool on) => _call('keepAwake', {'on': on});

  static Future<bool> shareImage(Uint8List png, String text) => _call('shareImage', {'bytes': png, 'text': text});
}

/// Card-table sound effects (made by tool/sounds/make_sounds.py).
class Sfx {
  Sfx._();

  static bool enabled = true;
  static const _names = ['tap', 'shuffle', 'chips', 'win', 'saaydeh'];

  static Future<void> init() async {
    for (final name in _names) {
      try {
        final data = await rootBundle.load('assets/sounds/$name.wav');
        await Device._call('loadSound', {'name': name, 'bytes': data.buffer.asUint8List()});
      } catch (_) {}
    }
  }

  static void play(String name, {double volume = 1}) {
    if (enabled) Device._call('play', {'name': name, 'volume': volume});
  }

  /// A card laid down: the tap sound with a light buzz.
  static void tap() {
    HapticFeedback.selectionClick();
    play('tap', volume: 0.7);
  }

  static void shuffle() => play('shuffle');
  static void chips() {
    HapticFeedback.mediumImpact();
    play('chips');
  }

  static void win() {
    HapticFeedback.heavyImpact();
    play('win');
  }

  static void saaydeh() {
    HapticFeedback.heavyImpact();
    play('saaydeh');
  }
}

/// Keeps the screen on while this widget is shown (when [on]).
class KeepAwake extends StatefulWidget {
  final bool on;
  final Widget child;
  const KeepAwake({super.key, required this.on, required this.child});

  @override
  State<KeepAwake> createState() => _KeepAwakeState();
}

class _KeepAwakeState extends State<KeepAwake> {
  @override
  void initState() {
    super.initState();
    Device.keepAwake(widget.on);
  }

  @override
  void didUpdateWidget(KeepAwake old) {
    super.didUpdateWidget(old);
    if (old.on != widget.on) Device.keepAwake(widget.on);
  }

  @override
  void dispose() {
    Device.keepAwake(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
