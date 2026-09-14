import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/safety_messages.dart';

class SafetyNoticeStorage {
  static const key = 'accepted_safety_notice_version';
  static Future<bool> isAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getInt(key) ?? 0) >= SafetyMessages.noticeVersion;
    } catch (_) {
      return false;
    }
  }

  static Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt(key, SafetyMessages.noticeVersion)) {
      throw StateError('Safety acknowledgement was not saved');
    }
  }
}
