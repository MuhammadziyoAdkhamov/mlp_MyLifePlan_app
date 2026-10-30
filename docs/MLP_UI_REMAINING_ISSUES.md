> **2026-10-30:** 27 ekranli yangi namuna bo‘yicha o‘zgarishlar davom etmoqda. Quyidagi eski test/render natijalari joriy kodga avtomatik tatbiq etilmaydi. Yangi holat: `MLP_UI_PROGRESS.md`; yangi loglar: `evidence/ios-reference-2026-10-29/`.

# MLP: ochiq masalalar va release chegaralari

2026-10-28. Joriy dalil: `MLP_UI_FIXES_COMPLETED.md` va
`docs/evidence/ui-audit-2026-10-28/`. 31 asosiy ekran holati tekshirildi,
10 UI topilmasi tuzatildi, 130 test o‘tdi. Bu native release uchun 100% emas.

| Ustuvorlik | Qolgan masala | Aniq dalil / keyingi amal |
|---|---|---|
| P0 release gate | Joriy Android APK yig‘ilmadi | Yangi `flutter build apk --debug --no-pub` exit 1: `java.io.IOException: Unable to establish loopback connection`. `android-build.log`. Host Java/Gradle loopback tashxislanishi kerak; yangi APK bor deb tarqatilmasin |
| P0 release gate | Joriy ilovaning Android runtime smoke testi ochiq | Pixel_4a headless ishga tushdi va ADB emulator-5554 device bo‘ldi; build yiqilgani uchun yangi ilova o‘rnatilmadi. Emulyatorning mavjudligi app testi o‘tganini bildirmaydi |
| P1 | Toolchain | Doctor: Android license status unknown; Windows native uchun Visual Studio yo‘q. Windows native build ushbu Android loyihasi uchun shart emas. SDK litsenziyasi tekshirilishi kerak |
| P1 | Ordinary core CRUD disk rejection | UI xato ko‘rsatadi, lekin ayrim task/habit/goal amallari diskdan oldin memoryni o‘zgartiradi. Saqlanmagan holatga rollback/retry va restart regressiyasi zarur. Atomic roadmap/focus va UI repository himoyalari saqlangan |
| P1 | To‘liq backup restore | Export core+UI+fonni qamraydi; eski import faqat core. Versionli to‘liq importer, preview, rollback va duplicate siyosati kerak |
| P1 | Native accessibility/lifecycle | TalkBack, real keyboard/gesture back, permission-denied gallery, lost-picker recovery, background/restart va uzoq sessiya fizik Androidda tekshiriladi. 60 FPS hali o‘lchanmagan |
| P1 production | Auth/account isolation/cloud | Faol app lokal demo. Eski Firebase/Google servislarining mavjudligi yangi oqimni xavfsiz cloud app qilmaydi. User ownership, guest migration va deletion sinovlari kerak |
| P1 production | Real tashqi xizmatlar | Matnli AI, STT/TTS, jonli weather, audio playback, local/push delivery, billing va partner rewards hozir to‘liq real ulanmagan. UI ularni preview/unavailable deb aytadi; reja `MLP_REAL_APP_ROADMAP_UZ.md`da |
| P2 | Katta tarix | 500 schedule/100 chat kabi mahalliy limitlar bor; productionda ehtiyojga qarab paging va migration, tasodifiy yangi infratuzilma emas |
| Keyingi platforma | iOS | Foydalanuvchi tanlovi: keyin. Mac/Xcode/iPhone/signing talab qilinadi; iOS 15 target va galereya description mavjud, native build/VoiceOver tasdiqlanmagan |

31 screenshot Flutter widget fixture renderidir; ular real telefondan olingan
rasmlar emas. 30 primary screenning kengaytirilgan layout matritsasi va fon
sahifasining alohida testi bor. Har nested dialogning har bir OS/text-scale
kombinatsiyasi manual tekshirilgan deb da’vo qilinmaydi.

**Keyingi yagona chipta: ANDROID-01.** Java/Gradle loopback sababini aniqlash,
joriy APK build, keyin guest → custom goal → task → schedule → focus → qayd →
self-report → restart, gallery va system-back oqimlari. Eslatma yetkazish
ulanmaguncha schedule intent “xabarnoma keldi” deb hisoblanmaydi.

SDK/host to‘sig‘i uchun ilova UI kodi qayta yozilmasin. Mavjud dirty fayllar,
staged `D lib/firebase_options.dart` va boshqa AI ishlari reset qilinmasin.
