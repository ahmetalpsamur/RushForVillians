# Elde Doğrulama Listesi — Bölüm D ve E

APK'yı telefona kurduktan sonra sırayla. Her madde: **ne yap** → *ne görmen
gerekiyor*.

Bu makinede `flutter run` çalışmıyor (§5.3), yani aşağıdakilerin hiçbiri
cihazda denenmedi. Golden'la doğrulananlar işaretli: 🖼

---

## ★ Önce bunları dene (15 madde)

Zamanın azsa yalnızca bunlar. Her biri bir bölümün en kritik maddesi;
parantezdeki numara ayrıntılı maddeye gider.

1. **Release APK'yı** kur, bir maceraya ve sonsuz koşuya gir → *Hiçbir yerde adım ekleme ya da admin düğmesi yok.* (99)
2. Eski bir kayıtla güncellemeyi kur → *Uygulama açılıyor, altın, seviye ve envanter aynı.* (57, 64)
3. Posta kutusu → *En üstte "Birleştirme hatası için özür": 750 altın + 3 çark hakkı; bir kez alınıyor.* (96)
4. Kapalı beta postasını **daha önce almış** hesapta → *Hâlâ "alındı", Erken Kalkan takılı, kod tekrar girilince "zaten kullanıldı".* (95)
5. Mağazada bir ekipmana dokun → *Onay penceresi; Vazgeç → altın aynı; Tamam → eşya envanterde.* (71, 72)
6. Mağaza düğmesine **hızlıca iki kez** dokun → *Tek pencere, tek satın alma.* (73)
7. Nadir imzalı bir eşyayı (ör. Su Kılıcı) epiğe birleştir → *2 → 3 etki; özel etki en üstte.* (60)
8. Tırpan kullanan bir sınıfla mağaza → *Hasat / Kan / Ayaz Tırpanı görünüyor; eski sıradan tırpanların nadirliği değişmemiş.* (64, 65)
9. Demirci → Filtrele → Epik → *"Filtrele (1)", çip görünüyor, sayaç "n / m".* (76)
10. Elinde olmayan bir nadirliği süz → *Boş ekran değil, sebep + "Temizle".* (78)
11. Demircide bir etkinin zarına dokun → Rastgele at → *Altın düşüyor, eski ve yeni yan yana, onaylamadan eşya değişmiyor.* (85)
12. Panel açıkken uygulamayı **kapat-aç** → *Karar paneli hâlâ orada.* (87)
13. "Yeniyi al" sonra aynı yuvada tekrar zar → *Fiyat 1,5 katı, sayaç 1.* (88)
14. Keşif kitabı (demircinin üstündeki simge) → *Atılan etkiler listede; başka bir eşyada "Keşiften seç" ile seçilebiliyor, ikinci bir onay penceresi var.* (90, 91)
15. Dili İngilizce yap, demirci ve posta kutusuna bak → *Bütün yeni metinler İngilizce; "Tier III · 2.9-4.8%" biçimi.* (74, 83)

---

## Release APK alma

Bu makinede release derlemesi **çalışıyor** (Bölüm E'de denendi; `flutter run`
çalışmıyor ama `flutter build` çalışıyor).

**Ön koşullar**

- `android/key.properties` yerinde (git dışında; içinde `storeFile`,
  `storePassword`, `keyAlias`, `keyPassword`). Yoksa derleme imzasız kalır ya
  da hata verir; dosyayı anahtarı tutan kişiden al, **repoya koyma**.
- Play Console'a yükleyeceksen `pubspec.yaml` içindeki `version: 0.2.0+N`
  satırında **N**, Play'e en son yüklenenden büyük olmalı (versionCode). Bugün
  `0.2.0+4`. Telefona elle kuracaksan değiştirmen gerekmez.
- JDK 25 kullanıyorsan önce: `flutter config --jdk-dir=<jdk-21-yolu>` (§5.1).

**Telefona kurmak için APK** (PowerShell, proje kökünde):

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Çıktı: `build\app\outputs\flutter-apk\app-release.apk`. Telefona USB ile
kurmak için: `adb install -r build\app\outputs\flutter-apk\app-release.apk`
(ya da dosyayı telefona kopyalayıp açarak kur; "bilinmeyen kaynak" izni
gerekebilir).

Daha küçük bir APK istersen (çoğu telefon arm64): `flutter build apk --release --target-platform android-arm64`.

**Play Store için App Bundle:**

```powershell
flutter build appbundle --release
```

Çıktı: `build\app\outputs\bundle\release\app-release.aab` → Play Console'a
bu yüklenir.

**Geliştirici kontrollerinin ikilide olmadığını doğrulamak** (isteğe bağlı,
madde 101): APK bir zip dosyası; `lib/arm64-v8a/libapp.so`'yu çıkar ve
`adventure-admin-panel` ara → bulunmamalı.

⚠️ **Debug APK telefona kurulan APK değil.** `flutter build apk --debug` ya da
`app-debug.apk` adım ekleme düğmesini **içerir**; test için telefona her zaman
`app-release.apk` kur.

---

## 0. Kurulum

1. Uygulamayı kur → *simge adı **Rush For Villains** görünmeli, `rush_for_villains` değil.*
2. Ayarlar → Uygulamalar listesinde ara → *yine **Rush For Villains**.*
3. Play Console'a yüklüyorsan sürümü kontrol et → *`pubspec.yaml` içindeki `+N` Play'e en son yüklenenden büyük olmalı (bugün `0.2.0+4`; bkz. "Release APK alma").*

## 1. Posta kutusu ve ödül alma

4. Ana sayfayı aç → *Posta kutusu kartının sağ üstünde kırmızı **1** rozeti.*
5. Posta kutusunu aç → *"Kapalı beta için teşekkürler" postası, altında 3 ödül çipi: 1000 altın · 5 çark hakkı · Ünvan: Erken Kalkan.*
6. "Ödülü al"a bas → *"Ödül alındı." bildirimi; altının 1000 artmış, çark hakkın 5 artmış.*
7. Posta kutusuna geri bak → *Posta **listede duruyor**, düğme "Alındı" ve tıklanamaz.*
8. Ana sayfaya dön → *Rozet **kayboldu**.*
9. Uygulamayı tamamen kapat, tekrar aç, posta kutusunu aç → *Hâlâ "Alındı"; altın ikinci kez gelmedi.*
10. Profil → Ünvanlar → *"Erken Kalkan" sahip olunanlar arasında, kaynağı **Posta**.*

## 2. Kod girme

11. Posta kutusunun üstündeki kutuya hiçbir şey yazmadan "Kullan"a bas → *"Önce bir kod yaz."*
12. `ABCDEF` yaz, Kullan → *"Bu kod geçerli değil. Yazımını kontrol et."*
13. ` weneedheroes2026 ` yaz (başta/sonda boşluk, küçük harf), Kullan → *"Kod kabul edildi. Ödülün posta kutunda." ve listede ikinci bir posta belirdi.*
14. Yeni postanın "Ödülü al"ına bas → *1000 altın + 5 çark hakkı daha.*
15. Aynı kodu tekrar gir → *"Bu kodu zaten kullandın." ve yeni posta **eklenmiyor**.*
16. Arka arkaya 5 yanlış kod gir, sonra 6.'yı dene → *"Çok fazla yanlış deneme. Biraz bekleyip tekrar dene."*
17. 10 dakika bekle, doğru bir kod dene → *Yavaşlatma kalkmış olmalı.*

## 3. İndirim penceresi

18. Erken Kalkan ünvanını **tak**, mağazayı aç → *Tepede gri şerit: "Bir macera tamamla ya da sonsuz koşuda bir canavar kes: %25 indirim 30 dakika açılır."*
19. Ünvanı **çıkar**, mağazayı aç → *Şerit **hiç görünmüyor**.*
20. Ünvanı tekrar tak, bir macerayı sonuna kadar bitir → *Mağazada şerit sarıya döndü: "İndirim açık: %25 · 30 dk kaldı."*
21. Bir ekipmanın fiyatına bak → *Normalden %25 düşük (ör. 100 → 75, 825 → 618).*
22. O ekipmanı satın al → *Düşen altın **ekranda yazan** fiyat kadar, liste fiyatı kadar değil.*
23. Uygulamayı kapat, 10 dakika bekle, aç, mağazayı aç → *Şerit hâlâ açık ama "20 dk kaldı" civarı — kapalıyken geçen süre düşmüş olmalı.*
24. 30 dakika dolana kadar bekle, mağazayı aç → *Şerit griye döndü, fiyatlar normale çıktı.*
25. Sonsuz koşuda bir canavar kes, mağazayı aç → *Şerit yeniden açık, 30 dk.*
26. Pencere açıkken ikinci bir macera bitir → *Süre **60 dk olmadı**, yeniden 30 dk oldu.*

## 4. Sonsuz koşu ekranı ve sekme kilidi 🖼

27. Macera sekmesinden Sonsuz Koşu'yu başlat → *Tam ekran savaş HUD'u: arka plan görseli, **iki taraflı** can çubuğu (solda sen, sağda canavar).*
28. Alt gezinme çubuğuna bak → ***Yok.** Sekme değiştirilemiyor.*
29. Üst şeride bak → *"N CANAVAR" başlığı ve altında büyük çarpan (ör. ×1.75).*
30. Geri sayan bir süre ara → ***Hiçbir yerde olmamalı.** Görünen tek ilerleme adım.*
31. Yürümeyi bırak, bir round süresi kadar bekle (2 dk) → *Canavar vuruyor, canın azalıyor — sayaçtan değil **sonucundan** anlıyorsun.*
32. "Macerayı bitir"e bas, onayla → *Sonuç perdesi açıldı, AppBar ve alt çubuk geri geldi.*
33. Rehber (pet) karakterine bak → *Koşu sürerken ekranda **yoktu**, bittikten sonra geri geldi.*

## 5. Round geri bildirimi

34. 2.000 adımlık bir macera başlat → *"ROUND 1/4", round hedefi 500 adım, süre 7 dakika.*
35. 500 adım yürü (ya da debug düğmesiyle ver) → *Alt kısımda bir bildirim: "Round 1 kazanıldı · N hasar vurdun", altında "Kan Dokuyan: X / Y can".*
36. Bildirimi okumadan bekleme → *En az 7 saniye ekranda kalmalı.*
37. Roundu **süresi dolmadan** bitir → *Aynı kutuda üçüncü satır: "Mükemmel round! Seri 1 · hasar ×1.16".*
38. Düşmanı devir → *Zafer perdesi açıldı; round bildirimi **çıkmadı** (perde zaten anlatıyor).*

## 6. Düşen eşya kartı 🖼

39. Zafer perdesine bak → *Altın/XP satırlarının altında bir kart: eşya görseli + adı + nadirlik rozeti (renkli çerçeve).*
40. Envanteri aç → *O eşya gerçekten envanterde.*
41. Sonsuz koşuyu bitir, sonuç perdesine bak → *Aynı tasarımda kart, farklı değil.*

## 7. Yeni tempo ve bonus yürüyüş

42. Hedef seçiciyi aç → *500 → 1 round / 7 dk · 1.000 → 2 round / 14 dk · 2.000 → 4 round / 28 dk · 3.000 → 3 round / 45 dk · 5.000 → 5 round / 75 dk · 10.000 → 10 round / 150 dk.*
43. 3.000'lik bir macerada düşmanı erken devir → *"YÜRÜYÜŞ FAZI" şeridi açıldı, kalan adım gösteriliyor.*
44. Yürüyüş fazı sahnesine bak 🖼 → *Karakter yürüyor ve **arkasında paralar yağıyor**.*
45. Yürüyüş fazında 100 adım at → *5 altın (20 adım = 1), normal 2 altın değil.*
46. Zafer ekranındaki hız ödülüne bak → *"N round · M adım — hız ödülü ×1.X" yazıyor.*
47. **500 hedefinde** düşmanı devir → *Bonus yürüyüş **açılmıyor** — bu beklenen, tek round zaten tüm macera.*

## 8. İngilizce

48. Profil → Dil → İngilizce → *Uygulama yeniden başlamadan İngilizceye döndü.*
49. Envanterde bir büyü kitabı/balta bul → *Ad sonunda **" I"**, **" II"** gibi boşluklu roma rakamı; "BookI" gibi yapışık **olmamalı**.*
50. Posta kutusunu aç → *"Thank you for the closed beta" ve ödül çipleri İngilizce.*
51. Mağazadaki indirim şeridi → *"Discount on: 25% · N min left" ya da "Finish an adventure or fell a monster...".*
52. Taverna sekmesi → *Üye adları "Mira" ve "Kano"; Türkçe ad görünmemeli.*
53. Sonsuz koşu ekranı → *Bütün etiketler İngilizce, ham `fire_sword_variant_03` gibi bir kimlik **hiçbir yerde** olmamalı.*

## 9. Ekran döndürme

54. Telefonun otomatik döndürmesini aç, uygulamayı yatay tut → *Uygulama **dikey kalmalı**.*
55. Savaş ekranındayken yatay tut → *Yine dikey.*
56. Uygulamayı kapat, telefonu yatay tutarken aç → *Açılış karesi bile dikey (kilit üç yerde birden: `main.dart`, Manifest, Info.plist).*

---

# Bölüm E

## 10. Birleştirme buff'ı (Faz E1)

57. Bölüm E'den **önce** birleştirdiğin imzalı bir eşya varsa (ör. epiğe çıkmış bir Rüzgâr Oku) güncellemeyi kur ve envanterde aç → *Eskisinden **bir** etki fazla; ilk satırlar hâlâ o eşyanın kendi özel etkisi, yeni etki **en altta**.*
58. Aynı eşyayı kapat-aç → *Etki sayısı değişmedi; ikinci açılış bir etki daha **eklemedi**.*
59. Katalogdaki bir efsaneviye bak (ör. Yıldız Düşüren) → *4 etki; ilk üçü eski özel etkiler.*
60. Nadir imzalı bir eşyayı (ör. Su Kılıcı) epiğe birleştir → *2 → 3 etki. Efsaneviye birleştir → 3 → 4.*
61. Sıradan bir eşyayı az bulunura birleştir → *2 → 3 etki (bu şerit zaten doğruydu, değişmemeli).*
62. Birleştirilmiş efsanevinin adım parası satırlarına bak → *Tek satır **%15**'i geçmiyor.*

## 11. Tek eşya tavanı (Faz E2)

63. İki ayrı "adım parası" satırı olan sıradan bir eşyayı efsaneviye kadar birleştir (ör. Orc ya da Werewolf ile) → *İki satır duruyor ama **toplamları %15'i geçmiyor**; ilk satır tam, ikincisi kırpılmış.*

## 12. Ara nadirlik basamakları (Faz E2)

64. Bölüm E'den önce elinde sıradan bir **tırpan** (ör. Zincirli/Oymalı/Yaldızlı Tırpan) varsa güncellemeyi kur → *Hâlâ sıradan, seviye kilidi aynı, kuşanılı kaldıysa hâlâ kuşanılı.*
65. Tırpan kullanan bir sınıfla (Werewolf, Slime, Greatsword Skeleton…) mağazaya bak → *Hasat Tırpanı (az bulunur), Kan Tırpanı (nadir), Ayaz Tırpanı (epik) görünüyor; görselleri sıradan tırpanlarla aynı, çerçeve rengi nadirliğe göre.*
66. Aynı mağazada fiyat ve kilide bak → *Hasat 300 altın / Sv. 4 · Kan 850 / Sv. 11 · Ayaz 3.650 / Sv. 23.*
67. Topuz kullanan bir sınıfla → *Gece Topuzu (nadir, Sv. 8, 775 altın).* Mızrak kullanan bir sınıfla → *Buz Çatalı (nadir, Sv. 9, 800 altın).*
68. Dili İngilizce yap → *Harvest Scythe · Blood Scythe · Rime Scythe · Night Mace · Frost Trident.*
69. Tırpan kullanmayan bir sınıfla (Wizard) mağazaya bak → *Bu beş eşya **görünmüyor**.*
70. Epik bir baltayı (Volkan Baltası) 8 adetle birleştir → *Efsanevi balta çıkıyor; katalogda efsanevi balta olmasa da birleştirme duvara çarpmıyor.*

## 13. Mağaza onay penceresi (Faz E2 test uyarlaması)

71. Mağazada alınabilir bir ekipmana dokun → *"Satın almayı onayla" penceresi, görsel, ad ve fiyat.* **Vazgeç** → *Altın aynı, envanter aynı.*
72. Tekrar dokun, **Tamam** → *Altın düştü, eşya envanterde.*
73. Alınabilir bir ekipmana **hızlıca iki kez** dokun → *Tek pencere açılıyor, tek satın alma oluyor, altın bir kez gidiyor.* (Karar verildi: istenen davranış.)
74. Dili İngilizce yap, aynı pencereyi aç → *"Confirm purchase", "N coins", "Cancel", "Confirm".* Türkçede → *"Satın almayı onayla", "N altın", "Vazgeç", "Tamam".*

## 14. Demirci süzgeç ve sıralama (Faz E3)

75. Demirciyi aç → *Üstte "Filtrele" düğmesi ve "Sırala: Nadirlik" menüsü; 320 dp'lik telefonda ikisi tek satıra sığıyor.*
76. Filtrele → Nadirlik: Epik + Efsanevi → Tamam → *Düğme "Filtrele (2)", altında "Epik" ve "Efsanevi" çipleri, "n / m eşya gösteriliyor".*
77. Bir çipin × işaretine dokun → *Yalnızca o süzgeç kalkıyor.* "Temizle" çipine dokun → *Hepsi kalkıyor, sıralama aynı kalıyor.*
78. Elinde olmayan bir nadirliği seç → *Boş ekran değil: "\"Az Bulunur\" süzgecine uyan hiç eşyan yok." ve "Temizle" düğmesi.*
79. Sırala → İsim → *Türkçede "Çekiç", "Zırh"tan önce geliyor.*
80. Bir süzgeç seç, demirciden çık, tekrar gir → *Seçim duruyor.* Uygulamayı kapat-aç → *Süzgeç sıfırlanmış (oturum boyunca hatırlanıyor, diske yazılmıyor).*
81. Altı etkili bir efsaneviye (birleştirilmiş) bak → *"Etkiler (6)" başlığı, altı satır, liste varsayılan açık; başlığa dokununca kapanıyor.*
82. Azrailin Tırpanı'na bak → *Dört satırda "İmza" rozeti, savunma bedelinde kırmızı "Bedel" rozeti.*

## 15. Yeniden atma ve keşif (Faz E4)

83. Kuraldan türeyen bir eşyanın etki satırına bak → *Altında "Kademe III · %2,9-4,8" gibi kademe ve aralık, sağında zar düğmesi.* İmzalı satırlarda zar **yok**.
84. Zara dokun → *Şimdiki etki, "Bu eşyada 0 kez yeniden atıldı", "Rastgele at · N altın" düğmesi, altta sarı çerçeveli ayrı "Keşiften seç · 4 kat fiyat" bölümü.*
85. Rastgele at → *Altın düştü; kartta "Yeni sonuç" paneli eskiyi ve yeniyi yan yana gösteriyor. Eşya henüz değişmedi.*
86. Panel açıkken başka bir zara dokun → *"Önce bekleyen sonuca karar ver." ve altın gitmiyor.*
87. Uygulamayı **kapat-aç**, demirciye dön → *Panel hâlâ orada (ödenmiş atış kaybolmadı).*
88. "Yeniyi al" → *Etki değişti.* Aynı yuvada tekrar zar → *Fiyat 1,5 katı, sayaç 1.* (25 → 40 → 50 → 65 → 75, sonra 75'te sabit; sıradan eşya)
89. "Eskisini koru" → *Etki aynı kaldı, altın geri gelmedi, sayaç yine arttı.*
90. AppBar'daki kitap simgesi → *"Keşfedilen etkiler" listesi; her atışın türü ve kademesi orada.*
91. **Başka bir** eşyada keşiften seç bölümünü aç → *Önceki eşyada öğrenilen ve bu yuvaya uyan etki seçilebilir.* Seç → düğme → *ikinci bir onay penceresi maliyeti söylüyor.* Onayla → *Tür ve kademe seçtiğin gibi, değer aralık içinde.*
92. Hiç keşfi olmayan yeni bir oyuncuda → *"Bu yuvaya uyan bir keşfin yok..." metni, pahalı düğme yok.*
93. Düşük seviyeli bir efsanevide zara dokun → *"Kademe V için eşya seviyesi 25 olmalı." uyarısı; atış Kademe IV'ten.*
94. Atılmış bir eşyayı birleştir → *Onay penceresinde "Yeniden atılmış etkiler birleşince sıfırlanır."*

## 16. Özür postası (Faz E5)

95. Bölüm E'den **önce** kapalı beta postasını almış ve kodu kullanmış bir hesapla güncellemeyi kur → *Kapalı beta postası "alındı" olarak duruyor, ünvan takılı, kod tekrar girilince "zaten kullanıldı".*
96. Posta kutusunun en üstünde → *"Birleştirme hatası için özür", 750 altın ve 3 çark hakkı.* Al → *Altın +750, çark hakkı +3; ikinci kez alınamıyor.*
97. Bölüm E'den önce **hiçbir şey almamış** bir hesapla → *Kapalı beta postası ve kod hâlâ alınabilir/kullanılabilir.*
98. Erken Kalkan takılıyken bir macera bitir → *Mağazada indirim penceresi açılıyor.*

## 17. Geliştirici kontrolleri (Faz E6)

99. **Release APK'yı** telefona kur, bir maceraya gir → *Sol üstte admin/adım düğmesi **yok**.* Sonsuz koşuda → *+200 düğmesi **yok**.* Ana sayfada → *adım ekleme hiçbir yerde yok.*
100. Bilgisayardan **debug** derlemesiyle aç → *Macerada sol üst panel ve +1.000/+5.000/+20.000 düğmeleri var, adım ekliyor.*
101. Release ikilisini kendin doğrulamak istersen: APK içinden `lib/arm64-v8a/libapp.so` çıkar ve `adventure-admin-panel`, `endless-simulate-200`, `+200 Steps` ara → *Hiçbiri bulunmamalı* (Bölüm E'de ölçüldü: 0; karşılaştırma `forge-filter-button`: 1).

---

## Bir şey ters giderse

- **Altın iki kez geldi / hiç gelmedi** → posta kutusu; `claimedMailIds` kaydı.
- **İndirim yanlış fiyat** → `discountedCost`; ekranda yazan ile düşen farklıysa bir çağrı noktası atlanmış.
- **Sonsuz koşuda sekme değişebiliyor** → `fullscreenAdventure` bayrağı.
- **Round bildirimi hiç çıkmıyor** → zafer/yenilgi roundunda bilerek bastırılıyor; ara roundda çıkmalı.
