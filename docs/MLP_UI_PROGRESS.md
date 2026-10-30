# MLP — 27 ekranli namuna bo‘yicha UI holati

Yangilanish: 2026-10-30. Holat: davom etmoqda, 100% emas.

Asosiy namuna: foydalanuvchining 27 ekranli ko‘k/binafsha Liquid Glass doskasi (`codex-clipboard-d64b0889-fd7b-4c94-adf8-aaa37bb54ec2.png`). Avvalgi 3 ekranli to‘rt-tab konsepsiyasi bu namuna bilan almashtirildi. Maqsad: mavjud Flutter ilovasini o‘zgartirish; statik maket yoki yangi loyiha emas.

## Saqlash nuqtasi

- Branch: `feat/mlp-beta-sprint01`.
- Tracked o‘zgarishlar nusxasi: `refs/codex-checkpoints/mlp-reference-20261030`, commit `f31a2ce177bf2ae5ab223f233c2a2664ddb5450c`.
- `git stash create` ishchi fayllar va indexni o‘zgartirmadi. Untracked fayllar bu Git nusxaga kirmaydi.
- Oldindan staged `D lib/firebase_options.dart` saqlandi, reset qilinmadi.

## Shu iteratsiyada

- Pastki navigatsiya: Bugun / Maqsadlar / Fokus / Ustoz / Profil. Vazifalar Maqsadlar ichida, statistika Profil ichida ochiladi. Eski ichki route indekslari saqlangan.
- Bugun: real sana/hafta tanlovi, shu kundagi vazifa, real start va 5 daqiqalik variant, keyingi vazifalar, tafsilot va yordam.
- Maqsadlar: Faol/Arxiv filtri, haqiqiy progress, tafsilot navigatsiyasi. Vazifalar: yaratish, qidirish, sana guruhlari, tahrirlash va baholash mavjud.
- Splash va Welcome: qayta ishlatiladigan vektor M belgisi; Welcome va Ustozda tabassumli orb. Animatsiya reduced-motion va TickerModega amal qiladi.
- Fokus: taymer sozlash, faol holatda tog‘li fon, haqiqiy qolgan vaqt, pauza/davom/yakunlash; yakunda real vaqt va yozma qayd. Fokus taskni avtomatik tugatmaydi.
- Profil tugmasining accessibility node chegarasi tuzatildi.

## 27 ekran qamrovi

| Namuna | Mavjud amalga oshirish | Yangi namuna tekshiruvi |
|---|---|---|
| 01 Splash, 02 Welcome | `mlp_account_flow.dart`, `mlp_brand.dart`, `mlp_ai_orb.dart` | Yangi logo/orb; qayta render kerak |
| 03 Registration, 04 Preferences | `mlp_account_flow.dart` | Umumiy glass; vizual solishtirish kerak |
| 05 Interests, 06 Goal, 07 Diagnosis, 08 Roadmap | `mlp_goal_flow.dart` | Oqim mavjud; qiziqishlar discovery ichida; alohida namuna joylashuvi tekshiriladi |
| 09 Home | `mlp_ios_workspace.dart` | Hafta va qisqa fokus qo‘shildi; qayta render kerak |
| 10 Goals, 11 Tasks | `mlp_ios_workspace.dart`, `mlp_workspace_pages.dart` | Filtr/progress/navigation ulandi; qayta render kerak |
| 12 Calendar | `mlp_calendar.dart`, `mlp_schedule_editor.dart` | Umumiy glass; vizual solishtirish kerak |
| 13 Focus, 14 Active, 15 Result | `mlp_focus_pages.dart`, `mlp_focus_dial.dart` | Yangi dial va scenic active; qayta render kerak |
| 16 Chat, 17 Voice | `mlp_companion_pages.dart`, `mlp_ai_orb.dart` | Orb yangilandi; tashqi AI/voice demo holati aniq |
| 18 Profile | `mlp_lifestyle_pages.dart` | Root navigatsiya va statistikaga yo‘l tekshiriladi |
| 19 Statistics | `mlp_progress_pages.dart` | Haqiqiy fokus va baholash alohida; vizual solishtirish kerak |
| 20 Rewards, 21 Weather, 22 Soundspace | `mlp_lifestyle_pages.dart` | Mavjud glass; unavailable xizmatlar yashirilmaydi |
| 23 Settings, 24 Notifications | `mlp_lifestyle_pages.dart`, `mlp_background_settings.dart` | Galereya foni saqlanadi; native tekshiruv ochiq |
| 25 Skill Passport | `mlp_progress_pages.dart` | O‘z-o‘zini hisobot/activity/test farqi saqlangan |
| 26 Goal Details | `mlp_goal_detail.dart` | Mavjud CRUD va reja; vizual solishtirish kerak |
| 27 Floating navigation | `mlp_widgets.dart`, `mlp_product_shell.dart` | Yangi besh tab; navigatsiya va katta shrift testi kerak |

## Qabul qilish mezonlari

Har ekran uchun: yangi rasm tekshiriladi, ko‘rinadigan tugma ishlaydi, kichik/keng ekran va katta shriftda overflow yo‘q. Barcha testlar va analyze o‘tadi. Widget rasmlari native runtime yoki 60 FPS dalili emas. Android build/lifecycle, iOS qurilma, haqiqiy tashqi xizmatlar holati `MLP_UI_REMAINING_ISSUES.md`da alohida qoladi.

Aniq bo‘lmagan foiz o‘rniga tekshirilgan ekranlar va buyruqlar natijasi qayd etiladi. `docs/evidence/ios-reference-2026-10-29/` joriy iteratsiya loglarini saqlaydi. Oldingi 130 test natijasi yangi o‘zgarishlar o‘tganini anglatmaydi.

## Foydalanuvchining so‘nggi yo‘nalishi

2026-10-30: token va takroriy testlarni kamaytirish, ko‘rinadigan natijani tezroq berish so‘raldi. Uch faylli maqsadli test to‘plami 32/32 o‘tdi. Vizual fixture 31 rasm yaratdi (1 test o‘tdi). Keyingi keng `flutter test` foydalanuvchi so‘roviga binoan to‘xtatildi; uning natijasi o‘tgan deb hisoblanmaydi. Fokus presetlari va scenic fonning so‘nggi tuzatishi keyingi web build ichida tekshirilmoqda. Endi zarur build va faqat aniq topilgan xatolar tekshiruvi bajariladi.

Vizual ko‘rib chiqishda faol fokus foni ichki scaffold bilan yopilib qolgani aniqlandi; background injection orqali tuzatildi. Yangi dizayn hali barcha 27 ekran bo‘yicha 1:1 tasdiqlanmagan.

2026-10-30: flutter build web --release --no-pub exit 0 (98.8s). Preview serves build/web at http://127.0.0.1:8765/; browser was not opened automatically. Full visual parity and native runtime remain open.

2026-10-30 — UI-only yo‘nalish: foydalanuvchi hozir faqat 27 ekranli namunaga vizual moslashni so‘radi. Keyingi ishlar backend yoki yangi funksiya emas, joylashuv/rang/o‘lcham/ikonka/oraliqlarga qaratiladi. Shared fonning keskin to‘ldirilgan shakllari yumshoq yorug‘ chiziqlarga almashtirildi; onboarding sarlavhalari ixchamlandi; diagnostika tanlovlari yagona glass-radio ko‘rinishiga o‘tdi; qiziqish chiplariga ikonka qo‘shildi; sozlamalar qatorlari ixcham glass ko‘rinishiga o‘tdi. Form callbacklari va saqlash sxemasi o‘zgarmadi. Keng testlar qayta ishga tushirilmadi. Vizual 1:1 moslik hali to‘liq tasdiqlanmagan.
