# MLP Liquid Glass audit va amalga oshirish

Scope: foydalanuvchining 2026-10-27 dagi yangi talabi barcha faol ekran va modal oynalarga tegishli. Avvalgi 28 ekranli mahalliy prototip va saqlov mantiqi saqlanadi. Figma URL yo‘q; foydalanuvchi faqat yuborilgan rasm asosida davom etishni tanladi. Keyingi Liquid Glass talabi vizual asos bo‘ladi.

Audit: mavjud MLPGlassCard oddiy opaque Material; BackdropFilter yo‘q. AppBar/nav opaque. Dialoglar Material AlertDialog, secondary pages 20px oddiy kartalar. Focus halqasi oddiy progress; AI orb statik. Projects/tasks bir listda; reference bo‘yicha alohida ko‘rinish kerak. Statistikada source-state bor, period selector va project donut yo‘q. Existing core CRUD / prefs / local focus controller o‘zgartirilmasligi kerak.

Yangi umumiy qatlam: clipped grouped BackdropFilter, 10px blur, translucent gradient/reflection, thin edge, dark ambient background; nav/dialog blur alohida guruhda. Reduced motion, high contrast, safe areas va 48px touch targets. Blur butun screen uchun har frame animatsiya qilinmaydi. Orb uchun faqat transform/opacity, painter ring uchun alohida repaint.

Qamrov: Home, Projects, Tasks, Focus setup/active/summary, Statistics, Calendar/editor, Ustoz chat/voice/preferences, Goal wizard/detail, Rewards/detail, Weather, Soundspace, Profile, Settings, Notifications, Login/Registration/Preferences/Onboarding/Splash va eski data CRUD/import/export dialoglari. Backend va storage kalitlari o‘zgarmaydi. Ulanmagan real xizmatlar uchun mavjud halol capability matnlari saqlanadi.

Rasmiy platforma tekshiruvi alohida: Windowsda iOS qurilma buildi olinmaydi. Android Java loopback oldingi muammo; hech qanday test chiqishi iOS/Android 60 FPS isboti deb ko‘rsatilmaydi.

Galereya mosligi: lockdagi `image_picker_ios 0.8.13+13` podspec va rasmiy changelog iOS 15.0 yoki yangisini talab qiladi. Runner deployment targetlari va Flutter framework minimumi 15.0 ga moslashtirildi; iOS 13/14 ushbu konfiguratsiyada qo‘llab-quvvatlanmaydi. Repozitoriyda `ios/Podfile` mavjud emas. Manba: [Flutter image_picker_ios changelog](https://pub.dev/packages/image_picker_ios/changelog). Bu konfiguratsiya tekshiruvi; haqiqiy iOS build yoki qurilma sinovi bajarilgani haqidagi da’vo emas.
