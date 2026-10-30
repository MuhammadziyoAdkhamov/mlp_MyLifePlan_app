> **2026-10-30:** 27 ekranli yangi namuna bo‘yicha o‘zgarishlar davom etmoqda. Quyidagi eski test/render natijalari joriy kodga avtomatik tatbiq etilmaydi. Yangi holat: `MLP_UI_PROGRESS.md`; yangi loglar: `evidence/ios-reference-2026-10-29/`.

# MLP UI yakuniy QA hisoboti

2026-10-27. UI source checkpoint: `9520df6`, branch `feat/mlp-beta-sprint01`. Barcha 28 ekran mahalliy prototip oqimida yozilgan. Android yopiq beta uchun native build/runtime gate hali ochiq. To‘liq inventar: `MLP_UI_SCREEN_INVENTORY.md`.

## Buyruqlar va aniq natijalar

| Buyruq | Natija | Dalil |
|---|---|---|
| flutter analyze --no-pub | exit 0, No issues found, 46.6s | evidence/sprint01/flutter-analyze-product-final.txt |
| flutter test --no-pub --concurrency=1 --reporter expanded | exit 0, **106/106 passed**, 93s | evidence/sprint01/flutter-test-full-product-final.txt |
| flutter build web --release --no-pub --no-wasm-dry-run --optimization-level=1 | exit 0, Built build/web, 101.7s | evidence/sprint01/flutter-build-web-product-final.txt |
| flutter build apk --debug --no-pub --target-platform android-arm64 | exit 1, Java Unable to establish loopback connection, 49.1s | evidence/sprint01/flutter-build-android-product.txt |
| flutter doctor -v / flutter pub get | Oldingi baseline dalillari saqlangan; bu UI checkpointda dependency versiyasi o‘zgarmagan | evidence/sprint01/flutter-doctor.txt; flutter-pub-get.txt |

Web O1 optimizatsiyasi va WASM dry-runni o‘chirish faqat ushbu hostdagi kam joy/compile yukini kamaytirish uchun. Build `lib/main.dart`dan olingan. Build muvaffaqiyati alohida, brauzer runtime tekshiruvi alohida qayd etilgan. Eski APK yangilanmagan.

## Tekshirilgan ish oqimlari

- Production entry → demo registration/preferences → Bugun, guest/restart va keyingi preferences edit.
- Erkin maqsad → clarification → diagnosis/self-report → tahrirlangan roadmap → bitta persisted goal va linked tasks; rollback/retry va competing-write guard.
- Calendar kun/hafta/oy, recurrence/leap/boundary, conflict/adjacency, capacity de-dup, warning cancel/confirm, save/edit/delete, Duolingo external-unavailable va self-report.
- Today → linked focus → injected clock bilan 53 haqiqiy soniya → summary qaydi → saqlash. Task avtomatik bajarilmaydi. Background pause, restart paused, fixed-clock unique IDs, idempotent retry va break exclusion.
- Deterministik chat send/persist/restart, rejected write uchun pair rollback, context opt-in va tone adapter; ovoz holatlari faqat UI sifatida belgilangan.
- Uch savolli test: unknown/wrong 0 ball, score qayta hisoblanadi, self-report va focusdan alohida; XP oshmaydi. Passport va growth manba holatidan olinadi.
- Virtual reward lock/claim/selection, Soundspace favorite persistence va audio-unavailable dialog, dismissible launcher, source notifications.
- Barcha tablar va secondary route dispatch, missing ID/draft/unknown route recovery, system back va focus pause. Focus ring semantikasi uning tugmalaridan ajratilgan. Floating tablarda selected va tap semantics bor.

## Responsive va vizual tekshiruv

Oldingi 10 onboarding/goal + calendar/editor ekranlari: 320×640, 390×844, 844×390, 1440×900; 1.4× matn, 160 keyboard inset, reduced motion. Yangi 16 ekran: 320×740, 390×844 1.4×, 430×932 2.0×, 844×390. Bular widget tekshiruvlari; barcha platform date/time picker va fizik screen-reader holatlari degani emas.

16 real-font widget PNG qayta yaratildi va `evidence/sprint01/ui-latest/`ga nusxalandi: welcome, login, preferences, clarification, roadmap, goal detail, calendar/editor, today, focus, chat, profile, growth, rewards, weather, Soundspace. Asosiy mobil tasvirlar ko‘rib chiqildi. Logotip dekorativ bo‘lib, fixed text scale va alohida semantik yorliqqa ega; qolgan matn tizim scale’iga moslashadi.

Brauzerda topilgan va tuzatilgan xatolar:

1. Dark theme custom TextStyle ranglari ayrim web sarlavhalarida qora bo‘lib qolgan — body/display ranglari aniq berildi va regressiya testi qo‘shildi.
2. Ustoz overlay tugmasi fokusning asosiy tugmasiga chiqib qolgan — launcher pastki navigatsiya ustidagi o‘z joyiga ko‘chirildi.
3. Progress semantics card controls bilan qo‘shilgan — timer halqasi alohida semantik chegaraga ega qilindi.
4. 320px katta matnda dekorativ logo o‘ralib overflow bergan — dekorativ logo fixed scale, label alohida.
5. Nested Navigator dastlabki pushda snackbar tozalashi build paytida setState qilgan — observer post-framega o‘tkazildi.

## Haqiqiy web runtime

Codex in-app brauzerida `http://127.0.0.1:8765/` orqali joriy release web build ochildi. Guest profil yaratildi va reload bilan tiklandi. Bugundan vazifali fokus boshlandi; **15 soniya** ishladi; “UI sinovi: fokus oynasi va saqlash oqimi tekshirildi.” qaydi bilan saqlandi. Tarix 7 tadan 8 sessiyaga o‘tdi. Sahifa qayta yuklanganda 15 soniyali sessiya va qayd ochildi. Vazifa o‘z-o‘zidan topshirilmadi.

Ustozga “Flutter nima?” savoli berildi. Belgilangan demo javob paydo bo‘ldi va reload → Ustozdan keyin qayta ko‘rildi. Javobda jonli model emasligi aniq aytilgan. Brauzer tab Bugun ekranida ochiq qoldirildi; local server ishlayotganida namoyish qilish mumkin.

Runtime PNG: `web-today.png`, `web-active-focus.png`, `web-chat.png`, `web-chat-restored.png`, `web-focus-restored.png`. `web-welcome-before-contrast.png` tuzatishdan oldingi diagnostik dalil; yakuniy welcome tasviri `ui-latest/welcome-390.png`.

## Host cheklovlari va dastlabki runlar

Parallel full test target device full / OS error112 bilan test dill faylini nusxalay olmadi. C: diskida taxminan 250MB joy qolgan. Generated cache cleanup avtomatik siyosat tomonidan rad etildi; hech qanday foydalanuvchi fayli o‘chirilmadi. O‘chirishsiz `--concurrency=1` bilan yakuniy 106 test o‘tdi. Dastlabki failed/cancelled runlar diagnostika uchun saqlangan; yakuniy dalillar `*-final.txt` fayllari.

Birinchi product fixture runlarida setup future zonasi, scroll layoutdan oldin tap va SemanticsHandle teardown xatolari tuzatildi. UI boshqaruvlarini qayta bosishdan oldin layout tekshirildi; assertlar olib tashlanmadi. Yakuniy natija yuqoridagi to‘liq regressiyada.

Android emulator/fizik qurilma runtime, TalkBack/VoiceOver, real push delivery, live auth/AI/weather/audio va release signing tasdiqlanmagan. Ular ishlaydi deb ko‘rsatilmaydi. Keyingi bitta chipta: **F-ANDROID-01** (`MLP_UI_REMAINING_ISSUES.md`).
