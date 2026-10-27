# MLP UI ekran inventari

Yangilanish: 2026-10-27. 10 ekran yozilgan, 18 ekran yangi scope bo‘yicha hali tugallanmagan. Route deklaratsiyasi ekran ishlashini isbotlamaydi. `WIDGET` — ko‘rsatilgan widget tekshiruvi bor, to‘liq Phase F QA yoki Android runtime degani emas. `4V`: 320×640, 390×844, 844×390, 1440×900, matn 1.4× va klaviatura inset 160.

| # | Ekran / route | Amalga oshirish | Navigatsiya / amal | Responsive / QA |
|---|---|---|---|---|
| 1 | Splash /splash | WIDGET: mlp_account_flow.dart | Entry gate avtomatik ochadi, restore bilan home/welcome | 4V; landscape overflow tuzatildi |
| 2 | Welcome /welcome | WIDGET | Root entry gate; boshlash, login va guest yo‘llari | 4V; guest/restart va screenshot |
| 3 | Registration /registration | WIDGET | Ism/telefon/jins; demo→preferences | 4V; invalid input va production oqim testi |
| 4 | Login /login | WIDGET | SMS/Google unavailable; demo/guest tanlovi | 4V; screenshot; barcha action holatlari Phase Fda |
| 5 | Preferences /preferences | WIDGET | Kunlik vaqt/soat/eslatma xohishi/ustoz nomi; settingsdan qayta ochish | 4V; save/edit/restart va screenshot |
| 6 | Goal discovery /goals/new | WIDGET: mlp_goal_flow.dart | Erkin matn, 8 toifa, clarificationga o‘tish | 4V; custom goal navigatsiyasi |
| 7 | Goal clarification /goals/clarify | WIDGET | Outcome/date/time/starting level/why; editable summary | 4V; form oqimi va screenshot |
| 8 | Diagnostics /goals/diagnosis | WIDGET | Deterministik 2 savol yoki self-report; Bilmayman | 4V; wrong/unknown 0 ball, XP yo‘q |
| 9 | Roadmap /goals/roadmap | WIDGET | Tahrirlangan task/time/date; goal+tasks bir yozuvda | 4V; persist/rollback/retry; screenshot |
| 10 | Goal detail /goals/detail | WIDGET: mlp_goal_detail.dart | Timeline, next step, linked task, edit/archive/delete confirm | 4V; CRUD/archive testi, screenshot |
| 11 | Today /today | QISMAN: demo_app.dart | Haqiqiy mahalliy vazifa/odat/fokus | Baseline widget testlar |
| 12 | Planner /calendar | YO‘Q | ICS eksport haqiqiy planner emas | Yo‘q |
| 13 | Schedule editor /calendar/edit | YO‘Q | Rejalashtirilgan | Yo‘q |
| 14 | Focus hub /focus | QISMAN: demo_app.dart | Preset, tarix | Baseline testlar |
| 15 | Active focus /focus/active | QISMAN: demo_app.dart | Haqiqiy faol soniya, pause/resume | Baseline testlar; alohida route yo‘q |
| 16 | Focus summary /focus/summary | QISMAN | Soniyalar saqlanadi, yangi yakun UI yo‘q | Yangi QA yo‘q |
| 17 | Chat /ustoz | YO‘Q yangi oqim | Eski mock aktiv rootga ulanmagan | Yo‘q |
| 18 | Voice /ustoz/voice | YO‘Q | Faqat demo UI rejalangan | Yo‘q |
| 19 | AI personalization /ustoz/preferences | YO‘Q | Preference modeli bor | Yo‘q |
| 20 | Verification /verification | QISMAN: demo_forms.dart | O‘z hisobotini topshirish bor | Deterministik baholash yo‘q |
| 21 | Skill passport /passport | YO‘Q | Rejalashtirilgan | Yo‘q |
| 22 | Growth /progress | QISMAN: demo_review.dart | Manba holatidan statistika | Tarixiy odat nuqsoni ochiq |
| 23 | Rewards /rewards | YO‘Q | Virtual / demo rejalangan | Yo‘q |
| 24 | Weather /weather | YO‘Q | Belgilangan preview rejalangan | Yo‘q |
| 25 | Soundspace /soundspace | YO‘Q | Litsenziyali asset yo‘q → unavailable UI | Yo‘q |
| 26 | Profile /profile | QISMAN | Eski ism/kunlik limit sozlamalari | Yangi profil yo‘q |
| 27 | Settings /settings | QISMAN | Import/eksport/reset eski Markazda | Yangi sozlamalar yo‘q |
| 28 | Notifications /notifications | YO‘Q | Real yetkazish ulanmagan | Yo‘q |

Har bir ekranga yakuniy QA: initial rendering, route/back, asosiy amal, loading/empty/error, keyboard, 320/390/katta/landscape, dark theme, Uzbek Latin, persistence. Dalil yo‘q kataklar yakunlangan deb belgilanmaydi.
