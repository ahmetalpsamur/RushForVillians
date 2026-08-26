import 'package:shared_preferences/shared_preferences.dart';

import '../models/tutorial_guide_variant.dart';

class TutorialGuideStorage {
  TutorialGuideStorage._();

  static const _key = 'tutorial_guide_v1';

  static Future<TutorialGuideVariant?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final id = preferences.getString(_key);
    if (id == null) return null;
    return TutorialGuideVariant.fromId(id);
  }

  static Future<void> save(TutorialGuideVariant guide) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, guide.id);
  }
}
