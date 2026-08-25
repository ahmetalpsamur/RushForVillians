import 'package:flutter/services.dart';

class RewardSound {
  RewardSound._();

  static const _channel = MethodChannel('rush_for_villains/launch_sound');

  /// Ödül karartısı görünür olduğu anda kazanma sesini bir kez çalar.
  static Future<void> play() async {
    try {
      await _channel.invokeMethod<void>('playReward');
    } on PlatformException {
      // Ses açılamazsa ödül akışı kesilmez.
    } on MissingPluginException {
      // Widget testlerinde native kanal bulunmaz.
    }
  }
}
