import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instance de SharedPreferences, fournie depuis `main` via un override.
/// (Évite d'avoir à attendre un Future partout.)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('À surcharger dans main() avec overrideWithValue');
});

const _kThemeKey = 'theme_mode';

/// Gère le mode de thème (clair / sombre / système) et le persiste.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_kThemeKey);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kThemeKey, mode.name);
  }

  /// Bascule simplement entre clair et sombre.
  Future<void> toggle() async {
    final isDark = state == ThemeMode.dark;
    await set(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
