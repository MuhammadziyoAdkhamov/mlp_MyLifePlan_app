# MLP UI audit: tekshirilgan tuzatishlar

2026-10-28 · `feat/mlp-beta-sprint01` · baseline HEAD `4a15b9e`.
Bu batch commit qilinmadi: ishchi daraxtda oldingi va parallel ishlar bor.
`lib/firebase_options.dart`ning oldindan staged o‘chirilishi o‘zgartirilmadi.

**31 asosiy ekran holati ko‘rib chiqildi; 10 aniq audit topilmasi tuzatildi.**
Bu butun real ilova yoki barcha native interaksiyalar 100% tayyor degani emas.

| ID | Natija | Dalil |
|---|---|---|
| UI-01 | Odat increment/undo endi umumiy error feedback orqali; saqlanmagan amal uchun tabrik yo‘q | Rejected-storage widget testi |
| UI-02 | Odatning asosiy tugmasi 48px, tooltip/semantics va keyboard aktivatsiyasi bor | 48px geometriya va action testi |
| UI-03 | Reduced motionda statik tabrik; odatiy animatsiya saqlangan; uzun matn xavfsiz kenglikda | 320px, 2× matn, motion on/off: ikki test |
| UI-04 | Dialog, custom fokus dialogi va secondary transition umumiy motion siyosatida | Modal duration va transition regressiyasi; analyze |
| UI-05 | Web ramka lokal MediaQuery va safe insets beradi; qisqa/klaviaturali oynada to‘liq layout | 1200×900 va 844×390 geometry testi |
| UI-06 | Ramka “mobil ko‘rinish namunasi” deb nomlangan; keng/mobil almashtirish ikki tomonga ishlaydi | Toggle/reverse testi |
| UI-07 | Odat rang/o‘lcham animatsiyasi shared motion durationdan foydalanadi | Shared foundation reduced-motion testi |
| UI-08 | Eski 100% demo hisoboti superseded deb belgilandi; audit/reja/ochiq to‘siqlar yangilandi | Ushbu hujjatlar va yangilangan handoff |
| UI-09 | Bosh sahifa endi hisoblangan taxminiy daily XP o‘rniga `DemoStore.xp` jami qiymatini ko‘rsatadi | Authoritative XP widget assertion va 31 PNG fixture |
| UI-10 | Pastki panel Center vertikal kengaymaydi; bar pastda qoladi | 393×852da bar height <150, bottom=852; qayta yaratilgan tasvirlar |

Oldindan mavjud chat `jumpTo` reduced-motion tuzatishi va voice → oldingi chat
navigationi yangi testlar bilan tasdiqlandi. Ular bu batchda qayta yozilmadi.

## Test va build dalillari

Loglar: `docs/evidence/ui-audit-2026-10-28/`.

| Buyruq | Natija |
|---|---|
| `flutter pub get` | Exit 0; dependencies olindi; 40 newer incompatible versions haqida ma’lumot, majburiy upgrade qilinmadi |
| Baseline `flutter test --concurrency=1 --reporter expanded` | 116/116 passed |
| Targeted `flutter test test/mlp_ui_audit_test.dart test/mlp_product_test.dart --timeout 45s --concurrency=1 --reporter expanded` | O‘sha checkpointda 23/23 passed; keyin bottom-bar regressiyasi qo‘shilgan |
| Yakuniy `flutter test --concurrency=1 --reporter expanded` | **130/130 passed**, exit 0; `final-tests.log` |
| Yakuniy `flutter analyze` | **No issues found**, exit 0; `analyze.log` |
| `flutter build web --release --optimization-level=1 --no-pub` | **Built build/web**, exit 0; brauzer ochilmadi |
| `flutter doctor -v` | Flutter 3.47.0 / Dart 3.13.0; Android license status unknown; Windows native uchun Visual Studio yo‘q |
| `flutter devices` / ADB initial check | Windows/Chrome/Edge; Android ulanmagan. `-list-avds` esa Pixel_4a topdi; native urinish natijasi remaining-issuesda |
| `flutter build apk --debug --no-pub` | **Exit 1**, Java `Unable to establish loopback connection`; `android-build.log`. Pixel_4a headless boot/ADB muvaffaqiyatli, lekin joriy APK yo‘qligi sabab app install/runtime bajarilmadi |
| Touched tracked source/tests `git diff --check` | Passed. Butun dirty daraxtdagi oldingi legacy whitespace muammolari bu batchga qo‘shilmadi |

Yangi audit test harnessining birinchi urinishida async fixture osilib qoldi;
u to‘xtatilib, setup widget-test zonasiga ko‘chirildi. Bu ilova xatosi deb
hisoblanmadi. Yakuniy suite to‘liq muvaffaqiyatli. Foiz yoki test natijasi
to‘xtatilgan run asosida yozilmadi.

## Layout / vizual dalil chegarasi

- 18 workspace/support sahifa: 320/360/390/393/430/844, 1×/1.4×/2× matn;
  safe insets, 360pxda keyboard inset.
- 10 onboarding/goal sahifa va 2 planner sahifa: 320/360/390/393/430/844/1440,
  1.4× matn, keyboard va safe insets.
- Fon sahifasi: alohida 320px/1.6× cancel/persistence/resize testlari.
- 31 real-font widget PNG qayta chiqarildi va 4 overview tasvirda ko‘rib chiqildi:
  `review-sheet-1.png` … `review-sheet-4.png`. Asl 31 PNG:
  `docs/evidence/sprint01/liquid-glass/`. Ko‘rinadigan sonlar test fixture ma’lumoti.
- Uzun sahifalar scroll qilinadi; PNG faqat boshlang‘ich viewportni ko‘rsatadi.
  Flow testlari scroll/actionlarni tekshiradi. Barcha har bir button × viewport ×
  native OS kombinatsiyasi qo‘lda sinalgan degan da’vo yo‘q.
- Native TalkBack/VoiceOver, haqiqiy gallery permission, Android gesture nav,
  physical-device FPS hali tasdiqlanmagan. UI 100% deb belgilanmaydi.

## Ushbu batch o‘zgartirgan manba fayllar

- `lib/app/theme/mlp_design_system.dart`
- `lib/core/design_system/mlp_liquid_glass.dart`
- `lib/core/design_system/mlp_confetti.dart`
- `lib/core/design_system/mlp_device_frame.dart`
- `lib/core/design_system/mlp_widgets.dart`
- `lib/features/workspace/mlp_workspace_pages.dart`
- `lib/features/focus/mlp_focus_pages.dart`
- `test/mlp_ui_audit_test.dart` (yangi, 8 regressiya)
- `test/mlp_product_test.dart`, `test/mlp_goal_flow_test.dart`, `test/mlp_planner_test.dart`

Hujjatlar: yangi audit report, ushbu fixes report va `MLP_REAL_APP_ROADMAP_UZ.md`;
yangilangan remaining issues, eski screen inventory/completion reportga joriy
holat havolasi, root TXT handoffga qo‘shimcha. Evidence PNG/loglar ham yangilangan.

Keyingi yagona chipta: **ANDROID-01**. Ilk real auditoriya IT talaba va juniorlar;
Android birinchi, iOS keyin. Production navbati va bozor dalillari
`MLP_REAL_APP_ROADMAP_UZ.md`da.
