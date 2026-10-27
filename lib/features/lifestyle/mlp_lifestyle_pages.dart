import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../data/models/mlp_schedule.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import '../onboarding/mlp_account_flow.dart';

class MLPReward {
  const MLPReward(this.id, this.title, this.xp, this.color);
  final String id, title;
  final int xp;
  final Color color;
  static const all = [
    MLPReward('cyan', 'Firuza boshlanish', 0, MLPColors.turquoise),
    MLPReward('violet', 'Binafsha intilish', 100, MLPColors.primaryLight),
    MLPReward('amber', 'Oltin davomiylik', 500, MLPColors.warning),
  ];
}

class MLPRewardsPage extends StatelessWidget {
  const MLPRewardsPage({super.key, required this.e});
  final MLPEnvironment e;
  Future<void> detail(
    BuildContext context,
    MLPReward reward,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => ListenableBuilder(
      listenable: e.ui,
      builder: (context, _) {
        final locked = e.store.xp < reward.xp;
        final used = e.ui.cosmetic == reward.id;
        final earned = e.ui.claimedRewards.contains(reward.id);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 64,
                color: reward.color,
              ),
              const SizedBox(height: 20),
              Text(
                reward.title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                locked
                    ? '${reward.xp} faollik XP kerak. Hozir: ${e.store.xp}.'
                    : used
                    ? 'Profilingizda ishlatilmoqda.'
                    : earned
                    ? 'Olingan. Qayta tanlashingiz mumkin.'
                    : 'Olish mumkin — bepul virtual bezak.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const MLPNotice(
                'Faqat shu qurilmadagi profil halqasi rangi. Pul, sovg‘a, chegirma yoki ko‘nikma tasdig‘i emas. Namuna ma’lumotlar XP hisobiga kirishi mumkin.',
              ),
              MLPPrimaryButton(
                label: locked
                    ? 'Hozircha yopiq'
                    : used
                    ? 'Tanlangan'
                    : 'Profilga qo‘llash',
                onPressed: locked || used
                    ? null
                    : () => e.act(context, () async {
                        // Eligibility is checked again at action time, not just by presentation.
                        if (e.store.xp < reward.xp) {
                          throw StateError('XP yetarli emas.');
                        }
                        await e.ui.useCosmetic(reward.id);
                      }, success: 'Virtual bezak tanlandi.'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheet),
                child: const Text('Yopish'),
              ),
            ],
          ),
        );
      },
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([e.store, e.ui]),
    builder: (context, _) => MLPPage(
      title: 'Yutuqlar',
      children: [
        const MLPNotice(
          'Virtual motivatsiya. XP — mahalliy faollik, mustaqil baholangan mahorat emas.',
        ),
        MLPMetrics(
          items: [
            (value: '${e.store.xp}', label: 'Faollik XP', icon: Icons.bolt),
            (
              value: '${e.store.level}',
              label: 'Faollik bosqichi',
              icon: Icons.trending_up,
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...MLPReward.all.map(
          (r) => MLPMenuTile(
            title: r.title,
            subtitle: e.store.xp < r.xp
                ? 'Yopiq · ${r.xp} XP'
                : e.ui.cosmetic == r.id
                ? 'Ishlatilmoqda'
                : e.ui.claimedRewards.contains(r.id)
                ? 'Olingan'
                : 'Olish mumkin · virtual',
            icon: e.store.xp < r.xp ? Icons.lock_outline : Icons.auto_awesome,
            onTap: () => detail(context, r),
          ),
        ),
        MLPMenuTile(
          title: 'Hamkor sovg‘alari',
          subtitle: 'Mavjud emas · kelajak g‘oyasi',
          icon: Icons.card_giftcard,
          onTap: () => e.info(
            context,
            'Hamkor mukofotlari mavjud emas',
            'Bu prototipda hamkorlik, pul to‘lovi yoki sovg‘a yetkazib berish xizmati ulanmagan. Hech narsa buyurtma qilinmaydi.',
          ),
        ),
      ],
    ),
  );
}

class MLPWeatherPage extends StatefulWidget {
  const MLPWeatherPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPWeatherPage> createState() => _WeatherState();
}

class _WeatherState extends State<MLPWeatherPage> {
  int day = 0;
  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: e.ui,
      builder: (context, _) {
        final date = e.store.today.add(Duration(days: day));
        final schedules = e.ui.schedules
            .where((s) => s.occursOn(date))
            .toList();
        return MLPPage(
          title: 'Ob-havo va reja',
          children: [
            const MLPNotice(
              'NAMUNA PROGNOZ. Jonli ob-havo yoki joylashuv ulanmagan. Quyidagi haroratga qarab muhim qaror qilmang.',
              warning: true,
            ),
            DropdownButtonFormField<String>(
              initialValue: e.ui.city,
              decoration: const InputDecoration(
                labelText: 'Shahar · qo‘lda tanlash',
              ),
              items: [
                'Toshkent',
                'Samarqand',
                'Buxoro',
                'Andijon',
              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) {
                if (v != null) e.act(context, () => e.ui.selectCity(v));
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Bugun'),
                  selected: day == 0,
                  onSelected: (_) => setState(() => day = 0),
                ),
                ChoiceChip(
                  label: const Text('Ertaga'),
                  selected: day == 1,
                  onSelected: (_) => setState(() => day = 1),
                ),
              ],
            ),
            const SizedBox(height: 20),
            MLPGlassCard(
              accent: true,
              child: Column(
                children: [
                  Icon(
                    day == 0 ? Icons.wb_sunny_outlined : Icons.cloud_outlined,
                    size: 64,
                    color: MLPColors.turquoise,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    day == 0 ? '22°' : '18°',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  Text('${e.ui.city} · ${mlpDayKey(date)} · namuna'),
                  const SizedBox(height: 12),
                  const Text(
                    'Ochiq havodagi rejangizni haqiqiy prognoz bilan tekshiring.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const MLPSectionHeader(title: 'Shu kundagi mashg‘ulotlar'),
            const SizedBox(height: 12),
            if (schedules.isEmpty)
              const MLPEmptyState(
                title: 'Mashg‘ulot yo‘q',
                message: 'Taqvimdan yangi vaqt belgilang.',
              ),
            ...schedules.map(
              (s) => MLPMenuTile(
                title: s.title,
                subtitle:
                    '${mlpTime(s.startMinute)}–${mlpTime(s.endMinute)} · ko‘chirish uchun oching',
                icon: Icons.calendar_month_outlined,
                onTap: () => e.go(
                  MLPScreen.scheduleEditor,
                  args: MLPRouteArgs(scheduleId: s.id),
                ),
              ),
            ),
            MLPSecondaryButton(
              label: 'Taqvimni ochish',
              onPressed: () => e.go(MLPScreen.calendar),
            ),
          ],
        );
      },
    );
  }
}

class MLPSoundspacePage extends StatefulWidget {
  const MLPSoundspacePage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  State<MLPSoundspacePage> createState() => _SoundState();
}

class _SoundState extends State<MLPSoundspacePage> {
  String? selected;
  bool favoritesOnly = false;
  static const tracks = [
    ('forest', 'O‘rmon muhiti', 'Tabiat', Icons.forest_outlined),
    ('rain', 'Yomg‘ir', 'Tabiat', Icons.water_drop_outlined),
    ('deep', 'Chuqur diqqat', 'Fokus', Icons.graphic_eq),
    ('calm', 'Sokin nafas', 'Dam olish', Icons.spa_outlined),
  ];
  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: e.ui,
      builder: (context, _) {
        final category = e.ui.soundIntent['category'] as String;
        final visible = tracks.where(
          (t) =>
              favoritesOnly ? e.ui.favorites.contains(t.$1) : t.$3 == category,
        );
        return MLPPage(
          title: 'MLP Soundspace',
          children: [
            const MLPNotice(
              'Katalog ko‘rinishi. Litsenziyalangan audio fayllar hali yo‘q; ovoz ijro etilmaydi. Tanlanganlar va uyqu taymeri niyati saqlanadi.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ['Fokus', 'Tabiat', 'Dam olish'])
                  ChoiceChip(
                    label: Text(c),
                    selected: !favoritesOnly && category == c,
                    onSelected: (_) {
                      setState(() => favoritesOnly = false);
                      e.act(
                        context,
                        () => e.ui.saveSoundIntent(
                          c,
                          e.ui.soundIntent['sleep'] as int,
                        ),
                      );
                    },
                  ),
                FilterChip(
                  label: const Text('Sevimlilar'),
                  selected: favoritesOnly,
                  onSelected: (v) => setState(() => favoritesOnly = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (visible.isEmpty)
              const MLPEmptyState(
                title: 'Tanlangan audio yo‘q',
                message: 'Yurak belgisi bilan katalogga qo‘shing.',
              ),
            ...visible.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MLPGlassCard(
                  padding: 8,
                  child: ListTile(
                    leading: Icon(t.$4, color: MLPColors.turquoise),
                    title: Text(t.$2),
                    subtitle: const Text('Namuna · ijro mavjud emas'),
                    onTap: () => setState(() => selected = t.$1),
                    trailing: IconButton(
                      tooltip: 'Sevimlilarga qo‘shish yoki olib tashlash',
                      icon: Icon(
                        e.ui.favorites.contains(t.$1)
                            ? Icons.favorite
                            : Icons.favorite_outline,
                      ),
                      onPressed: () =>
                          e.act(context, () => e.ui.toggleFavorite(t.$1)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: e.ui.soundIntent['sleep'] as int,
              decoration: const InputDecoration(
                labelText: 'Uyqu taymeri · tanlov',
              ),
              items: [0, 15, 30, 60]
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text(n == 0 ? 'O‘chirilgan' : '$n daqiqa'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  e.act(context, () => e.ui.saveSoundIntent(category, v));
                }
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Ovoz ulanmaguncha taymer ishlamaydi.',
              style: TextStyle(color: MLPColors.secondaryText),
            ),
            if (selected != null) ...[
              const SizedBox(height: 24),
              MLPGlassCard(
                accent: true,
                child: Column(
                  children: [
                    Text(
                      tracks.firstWhere((t) => t.$1 == selected).$2,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    const Text('Ijrochi ko‘rinishi · audio mavjud emas'),
                    const SizedBox(height: 12),
                    MLPSecondaryButton(
                      label: 'Nega ovoz yo‘q?',
                      icon: Icons.info_outline,
                      onPressed: () => e.info(
                        context,
                        'Audio hali ulanmagan',
                        'Bu ko‘rinish ijro holatini taqlid qilmaydi. Litsenziyalangan fayllar va audio xizmati ulangach ijro imkoniyati ochiladi.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class MLPProfilePage extends StatelessWidget {
  const MLPProfilePage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([e.ui, e.store]),
    builder: (context, _) {
      final name = e.ui.profile?.name ?? 'Mehmon';
      final color =
          MLPReward.all
              .where((r) => r.id == e.ui.cosmetic)
              .firstOrNull
              ?.color ??
          MLPColors.turquoise;
      return MLPPage(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Profil',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Sozlamalar',
                onPressed: () => e.go(MLPScreen.settings),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),
          MLPGlassCard(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: .15),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      const Text(
                        'Katta maqsadlar sari, har kuni bir qadam.',
                        style: TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MLPMetrics(
            items: [
              (
                value: '${e.store.streak}',
                label: 'Faol kunlar ketma-ketligi',
                icon: Icons.local_fire_department_outlined,
              ),
              (
                value: '${e.store.todayFocusMinutes}',
                label: 'Bugun fokus · daqiqa',
                icon: Icons.timelapse,
              ),
              (
                value: '${e.store.goals.length}',
                label: 'Mahalliy maqsadlar',
                icon: Icons.flag_outlined,
              ),
            ],
          ),
          const SizedBox(height: 24),
          MLPMenuTile(
            title: 'Ko‘nikmalar pasporti',
            icon: Icons.verified_outlined,
            onTap: () => e.go(MLPScreen.passport),
          ),
          MLPMenuTile(
            title: 'Mening yutuqlarim',
            icon: Icons.emoji_events_outlined,
            onTap: () => e.go(MLPScreen.rewards),
          ),
          MLPMenuTile(
            title: 'Maqsadlarim',
            icon: Icons.flag_outlined,
            onTap: () => e.tab(1),
          ),
          MLPMenuTile(
            title: 'Rivojlanishim',
            icon: Icons.bar_chart_outlined,
            onTap: () => e.go(MLPScreen.analytics),
          ),
          MLPMenuTile(
            title: 'Ob-havo va reja',
            icon: Icons.cloud_outlined,
            onTap: () => e.go(MLPScreen.weather),
          ),
          MLPMenuTile(
            title: 'MLP Soundspace',
            icon: Icons.headphones_outlined,
            onTap: () => e.go(MLPScreen.soundspace),
          ),
          MLPMenuTile(
            title: 'MLP Pro',
            subtitle: 'Obuna va to‘lov mavjud emas',
            icon: Icons.workspace_premium_outlined,
            onTap: () => e.info(
              context,
              'MLP Pro',
              'Yopiq demo uchun obuna sotilmaydi. To‘lov, karta yoki pullik xizmat ulanmagan.',
            ),
          ),
          const MLPNotice(
            'Mahalliy demo profil. Telefon tasdiqlanmagan. Ma’lumotlar shu qurilmada saqlanadi.',
          ),
          MLPSecondaryButton(
            label: 'Profildan chiqish',
            onPressed: () async {
              final yes = await MLPConfirmationSheet.show(
                context,
                title: 'Profildan chiqilsinmi?',
                message:
                    'Mahalliy ma’lumotlar saqlanadi. Bu qurilmada profillar alohida hisoblar sifatida ajratilmagan.',
              );
              if (yes && context.mounted) {
                await e.act(context, () async {
                  e.focus.pause();
                  e.tab(0);
                  await e.ui.exitSession();
                });
              }
            },
          ),
        ],
      );
    },
  );
}

class MLPSettingsPage extends StatelessWidget {
  const MLPSettingsPage({super.key, required this.e});
  final MLPEnvironment e;
  Future<void> _identity(BuildContext context) async {
    final controller = TextEditingController(
      text: e.ui.profile?.name ?? 'Mehmon',
    );
    final form = GlobalKey<FormState>();
    bool busy = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: const Text('Profil nomi'),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MLPTextField(
                    label: 'Ism',
                    controller: controller,
                    maxLength: 60,
                    validator: (v) => (v ?? '').trim().length < 2
                        ? 'Kamida 2 belgi kiriting.'
                        : null,
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(color: MLPColors.error),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialog),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      refresh(() => busy = true);
                      try {
                        await e.ui.saveWorkspaceIdentity(
                          controller.text.trim(),
                          e.ui.preferences.minutes,
                        );
                        if (dialog.mounted) Navigator.pop(dialog);
                      } catch (_) {
                        if (dialog.mounted) {
                          refresh(() {
                            busy = false;
                            error = 'Saqlanmadi. Qayta urinib ko‘ring.';
                          });
                        }
                      }
                    },
              child: Text(busy ? 'Saqlanmoqda…' : 'Saqlash'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  Future<void> _backup(BuildContext context) async {
    final json = const JsonEncoder.withIndent('  ').convert({
      'schema': 'mlp.ui.bundle',
      'version': 1,
      'core': jsonDecode(e.store.exportJson()),
      'ui': jsonDecode(e.ui.exportUiState()),
    });
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('To‘liq mahalliy nusxa'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: SelectableText(json, style: const TextStyle(fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Yopish'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (dialog.mounted) {
                MLPToast.show(
                  dialog,
                  'Nusxa buferga ko‘chirildi. Unda shaxsiy qaydlaringiz bor.',
                );
              }
            },
            child: const Text('Nusxalash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: e.ui,
    builder: (context, _) => MLPPage(
      title: 'Sozlamalar',
      children: [
        MLPMenuTile(
          title: 'Profil ma’lumotlari',
          subtitle: e.ui.profile?.name,
          icon: Icons.person_outline,
          onTap: () => _identity(context),
        ),
        MLPMenuTile(
          title: 'Shaxsiy tanlovlar',
          subtitle: '${e.ui.preferences.minutes} daqiqa / kun',
          icon: Icons.tune,
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: '/preferences'),
              builder: (_) => MLPPreferencesScreen(repository: e.ui),
            ),
          ),
        ),
        MLPMenuTile(
          title: 'Ustoz va ruxsatlar',
          icon: Icons.auto_awesome,
          onTap: () => e.go(MLPScreen.aiPersonalization),
        ),
        MLPMenuTile(
          title: 'Bildirishnomalar',
          subtitle: 'Faqat mahalliy reja · yetkazish ulanmagan',
          icon: Icons.notifications_none,
          onTap: () => e.go(MLPScreen.notifications),
        ),
        MLPMenuTile(
          title: 'Mavzu',
          subtitle: 'Qorong‘i · firuza',
          icon: Icons.dark_mode_outlined,
          onTap: () => e.info(
            context,
            'Qorong‘i mavzu',
            'Ushbu versiyada qorong‘i mavzu tayyor. Tizimdagi kamaytirilgan harakat va kattalashtirilgan matn tanlovlari hisobga olinadi. Yorug‘ mavzu hozircha mavjud emas.',
          ),
        ),
        MLPMenuTile(
          title: 'Til',
          subtitle: 'O‘zbekcha · lotin',
          icon: Icons.translate,
          onTap: () => e.info(
            context,
            'Ilova tili',
            'Interfeys o‘zbekcha lotin yozuvida. Boshqa tillar hali tarjima qilinmagan.',
          ),
        ),
        SwitchListTile.adaptive(
          title: const Text('Ustoz tezkor tugmasi'),
          subtitle: const Text('Faqat ilova ichida'),
          value: !e.ui.assistantHidden,
          onChanged: (v) => e.act(context, () => e.ui.hideAssistant(!v)),
        ),
        MLPMenuTile(
          title: 'Mahalliy nusxa olish',
          subtitle: 'Maqsadlar, qaydlar, taqvim va UI tanlovlari · JSON',
          icon: Icons.save_alt,
          onTap: () => _backup(context),
        ),
        MLPMenuTile(
          title: 'Ma’lumotlar va avvalgi ish oynasi',
          subtitle:
              'Vazifa va odatlar CRUD, asosiy JSON import/eksport, CSV va ICS',
          icon: Icons.inventory_2_outlined,
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => e.legacy()),
          ),
        ),
        const MLPNotice(
          'Asosiy JSON import eski ma’lumotlar oynasida faqat vazifa, maqsad, odat va faoliyatni tiklaydi. To‘liq UI nusxasini import qilish hali mavjud emas. Uni asosiy JSON importeriga bermang.',
        ),
        MLPMenuTile(
          title: 'Maxfiylik',
          icon: Icons.shield_outlined,
          onTap: () => e.info(
            context,
            'Mahalliy demo va maxfiylik',
            'Bu ish oqimida hisob, chat va baholash shu qurilmada saqlanadi. Serverga AI so‘rovi yuborilmaydi; mikrofon, kamera va joylashuv so‘ralmaydi. Mahalliy saqlov shifrlanmagan. Umumiy qurilmada maxfiy ma’lumot kiritmang. Eksportni faqat o‘zingiz ishonadigan joyda saqlang.',
          ),
        ),
        MLPMenuTile(
          title: 'Yordam va fikr-mulohaza',
          icon: Icons.help_outline,
          onTap: () => e.info(
            context,
            'Beta tekshiruvi',
            'Muammo haqida ekran nomi, bajarilgan qadamlar, kutilgan va amaldagi natijani loyiha egasiga yetkazing. Ilova ichida yuborish xizmati hali ulanmagan.',
          ),
        ),
        MLPMenuTile(
          title: 'Ilova haqida',
          subtitle: 'MLP · mahalliy UI prototip',
          icon: Icons.info_outline,
          onTap: () => e.info(
            context,
            'MLP',
            'Talaba va junior mutaxassislar uchun: maqsad → reja → fokus → o‘z hisoboti → namuna baholash. Haqiqiy Google/SMS, AI, ob-havo, audio va masofaviy sinxronlash bu ish oqimiga ulanmagan.',
          ),
        ),
        const SizedBox(height: 16),
        MLPSecondaryButton(
          label: 'UI tanlovlarini tozalash',
          onPressed: () async {
            final yes = await MLPConfirmationSheet.show(
              context,
              title: 'UI ma’lumoti tozalansinmi?',
              message:
                  'Demo profil, chat, jadval, baholashlar va tanlovlar o‘chadi. Asosiy maqsad, vazifa va fokus tarixi qoladi.',
            );
            if (yes && context.mounted) {
              await e.act(context, () async {
                await e.focus.discard();
                e.tab(0);
                await e.ui.resetUiData();
              });
            }
          },
        ),
      ],
    ),
  );
}

class MLPNotificationsPage extends StatelessWidget {
  const MLPNotificationsPage({super.key, required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([e.ui, e.store]),
    builder: (context, _) {
      final items = <(DateTime, String, String, String)>[];
      for (var offset = 0; offset < 2; offset++) {
        final day = e.store.today.add(Duration(days: offset));
        for (final s in e.ui.schedules.where(
          (s) =>
              s.occursOn(day) &&
              s.reminderMinutes != null &&
              !s.endOn(day).isBefore(e.clock()),
        )) {
          items.add((
            s.startOn(day).subtract(Duration(minutes: s.reminderMinutes!)),
            s.title,
            s.id,
            '${s.reminderMinutes} daqiqa oldin · ${mlpDayKey(day)}',
          ));
        }
      }
      items.sort((a, b) => a.$1.compareTo(b.$1));
      return MLPPage(
        title: 'Bildirishnomalar',
        children: [
          const MLPNotice(
            'Bu ekran rejalangan eslatma niyatlarini ko‘rsatadi. Android/iOS push yoki mahalliy xabarnoma yetkazish ulanmagan; ruxsat berilgan deb ko‘rsatilmaydi.',
            warning: true,
          ),
          SwitchListTile.adaptive(
            title: const Text('Eslatma tanlovim'),
            subtitle: Text(
              e.ui.preferences.notifications
                  ? 'Tanlov saqlangan · yetkazish faol emas'
                  : 'Tanlov o‘chirilgan',
            ),
            value: e.ui.preferences.notifications,
            onChanged: (v) => e.act(
              context,
              () => e.ui.savePreferences(
                MLPUserPreferences.fromJson({
                  ...e.ui.preferences.toJson(),
                  'notifications': v,
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const MLPSectionHeader(title: 'Bugun va ertaga · rejalangan'),
          const SizedBox(height: 12),
          if (items.isEmpty)
            MLPEmptyState(
              title: 'Rejalangan eslatma yo‘q',
              message:
                  'Mashg‘ulotga eslatma vaqtini kiriting. Yetkazish hali ulanmagan.',
              action: 'Taqvimni ochish',
              onAction: () => e.go(MLPScreen.calendar),
            ),
          ...items.map(
            (i) => MLPMenuTile(
              title: i.$2,
              subtitle: '${mlpTime(i.$1.hour * 60 + i.$1.minute)} · ${i.$4}',
              icon: Icons.notifications_none,
              onTap: () => e.go(
                MLPScreen.scheduleEditor,
                args: MLPRouteArgs(scheduleId: i.$3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const MLPSectionHeader(title: 'Mahalliy natijalar'),
          const SizedBox(height: 12),
          if (e.store.todayCompleted == 0)
            const MLPNotice('Bugun topshirilgan vazifa hali yo‘q.'),
          ...e.store.tasks
              .where(
                (t) =>
                    t.completed &&
                    t.completedAt != null &&
                    mlpDayKey(t.completedAt!) == e.store.todayKey,
              )
              .map(
                (t) => MLPMenuTile(
                  title: t.title,
                  subtitle: 'Bugun topshirilgan · o‘z hisoboti',
                  icon: Icons.task_alt,
                  onTap: () => e.go(
                    MLPScreen.verification,
                    args: MLPRouteArgs(taskId: t.id),
                  ),
                ),
              ),
        ],
      );
    },
  );
}
