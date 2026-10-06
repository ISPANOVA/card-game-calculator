import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../estimation/est_model.dart';
import '../trix/trix_model.dart';
import 'device.dart';

/// Everything the app keeps: language, saved games, last names, default
/// Estimation rules. All on the device; nothing leaves it.
class AppState extends ChangeNotifier {
  final SharedPreferences _prefs;

  AppState._(this._prefs);

  static const _kLang = 'lang';
  static const _kGames = 'games';
  static const _kNames = 'names';
  static const _kRules = 'est_rules';
  static const _kSound = 'sound';
  static const _kAwake = 'keep_awake';

  String lang = 'ar';
  final List<Object> games = [];
  List<String> lastNames = [];
  EstRules estRules = EstRules.defaults;
  bool sound = true;
  bool keepAwake = true;

  static Future<AppState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = AppState._(prefs);
    s.lang = prefs.getString(_kLang) ??
        (WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar' ? 'ar' : 'en');
    s.lastNames = prefs.getStringList(_kNames) ?? [];
    s.sound = prefs.getBool(_kSound) ?? true;
    s.keepAwake = prefs.getBool(_kAwake) ?? true;
    Sfx.enabled = s.sound;
    try {
      final raw = prefs.getString(_kRules);
      if (raw != null) s.estRules = EstRules.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {}
    try {
      final raw = prefs.getString(_kGames);
      if (raw != null) {
        for (final g in (jsonDecode(raw) as List)) {
          final m = Map<String, dynamic>.from(g as Map);
          try {
            s.games.add(m['type'] == 'trix' ? TrixGame.fromJson(m) : EstGame.fromJson(m));
          } catch (_) {}
        }
      }
    } catch (_) {}
    return s;
  }

  bool get arabic => lang == 'ar';
  Locale get locale => Locale(lang);

  Future<void> setLang(String code) async {
    lang = code;
    notifyListeners();
    await _prefs.setString(_kLang, code);
  }

  static String idOf(Object g) => g is TrixGame ? g.id : (g as EstGame).id;
  static DateTime createdOf(Object g) => g is TrixGame ? g.created : (g as EstGame).created;
  static bool finishedOf(Object g) => g is TrixGame ? g.finished : (g as EstGame).finished;
  static List<String> playersOf(Object g) => g is TrixGame ? g.players : (g as EstGame).players;
  static List<int> totalsOf(Object g) => g is TrixGame ? g.totals : (g as EstGame).totals;

  static String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// Adds or updates [game] (newest first) and saves.
  Future<void> saveGame(Object game) async {
    final id = idOf(game);
    final i = games.indexWhere((g) => idOf(g) == id);
    if (i >= 0) {
      games[i] = game;
    } else {
      games.insert(0, game);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> deleteGame(String id) async {
    games.removeWhere((g) => idOf(g) == id);
    notifyListeners();
    await _persist();
  }

  Future<void> setSound(bool on) async {
    sound = on;
    Sfx.enabled = on;
    notifyListeners();
    await _prefs.setBool(_kSound, on);
  }

  Future<void> setKeepAwake(bool on) async {
    keepAwake = on;
    notifyListeners();
    await _prefs.setBool(_kAwake, on);
  }

  Future<void> rememberNames(List<String> names) async {
    lastNames = List.of(names);
    await _prefs.setStringList(_kNames, lastNames);
  }

  Future<void> setDefaultRules(EstRules r) async {
    estRules = r;
    notifyListeners();
    await _prefs.setString(_kRules, jsonEncode(r.toJson()));
  }

  Future<void> _persist() async {
    final list = [
      for (final g in games) g is TrixGame ? g.toJson() : (g as EstGame).toJson(),
    ];
    await _prefs.setString(_kGames, jsonEncode(list));
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
