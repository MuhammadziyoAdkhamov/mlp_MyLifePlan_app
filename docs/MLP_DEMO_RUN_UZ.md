# MLP demoni ochish va topshirish

Faol manba: `lib/main.dart`. Yangi UI shu entrypointdan ochiladi. `lib/main_legacy.dart` yoki eski APKni yangi versiya sifatida ishlatmang.

## Hozir ochish

Ushbu sessiyada mahalliy web demo: http://127.0.0.1:8765/ . Codex brauzer panelida ham ochilgan. Bu public sayt emas; o‘z kompyuteringizdagi web build.

Server yopilgan bo‘lsa, loyiha ildizida:

```powershell
python -m http.server 8765 --bind 127.0.0.1 --directory build/web
```

Brauzerdan yuqoridagi manzilni oching. Firebase yoki API kaliti talab qilinmaydi. `Mehmon sifatida kirish` orqali sinash mumkin. Web ma’lumoti shu browser/originda saqlanadi; Android ma’lumoti bilan avtomatik sinxronlash yo‘q.

## 5 daqiqalik namoyish

1. Welcome → mehmon yoki tasdiqlanmagan demo profil.
2. Maqsadlar → yangi maqsad → erkin matn → aniqlashtirish → namuna diagnostika yoki o‘z bahosi → tahrirlangan yo‘l xaritasi.
3. Bugun → keyingi vazifa yoki 5 daqiqalik qadam.
4. Taqvim → mashg‘ulot → vaqt/takror/eslatma niyati → to‘qnashuv/sig‘im ogohlantirishini tekshirish.
5. Fokus → preset/custom → faol vaqt → pauza → yakun → qayd saqlash. Topshirilgan vazifa bilan bir xil deb hisoblanmaydi.
6. Maqsadlar → vazifa → hisobot/baholash → dalil yoki uch savolli namuna test. Pasport va rivojlanishdan manbalar ajratilganini ko‘rsatish.
7. Ustoz → demo savol → mahalliy javob; ism/uslub/kontekst va voice-state UI.
8. Profil → virtual yutuqlar, preview weather, Soundspace, sozlamalar/nusxa. Ulanmagan xizmatlar aniq yozilgan.
9. Sahifani qayta ochib mahalliy ma’lumot tiklanishini ko‘rsatish.

## Qayta tekshirish

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter build web --release --no-pub --no-wasm-dry-run --optimization-level=1
```

Disk sig‘imi kamligi sabab testlarni ketma-ket bajarish ishlatiladi. Source screenshots: `build/mlp_ui_phase_b/`; saqlangan dalillar: `docs/evidence/sprint01/`.

Android build qayta sinab ko‘rildi: Java `Unable to establish loopback connection` sabab muvaffaqiyatsiz. Eski APK mavjud bo‘lishi uning yangi UI ekanini bildirmaydi. Keyingi ish — Android host/build muammosi va fizik qurilmadagi smoke test. UI demo real SMS/Google, push delivery, live AI/STT/TTS, live ob-havo yoki audio ijrosi borligini va’da qilmaydi.
