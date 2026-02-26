import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Persisted locale provider — defaults to Korean.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('ko', 'KR')) {
    _load();
  }

  static const _boxName = 'settings';
  static const _key = 'locale';

  void _load() {
    final box = Hive.box(_boxName);
    final code = box.get(_key, defaultValue: 'ko') as String;
    state = code == 'en' ? const Locale('en', 'US') : const Locale('ko', 'KR');
  }

  void toggle() {
    final next = state.languageCode == 'ko'
        ? const Locale('en', 'US')
        : const Locale('ko', 'KR');
    state = next;
    Hive.box(_boxName).put(_key, next.languageCode);
  }
}
