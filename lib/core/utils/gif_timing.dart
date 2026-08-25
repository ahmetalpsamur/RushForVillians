import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Bir GIF'in tek tam oynatım süresini asset karelerinden hesaplar.
class GifTiming {
  GifTiming._();

  static final Map<String, Future<Duration?>> _cache = {};

  static Future<Duration> cycle(
    String asset, {
    Duration fallback = const Duration(milliseconds: 850),
  }) async {
    final measured = await _cache.putIfAbsent(asset, () => _measure(asset));
    if (measured == null || measured <= Duration.zero) return fallback;
    return measured;
  }

  static Future<Duration?> _measure(String asset) async {
    ui.Codec? codec;
    try {
      final data = await rootBundle.load(asset);
      codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      var total = Duration.zero;
      for (var index = 0; index < codec.frameCount; index++) {
        final frame = await codec.getNextFrame();
        total += frame.duration;
        frame.image.dispose();
      }
      return total;
    } catch (_) {
      return null;
    } finally {
      codec?.dispose();
    }
  }
}
