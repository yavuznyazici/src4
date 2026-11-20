# SRC4 Sınav Hazırlık

SRC4 (yurtiçi eşya-kargo taşımacılığı) sınavına hazırlık için çevrimdışı çalışan Flutter uygulaması.

## Özellikler
- 250 özgün, dört seçenekli çalışma sorusu
- Doğru/yanlış cevapta anında renkli geri bildirim ve açıklama
- İlk çözümde yanlış yapılan soruları tekrar çözme
- Cihazda saklanan ilerleme ve istatistikler
- Konu bazında başarı görünümü ve rozetler
- GitHub Actions ile release APK üretimi

## Yerel çalıştırma
1. Flutter SDK (stable) kurun.
2. Depoyu klonlayın.
3. `flutter pub get`
4. `flutter run`

## APK üretme
`flutter build apk --release`

APK: `build/app/outputs/flutter-apk/app-release.apk`

GitHub'da Actions sekmesinden **Build Android APK** iş akışını çalıştırın. Tamamlandığında `src4-sinav-hazirlik-apk` artifact'ini indirin.

## Soru bankası hakkında
Sorular eğitim amacıyla hazırlanmış özgün deneme sorularıdır; resmî çıkmış sınav soruları değildir ve resmî kurumlarca onaylandığı anlamına gelmez. Mevzuat, belge kapsamı, süreler, ağırlık/ölçü sınırları ve idari uygulamalar değişebileceğinden sınav öncesinde güncel Ulaştırma ve Altyapı Bakanlığı duyuruları ile yürürlükteki mevzuat kontrol edilmelidir.

## Proje yapısı
```text
src4_sinav_hazirlik/
├── .github/workflows/build-apk.yml
├── assets/questions.json
├── lib/main.dart
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```
