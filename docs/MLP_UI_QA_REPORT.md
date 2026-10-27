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

## C02/C03 — taqvim checkpoint, 2026-10-27

`MLPSchedule` va `MLPScheduleResult` domain modellari, `MLPScheduleRepository` interfeysi va mavjud UI saqloviga adapter qo‘shildi. Eski UI JSONga `scheduleResults: []` default qo‘shiladi; eski kalitlar migratsiyasiz saqlanadi. Kunlik/ish kuni/haftalik/bir martalik takror, inclusive until, canonical sana, xavfsiz http(s) havola, vaqt chegaralari va per-day self-report bor. UI saqlov hajmi chegarasidan oshgan yozuv avval rad etiladi; restartda yaroqsiz zaxira hosil qilinmaydi.

Calendar main headerdan ochiladi; kun/hafta/kompakt oy ko‘rinishi va lazy ro‘yxat bor. Editor CRUD, goal/task bog‘lash, sanalar, soatlar, reminder intent, overlap va sig‘im tasdig‘i bilan ishlaydi. Kunlik yukda vazifa taxmini takror sanalmaydi va qisqa calendar bloki qolgan vazifa mehnatini yashirmaydi. Eski recurring series tahririda kelayotgan hafta tekshiriladi. Tashqi ilova ochish aniq unavailable; havolani nusxalash mumkin. Natija faqat sessiya tugagach o‘z hisoboti sifatida yoziladi, task completion/XP/malaka tasdig‘iga avtomatik aylantirilmaydi.

`test/mlp_planner_test.dart`: **12/12 passed** — recurrence/leap/boundaries, uzoq kelajakda boshlanadigan series conflict, adjacent slot, capacity de-dup, persist/edit/delete, per-occurrence update, future report rejection, corrupt recovery, Duolingo create→calendar→unavailable→report, warning cancel/confirm, old-series workload, 4V layout. Fault-injection testida rejected schedule save/delete eski data va qayta urinishni saqlaydi.

Yakuniy full regression: **91/91 passed** (24s), `flutter-test-planner-regression.txt`. Full analyzer no issues (123.8s); undan keyingi chip-font va eski-series edge-case uchun yakuniy scoped analyze ham **No issues found**. Dalillar: `dart-analyze-planner-final.txt`, `flutter-analyze-planner.txt`, `flutter-test-planner.txt`.

Calendar-390 va schedule-editor-390 PNGlar `build/mlp_ui_phase_b/`da yaratildi va ko‘rildi. Chip shriftining fixture fallback muammosi theme’da tuzatildi; fresh calendar tasvirida barcha chip matnlari o‘qiladi. 320/390px dropdown overflowlari tuzatildi. Populated calendar cards, result sheet va date/time pickerlarning barcha viewport, textScale 2.0 va screen-reader holatlari hali Phase Fga qolgan. Main shell hali eski 5 bo‘limli navigatsiyani saqlaydi; yangi floating tab componentining o‘zi mavjudligi C01 bajarilgan degani emas.
