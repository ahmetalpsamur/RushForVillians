# Elde Doğrulama Listesi — Bölüm D

APK'yı telefona kurduktan sonra sırayla. Her madde: **ne yap** → *ne görmen
gerekiyor*.

Bu makinede `flutter run` çalışmıyor (§5.3), yani aşağıdakilerin hiçbiri
cihazda denenmedi. Golden'la doğrulananlar işaretli: 🖼

---

## 0. Kurulum

1. Uygulamayı kur → *simge adı **Rush For Villains** görünmeli, `rush_for_villains` değil.*
2. Ayarlar → Uygulamalar listesinde ara → *yine **Rush For Villains**.*
3. Play Console'a yüklüyorsan sürümü kontrol et → *`0.2.0+5`; versionCode 5, bir öncekinden (4) büyük.*

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

## Bir şey ters giderse

- **Altın iki kez geldi / hiç gelmedi** → posta kutusu; `claimedMailIds` kaydı.
- **İndirim yanlış fiyat** → `discountedCost`; ekranda yazan ile düşen farklıysa bir çağrı noktası atlanmış.
- **Sonsuz koşuda sekme değişebiliyor** → `fullscreenAdventure` bayrağı.
- **Round bildirimi hiç çıkmıyor** → zafer/yenilgi roundunda bilerek bastırılıyor; ara roundda çıkmalı.
