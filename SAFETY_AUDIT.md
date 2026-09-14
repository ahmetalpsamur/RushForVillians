# SAFETY AUDIT

14 Eylül 2026 — Rush for Villains

## 1. Already existed

- Flutter uygulaması `app.dart` üzerinden avatar, rehber, dil tercihi ve oyun kaydını yükler. Mevcut RootShell sekmeleri: Ana Sayfa, Macera, Mağaza, Taverna, Profil. Envanter, demirci, ünvanlar, ödüller ve çark mevcut Navigator akışını kullanır. `BossBattleScreen` mevcut kök gezinmeye bağlı değildir.
- PedometerStepSource gerçek sensörün kümülatif adımlarını işler; sensör sıfırlanması ve adım partisi hız sınırlaması ayrı servislerde bulunur. Bu sınırlama güvenilir araç/hız algılama değildir; araç tespiti amacıyla kullanılmadı.
- GameStorage/SharedPreferences kalıcı kayıt, geciktirilmiş yazma ve arka plana geçerken flush sağlar. Savaş tohumu, can, round sonucu ve ödülün daha önce verilip verilmediği saklanır.
- Savaş hızlı dokunma veya reaction-time görevi gerektirmiyordu. Gerçek koordinatlara yönlendirme, GPS canavar yerleşimi veya uygulamada GPS takip altyapısı bulunmadı.
- Yerel bildirim, ses/titreşim ve ilgili mevcut izin altyapıları vardı. Ana sayfadaki çark geri sayımı bir sonraki hakkın açılmasını gösteriyor; düşman kaçışı veya son anda saldırı zorunluluğu oluşturmuyor.

Değişiklik öncesi checklist: adım/kayıt/GPS'siz yapı [EXISTS]; zaman baskısı, savaş geçişi, gün değişimi, bildirimler [PARTIAL]; sürümlü ilk onay, her macerada kısa uyarı, erişilebilir Güvenlik sayfası [MISSING].

## 2. Added

- İlk açılışta ana oyun oluşturulmadan tam Güvenlik Uyarısı. Checkbox olmadan Devam Et kullanılamaz. Başarılı kalıcı yazma gerçekleşmeden giriş açılmaz; hata durumunda yeniden deneme mesajı gösterilir.
- `SafetyMessages.noticeVersion = 1`; cihazdaki `accepted_safety_notice_version` ile karşılaştırılır. Sürüm yükseltilirse yeniden onay gerekir. Güvenlik metinleri Türkçe/İngilizce merkezi dosyadadır.
- Her yeni macerada ve yeni Hayat Yürüyüşü başlangıcında kısa onay. İptal, geri veya dışarı dokunma macerayı başlatmaz. Başlangıç adımı onay anında alınır; modal açıkken atılan önceki adımlar yeni maceraya sayılmaz.
- Her raund 15 dakikalık süreyle otomatik ilerler. Adım hedefi erken dolduğunda veya süre bittiğinde savaş motoru raundu çözer.
- Profilin üst çubuğundaki kalkan/Güvenlik girişi tam metni salt okunur gösterir.
- Uygulama arka plandayken kalan raund süresine göre mevcut yerel hatırlatmalar planlanır.

## 3. Modified

- Sürenin geçmesi kendi başına hasar vermiyor veya savaşı başlatmıyor. Zamanlayıcı ve lifecycle geri dönüşü savaşı otomatik çözmüyor. Düşman bekliyor.
- Süre dolduğunda eksik adım oranı düşman hasarına dönüşür; hedef erken dolarsa raund anında çözülür ve mükemmel seri ilerler.
- Raund geri sayımı, erken bitirme bonusu ve mükemmel seri göstergesi yeniden aktiftir. Macera başlangıcındaki güvenlik onayı korunur.
- Gün değişimi macerayı silmiyor. Önceki günlerin kabul edilmiş adımları `carriedSteps` ile taşınıyor. Beklerken tamamlanan fazla adımlar sonraki roundlara ve kalan yürüyüş hedefine sayılıyor. Önceden kazanılmış adım XP/coin'i tekrar verilmez.
- Kayıt şeması 21 → 22; eski kayıtlara iki yeni alanın varsayılanlarını ekleyen migration eklendi.
- Eski periyodik bildirim planlama çağrıları uygulama lifecycle akışından çıkarıldı; açılışta eski planlanmış bildirimler iptal ediliyor. Yeni mesajlar acele ettirmiyor.
- Hızlı yürüme/tereddüt baskısı ve otomatik vuruş izlenimi veren ilgili oyun/rehber metinleri düzeltildi. Eski `speedRewardMultiplier` API adı kayıt/kod uyumluluğu için kaldı; fiziksel hız ölçmez, tüketilen savaş adımlarının verimini ifade eder. Zafer damgası beklerken fazladan yürümekten etkilenmez.
- Gece ekipman etkisi açıklaması gerçek hesapla uyumlu olarak gece yapılan **savaşlara** referans veriyor; gece dışarıda yürümeyi gerektirmiyor.
- Dar macera ekranında uzun sayı taşması saptandı. StatBar yalnızca kullanılabilir genişliğe sığmayan değeri alt satıra sarıyor; sığan değerlerin eski yerleşimi korunuyor.

## 4. Potential risks remaining

- Telefonun işletim sistemi uygulamayı askıya aldığında veya kapattığında sensör olayının/bildirimin tam hedef anında teslimi garanti edilemez. Yeni background servis, GPS veya hassas izin eklenmedi. Android/iOS cihaz testi gerekiyor.
- Onay ve hatırlatmalar kullanıcının gerçekten durduğunu veya araç kullanmadığını tespit etmez. Amaç etkileşim baskısını azaltmaktır.
- Savaş zorluğu artık hedefi tamamlama süresi, düşman türü/kademesi, hedef zorluğu ve oyuncunun savunma ekipmanından türetilir. Denge eğrisi ürün testiyle izlenmelidir.
- Günlük seri, günlük çark ve günlük XP desteği mevcut takvim kurallarını korur. Bunlar son anda savaşma zorunluluğu yaratmıyor; yine de uzun vadeli davranışsal baskı açısından izlenebilir.
- Eğitimdeki ilk savaş, fiziksel yürüyüş gerektirmeyen mevcut gösterim olarak kaldı; ilk kullanım ve macera güvenlik onaylarından sonra çalışır.
- Bu çalışma hukuki sorumluluğun ortadan kalktığı varsayımına dayanmaz; öngörülebilir fiziksel riskleri ürün tasarımıyla azaltmayı amaçlar.

## 5. Files changed

| Dosya | Amaç |
|---|---|
| `lib/core/constants/safety_messages.dart` | Merkezi TR/EN güvenlik metinleri ve noticeVersion. |
| `lib/services/safety_notice_storage.dart` | Kalıcı, sürümlü onay ve kayıt hatası davranışı. |
| `lib/features/safety/safety_screen.dart` | Tam uyarı, checkbox ve kısa modal; mevcut tema/SectionCard kullanımı. |
| `lib/app.dart` | Ana oyun öncesi ilk kullanım kapısı. |
| `lib/features/root/root_shell.dart` | Macera/yeniden doğuş/savaş kapıları, hazır bildirimi, gün değişimi ve ödül entegrasyonu. |
| `lib/features/adventure/adventure_screen.dart` | Süresiz ilerleme kartı ve güvenli savaş düğmesi. |
| `lib/features/profile/profile_screen.dart` | Güvenlik sayfası girişi. |
| `lib/models/adventure_quest.dart` | Süre cezasının kaldırılması, bankalanan adımlar ve kalıcı bildirim işaretçisi. |
| `lib/services/game_storage.dart` | Şema 22 migration. |
| `lib/services/adventure_notification_service.dart` | Hedefe bağlı tek bildirim; eski bildirimlerin temizlenmesi. |
| `lib/data/pet_sayings.dart` | Güvenli oyun akışıyla uyumlu rehber ifadeleri. |
| `lib/l10n/app_tr.arb`, `lib/l10n/app_en.arb` | Süre/hız baskısı içermeyen oyun açıklamaları. |
| `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_tr.dart`, `lib/l10n/app_localizations_en.dart` | ARB kaynaklarından üretilen karşılıklar. |
| `lib/widgets/stat_bar.dart` | Dar ekranda taşan uzun değerin sarılması. |
| `test/safety_flow_test.dart` | İlk onay, sürüm, modal iptali, bekleme, bankalanan adımlar, ödül ve responsive güvenlik testleri. |
| `test/app_boot_test.dart` | İlk/ikinci açılış ve sürüm güncellemesi. |
| `test/timed_combat_test.dart` | Süre eğrisi, determinizm, saldırı sırası, ölüm, savunma ve donmuş hedef zamanı. |
| `test/combat_persistence_test.dart` | Savaşın açık kullanıcı onayıyla başlaması ve ödül/kayıt kontrolleri. |
| `test/adventure_progress_test.dart` | Güvenli ilerleme metni, macera başlangıç onayı ve görsel beklentileri. |
| `test/tutorial_guide_test.dart`, `test/revival_walk_test.dart` | Eğitim ve Hayat Yürüyüşü başlangıç onayları. |
| `test/goldens/safety_notice_320.png`, `test/goldens/safety_notice_390.png` | Yeni güvenlik ekranı görsel referansları. |
| `test/golden/goldens/adventure_320.png`, `test/golden/goldens/adventure_390.png` | Değişen macera kartının görsel referansları. |
| `SAFETY_AUDIT.md` | Bu denetim, doğrulama ve cihaz testi raporu. |

Gerçek fontlarla yerel görsel kontrol: `.dart_tool/goldens/safety_notice_320.png` ve `.dart_tool/goldens/safety_notice_390.png`. Taşma görülmedi. Portable golden testler Flutter'ın varsayılan test fontunu kullanır.

## 6. Permissions

Yeni paket, Android/iOS izni, GPS/background location veya foreground/background tracking servisi eklenmedi. Firebase dosyalarına dokunulmadı. Mevcut bildirim izni ve hareket/adım izinleri korunuyor.

## 7. Manual tests

1. Uygulama verisini temizle: açılış görseli → tam uyarı → checkbox olmadan pasif Devam Et → checkbox/onay → rehber/karakter/ana uygulama. Donanım geri tuşu oyun kapısını atlamamalı.
2. Uygulamayı kapat/aç: aynı noticeVersion için tam uyarı tekrar çıkmamalı. `noticeVersion` artırılan build'de yeniden çıkmalı.
3. Macera seç: kısa uyarıda iptal/geri/dışarı dokunmayı dene; macera başlamamalı. Onayla; her sonraki yeni macerada da aynı kısa uyarı görünmeli.
4. Modal açıkken adım at, sonra onayla: yeni macera onay anından itibaren saymalı. Günlük adımlar korunmalı.
5. Telefonu cebinde tutarak yürü: toplam hedef dolunca mümkünse tek titreşim/ses/bildirim; ekran açmadan bekle. Bekledikten ve oyun günü değişiminden sonra hedef tamamlama damgası ile adımlar korunmalı.
6. Hedef tamamlandıktan sonra yürümeye devam et: savaş hasarı artık artmamalı. Uygulamayı kapat/açıp aynı sonucu verdiğini kontrol et.
7. Savaşa Başla → kısa hatırlatmayı iptal et: can, savaş ve ödül değişmemeli. Güvenli yerde onayla: düşman saldırısı → sağ kalırsa oyuncu saldırısı → ödül. Tekrar dokunma/yeniden açma aynı ödülü çoğaltmamalı.
8. Kaydedilmiş yenilgi durumunda Hayat Yürüyüşü: kısa güvenlik onayı olmadan başlamamalı; 500 adım ve yeniden doğuş akışı korunmalı.
9. Bildirim izni reddedilmiş, sessiz/rahatsız etmeyin açık, kilit ekranı, pil tasarrufu ve uygulama sonlandırılmış koşulları Android/iOS üzerinde ayrı ayrı dene. Bildirim gelmemesi ilerlemeyi veya savaş hakkını kaybettirmemeli.
10. Profilde Güvenlik sayfasını aç; TR/EN, küçük ekran, büyük yazı ve ekran okuyucuyla metin/checkbox/düğmeyi kontrol et.

## Verification

- `flutter analyze --no-pub`: sorun yok.
- Güvenlik, açılış, macera modeli, savaş kaydı, eğitim ve yeniden doğuş için seçilmiş 60 test: tamamı geçti.
- Güvenlik ekranı 320/390 dp görsel kontrolü ve küçük ekranda %140/%180 yazı ölçeği testleri geçti.
- Son tam paket: **865 geçti, 34 başarısız** (`safety-final-results.log`).
- Aynı ortamda bağımsız temiz HEAD kaynakları: **848 geçti, 36 başarısız** (`safety-baseline-results.log`). Başarısız test adları karşılaştırıldığında son 34 hatanın tamamı HEAD koşusundaki kümenin içindedir; yeni bir başarısız test yoktur. İki önceki başarısız beklenti artık geçmektedir.
- Kalan hatalar arasında eski yerelleştirme/sayı biçimi beklentileri, mağaza XP senaryoları ve görsel referans farkları bulunuyor. Özellikle animasyonlu macera görselleri tekil çalışmada geçse de tam pakette farklı GIF kareleri üretebiliyor; tüm test paketinin yeşil olduğu iddia edilmiyor.
- Yeni güvenlik testleri, açılış sürüm kontrolleri ve cihaz fontuyla görsel doğrulama başarılıdır. Mevcut testler silinmedi veya devre dışı bırakılmadı.

Önerilen commit mesajı: `feat: add safety gates and bank walking progress for safe battles`

Commit oluşturulmadı.
## Profil dili ve yürüyüş onayı güncellemesi

- Profildeki büyük dil kartı kaldırıldı; kalkan ikonunun yanında TR / ENG kısa seçim düğmeleri kullanılıyor. Mevcut dil kaydetme ve anında uygulama geri çağrısı korunuyor.
- Her yeni macera/Hayat Yürüyüşü modalında, yürürken telefonla ilgilenilmeyeceğini belirten TR/EN checkbox eklendi. İşaretlenmeden başlatma düğmesi kullanılamıyor; onay her açılışta sıfırlanıyor.
- `lib/widgets/language_selector_card.dart` dosyasına kompakt seçim görünümü eklendi; mevcut kart diğer kullanım/testler için korunuyor.
- İlgili güvenlik/eğitim/yeniden doğuş/dil testleri: 31 geçti. `flutter analyze --no-pub`: sorun yok.
