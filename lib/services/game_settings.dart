import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class GameSettings {
  static const _notificationsKey = 'notifications_enabled_v1';
  static const _soundKey = 'sound_effects_enabled_v1';

  static final notificationsEnabled = ValueNotifier<bool>(true);
  static final soundEffectsEnabled = ValueNotifier<bool>(true);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled.value = prefs.getBool(_notificationsKey) ?? true;
    soundEffectsEnabled.value = prefs.getBool(_soundKey) ?? true;
  }

  static Future<void> setNotifications(bool enabled) async {
    notificationsEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, enabled);
  }

  static Future<void> setSoundEffects(bool enabled) async {
    soundEffectsEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }
}
