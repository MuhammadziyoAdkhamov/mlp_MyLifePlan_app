# MLP UI ekran inventari

Yangilanish: 2026-10-27. 28 ekran mahalliy UI prototipda yozilgan va asosiy entrypointga ulangan. Bu ishlab chiqarish backend yoki Android qurilmadagi yakuniy tasdiq degani emas. Barcha eski maqsad/vazifa/odat boshqaruvlari Sozlamalar va Maqsadlar orqali ochiladi.

Navigatsiya: `main.dart` → xavfsiz bootstrap → entry gate → `MLPProductShell`. Asosiy tablar: Bugun / Maqsadlar / Fokus / Ustoz / Profil. Boshqa ekranlar ichki Navigator orqali ochiladi. Noma’lum route va yo‘qolgan ID xato holatiga ega. Maqsadning 7–9 ekranlari oldingi bosqichdan draft oladi; to‘g‘ridan-to‘g‘ri draftsiz manzil tiklanadigan holatni ko‘rsatadi.

| # | Ekran / route | Haqiqiy fayl | Asosiy amal / holat | Tekshiruv |
|---|---|---|---|---|
| 1 | Splash /splash | features/onboarding/mlp_account_flow.dart | Saqlov yuklanishi, home/welcome tanlovi | Entry gate va responsive fixture |
| 2 | Welcome /welcome | shu fayl | MLP gradient belgisi, mahalliy chizilgan ufq, boshlash/login/guest | Guest/restart, 4 viewport, PNG |
| 3 | Registration /registration | shu fayl | Ism, +998 format, jins; tasdiqlanmagan demo profil | Validatsiya, preferences oqimi |
| 4 | Login /login | shu fayl | Telefon/Google uchun unavailable izoh; demo va guest | Render, mavjud action, 320px PNG |
| 5 | Preferences /preferences | shu fayl | Vaqt, vaqt oralig‘i, eslatma niyati, ustoz nomi | Save/edit/restart; vaqt xatosi |
| 6 | Goal discovery /goals/new | features/goals/mlp_goal_flow.dart | 8 yo‘nalish va erkin matnli maqsad | Maxsus maqsad oqimi |
| 7 | Goal clarification /goals/clarify | shu fayl | Natija, muddat, vaqt, daraja, sabab | Form, date, draft/back, 4 viewport |
| 8 | Diagnosis /goals/diagnosis | shu fayl | Namuna savollar yoki o‘z bahosi, Bilmayman | Wrong/unknown, XPga ta’sir yo‘q |
| 9 | Roadmap /goals/roadmap | shu fayl | Tahrirlanadigan bosqichlar, vaqt va sana | Goal+tasks bitta yozuv, rollback/retry |
| 10 | Goal detail /goals/detail | features/goals/mlp_goal_detail.dart | Keyingi vazifa, timeline, edit/archive/delete | CRUD/confirm/cancel, PNG |
| 11 | Today /today | features/workspace/mlp_workspace_pages.dart | Hafta tanlash, capacity, keyingi vazifa, 5 daqiqa, goal va schedule | Haqiqiy production root, 4 viewport, PNG |
| 12 | Calendar /calendar | features/planner/mlp_calendar.dart | Kun/hafta/kompakt oy, natija, havola nusxasi | Recurrence va Duolingo oqimi, 4 viewport |
| 13 | Schedule editor /calendar/edit | features/planner/mlp_schedule_editor.dart | CRUD/link/repeat/until/reminder, conflict va capacity tasdig‘i | 12 planner test, persistence failure |
| 14 | Focus hub /focus | features/focus/mlp_focus_pages.dart | 25/5, 50/10, custom, task link, tarix, tanaffus | 4 viewport, PNG, preset va history |
| 15 | Active focus /focus/active | shu fayl + mlp_focus_controller.dart | Haqiqiy sekundlar, pause/resume, lifecycle pause, rest | Clock injection; system back, restart paused |
| 16 | Focus summary /focus/summary | shu fayl | Haqiqiy vaqt, qayd, xavfsiz URL, save/discard confirm | Today→focus→53 sec→summary; idempotency |
| 17 | Chat /ustoz | features/ai_companion/mlp_companion_pages.dart | Deterministik javob, loading/retry, 100 xabar, kontekst tanlovi | Persist/restart/rejected write, send workflow |
| 18 | Voice /ustoz/voice | shu fayl | Vizual holatlar, mute tanlovi, end, matnli tarix | Route, 4 viewport; mikrofon/STT/TTS yo‘q |
| 19 | AI personalization /ustoz/preferences | shu fayl | Nom/uslub/ovoz niyati/kontekst, chat clear confirm | Persist/validatsiya; 4 viewport |
| 20 | Verification /verification | features/progress/mlp_progress_pages.dart | Hisobot va fokusdan alohida 3 savolli namuna test | 0/3 unknown, deterministic scoring, XP o‘zgarmaydi |
| 21 | Passport /passport | shu fayl | Namuna baholash va self-report dalillari | Source-state, empty, 4 viewport |
| 22 | Growth /progress | shu fayl | Haqiqiy 7 kunlik fokus, tasks, goal self-report, testlar | Source-state, zero bars, 4 viewport, PNG |
| 23 | Rewards /rewards | features/lifestyle/mlp_lifestyle_pages.dart | Locked/available/claimed/selected virtual profil bezagi, unavailable hamkor | Lock/claim/persist, detail sheet, PNG |
| 24 | Weather /weather | shu fayl | Preview, city, bugun/ertaga, haqiqiy schedule edit | City persist, route/4 viewport/PNG; jonli prognoz yo‘q |
| 25 | Soundspace /soundspace | shu fayl | Katalog/sevimli/mini-player ko‘rinishi/sleep intent | Favorite persistence, unavailable playback dialog, PNG |
| 26 | Profile /profile | shu fayl | Avatar bezagi, haqiqiy activity, pasport/yutuq/progress, logout confirm | Tab, 4 viewport, PNG; mahalliy hisob |
| 27 | Settings /settings | shu fayl | Ism/preferences/AI/notification, til/mavzu izohi, backup, eski data tools, privacy/help/reset | Saqlash, legacy access, recovery; 4 viewport |
| 28 | Notifications /notifications | shu fayl | Bugun/ertaga haqiqiy reminder-intent va topshirilgan ishlar | Source-state, empty, settings; yetkazish ulanmagan |

16 yangi asosiy/support ekran 320×740, 390×844 (1.4× matn), 430×932 (2.0× matn), 844×390 bilan tekshirildi. Avvalgi onboarding/goal/planner testlari 320×640, 390×844, 844×390, 1440×900, 1.4× matn va keyboard insetni qamraydi. Bu barcha native date/time picker, TalkBack/VoiceOver va fizik qurilma holatlari qo‘lda tekshirildi degani emas.

PNGlar: `build/mlp_ui_phase_b/` (nom tarixiy; endi yangi UI ham shu yerda). Haqiqiy qurilma screenshotlari emas, font yuklangan Flutter widget renderlari. Yakuniy buyruq natijalari `MLP_UI_QA_REPORT.md`da.
