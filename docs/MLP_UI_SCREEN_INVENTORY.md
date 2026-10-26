# MLP UI ekran inventari

Bu jadval yakunlanganlik da’vosi emas. Route deklaratsiyasi ekran ishlashini isbotlamaydi. `QISMAN` eski foydali oqimni, `KOD` yangi yozilgan lekin hali to‘liq tekshirilmagan ekranni bildiradi. Yangilanish: 2026-10-26, Phase A/B ishlanmoqda.

| # | Ekran / route | Amalga oshirish | Navigatsiya / amal | Responsive / QA |
|---|---|---|---|---|
| 1 | Splash /splash | KOD: mlp_account_flow.dart | Asinxron UI saqlov yuklanishi | Kutilmoqda |
| 2 | Welcome /welcome | KOD | Boshlash, kirish, mehmon | Kutilmoqda |
| 3 | Registration /registration | KOD | Ism/telefon/jins validatsiyasi, demo profil | Kutilmoqda |
| 4 | Login /login | KOD | SMS/Google ulanmagan holati; mehmon | Kutilmoqda |
| 5 | Preferences /preferences | KOD | Vaqt/soat/eslatma xohishi/ustoz nomi | Kutilmoqda |
| 6 | Goal discovery /goals/new | QISMAN: eski goal form | Erkin matn bor, yangi oqim yo‘q | Eski test bor; yangi QA yo‘q |
| 7 | Goal clarification /goals/clarify | YO‘Q | Rejalashtirilgan | Yo‘q |
| 8 | Diagnostics /goals/diagnosis | YO‘Q | Rejalashtirilgan | Yo‘q |
| 9 | Roadmap /goals/roadmap | QISMAN: DemoHub | 7 kunlik starter bor, yangi editor yo‘q | Yangi QA yo‘q |
| 10 | Goal detail /goals/detail | QISMAN: demo_app.dart | CRUD va bog‘langan vazifalar bor | Eski test; yangi detail yo‘q |
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
