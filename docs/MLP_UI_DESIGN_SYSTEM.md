# MLP UI dizayn tizimi

Manba: `lib/app/theme/mlp_design_system.dart`; umumiy komponentlar: `lib/core/design_system/mlp_widgets.dart`.

Ranglar bitta manbadan olinadi: fon #090F22, ikkilamchi #101A34, ko‘tarilgan #172342, binafsha #8C6BFF, och binafsha #B6A3FF, firuza #44D8CD, muvaffaqiyat #51D3A1, ogohlantirish #F4BC68, asosiy matn #F7F8FF, ikkilamchi #AAB6D5, sust #7887AB. Demo integratsiya holati muvaffaqiyat deb ranglanmaydi. Tugma fonida och binafsha va to‘q matn ishlatiladi.

Tipografiya: 32/28/24/20/16/14/12; matn qatori 1.2–1.5. Tarmoqdan shrift yuklanmaydi. Segoe UI mavjud bo‘lmagan platformada tizim fallback shrifti ishlaydi. Androiddagi haqiqiy shrift ko‘rinishi hali qurilmada tekshirilmagan.

Kartalar radiusi 20, boshqaruvlar 14, asosiy chet 24, ixcham chet 20. Tegish nishoni kamida 48 mantiqiy piksel. Harakat 180 ms, sahifa almashinuvi 240 ms; `disableAnimations` bilan nol. Doimiy cheksiz orb animatsiyasi yo‘q.

Komponentlar: MLPScaffold, MLPAppBar, MLPFloatingTabBar, MLPPrimaryButton, MLPSecondaryButton, MLPIconButton, MLPGlassCard, MLPSectionHeader, MLPTextField, MLPPhoneField, MLPGoalCard, MLPTaskCard, MLPProgressBar, MLPProgressRing, MLPStatCard, MLPEmptyState, MLPLoadingState, MLPErrorState, MLPConfirmationSheet, MLPToast, MLPAvatarOrb, MLPRewardCard, MLPTimerDisplay.

Tab tartibi: Bugun → Maqsadlar → Fokus → Ustoz → Profil. Yangi tab komponentida matn/ikonka/selected semantikasi bor. Faol eski ish stoli hozircha eski navigatsiyasini saqlagan; keyingi bosqichda yangi shellga ulanadi.

Formalar: label, validator, cheklangan uzunlik, kutilayotgan operatsiyada takroriy bosishni to‘sish, xato matni va qayta urinish. Scroll va SafeArea klaviatura/kichik ekran uchun ishlatiladi. Semantika, katta shrift va turli ekran testlari QA hisobotidagi dalil bilan belgilanadi; bu hujjatning o‘zi tekshiruv isboti emas.

Mahalliy qo‘shimcha UI saqlov: `mlp_ui_prototype_v1`; mavjud vazifalar/maqsadlar kaliti o‘zgarmaydi. Yozish avval diskda tasdiqlanadi, keyin yangi UI holati e’lon qilinadi. Demo telefon hech qachon tasdiqlangan identifikatsiya deb belgilanmaydi.
