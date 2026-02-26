import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Persisted theme mode provider — defaults to dark.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  static const _boxName = 'settings';
  static const _key = 'themeMode';

  void _load() {
    if (!Hive.isBoxOpen(_boxName)) return;
    final box = Hive.box(_boxName);
    final value = box.get(_key, defaultValue: 'dark') as String;
    state = value == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  void toggle() {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    if (Hive.isBoxOpen(_boxName)) {
      Hive.box(_boxName).put(_key, next == ThemeMode.light ? 'light' : 'dark');
    }
  }
}
