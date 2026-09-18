# Rush for Villains — tamamlanan Reels paketi

Ana teslim: `Rush-for-Villains-A-FINAL.mp4`.

- A, B ve C tam sürümler: 23.000 saniye, 1080 × 1920, 9:16, 30 fps, 690 kare, H.264/AAC.
- `opening-B-2s.mp4` ve `opening-C-2s.mp4`: bağımsız alternatif açılışlar, tam 2.000 saniye / 60 kare.
- `subtitles-A.srt`, `subtitles-B.srt`, `subtitles-C.srt`: ayrı İngilizce altyazılar; okunabilir metinler videolara da işlendi.
- `poster.png`: final kompozisyonu. `encoded-review.jpg`: son MP4'ten kontrol kareleri.
- `verification.json`: süre, çözünürlük, kare sayısı, tam video çözümleme, ses seviyesi ve ortak bölüm kontrolü.

## Uygulama kaydının kaynağı

Mevcut proje `flutter build web --debug` ile derlendi. Ayrı ve yerel bir Chrome oturumunda uygulama arayüzü kullanılarak karakter oluşturuldu, eğitim tamamlandı, 2.000 adımlık Night Oath macerası seçildi ve uygulamanın kendi demo adım kontrolü kullanıldı. Ham ekran kaydı `raw/page@b634b8f3e003245e5cbe5e5302c52441.webm` dosyasındadır; kesit zamanları `source-cuts.json` içindedir.

Bu fiziksel yürüyüş veya Android cihaz sensör kaydı değildir. Videodaki uygulama sahnelerinde **IN-APP FOOTAGE · DEMO STEPS** etiketi bulunur. Arayüz yapay zekâyla çizilmedi; uygulamadaki sonuç ve sayılar değiştirilmedi. Uygulama görüntüsünün toplam süresi 14,5 saniyedir.

Uygulama bu oturumda savaşı ilk 1.000 adımda kazandırdı ve kalan 1.000 adım için yürüyüş fazına geçti. Bu nedenle sonuç bölümünde **Battle won. Walk continues.** ifadesi ve uygulamanın kalan adım açıklaması korunur. Görünen gerçek savaş ödülü **+16 coin ve +176 XP**. Bunlar bütün oyuncular için vaat edilen sabit ödüller değildir. Macera tamamlanmış gibi sunulmaz.

## Son kurgu

| Süre | İçerik |
|---|---|
| 0–2 | Özgün Pinky sprite'ı ile hareketli, açıkça kurgusal piksel park açılışı. A/B/C burada farklıdır. |
| 2–6 | Gerçek uygulamadan hedef seçimi ve Night Oath ayrıntıları; 2.000 adım hedefi okunur. |
| 6–7,25 | Pinky çevresine bakarak yürür; telefon kullanmaz. |
| 7,25–9,75 | Gerçek uygulamanın savaş öncesi adım hedefi ve ilerleme ekranı. |
| 9,75–11 | Farklı yürüyüş anı, “Later in the walk...” yazısı; Pinky durur. |
| 11–11,8 | Gerçek kayıttan son savaş animasyonu. |
| 11,8–15 | Aynı maceranın gerçek sonucu ve ödülü. Son 0,75 saniyede Pinky'nin gururlu tepkisi. |
| 15–19 | Mavili: “You went around the block.” Pinky: “A legendary block.” Kısa sessiz duraklama. |
| 19–23 | Uygulama adı, gerçek yürüyüş fazı görüntüsü, Pinky ve sabit Android kapalı beta çağrısı. |

Pinky ve Mavili için projedeki özgün GIF kareleri kullanıldı; yeniden çizilmediler. Kadraj hareketi ve poz geçişleriyle oyunculuk sağlandı. İngilizce sesler sentetiktir: Pinky için AvaMultilingualNeural, Mavili için AndrewMultilingualNeural. Müzik ve kısa efektler bu kurgu için yerelde sentezlendi. Başka konuşan karakter yok.

## Doğrulama

- Üç tam videonun her biri 690 kare; iki alternatif açılışın her biri 60 kare.
- B/C'nin 2. saniyeden sonraki kaynak ses örnekleri A ile birebir aynı.
- Kodlanmış ortak görüntüler küçültülmüş kare karşılaştırmasında sıfır piksel farkıyla geçti.
- Beş teslim videosunun tamamı hatasız çözümlendi.
- Tam videoların ölçülen sesi yaklaşık −15 LUFS-I, tepe değeri yaklaşık −3 dBTP; konuşma sırasında müzik kısılır.
- Son MP4'lerden alınan kareler görsel olarak kontrol edildi. Gerçek Instagram uygulamasında yayın önizlemesi yapılmadı; hiçbir paylaşım yapılmadı.

## Instagram açıklaması

Your daily walk becomes a side quest. A legendary block still counts. ⚔️ Rush for Villains is in Android closed beta. Join through the link in bio.

## Dosya değişiklikleri

Yeni kurgu, kayıt, ses, altyazı ve doğrulama dosyaları `output/promo/side-quest-23s` altında. Yerel kurgu bağımlılıkları çıktı klasörlerine kuruldu. Uygulama kaynak kodu değiştirilmedi; commit atılmadı.

İsteğe bağlı commit mesajı: `feat(promo): add recorded 23-second side quest reels`
