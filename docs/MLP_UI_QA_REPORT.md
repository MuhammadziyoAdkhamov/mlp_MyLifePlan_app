# MLP UI QA — jarayonda

Baseline: `docs/evidence/sprint01/` — pub get 0; analyze 0/no issues; test 59/59. Bu natijalar yangi UI o‘zgarishlaridan OLDIN olingan. Yangi test natijalari tekshirilgach alohida qo‘shiladi.

Android debug build: exit 1, Gradle `Unable to establish loopback connection`; adb qurilma yo‘q. Android runtime va bildirishnoma yetkazish tekshirilmagan. Mavjud APK eski; yangi build sifatida tarqatilmaydi.

Phase A: markaziy ranglar va reusable komponentlar, 28 unique route registry. Phase B: mahalliy demo profil/kirish/tanlov oqimi yozildi va aktiv `main.dart`ga entry gate ulandi. Eski widget harness uchun `enableOnboarding: false` varianti mavjud; ishlab chiqarish entrypoint `true` ishlatadi. Unga alohida test qo‘shildi.

Qo‘shilgan testlar: route unique/unknown; telefon/ism validatsiyasi; identifikatsiya tasdiqlanmaganligi; legacy kalitni saqlash; restartdan tiklash; buzilgan saqlovni o‘zgartirmaslik; mehmon kirishi; registration→preferences; 320px/katta matn/reduced motion. Ishga tushirish natijasi hozir kutilmoqda.

Hali talab qilinadi: barcha yangi ekranlar va ko‘ndalang oqimlar, kichik/standart/katta/landscape, klaviatura/textScale/semantics, screenshotlarni ko‘rib chiqish, yakuniy analyzer/test/web build, mavjud bo‘lsa Android runtime.
