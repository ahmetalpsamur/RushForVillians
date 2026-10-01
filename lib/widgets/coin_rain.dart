import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Yürüyüş fazında düşen paralar (Bölüm D / Faz 1.5).
///
/// Bonuslu oranı (`walkPhaseStepsPerCoin`) **görünür** kılar: oyuncu düşmanı
/// erken devirdiği için bu fazı kazandı ve burada geçen her adım normalin
/// ×2,5'i ediyor. Görünmeyen bir çarpan kural değil, sürprizdir — GD56'nın
/// "gösterim şart" kuralıyla aynı fikir.
///
/// Üç kısıt:
/// 1. **Dokunmayı engellemez** — bütün katman [IgnorePointer] içinde
///    (GD77 ile aynı fikir: engellememe garantisi etkileşimden değerli).
/// 2. **Deterministik** — konum, boy ve faz indeksten türüyor, `Random()`
///    yok. Sunum rastgeleliği serbest olsa da (§6.10) golden'ların
///    tekrarlanabilir olması için sabit.
/// 3. **`pumpAndSettle` bu sahnede zaten kullanılamıyor**: yürüyüş
///    animasyonu da sonsuz tekrarlı (GD76). Yeni controller mevcut durumu
///    değiştirmiyor.
///
/// ⚠️ **Dağıtım `stableSpread` ile yapılmıyor.** İlk sürüm öyleydi ve
/// ölçüldü: `'rain-x-0'` … `'rain-x-11'` gibi kısa ve birbirine çok benzeyen
/// anahtarlarda `stableSpread` dağıtmıyor — 12 paranın onu **aynı** sütuna ve
/// aynı yüksekliğe düşüyordu (col 0,36 · top 96), ekranda iki para
/// görünüyordu. `stableSpread` kalıcı kimlikler için yazıldı, yoğun bir
/// indeks dizisi için değil.
///
/// Yerine **düşük tutarsızlık dizisi**: altın oran gibi irrasyonel bir
/// çarpanın kesirli kısmı, indeks arttıkça aralığı eşit doldurur ve asla
/// kümelenmez. Hash'lemekten hem daha basit hem bu iş için daha doğru.
class CoinRain extends StatelessWidget {
  final AnimationController controller;

  /// Aynı anda düşen para sayısı. Daha fazlası sahneyi kapatıyor, daha azı
  /// "yağmur" hissi vermiyor.
  static const int coinCount = 12;

  /// Altın oranın kesirli kısmı — sütun dağılımı.
  static const double _phi = 0.6180339887498949;

  /// Plastik sayının kesirli kısmı — düşüş fazı. `_phi` ile aynı çarpanı
  /// kullanmak sütun ve fazı birbirine kilitler, paralar köşegen bir çizgiye
  /// dizilirdi.
  static const double _plastic = 0.7548776662466927;

  /// Üçüncü bağımsız çarpan — boy.
  static const double _sqrt2 = 0.4142135623730951;

  /// Kullanılan para görselleri.
  static const List<String> assetPaths = [
    'lib/All_Assets/coins/coin_gold_medium_shine.gif',
    'lib/All_Assets/coins/coin_gold_large_shine.gif',
    'lib/All_Assets/coins/coin_silver_medium_shine.gif',
  ];

  const CoinRain({super.key, required this.controller});

  static double _frac(double value) => value - value.floorToDouble();

  /// Görsel henüz çözülmediğinde ya da hiç açılamadığında çizilen disk.
  static Widget _coinPlaceholder(double size) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.streak,
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.black.withValues(alpha: 0.45),
        width: 2,
      ),
    ),
    child: SizedBox(width: size, height: size),
  );

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final width = constraints.maxWidth;
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final coins = <Widget>[];
              for (var i = 0; i < coinCount; i++) {
                final column = _frac((i + 1) * _phi);
                final sizeRoll = _frac((i + 1) * _sqrt2);
                final phase = _frac((i + 1) * _plastic);
                final size = 14 + sizeRoll * 14;
                final progress = _frac(controller.value + phase);
                final top = progress * (height + size) - size;
                coins.add(
                  Positioned(
                    left: column * (width - size),
                    top: top,
                    child: Opacity(
                      // Uçlarda sönümleniyor: paralar kutunun kenarında
                      // aniden belirip kaybolmasın.
                      opacity: (1 - (progress - 0.5).abs() * 1.2).clamp(
                        0.0,
                        0.9,
                      ),
                      child: Image.asset(
                        assetPaths[i % assetPaths.length],
                        width: size,
                        height: size,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        // ⚠️ Hem **yükleme** hem **hata** durumunda çizilen
                        // bir disk gösteriliyor, `Icon` değil.
                        //
                        // İki ayrı şey ölçüldü. (1) `Icon` yedeği test
                        // ortamında ikon fontu olmadığı için hiçbir şey
                        // çizmiyor. (2) Asıl sorun `errorBuilder` bile
                        // değildi: GIF **hata vermiyor**, yalnızca henüz
                        // çözülmemiş oluyor ve o sırada `Image` boşluk
                        // çiziyor. Golden bu yüzden bomboş çıkıyordu.
                        // `frameBuilder` ilk kare gelene kadar boşluğu
                        // kapatıyor — üretimde de pop-in boşluğunu siliyor.
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) =>
                                wasSynchronouslyLoaded || frame != null
                                ? child
                                : _coinPlaceholder(size),
                        errorBuilder: (context, error, stackTrace) =>
                            _coinPlaceholder(size),
                      ),
                    ),
                  ),
                );
              }
              return Stack(children: coins);
            },
          );
        },
      ),
    );
  }
}
