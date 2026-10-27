# MLP yakuniy topshirish — 2026-10-27

## A. Joriy holat

28 ekranli mahalliy UI prototip ulangan. Asosiy tablar Bugun / Maqsadlar / Fokus / Ustoz / Profil. Foydalanuvchi bergan iOS uslubidagi qoramtir, firuza va binafsha ko‘rinish qo‘llandi. MLP gradient belgisi, kodda chizilgan ufq, kartalar, haqiqiy aylana taymer va pastki navigatsiya bor. Mavjud CRUD/import/eksport/odat oynalari o‘chirilmagan.

Faol entrypoint `lib/main.dart`; source commit **9520df6**; branch **feat/mlp-beta-sprint01**. Source commitda 22 fayl, 4943 qo‘shilgan qator va 39 olib tashlangan qator bor; katta ekran rewrite o‘rniga mavjud data store saqlanib, yangi UI qatlamlari qo‘shildi. Userning oldingi dirty o‘zgarishlari, jumladan oldindan staged bo‘lgan `lib/firebase_options.dart` deletion source commitga kiritilmadi.

Yangi fayllar: `lib/app/mlp_environment.dart`, `lib/app/mlp_product_shell.dart`, `features/focus` controller/pages, `features/ai_companion`, `features/progress`, `features/lifestyle`, `features/workspace` va `test/mlp_product_test.dart`. Yangilanganlar: theme/widgets, routes, UI repository, schedule model, DemoStore/Review/App, onboarding, main va tegishli testlar. To‘liq ro‘yxat: `git show --stat 9520df6`.

## B. Eng muhim 10 cheklov va keyingi ustuvorlik

1. P0: Android build Java loopback xatosida to‘xtaydi — yangi APK yo‘q.
2. P0: host C: diskida joy juda kam; parallel compile/test ishlamay qolishi mumkin.
3. P1: fizik Android/emulator yo‘q; native smoke va TalkBack tekshiruvi kerak.
4. P1: eski oddiy core CRUD memory-first; rejected disk write xatosi va Retry ko‘rinadi, lekin barcha eski amallar rollbackga o‘tmagan.
5. P1: to‘liq core+UI backup olinadi, ammo UI bundle import hali mavjud emas; eski core JSON import alohida.
6. P1: eslatma faqat niyat va reja. Platform notification yetkazish ulanmagan.
7. P2: haqiqiy SMS/Google active-root auth ulanmagan; demo profil tasdiqlanmagan va umumiy qurilmadagi data alohida accountlarga ajratilmagan.
8. P2: Ustoz deterministik mock; voice faqat holat UI. Jonli AI/STT/TTS yo‘q.
9. P2: weather preview, Soundspace audio mavjud emas, yutuqlar virtual. Pul/hamkor fulfillment yo‘q.
10. P2: iOS build, barcha native picker holatlari, juda katta tarix va 24 soatlik lifecycle sinovi bajarilmagan.

7–9 bandlar yashirin nuqson sifatida berilmagan: prototipda aniq ko‘rsatilgan integratsiya chegaralari. Production tayyor deb talqin qilinmaydi.

## C. Tekshiruv dalillari

- Analyzer: No issues found, exit 0.
- Full regression: **106/106 passed**, exit 0, serial mode.
- Joriy web release: muvaffaqiyatli, exit 0; O1 va WASM dry-run o‘chirilgan.
- Android debug: exit 1, `Unable to establish loopback connection`.
- ADB: ulangan qurilmalar yo‘q.
- Brauzer smoke: guest → Today → 15s focus → note save → history, mock chat → reload → record/chat restore.
- 16 real-font widget PNG va runtime screenshotlar saqlandi.

Aniq buyruqlar/loglar: `MLP_UI_QA_REPORT.md`. Ekranlar/interaksiyalar: `MLP_UI_SCREEN_INVENTORY.md`. Qanday namoyish qilish: `MLP_DEMO_RUN_UZ.md`.

## D. Hozir ochish

http://127.0.0.1:8765/ — shu kompyuterdagi joriy demo, server sessiyasi ishlayotganida ochiladi. Codex brauzer tabida ham qoldirildi. Public serverga deploy qilinmagan. Serverni qayta ishga tushirish:

```powershell
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

## E. Keyingi faqat bitta chipta

**F-ANDROID-01 — host/build muammosini hal qilib, joriy commitni fizik Androidda smoke testdan o‘tkazish.** Qabul mezoni: guest/custom goal/linked task/schedule intent/real focus/report/sample assessment/restart; background pause/back/keyboard/large text. Build log, qurilma ma’lumoti va haqiqiy screenshotlar yoziladi. Firebase qoidalarini yumshatish, avtomatik license tasdiqlash yoki eski APKni yangi deb ko‘rsatish qilinmaydi.
