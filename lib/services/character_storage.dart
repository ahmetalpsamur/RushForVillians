import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_profile.dart';
import 'game_storage.dart';

class CharacterStorage {
  CharacterStorage._();

  static bool _writeBlocked = false;
  static bool get writeBlocked => _writeBlocked;

  static const _key = 'player_avatar_v1';

  static Future<AvatarProfile?> load() async {
    _writeBlocked = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(_key);
      if (value == null) {
        _writeBlocked = false;
        return null;
      }
      final avatar = AvatarProfile.fromJson(
        jsonDecode(value) as Map<String, dynamic>,
      );
      _writeBlocked = false;
      return avatar;
    } catch (_) {
      GameStorage.protectUnreadableSave();
      return null;
    }
  }

  static Future<void> save(AvatarProfile avatar) async {
    if (_writeBlocked || GameStorage.writeBlocked) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(avatar.toJson()));
  }
}
