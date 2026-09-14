# Rush for Villains — Combat Audit

## İncelenen mevcut yapı

- Macera seçimi `RootShell` içinde güvenlik onayından sonra otoriter `AdventureQuest` kaydını oluşturuyor.
- Adımlar tek giriş noktası olan `_onStepsReported` üzerinden günlük ilerlemeye ve aktif maceraya yazılıyor.
- Oyuncu statları seviye, ekipman, seri bonusları ve koşullu etkiler birleştirildikten sonra savaş modeline veriliyor.
- Düşman statları katalogdaki tür/kademe değerlerinden geliyor. Hedef zorluğu ayrıca merkezi çarpanla uygulanıyor.
- Zafer, yenilgi, XP/coin, ölüm animasyonu ve Hayat Yürüyüşü mevcut `AdventureQuest` terminal durumları üzerinden devam ediyor.

## Uygulanan savaş akışı

1. Macera güvenlik onayı kabul edilince başlıyor.
2. Toplam hedef, en fazla 1.000 adımlık raundlara ayrılıyor; 10.000 adımlık macera 10 raund sürüyor.
3. Her raund 15 dakikalık geri sayımla başlıyor. Adım hedefi erken dolarsa raund hemen ve otomatik çözülüyor.
4. Süre dolarsa o ana kadar tamamlanan oranla raund otomatik çözülüyor; eksik oran düşman saldırısının gücünü belirliyor.
5. Oyuncu ve düşman saldırıları mevcut stat, savunma, zırh, kaçınma, kritik ve eşya kurallarıyla çözülüyor.
6. Düşmanın canı raund raund azalıyor; terminal zafer mevcut animasyon ve ödül akışını çalıştırıyor.
7. Oyuncu ölürse mevcut yenilgi ve Hayat Yürüyüşü akışı açılıyor.
8. Uygulama arka plandayken mutlak raund süresi ilerliyor; dönüşte kaçırılan raundlar sırayla hesaplanıyor.
9. Düşman saldırısı olduğunda sonuç sahnesi 2,4 saniye bekliyor; alınan hasar ile kalan/maksimum canı gösteriyor.

## Denge kaynağı

Raund hedefleri `AttackConfig`, savaş hesabı `combat_engine.dart`, oyuncu ve düşman statları mevcut stat yardımcıları tarafından belirlenir. Savaş tohumu kayıtta tutulduğu için sonuçlar yeniden açılışla değişmez.

## Kalıcılık ve geçiş

- Kayıt şeması `v23` oldu.
- Başlangıç ve hedef tamamlama zamanları ISO-8601 olarak yazılıyor.
- `v22 → v23` geçişi eklendi. Eski aktif kayıtta başlangıç güvenli biçimde türetiliyor; tamamlanmış hedef damgası ilk uygun yükleme/adım akışında o an sabitleniyor.
- Savaş tohumu, hedef damgası, canlar ve terminal sonuç kayıtta kaldığı için uygulamayı kapatıp açmak yeni zar attırmıyor.

## Debug gözlemlenebilirliği

Raund sonucu, canlar, saldırı sırası ve savaş tohumu mevcut model alanlarından debug sırasında incelenebilir. Release arayüzünde iç denge çarpanları gösterilmez.

## Otomatik doğrulama

- Hızlı, normal, hafif geç ve çok geç tamamlama eğrisi.
- Aynı seed ve girdilerle deterministik sonuç.
- Düşmanın ilk saldırması; sağ kalan oyuncunun ikinci ve öldürücü saldırısı.
- Ölümcül ilk saldırıdan sonra oyuncu vuruşunun oluşmaması.
- Savunma/zırhın hasarı azaltması.
- Hedef zorluğunun hasarı artırması.
- Toplam hedef dolmadan savaşın çözülmemesi.
- Hedef damgasından sonra günlerce beklemenin gerçek süreyi ve hasarı değiştirmemesi.
- Zaman damgalarının JSON kayıt turunda korunması.
- Türkiye bölgesinde ilk sistem dilinin Türkçe seçilmesi ve kayıtlı manuel tercihin korunması.

## Manuel cihaz kontrol listesi

1. Yeni macera başlat; güvenlik onayını iptal ederek maceranın başlamadığını doğrula.
2. 2.000 adımlık hedefte 1.000 adımda savaş düğmesinin görünmediğini kontrol et.
3. Hedefi tamamla; bildirimi al, telefonu güvenli yerde daha sonra aç ve savaşı onayla.
4. Düşman saldırı animasyonunun önce, oyuncu sağ kalırsa oyuncu saldırısının sonra oynadığını doğrula.
5. Ölümcül denge senaryosunda oyuncu saldırısı ve zafer ödülü oluşmadığını, Hayat Yürüyüşünün açıldığını doğrula.
6. Aynı düşmanda zırhlı/zırhsız sonuçları debug loguyla karşılaştır.
7. Cihaz dili İngilizce, bölgesi Türkiye iken temiz kurulumda Türkçe açılışı; ardından elle ENG seçip yeniden açıldığında İngilizcenin korunmasını kontrol et.

## Kalan sınırlar

- İşletim sistemi uygulamayı askıya aldığında pedometer olayını tam fiziksel adım anında teslim etmeyebilir; damga uygulamanın aldığı ilk hedefe ulaşmış raporun zamanıdır.
- Denge katsayıları otomatik olarak doğrulanıyor ancak gerçek cihaz yürüyüş dağılımları ve farklı ekipman setleriyle ürün dengelemesi yine gerekir.
- Yeni izin, GPS, arka plan konum servisi veya paket eklenmedi.
