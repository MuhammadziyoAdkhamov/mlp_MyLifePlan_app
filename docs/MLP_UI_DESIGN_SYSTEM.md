# MLP UI dizayn tizimi

Manba: `lib/app/theme/mlp_design_system.dart`; komponentlar: `lib/core/design_system/mlp_widgets.dart`. 2026-10-27 dagi foydalanuvchi tasviri uslub uchun asos: to‘q dengizrang fon, firuza asosiy amallar, binafsha ikkilamchi rang, yumaloq kartalar, katta halqali taymer, beshta ixcham tab.

Ranglar: background #070E1B, secondary #111C2B, elevated #192739, border #2B3859, cyan #00D1EF, violet #8C6BFF, light violet #B6A3FF, success #51D3A1, warning #F4BC68, text #F7F8FF, secondary text #AAB6D5. Asosiy tugma: firuza fon + qoramtir matn. Faol tab: firuza. Ulanmagan xizmat holati muvaffaqiyat deb ranglanmaydi.

Shrift: platformada mavjud Segoe UI yoki tizim fallback; internetdan shrift olinmaydi. Asosiy o‘lchamlar 32/28/24/20/16/14/12, ixcham yordamchi matn 11. iOS uslubidagi Flutter interfeys, native SwiftUI yoki iOSda tasdiqlangan build degani emas. Uzbek emoji fallbackdagi to‘rtburchak belgini olib tashladik.

Kartalar radiusi 20, controls 14, floating tab 24. Asosiy chet 20–24. Touch target 48 va undan katta; tab min72. 3 metrikaning ixcham qatori yetarli kenglikda ishlaydi, kichik ekran yoki katta matnda 2 ustunga o‘tadi. Taymer aspect ratio 1:1. Content max920, form scroll/SafeArea/keyboard dismiss bilan.

Harakat: 180ms, route 240ms; disableAnimations bilan nol. Orb doimiy animatsiya qilmaydi; holat faqat rang/ikonka bilan almashadi. Welcome ufqi kodda chizilgan; tashqi rasm yoki litsenziyasiz asset yo‘q. Ustoz orbi va taymer kodda chiziladi.

Komponentlar: MLPScaffold/AppBar/FloatingTabBar, Primary/Secondary/IconButton, GlassCard, SectionHeader, TextField/PhoneField, GoalCard/TaskCard, ProgressBar/Ring, StatCard, Empty/Loading/ErrorState, ConfirmationSheet, Toast, AvatarOrb, WelcomeHero, RewardCard, TimerDisplay. Support: MLPPage/Notice/MenuTile/Metrics, WeeklyBars.

Navigation: Bugun → Maqsadlar → Fokus → Ustoz → Profil. Ichki route dispatcher boshqa ekranlarni ochadi. Missing argument/ID va noma’lum manzil tiklanadigan bo‘sh/xato holati bilan chiqadi. In-app Ustoz launcher yashiriladi va Sozlamalardan qaytariladi. Klaviaturada launcher va tablar yashiriladi. Bu Android system overlay emas.

Saqlov: asosiy `mpl_lifeos_demo_v1` saqlanadi; qo‘shimcha `mlp_ui_prototype_v1`. UI yozuvi disk tasdig‘idan keyin e’lon qilinadi. Maqsad+bosqich va batafsil fokus sessiyasi rollbackga ega. Oddiy eski core CRUD memory-first bo‘lib, disk xatosi va Retry bilan ochiq ko‘rsatiladi. Faollik, self-report, test natijasi alohida manbalarda.
