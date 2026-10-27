# MLP UI QA — jarayonda

Baseline: `docs/evidence/sprint01/` — pub get 0; analyze 0/no issues; test 59/59. Bu natijalar yangi UI o‘zgarishlaridan OLDIN olingan. Yangi test natijalari tekshirilgach alohida qo‘shiladi.

Android debug build: exit 1, Gradle `Unable to establish loopback connection`; adb qurilma yo‘q. Android runtime va bildirishnoma yetkazish tekshirilmagan. Mavjud APK eski; yangi build sifatida tarqatilmaydi.

Phase A: markaziy ranglar va reusable komponentlar, 28 unique route registry. Phase B: mahalliy demo profil/kirish/tanlov oqimi yozildi va aktiv `main.dart`ga entry gate ulandi. Eski widget harness uchun `enableOnboarding: false` varianti mavjud; ishlab chiqarish entrypoint `true` ishlatadi. Unga alohida test qo‘shildi.

2026-10-27 checkpoint: `flutter analyze --no-pub` — No issues found; `flutter test --no-pub` — **78/78 passed**. Natijalar `docs/evidence/sprint01/flutter-analyze-ui-b.txt` va `flutter-test-ui-b.txt`da. Jarayon kompyuter uyqusi oralig‘ini ham hisoblagan juda katta elapsed vaqt ko‘rsatgan; uni faol bajarish tezligi sifatida talqin qilmang. Oldingi muvaffaqiyatsiz runlar `*-first.txt`da saqlangan.

Yangi tekshiruv: production default onboarding → demo registration → preferences save → Bugun → preferences qayta edit; guest/restart; custom goal → clarification → self-assessment → editable roadmap → persisted linked tasks; sample-test wrong/unknown 0 ball; detail edit/archive/delete/cancel; rejected platform writes, cache reload, retry va concurrent reset guard. Eski demo regressiya testlari ham o‘tdi.

10 ekran 320×640, 390×844, 844×390, 1440×900 viewportlarda, 1.4× matn va 160 keyboard inset bilan render qilindi. Bu barcha ekranlar uchun barcha interaksiya/states/semantics to‘liq qo‘lda tekshirildi degani emas. Floating tab komponenti uchun 320px/1.5× va reduced motion testi bor; asosiy shell hali ushbu tablarga o‘tmagan.

`test/mlp_visual_test.dart` 6 PNG yaratadi: `build/mlp_ui_phase_b/` ichida welcome-390, login-320, preferences-390, clarification-390, roadmap-390, goal-detail-1440. Welcome/roadmap tasvirlari font tuzatilgach ko‘rildi; qolgan tasvirlar va yakuniy UI matritsasi Phase Fda yana tekshiriladi. Bular widget renderlari, Android screenshotlari emas. Birinchi renderdagi Ahem bloklari markaziy TextTheme fonti bilan tuzatildi. Landscape Splash overflow va keyingi formani yopgan eski snackbar tuzatildi.

`flutter pub get` muvaffaqiyatli: mavjud `shared_preferences_platform_interface` 2.4.2 fault-injection testlari uchun bevosita dev dependency bo‘ldi; paket versiyasi yangilanmadi. Avvalgi worktreedagi dependency o‘zgarishlari saqlandi.

Hali talab qilinadi: barcha yangi ekranlar va ko‘ndalang oqimlar, kichik/standart/katta/landscape, klaviatura/textScale/semantics, screenshotlarni ko‘rib chiqish, yakuniy analyzer/test/web build, mavjud bo‘lsa Android runtime.
