# MLP UI qolgan ishlar va beta chegaralari

2026-10-27: 28 ekran mahalliy UI prototip sifatida yozildi; yangi besh tabli shell faol. Ekranlar ro‘yxati va tekshirilgan holatlar `MLP_UI_SCREEN_INVENTORY.md`da. UI prototip va Android yopiq beta tayyorligi alohida baholanadi.

1. **P0 — Android qurilmada yakuniy tekshiruv.** Qurilma/emulator yo‘q. Oldingi Gradle urinishida Java loopback xatosi bo‘lgan. Yangi APK isbotlanmaguncha eski APKni yangi deb tarqatmang. iOS native build bu Windows hostda tekshirilmagan.
2. **P0 — host disk sig‘imi.** Umumiy parallel test C: diskida nusxa yozish uchun joy yetmasligi bilan to‘xtadi. Kam resursli ketma-ket run alohida bajariladi. Task generated cache cleanup avtomatik siyosat tomonidan bloklandi; foydalanuvchi fayllari o‘chirilmagan.
3. **P1 — oddiy eski core CRUD saqlov semantikasi.** DemoStore oddiy task/habit/goal o‘zgarishlarini avval xotirada ko‘rsatadi; disk xatosida xato va Retry bor. Goal+roadmap va yangi batafsil fokus yozuvi rollbackga ega, UI repository commit-before-publish. Qolgan core operatsiyalarni xavfsiz transactionga o‘tkazish keyingi backend/data ishidir.
4. **P1 — to‘liq UI bundle import.** Sozlamalardan ikkala kalitni qamragan JSON nusxa olinadi. Eski JSON import faqat core store uchun. UI bundle import hali mavjud emas va ekranda aniq aytilgan. Turli formatni noto‘g‘ri importerga bermang.
5. **P1 — native accessibility va platform pickers.** Widget semantics/large text/back tekshiruvlari mavjud; fizik Android TalkBack/iOS VoiceOver, barcha native date/time picker holatlari, 24 soatlik lifecycle va haqiqiy klaviatura uchun qurilma testi kerak.
6. **P2 — yirik tarix va jadval.** Prototip cheklovlari bor: 500 schedule, 100 chat xabari, cheklangan dashboard preview; eski to‘liq data oynasi ochiladi. Katta production tarix uchun paging/backend kerak.
7. **P2 — umumiy qurilma hisoblari.** Demo logout ma’lumotni saqlaydi; yangi demo ism alohida xavfsiz account yaratmaydi. Mahalliy JSON shifrlanmagan. Bu chegaralar profil va maxfiylik oynasida aytilgan.

Quyidagilar UI scope ichida aniq preview/unavailable sifatida tugatilgan, ishlayotgandek ko‘rsatilmaydi: haqiqiy SMS/Google login, live AI, STT/TTS/mikrofon, joylashuv/jonli ob-havo, audio fayllar/real sleep playback, Android/iOS xabarnoma yetkazish, pullik obuna, hamkor sovg‘alari. Wakeword, tizim overlay va yangi production backend qo‘shilmagan. Firebase egalik qoidalari o‘zgartirilmagan.

**Keyingi bitta chipta: F-ANDROID-01 — joriy commitdan Android build va fizik qurilmada smoke test.** Qabul mezoni: guest → custom goal → task → schedule reminder intent → 1 daqiqa real fokus → qayd saqlash → self-report → namuna test → restartda ma’lumot saqlanishi. Back, keyboard, background pause, 320px va katta matn tekshiriladi. Build log, qurilma modeli/Android versiyasi va real screenshot dalili yoziladi. Yetkazish ulanmaguncha eslatma keladi deb va’da qilinmaydi.

Yakuniy dalil: 106/106 test passed; analyzer no issues; web release built va brauzerda focus/chat/reload tekshirildi. Source checkpoint `9520df6`. Batafsil yakuniy holat `MLP_UI_QA_REPORT.md` va `MLP_UI_FINAL_HANDOFF_UZ.md`da. Android build yangi urinishda ham Java loopback exit1 berdi; yangi APK olinmadi. ADB ro‘yxati bo‘sh.
