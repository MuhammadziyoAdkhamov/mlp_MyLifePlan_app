# MLP — 2026-11-02 22:00 (UZT) tanlovga tayyorlash: real delivery contract

**Holat:** reja va qabul mezonlari. Hamma vaqtlar Asia/Tashkent. **Muhim:** 100/100 kafolat emas; haqiqiy pilot yoki native APK hali isbotlanmagan. “Eng yaxshi kreativ g‘oya” nizomida raqamli 5×20 ball jadvali bor deb da’vo QILMANG. Huquqiy kontekst: 2026-02-11 51-son buyruq; ikki bosqich; 3-band innovatsionlik / amaliy qo‘llanish / ijtimoiy ahamiyat, 20-band aniq mexanizm / muddat / dastlabki natijalar, 24-band prezentatsiya (foydalanuvchi bergan normativ kontekst; asl hujjat bilan qayta solishtirish kerak).

## 1. Asosiy taklif va fanlar
**MLP — o‘zbek talabasining maqsadi, ishlash jarayoni va tekshiriladigan amaliy ko‘nikmasi orasidagi uzilishni kamaytiruvchi AI-assisted growth platform.**
Birlamchi auditoriya: O‘zbekistonda dasturlashni o‘rganayotgan talabalar; ikkilamchi: ustozlar, karyera markazlari; keyin boshqa fanlar. “Activity recorded”, “evidence submitted” va “verified via deterministic assessment” bir narsa emas. AI “xolis yakuniy baholovchi” bo‘lib ko‘rsatilmaydi.

**Ishlaydigan demo**: Bugun/Maqsad -> Vazifa -> Focus -> Dalil -> lokal deterministik savol testi -> Skill Passport, app restartda saqlanish.
**Yaqin vision (not shipped)**: ustoz rubrikali manual tasdiq; universitet karyera markazi agregat insight; HEMIS uchun ruxsatli integratsiya.
**Keyingi vision (not shipped)**: AI assessment draft + human approval/dissent explanation; rector/dean request workflow; sponsor coin redemption/auction; store partners. Bu oxirgilari demo funksiyasi va investor tractioni EMAS.

## 2. 2026-11-01 -> 2026-11-02 vaqt qutisi
| Qachon (UZT) | Egasi | Natija | “Tayyor” sharti |
|---|---|---|---|
| 11/01 18:00–20:30 | Dasturchi | Android env diagnostic: loopback, Java21, proxy/firewall, licenses; mustaqil CI | APK haqiqatan build bo‘ladi yoki to‘liq error log, 1 workaround, WEB fallback |
| 11/01 20:30–22:00 | Dasturchi | Android device smoke: first launch, offline, restart, focus, evidence, quiz, passport, back | qurilma ekran yozuvi; crash / data loss yo‘q; statuslar aniq |
| 11/01 22:00–23:30 | Dizayn/QA | Golden path 7–8 ekranga muzlatish | faqat kerakli tugmalar va loading/error/offline |
| 11/02 07:00–10:00 | Dasturchi/QA | Yetishmaydigan golden-path buglar; 1.0-demo tag candidate | analyze/test log; 1 Android smoke; demo data label |
| 11/02 10:00–12:00 | Talaba-koordinator | 8–10 ko‘ngilli pilot recruit va rozi qilish | rozi bo‘lgan haqiqiy ishtirokchilar, anonim ID |
| 11/02 12:00–15:30 | Talaba-koordinator | 1-session pilot | haqiqiy event sheet; 5 muvaffaqiyatli end-to-end session maqsadi, natija uydirilmaydi |
| 11/02 15:30–17:00 | Tahlil | Pilot denominator/funnel, xatolar va observations | hammasi observed vs sample aniq |
| 11/02 17:00–19:00 | Founders | 7-8 slayd, bir betlik demo report, smeta | barcha 3/20/24 bandlari qoplangan |
| 11/02 19:00–21:00 | Founder + 2 do‘st | 5 daqiqa rehearsals, questions, backup | ikki marta uzluksiz demo, video va offline fallback |
| 11/02 21:00–22:00 | Founder | Pack: APK / demo-web / pitch / screenshot / log | bitta mustaqil papkadan ochiladi |

**Agar Android 11/01 20:30 gacha tuzalmasa:** vaqtni cheksiz troubleshootingga sarflamang. Web demo + ekran yozuvi + haqiqiy mobil qurilma pending hujjatini tayyorlang; android CI diagnosticni davom ettiring. Pilotni webda o‘tkazib, “Android pilot” deb yozmang.

## 3. Android P0— diagnostika (Windows Powershell)
1. `git status --short` va faol branchni tekshiring, dirty fayllarni reset QILMANG.
2. `flutter doctor -v`, `flutter devices`, `flutter doctor --android-licenses`, `java -version`.
3. `cd android; .\gradlew.bat --stop; .\gradlew.bat --version; cd ..`; xato aynan Gradle startida yoki Java socket initda chiqyaptimi?
4. `Get-ChildItem Env:*proxy*`; `Get-Content $env:windir\System32\drivers\etc\hosts`; `Test-NetConnection 127.0.0.1 -Port 80` (80 port yopiq bo‘lishi loopback xatosini **isbotlamaydi**).
5. `flutter build apk --debug --no-pub -v *> android-build-verbose.log`.
6. Loopback sababini antivirus/VPN/Java socket/bind bilan ajrating; xavfsizlik devorini doimiy o‘chirmang va o‘ylamay proxy/firewall konfiguratsiyasini o‘zgartirmang.
7. CI ubuntu Android job lokal Windows muammosini ajratishga yordam beradi; CI muvaffaqiyati telefon smoke-test isboti emas.
8. Mavjud offline entry `lib/main.dart` Firebase initialize qilmaydi. `google-services.json` ni ommaviy GitHub’ga qo‘ymang. Android Google Services pluginining shartli qo‘llanishi alohida competition branchda sinov uchun kiritildi; real Google/Firebase auth shu bilan ishlaydi degan xulosa YO‘Q.

## 4. Demo 7 ekran — freeze
1. Start / “Mehmon sifatida” (login bypass truthful).
2. Bugun -> Maqsad va keyingi vazifa (tayyor real goal).
3. Roadmap: qoidalarga asoslangan reja bo‘lsa “AI ishlab chiqdi” demang.
4. Focus: 5 soniyada 25 daqiqa bo‘lib qolmasin, real session yoki qayd.
5. Dalil: izoh + URL; real binary attachment ishlamasa “fayl upload” deya va’da QILMANG.
6. Deterministik assessment: 3 savol, natija va mezon; faqat haqiqiy testda verified.
7. Skill Passport: oldingi activity, self-report va passed-assessment alohida, restartda saqlangan.
8. Pilot/Impact summary (ixtiyoriy alohida demo ekran emas; bir-betlik print).

## 5. HEMIS integratsiya — real cheklov bilan
- **Phase P0 (48h):** talaba kiritadigan kurs nomi, jadval, vazifa muddati, fan/mavzu, haftalik “qiyin fan” ni qo‘shish; ixtiyoriy .ics kalendar eksporti va manual import; HEMIS’ga ulangan deb aytmang.
- **Phase P1 (OTM hamkorligi):** OTM ruxsati bilan fan, dars jadvali, baho/GPA/davomat kerak bo‘lsa, rasmiy ma’lumot kontrakti/API, user consent, minimal scopes, audit, deletion va role separation. Qonuniy asos, talabalar shaxsiy ma’lumotlari xavfsizligi va OTM ruxsati shart.
- **Phase P2:** 1) akademik riskni real ko‘nikma yo‘l xaritasi bilan birlashtirish, 2) kursdagi amaliy skill gap, 3) karyera markazi dashboard — shaxsiy baho/ma’lumotlarni ommaga chiqarmaslik, 4) OTM topshirig‘idan Skill Passportga verified evidence. HEMIS login/parolni yig‘ish, brauzer scraping qilish yoki ruxsatsiz APIga ulanish TAQIQLANADI.
- **Phase P3:** ichki murojaatlar/pul-koin; universiyettan aniq tasdiq va hamkorliklarsiz “integrated” yoki “revenue” emas.
- HEMIS’da akademik monitoring va prognoz allaqachon mavjud; yangilik — o‘lchangan ko‘nikma va talaba next-action loopini bog‘lash.

## 6. Pilot ma’lumot modeli va shaxsiylik
Tug‘ilgan sana, tel, ID, kurs reytingi, to‘liq ism majburiy QILMANG. Ishtirokchi rozi bo‘lgach taxminiy cohort `U01..U10`:
`user_id,consent_at,platform,app_version,first_open_at,goal_created_at,focus_started_at,focus_completed_at,evidence_submitted_at,assessment_started_at,assessment_passed_at,passport_opened_at,feedback_1_5,critical_issue,notes`.
Minimizatsiya: faqat ishtirokchi roziligi; raw evidence fayllarini ommaviy hisobotga qo‘shmang; natijalarni anonim ko‘rsating; real chiqish yo‘q bo‘lsa `N=0`. Har eventga timestamp kiritiladi va demo sample alohida bayroq bilan belgilanadi.

**Pilot KPI**: N contacted, N consented, N installed/opened, N created goal, N completed ≥1 focus, N submitted evidence, N passed actual deterministic test, N reopened app, crash count. Har ulushda denominator ko‘rsatilsin; 1-2 kunlik test retention yoki PMF emas. Eng muhim “first-value”: submit evidence + review status to passport.

## 7. Pitch 8 slayd (3–5 daqiqa)
1. 15s: real muammo (ishlash va ko‘nikma orasidagi farq) + bitta real mahalliy dalil.
2. 20s: HEMIS / oddiy task / kurs natijasi nima o‘lchaydi, MLP nima qo‘shadi.
3. 15s: 1 jumlada yechim: goal→action→evidence→verified skill.
4. 90s: golden path jonli Android (yoki ochiq “web demo”).
5. 25s: innovatsiya + haqiqiy cheklov: verified only deterministic/manual.
6. 30s: pilot N=... haqiqiy ma’lumotlar, funnels, fail cases.
7. 25s: business model: consumer premium gipoteza + universitet pilot/litsenziya niyati (hozir 0 OTM shartnoma).
8. 30s: 90 kun roadmap + 100 mln so‘m mablag‘ qanday bosqichlardagi deliverable bilan sarflanadi.

## 8. Tanlov va investor uchun minimum “evidence pack”
1. Dated APK yoki web release build, SHA-256 hash, commit SHA.
2. 60–90s screen recording, demo va sample status banneri.
3. Analyze/test/build/Android smoke-test loglari: pass/fail ochiq.
4. Pilot 1-page funnel va 2–3 foydalanuvchining anonim, rozilik olingan sitatasi.
5. 5–7 bevosita analog feature matrix, manbalar va sana.
6. Xarajatlar smetasi: narxlar, miqdorlar, qaysi bosqichda nima ishlab chiqilishi.
7. Cheklovlar: AI model live yoki demo, Firebase live yoki local, HEMIS ulanish yo‘q, reward sponsorlar yo‘q.
8. Roadmap bo‘yicha va’da vs hozirgi bajarilgan ish ikki rangda.

## 9. Stop / Go qoida
- **P0 GO**: deterministic goal→focus→evidence→verification→passport, restart persistence, demo script, real log, backup web.
- **P0 STOP**: data loss, false verified, crashes on golden path, no recoverable demo, fictitious pilots or partnership.
- **P1**: aesthetics polishing, real AI backend (only if already configured), real media file attachment, one-pager.
- **P2**: HEMIS sync, AI grade appeal, rewards auction, Rector/dean messaging, monetization infrastructure, full refactor.
