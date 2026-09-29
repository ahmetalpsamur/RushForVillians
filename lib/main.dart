import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Oyun yalnızca dikey çalışır: macera sahnesi, savaş HUD'u ve dolaşan
  // rehberin yerleşimi dikey orana göre ölçülüyor (bkz. GD82). Yatay çevirmek
  // sahneyi bozuyordu. Kilit üç yerde birden duruyor — burası, Android
  // manifestindeki `screenOrientation` ve iOS `Info.plist`. Yalnızca burası
  // yetmez: açılış karesi platform tarafından çizilir ve dönebilir.
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const RushForVilliansApp());
}
