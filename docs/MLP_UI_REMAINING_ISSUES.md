# MLP UI qolgan ishlar

To‘liq master maqsad hali bajarilmagan. Route ro‘yxati tayyor ekran hisoblanmaydi.

1. P0: Android Gradle loopback xatosi va qurilma yo‘qligi. Ishlaydigan Android build/runtime dalili olish.
2. Phase A checkpoint: 578d552. Phase B: 10 ekran va asosiy oqimlar yozildi; umumiy analyzer clean, 78/78 test passed. To‘liq QA Phase Fda qoladi.
3. B — yangi oqim ishlaydi. Qolgan nozik tekshiruvlar: barcha date/time controls/back/error variantlari, 2.0× text scale va barcha screen-reader actionlari; katta task ro‘yxati uchun detail lazy rendering.
4. P1: C — yangi 5 tab shell, goal detail, today, calendar/recurrence/schedule overlap/capacity/reminder holati, focus hub/active/summary.
5. P1: D — persistent demo chat/retry, voice UI, AI personalization, task verification/deterministik test, passport, analytics va tarixiy odat hisobini tuzatish.
6. P1: E — virtual rewards, preview weather/reschedule, honest Soundspace, profile/settings/notifications, dismissible in-app launcher.
7. P1: F — 28 ekran route/back/interaction/responsive/error/persistence QA, screenshotlar, test/analyze va faza commitlari.
8. P1: eski DemoStore oddiy mutation yozishda rollback yo‘q va startup saqlov xatosi uncaught; yangi UI repository yozish oldidan commit qiladi, lekin bu eski store tuzatildi degani emas.
9. P2: README/legacy nomlar va ko‘rinadigan UI matnlarini yakuniy tekshirish; storage kalitlari migratsiyasiz o‘zgartirilmaydi.

Haqiqiy SMS/Google active-root auth, live AI/STT/TTS, background wakeword/overlay, live weather, audio asset va partner fulfillment bu UI prototipiga ulanmagan. Ular ishlayotgandek ko‘rsatilmaydi. Firebase qoidalari chetlab o‘tilmagan. Maxfiy config commit qilinmaydi.
