import 'package:flutter/services.dart';

class LaunchSound {
  LaunchSound._();

  static const _channel = MethodChannel('rush_for_villains/launch_sound');
  static bool _hasPlayed = false;

  /// Uygulama süreci boyunca açılış sesini yalnızca bir kez çalar.
  static Future<void> playOnce() async {
    if (_hasPlayed) return;
    _hasPlayed = true;

    try {
      await _channel.invokeMethod<void>('play');
    } on PlatformException {
      // Ses açılamazsa uygulamanın başlangıcı etkilenmez.
    } on MissingPluginException {
      // Widget testlerinde native kanal bulunmaz.
    }
  }
}
