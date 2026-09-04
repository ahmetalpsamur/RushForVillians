import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocalePreference {
  system('system'),
  turkish('tr'),
  english('en');

  final String storageValue;

  const LocalePreference(this.storageValue);

  Locale? get locale => switch (this) {
    LocalePreference.system => null,
    LocalePreference.turkish => const Locale('tr'),
    LocalePreference.english => const Locale('en'),
  };

  static LocalePreference fromStorage(String? value) => values.firstWhere(
    (preference) => preference.storageValue == value,
    orElse: () => LocalePreference.system,
  );
}

abstract final class LocalePreferenceStorage {
  static const String key = 'locale_preference_v1';

  static Future<LocalePreference> load() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalePreference.fromStorage(preferences.getString(key));
  }

  static Future<void> save(LocalePreference preference) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, preference.storageValue);
  }
}

Locale resolveSystemLocale(List<Locale>? deviceLocales) {
  for (final locale in deviceLocales ?? const <Locale>[]) {
    if (locale.languageCode == 'tr') return const Locale('tr');
    if (locale.languageCode == 'en') return const Locale('en');
  }
  return const Locale('tr');
}

void ignoreLocalePreference(LocalePreference _) {}
