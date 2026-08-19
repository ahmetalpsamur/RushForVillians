import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/avatar_profile.dart';

class CharacterStorage {
  CharacterStorage._();

  static const _key = 'player_avatar_v1';

  static Future<AvatarProfile?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_key);
    if (value == null) return null;
    try {
      return AvatarProfile.fromJson(jsonDecode(value) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static Future<void> save(AvatarProfile avatar) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(avatar.toJson()));
  }
}
