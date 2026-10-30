# MLP: hozirgi holatdan real ilovagacha

2026-10-28. Foydalanuvchi qarorlari: **avval Android; iOS keyin**. Birinchi
auditoriya O‘zbekistondagi IT talaba va juniorlar. Avval haqiqiy matnli Ustoz AI.
Server/AI uchun oyiga $0–20 maqsadli limit. Keyinchalik ovoz, ob-havo, audio,
pullik xizmatlar va hamkor mukofotlari ham haqiqiy ulanadi; ular bekor qilinmagan.

## Bugungi holat

Faol entrypoint mahalliy Flutter ilova: goal/task/habit CRUD, reja, timestamp
fokus, self-report, namuna test, statistika, chat tarixi va fon rasmi mavjud.
30 route + fon sozlamasi bor. Asosiy dizayn qayta yozilmaydi. Firebase paketlari
va eski servislar mavjudligi faol yangi oqimda login/cloud ishlashini isbotlamaydi.
AI javobi deterministik, ovoz/ob-havo/audio va xabarnoma yetkazish hozir namuna.
UI dalillari: `MLP_UI_AUDIT_REPORT.md`, `MLP_UI_FIXES_COMPLETED.md`.

## Ish tartibi: faqat zarur chiptalar

| Navbat / chipta | Amal va bog‘liqlik | Qabul dalili |
|---|---|---|
| 1 · ANDROID-01 | Joriy manbadan debug APK build, mavjud Java/Gradle loopback muammosini tashxislash; fizik Androidga o‘rnatish | Guest → erkin maqsad → vazifa → fokus → qayd → restart; log, qurilma/OS, screenshot. Background, keyboard, back, gallery ham tekshiriladi |
| 2 · DATA-01 | Oddiy core CRUD disk xatosida rollback; core+UI+fon to‘liq versionli backup/restore; mavjud kalitlarni saqlash | Disk rejection, retry, buzilgan import, duplicate import, restart testlari; asl ma’lumot saqlanadi |
| 3 · AUTH-01 | Faol oqimga Google/guest auth ulash; zarur bo‘lsa telefon OTP keyingi kichik chipta. Guest → account migration foydalanuvchi tasdig‘i bilan | Ikki hisob aralashmaydi; cancel/error/offline/login/logout/restart; soxta SMS yo‘q |
| 4 · CLOUD-01 | AUTH-01 va DATA-01dan keyin user-scoped repository, offline queue, konflikt siyosati, ownership qoidalari va account deletion | Ikki qurilma sinxi; A foydalanuvchi B ma’lumotini o‘qiy/yoza olmaydi; qayta urinish dublikat yaratmaydi; emulator rules test |
| 5 · REMIND-01 | Mavjud schedule intentni Android local notificationga ulash; ruxsat, timezone, edit/delete/cancel, qayta rejalash | Haqiqiy telefonda kelish va bekor qilish dalili; ruxsat radida tushunarli holat. OS cheklovlari ochiq |
| 6 · AI-01 | Server orqali matnli AI adapter; clientda maxfiy kalit yo‘q; timeout/retry/quota, ma’lumot ulashishni tanlash, schema validation | Uzbek maqsad → tahrirlanadigan haftalik reja; qabuldan oldin hech narsa avtomatik yozilmaydi; limit tugashi va xavfsiz fallback testi |
| 7 · RESULT-01 | Vazifaga natija URL/qayd, self-report/namuna test/mentor tasdig‘ini alohida ko‘rsatish; haftalik reja moslashuvi | Fokus daqiqasi malaka deb chiqmaydi; bajarilgan ish va tekshirilgan bilim alohida; foydalanuvchi keyingi amalni tushunadi |
| 8 · PILOT-01 | 10–15 IT talaba/junior bilan yopiq Android pilot; minimal rozilikli eventlar, xato hisobotlari, recovery/help/privacy; avval 1–7 ishonchli | P0/P1 yopiq; birinchi natija, D7 qaytish va takroriy natija soni; foydalanuvchi kuzatuvi; release build dalili |
| 9 · LIVE-01 | Ob-havo: manba/time/city/failure/cache. Audio: litsenziyasi tasdiqlangan kichik katalog, play/pause/sleep, audio focus | Offline va ruxsat radida halol holat; background audio haqiqiy qurilmada; har audio uchun foydalanish huquqi |
| 10 · VOICE-01 | Matnli AI barqarorlashgach push-to-talk STT/TTS; permission, cancel, recording indication, quota | Mikrofon faqat aniq amal bilan; transcript xatosi tahrirlanadi; real latency/cost o‘lchanadi. Wakeword va overlay talab qilinmaydi |
| 11 · COMMERCE-01 | Pullik imkoniyatlar uchun store billing va entitlement server tekshiruvi; hamkor mukofotlari uchun haqiqiy kelishuv/inventar/redemption | Sandbox purchase/restore/cancel/refund; haqiqiy hamkorsiz vaucher va’da qilinmaydi; huquqsiz musiqa qo‘shilmaydi |
| 12 · IOS-01 | Android pilotdan keyin Mac/Xcode, signing va iPhone; mavjud Flutter UI saqlanadi | iOS build/install, SafeArea/VoiceOver/gallery/audio/notification, TestFlight; Windows web ko‘rinishi iOS dalili emas |

Har chipta uchun mavjud testlar saqlanadi; tegishli regressiya + `flutter analyze`
va to‘liq suite yuritiladi. Provider/SDK tanlovidan oldin uning amaldagi narxi,
hududiy imkoniyati va shartlari tekshiriladi. Barcha servislarni $20 ichida
cheklanmagan ishlatish va’da qilinmaydi. Dastlab kam sonli foydalanuvchi, server
tomonda kunlik AI/ovoz limitlari, oylik budjet nazorati va limitda to‘xtash kerak.
Store hisoblari, SMS, musiqa huquqlari va hamkor hisob-kitobi alohida xarajat.

## Bozorda aniq o‘rin

**Taklif gipotezasi:** “O‘zbek tilida maqsadni bugungi kichik amaliy ishga aylantir,
diqqat bilan bajar va haftada ko‘rinadigan portfolio natijasini yig‘.”
Oddiy timer yoki umumiy chatbotning o‘zi yetarli farq bermaydi.

- [TickTick](https://ticktick.com/features) vazifa, kalendar, odat va fokusni
  birlashtiradi. MLP farqi sifatida faqat shu funksiyalarni sanamaymiz.
- [Habitica](https://habitica.com/static/features) o‘yin va mukofot orqali odat
  yaratadi. Bizning sinovimiz: ball yig‘ishdan tashqari amaliy ishni yakunlash.
- Rasmiy statistikada 2025/26 boshida **1,535 mln talaba** bor. Bu barcha
  yo‘nalishlar bo‘yicha yuqori auditoriya chegarasi; IT segmenti yoki to‘lovchi
  bozor hajmi emas. [Statistika qo‘mitasi](https://stat.uz/ru/press-tsentr/novosti-goskomstata/68785-talabalar-soni-1-5-mln-nafarga-etdi-ajollar-ulushi-yu-ori-3).

Hozir daromadli bozor hajmi isbotlanmagan. Pastdan hisoblash: biz yetib bora
oladigan IT guruhlari × qiziqqanlar × faollashganlar × qaytganlar × real to‘lovga
rozi bo‘lganlar. Dastlab 2–3 o‘quv guruhi va 10–15 pilot foydalanuvchi bilan
dalil yig‘iladi; kelishilmagan hamkorlik bo‘lgan deb yozilmaydi.

Ichki pilot mezonlari, prognoz emas: birinchi 24 soatda goal+task+natija ≥60%;
D7 qaytish ≥35%; haftada 3 kun natija qayd etish ≥30%. 10–15 kishilik pilot
statistik bozor isboti emas — ulush bilan birga odam soni va sabablar yoziladi.
Foydalanuvchi qaytmasa reklama/katta katalog emas, eng og‘riqli oqim tuzatiladi.
Asosiy reja/fokus bepul; pullik AI yoki haftalik tahlil faqat foyda va to‘lovga
tayyorlik amalda tekshirilgach. Narx hozir uydirilmaydi.

Yangi shaxsiy Google Play hisobiga tegishli bo‘lsa, production arizasidan oldin
12 testerning 14 kun uzluksiz opt-in talabi bor; 10 kishilik pilotning o‘zi
bu talabni bajarmaydi. [Google Play](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en).
Cloudga shaxsiy ma’lumot uzatishdan oldin amaldagi O‘zbekiston qoidalariga mos
saqlash/transfer asosini tekshirish kerak; oddiy rozilik hamma holatga yetadi deb
qabul qilinmaydi. [2026-yilgi o‘zgarish](https://lex.uz/uz/acts/-8099215?ONDATE=27.03.2026+00).

## Progress va boshqa AI bilan hamkorlik

`MLP_UI_FIXES_COMPLETED.md` — bu auditning tekshirilgan natijalari;
`MLP_UI_REMAINING_ISSUES.md` — joriy ochiq to‘siqlar. Eski 85/100 UI bahosi
production tayyorligi foizi emas. “100%” faqat tegishli scope va barcha dalillar
bilan yoziladi. Har real yopilgan qabul mezoni bilan status yangilanadi; foiz
ishlatilsa oldindan belgilangan mezonlar asosida hisoblanadi, vaqt yoki kod
satridan taxmin qilinmaydi. Hozir native release mezonlari yopilmagan.

Boshqa AI boshlashidan oldin: `git status`, ushbu uch hujjat, faol entrypoint,
`MLP_AI_HANDOFF_2026-10-28.txt` oxirgi qo‘shimchasini o‘qisin. Bir vaqtda bir
faylni ikki AI o‘zgartirmasin. Mavjud dirty ishlarni reset/clean yoki umumiy
commit qilmasin. Keyingi yagona chipta: **ANDROID-01**; qolganlari navbat.
