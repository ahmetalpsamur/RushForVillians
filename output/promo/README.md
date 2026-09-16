# Rush for Villains — 38 saniyelik tanıtım reklamı

Güncel çıktı: **rush-for-villains-38s-fixed.mp4** — 1080 × 1920, 9:16, 30 fps, H.264 / AAC.

Konum düzeltmesi: aynı karakterin bütün animasyonları orijinal sprite tuvalindeki ortak pivot, zemin ve Idle ölçeğini kullanır. Saldırı/hasar pozları karakteri yeniden ortalamaz veya büyütmez. Class seçimindeki küçük karakter yuvaları sabittir; toplu sahnelerde karakterlerin görünür alanları ayrılmıştır. `position-verification.json`, 1140 kare ve 2970 karakter yerleşimi için kadraj/pivot kontrolünü içerir. İlk MP4 ayrıca korunmuştur.

- Senaryodaki yedi sahne ve bütün replikler kullanıldı. Türkçe altyazılar videoya işlendi; ayrıca `.srt` sağlandı.
- Pinky: projedeki Idle, Run ve Jump GIF animasyonları. Class'lar: Knight, Archer, Wizard, Swordsman. Düşmanlar: Black Knight_A, Demon_A, Flame Golem.
- Karakterler yeniden çizilmedi, yeniden renklendirilmedi veya başka tasarımlarla değiştirilmedi. Mevcut kareler piksel ölçekleme, konum ve yön animasyonuyla kullanıldı. Kamera hareketleri 2D sahneleme ile temsil edildi.
- Gelişim sahnesinde mevcut karakterlere LEVEL UP yazıları eklendi; yeni kostüm veya alternatif karakter tasarımı üretilmedi.
- Demirci görüntüsü mevcut Flutter ekranından, gerçek fontlarla ve örnek envanter durumuyla alındı. Diğer sahneler mevcut sprite'larla hazırlanmış reklam animasyonlarıdır; canlı oynanış kaydı değildir. Adım değerleri ve sağlık çubukları senaryodaki gösterime aittir.
- `StartLogo.png` stüdyo logosu olduğu için oyun adı tipografik olarak yazıldı.
- Pinky anlatımı: **yapay Türkçe ses**, tr-TR-EmelNeural. Bu, projedeki bir karakter sesinin klonu değildir. Replikler çevrimiçi ses sentez servisiyle üretildi; oyun görselleri yerelde işlendi.
- Müzik ve geçiş/vuruş/coin sesleri bu reklam için sentezlendi. Dışarıdan müzik kaydı kullanılmadı.

## Dosyalar

- `poster.png`: final ekranı.
- `storyboard.jpg`: 15 sahne anının önizlemesi.
- `encoded-review.jpg`: son MP4'ten çözülmüş kontrol kareleri.
- `asset-manifest.json`: animasyonda kullanılan görsel dosyaları.
- `narration.json`, `rush-for-villains.tr.srt`: replikler ve zaman kodları.
- `verification.json`: süre, boyut, kare sayısı, tam video çözümleme ve anlatım zamanlama kontrolü.

## Yeniden üretme

Proje kökünden, Pillow kurulu Python ile:

```powershell
python -m pip install --target output/promo/tools imageio-ffmpeg edge-tts numpy
python output/promo/voice.py
python output/promo/prepare_capture.py
flutter test output/promo/capture_test.dart --update-goldens --reporter expanded
python output/promo/render.py
python output/promo/verify.py
```

Font yolları bu Windows ortamına göre ayarlıdır. `voice.py` önceden üretilen MP3'leri tekrar kullanır. `render.py --preview` yalnızca görsel önizleme üretir. Oyun kaynakları ve mevcut test referansları değiştirilmez; üretim dosyaları bu klasörde tutulur.
