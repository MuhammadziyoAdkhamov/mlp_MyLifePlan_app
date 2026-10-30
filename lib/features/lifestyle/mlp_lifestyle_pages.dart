import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/mlp_environment.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../core/design_system/mlp_appearance.dart';
import '../../data/models/mlp_schedule.dart';
import '../../data/repositories/mlp_ui_repository.dart';
import '../onboarding/mlp_account_flow.dart';
import 'mlp_background_settings.dart';

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
  ) => mlpShowSheet<void>(
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
    builder: (context, _) {
      final currentXp = e.store.xp > 0 ? e.store.xp : 480;
      const targetXp = 1000;
      final level = e.store.level > 1 ? e.store.level : 3;
      return MLPPage(
        title: 'Mukofotlar',
        children: [
          MLPGlassCard(
            accent: true,
            padding: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                          ),
                          child: const Icon(Icons.military_tech_rounded, color: Color(0xFF00E5FF), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Text('Level $level', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('$currentXp / $targetXp XP', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (currentXp / targetXp).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const MLPSectionHeader(title: 'Nishonlar va trofeylar'),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final badge in [
                ('Boshlovchi', Icons.star_rounded, const Color(0xFF00E5FF)),
                ('Fokuschi', Icons.timer_rounded, const Color(0xFFFFD700)),
                ('Intiluvchan', Icons.local_fire_department_rounded, const Color(0xFFFF5252)),
              ])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131D38),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: Column(
                        children: [
                          Icon(badge.$2, color: badge.$3, size: 32),
                          const SizedBox(height: 8),
                          Text(badge.$1, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const MLPSectionHeader(title: 'Rangli virtual profil bezaklari'),
          const SizedBox(height: 10),
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
    );
  },
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
            MLPSegmented(
              labels: const ['Bugun', 'Ertaga'],
              selected: day,
              onChanged: (value) => setState(() => day = value),
            ),
            const SizedBox(height: 20),
            MLPGlassCard(
              accent: true,
              padding: 20,
              child: Column(
                children: [
                  Icon(
                    day == 0 ? Icons.wb_sunny_rounded : Icons.cloud_rounded,
                    size: 58,
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    day == 0 ? '18°C' : '16°C',
                    style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${e.ui.city} · Yomg‘irsiz · Toza havo',
                    style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF131D38),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF00E5FF), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bugun sayr va ochiq havoda fokus uchun ajoyib kun!',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final h in [
                    ('10:00', '18°', Icons.wb_sunny_rounded),
                    ('12:00', '20°', Icons.wb_sunny_rounded),
                    ('14:00', '22°', Icons.wb_cloudy_rounded),
                    ('16:00', '19°', Icons.cloud_rounded),
                    ('18:00', '17°', Icons.nights_stay_rounded),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131D38),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(h.$1, style: const TextStyle(color: MLPColors.secondaryText, fontSize: 11)),
                            const SizedBox(height: 6),
                            Icon(h.$3, color: const Color(0xFF00E5FF), size: 22),
                            const SizedBox(height: 6),
                            Text(h.$2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
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

class _SoundState extends State<MLPSoundspacePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  String selectedId = 'deep';
  bool isPlaying = true;
  String currentFilter = 'Barchasi';

  static const tracks = [
    (
      id: 'deep',
      title: 'Deep Focus',
      category: 'Fokus',
      duration: '60:00',
      icon: CupertinoIcons.waveform,
      desc: 'Chuqur konsentratsiya to‘lqini',
    ),
    (
      id: 'rain',
      title: 'Yomg‘ir va momaqaldiroq',
      category: 'Yomg‘ir',
      duration: '45:00',
      icon: CupertinoIcons.cloud_rain,
      desc: 'Sokin tomchilar va mayin shabada',
    ),
    (
      id: 'mountain',
      title: 'Tog‘ shamoli va qushlar',
      category: 'Tabiat',
      duration: '30:00',
      icon: CupertinoIcons.wind,
      desc: 'Tiniq havo va osoyishta tabiat',
    ),
    (
      id: 'lofi',
      title: 'Lofi ritmlar',
      category: 'Motivatsiya',
      duration: '50:00',
      icon: CupertinoIcons.music_note_2,
      desc: 'O‘qish va kod yozish uchun yengil ritm',
    ),
    (
      id: 'ocean',
      title: 'Sokin ummon nafasi',
      category: 'Tabiat',
      duration: '40:00',
      icon: CupertinoIcons.waveform_path,
      desc: 'To‘lqinlar sasi va dam olish',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: e.ui,
      builder: (context, _) {
        final currentTrack = tracks.firstWhere(
          (t) => t.id == selectedId,
          orElse: () => tracks.first,
        );
        final filteredTracks = tracks.where((t) {
          if (currentFilter == 'Barchasi') return true;
          return t.category == currentFilter;
        }).toList();

        final sleepMinutes = (e.ui.soundIntent['sleep'] as int?) ?? 0;

        return MLPPage(
          title: 'Soundspace',
          children: [
            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in [
                    'Barchasi',
                    'Fokus',
                    'Yomg‘ir',
                    'Tabiat',
                    'Motivatsiya',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: currentFilter == cat,
                        selectedColor: MLPColors.turquoise.withValues(alpha: .2),
                        labelStyle: TextStyle(
                          color: currentFilter == cat
                              ? MLPColors.turquoise
                              : MLPColors.secondaryText,
                          fontWeight: currentFilter == cat
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => currentFilter = cat);
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Hero Playing Card (Screen 22 Poster Match)
            MLPLiquidSurface(
              tint: MLPColors.turquoise.withValues(alpha: .15),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isPlaying
                                  ? MLPColors.turquoise
                                  : MLPColors.secondaryText)
                              .withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (isPlaying
                                    ? MLPColors.turquoise
                                    : MLPColors.secondaryText)
                                .withValues(alpha: .4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPlaying
                                  ? CupertinoIcons.waveform_path
                                  : CupertinoIcons.pause,
                              size: 13,
                              color: isPlaying
                                  ? MLPColors.turquoise
                                  : MLPColors.secondaryText,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isPlaying ? 'Ijro etilmoqda' : 'Pauzada',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isPlaying
                                    ? MLPColors.turquoise
                                    : MLPColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sevimlilar',
                        icon: Icon(
                          e.ui.favorites.contains(currentTrack.id)
                              ? CupertinoIcons.heart_fill
                              : CupertinoIcons.heart,
                          color: e.ui.favorites.contains(currentTrack.id)
                              ? const Color(0xFFFF5252)
                              : MLPColors.secondaryText,
                          size: 20,
                        ),
                        onPressed: () => e.act(
                          context,
                          () => e.ui.toggleFavorite(currentTrack.id),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    currentTrack.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentTrack.desc,
                    style: const TextStyle(
                      color: MLPColors.secondaryText,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Waveform Visualizer
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, _) {
                      final val = _animController.value;
                      return SizedBox(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(24, (i) {
                            final base = ((i % 5) + 1) * 7.0;
                            final wave = isPlaying
                                ? (val * ((i % 3) + 1) * 6.0)
                                : 0.0;
                            final h = (base + wave).clamp(8.0, 42.0);
                            return Container(
                              width: 3.5,
                              height: h,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 2.2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    MLPColors.turquoise,
                                    MLPColors.primaryLight.withValues(alpha: .5),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    currentTrack.duration,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MLPColors.turquoise,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Player Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Tasodifiy',
                        icon: const Icon(
                          CupertinoIcons.shuffle,
                          color: MLPColors.secondaryText,
                          size: 20,
                        ),
                        onPressed: () {
                          final other = tracks.where((t) => t.id != selectedId).toList();
                          other.shuffle();
                          if (other.isNotEmpty) {
                            setState(() => selectedId = other.first.id);
                          }
                        },
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        tooltip: 'Oldingi',
                        icon: const Icon(
                          CupertinoIcons.backward_end_fill,
                          color: MLPColors.text,
                          size: 24,
                        ),
                        onPressed: () {
                          final idx = tracks.indexWhere((t) => t.id == selectedId);
                          final prevIdx = (idx - 1 + tracks.length) % tracks.length;
                          setState(() => selectedId = tracks[prevIdx].id);
                        },
                      ),
                      const SizedBox(width: 18),
                      // Glowing Center Play/Pause
                      GestureDetector(
                        onTap: () => setState(() => isPlaying = !isPlaying),
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [MLPColors.turquoise, Color(0xFF2979FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: MLPColors.turquoise.withValues(alpha: .45),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying
                                ? CupertinoIcons.pause_fill
                                : CupertinoIcons.play_arrow_solid,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      IconButton(
                        tooltip: 'Keyingi',
                        icon: const Icon(
                          CupertinoIcons.forward_end_fill,
                          color: MLPColors.text,
                          size: 24,
                        ),
                        onPressed: () {
                          final idx = tracks.indexWhere((t) => t.id == selectedId);
                          final nextIdx = (idx + 1) % tracks.length;
                          setState(() => selectedId = tracks[nextIdx].id);
                        },
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        tooltip: 'Takrorlash',
                        icon: const Icon(
                          CupertinoIcons.repeat,
                          color: MLPColors.secondaryText,
                          size: 20,
                        ),
                        onPressed: () {
                          MLPToast.show(context, 'Mavzu takrorlash yoqildi');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Track List
            const MLPSectionHeader(title: 'Musiqa to‘plamlari'),
            const SizedBox(height: 10),
            for (final track in filteredTracks)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MLPLiquidSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  tint: track.id == selectedId ? MLPColors.turquoise.withValues(alpha: .15) : null,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedId = track.id;
                        isPlaying = true;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: track.id == selectedId
                                ? MLPColors.turquoise.withValues(alpha: .2)
                                : MLPColors.elevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: track.id == selectedId
                                  ? MLPColors.turquoise
                                  : MLPColors.border,
                            ),
                          ),
                          child: Icon(
                            track.icon,
                            color: track.id == selectedId
                                ? MLPColors.turquoise
                                : MLPColors.primaryLight,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: TextStyle(
                                  fontWeight: track.id == selectedId
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: track.id == selectedId
                                      ? MLPColors.turquoise
                                      : MLPColors.text,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${track.category} · ${track.duration}',
                                style: const TextStyle(
                                  color: MLPColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Sevimlilar',
                          icon: Icon(
                            e.ui.favorites.contains(track.id)
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: e.ui.favorites.contains(track.id)
                                ? const Color(0xFFFF5252)
                                : MLPColors.secondaryText,
                            size: 18,
                          ),
                          onPressed: () => e.act(
                            context,
                            () => e.ui.toggleFavorite(track.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Sleep Timer section
            const MLPSectionHeader(title: 'Uyqu taymeri'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mins in [0, 15, 30, 45, 60])
                  ChoiceChip(
                    label: Text(mins == 0 ? 'O‘chirilgan' : '$mins daqiqa'),
                    selected: sleepMinutes == mins,
                    selectedColor: MLPColors.turquoise.withValues(alpha: .2),
                    labelStyle: TextStyle(
                      color: sleepMinutes == mins
                          ? MLPColors.turquoise
                          : MLPColors.secondaryText,
                    ),
                    onSelected: (val) {
                      if (val) {
                        e.act(
                          context,
                          () => e.ui.saveSoundIntent(
                            currentTrack.category,
                            mins,
                          ),
                        );
                        MLPToast.show(
                          context,
                          mins == 0
                              ? 'Uyqu taymeri o‘chirildi'
                              : 'Uyqu taymeri: $mins daqiqaga o‘rnatildi',
                        );
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class MLPProfilePage extends StatelessWidget {
  const MLPProfilePage({super.key, required this.e, this.showBack = false});
  final MLPEnvironment e;
  final bool showBack;
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
              if (showBack) const BackButton(),
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
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Student • TDTU',
                        style: TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'MLP Pro haqida',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _proInfo(context, e),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: MLPColors.warning.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: MLPColors.warning.withValues(alpha: .3),
                        ),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 22,
                            color: MLPColors.warning,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'MLP Pro',
                            style: TextStyle(
                              fontSize: 9,
                              color: MLPColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ProfileStats(e: e),
          const SizedBox(height: 16),
          _GlassMenuGroup(
            children: [
              _GlassMenuRow(
                title: 'Mening yutuqlarim',
                icon: CupertinoIcons.rosette,
                onTap: () => e.go(MLPScreen.rewards),
              ),
              _GlassMenuRow(
                title: 'Maqsadlarim',
                icon: CupertinoIcons.scope,
                onTap: () => e.tab(1),
              ),
              _GlassMenuRow(
                title: 'Statistikalarim',
                icon: CupertinoIcons.chart_bar,
                onTap: () => e.go(MLPScreen.analytics),
              ),
              _GlassMenuRow(
                title: 'Ko‘nikmalar pasporti',
                icon: CupertinoIcons.checkmark_shield,
                onTap: () => e.go(MLPScreen.passport),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GlassMenuGroup(
            children: [
              _GlassMenuRow(
                title: 'Sozlamalar',
                icon: CupertinoIcons.gear,
                onTap: () => e.go(MLPScreen.settings),
              ),
              _GlassMenuRow(
                title: 'Mavzu',
                detail: 'Liquid Glass',
                icon: CupertinoIcons.moon,
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MLPBackgroundSettingsPage(),
                  ),
                ),
              ),
              _GlassMenuRow(
                title: 'Bildirishnomalar',
                icon: CupertinoIcons.bell,
                trailing: CupertinoSwitch(
                  value: e.ui.preferences.notifications,
                  activeTrackColor: MLPColors.turquoise,
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
                onTap: () => e.go(MLPScreen.notifications),
              ),
              _GlassMenuRow(
                title: 'Yordam va fikr-mulohaza',
                icon: CupertinoIcons.question_square,
                onTap: () => e.info(
                  context,
                  'Beta tekshiruvi',
                  'Ekran nomi, bajarilgan qadamlar, kutilgan va amaldagi natijani loyiha egasiga yetkazing. Ilova ichida yuborish xizmati ulanmagan.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GlassMenuGroup(
            children: [
              _GlassMenuRow(
                title: 'Ustoz AI',
                icon: CupertinoIcons.sparkles,
                onTap: () => e.go(MLPScreen.chat),
              ),
              _GlassMenuRow(
                title: 'Ob-havo va reja',
                icon: CupertinoIcons.cloud,
                onTap: () => e.go(MLPScreen.weather),
              ),
              _GlassMenuRow(
                title: 'MLP Soundspace',
                icon: CupertinoIcons.headphones,
                onTap: () => e.go(MLPScreen.soundspace),
              ),
              _GlassMenuRow(
                title: 'MLP Pro',
                detail: 'Demo',
                icon: Icons.workspace_premium_outlined,
                onTap: () => _proInfo(context, e),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const MLPNotice(
            'Mahalliy demo profil. Telefon tasdiqlanmagan. Bildirishnoma tanlovi saqlanadi, lekin tizim orqali yetkazish ulanmagan.',
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

  static void _proInfo(BuildContext context, MLPEnvironment e) => e.info(
    context,
    'MLP Pro',
    'Bu demo uchun obuna sotilmaydi. To‘lov, karta yoki pullik xizmat ulanmagan. Belgini bosish xaridni boshlamaydi.',
  );
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({required this.e});
  final MLPEnvironment e;
  @override
  Widget build(BuildContext context) {
    final totalSeconds = e.store.focusSessions.fold<int>(0, (sum, s) => sum + s.seconds);
    final totalHours = (totalSeconds / 3600).round();
    final items = [
      (
        '${e.store.goals.length}',
        'Maqsadlar',
        CupertinoIcons.scope,
        MLPColors.turquoise,
      ),
      (
        '${e.store.tasks.length}',
        'Vazifalar',
        CupertinoIcons.checkmark_alt_circle_fill,
        MLPColors.warning,
      ),
      (
        '${totalHours > 0 ? totalHours : 48}',
        'Fokus soat',
        CupertinoIcons.stopwatch_fill,
        const Color(0xFF00E5FF),
      ),
    ];
    return MLPLiquidSurface(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: LayoutBuilder(
        builder: (context, box) {
          final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
          Widget item(int index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(items[index].$3, size: 22, color: items[index].$4),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[index].$1,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        items[index].$2,
                        style: const TextStyle(
                          fontSize: 9,
                          color: MLPColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
          return stacked
              ? Column(children: List.generate(3, item))
              : Row(
                  children: List.generate(3, (i) => Expanded(child: item(i))),
                );
        },
      ),
    );
  }
}

class _GlassMenuGroup extends StatelessWidget {
  const _GlassMenuGroup({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => MLPLiquidSurface(
    radius: 16,
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1)
            Divider(
              height: 1,
              thickness: .5,
              indent: 44,
              color: Colors.white.withValues(alpha: .08),
            ),
        ],
      ],
    ),
  );
}

class _GlassMenuRow extends StatelessWidget {
  const _GlassMenuRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.detail,
    this.trailing,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String? detail;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 34),
          child: Row(
            children: [
              Icon(icon, size: 20, color: MLPColors.secondaryText),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 12)),
              ),
              if (detail != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    detail!,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 11,
                      color: MLPColors.muted,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ] else ...[
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 13,
                  color: MLPColors.secondaryText,
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _GlassSwitch extends StatelessWidget {
  const _GlassSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: MLPLiquidSurface(
      radius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: MLPColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            label: title,
            child: CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: MLPColors.turquoise,
            ),
          ),
        ],
      ),
    ),
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
    await mlpShowDialog<void>(
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
      'appearance': MLPAppearanceScope.maybeOf(context)?.exportState(),
    });
    await mlpShowDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Mahalliy nusxa · fon rasmi ham kiradi'),
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
        _SettingsRow(
          title: 'Profil ma’lumotlari',
          subtitle: e.ui.profile?.name,
          icon: Icons.person_outline,
          onTap: () => _identity(context),
        ),
        _SettingsRow(
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
        _SettingsRow(
          title: 'Ustoz va ruxsatlar',
          icon: Icons.auto_awesome,
          onTap: () => e.go(MLPScreen.aiPersonalization),
        ),
        _SettingsRow(
          title: 'Bildirishnomalar',
          subtitle: 'Faqat mahalliy reja · yetkazish ulanmagan',
          icon: Icons.notifications_none,
          onTap: () => e.go(MLPScreen.notifications),
        ),
        _SettingsRow(
          title: 'Mavzu',
          subtitle: 'iOS Liquid Glass · shaxsiy fon',
          icon: Icons.dark_mode_outlined,
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const MLPBackgroundSettingsPage(),
            ),
          ),
        ),
        _SettingsRow(
          title: 'Til',
          subtitle: 'O‘zbekcha · lotin',
          icon: Icons.translate,
          onTap: () => e.info(
            context,
            'Ilova tili',
            'Interfeys o‘zbekcha lotin yozuvida. Boshqa tillar hali tarjima qilinmagan.',
          ),
        ),
        _GlassSwitch(
          title: 'Ustoz tezkor tugmasi',
          subtitle: 'Faqat ilova ichida',
          value: !e.ui.assistantHidden,
          onChanged: (v) => e.act(context, () => e.ui.hideAssistant(!v)),
        ),
        _SettingsRow(
          title: 'Mahalliy nusxa olish',
          subtitle: 'Maqsadlar, qaydlar, taqvim, UI va fon rasmi · JSON',
          icon: Icons.save_alt,
          onTap: () => _backup(context),
        ),
        _SettingsRow(
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
        _SettingsRow(
          title: 'Maxfiylik',
          icon: Icons.shield_outlined,
          onTap: () => e.info(
            context,
            'Mahalliy demo va maxfiylik',
            'Bu ish oqimida hisob, chat, baholash va tanlangan fon rasmi shu qurilmada saqlanadi. Galereyadan faqat o‘zingiz tanlagan rasm olinadi; serverga yuborilmaydi. Mikrofon, kamera va joylashuv so‘ralmaydi. Mahalliy saqlov shifrlanmagan. JSON nusxasiga fon rasmi ham kiradi. Eksportni faqat o‘zingiz ishonadigan joyda saqlang. Fon rasmini «Mavzu» bo‘limida o‘chirishingiz mumkin.',
          ),
        ),
        _SettingsRow(
          title: 'Yordam va fikr-mulohaza',
          icon: Icons.help_outline,
          onTap: () => e.info(
            context,
            'Beta tekshiruvi',
            'Muammo haqida ekran nomi, bajarilgan qadamlar, kutilgan va amaldagi natijani loyiha egasiga yetkazing. Ilova ichida yuborish xizmati hali ulanmagan.',
          ),
        ),
        _SettingsRow(
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
            final appearance = MLPAppearanceScope.maybeOf(context);
            final yes = await MLPConfirmationSheet.show(
              context,
              title: 'UI ma’lumoti tozalansinmi?',
              message:
                  'Demo profil, chat, jadval, baholashlar, tanlovlar va shaxsiy fon rasmi o‘chadi. Asosiy maqsad, vazifa va fokus tarixi qoladi.',
            );
            if (yes && context.mounted) {
              await e.act(context, () async {
                await e.focus.discard();
                await appearance?.setBackground(null);
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

class MLPNotificationsPage extends StatefulWidget {
  const MLPNotificationsPage({super.key, required this.e});
  final MLPEnvironment e;

  @override
  State<MLPNotificationsPage> createState() => _MLPNotificationsPageState();
}

class _MLPNotificationsPageState extends State<MLPNotificationsPage> {
  int _selectedFilter = 0; // 0: Barchasi, 1: O‘qilmagan, 2: Tizim
  final Set<String> _readIds = {'notif_2', 'notif_3'};

  static const List<Map<String, dynamic>> _sampleNotifications = [
    {
      'id': 'notif_1',
      'title': 'Vazifa eslatmasi',
      'subtitle': 'Login ekrani dizaynini yakunlash',
      'badge': 'Bugun 14:00',
      'category': 'Vazifalar',
      'icon': CupertinoIcons.bell_fill,
      'color': MLPColors.turquoise,
      'time': '10 daqiqa oldin',
      'isSystem': false,
    },
    {
      'id': 'notif_2',
      'title': 'Fokus yakunlandi',
      'subtitle': '25 daqiqalik Pomodoro muvaffaqiyatli bajarildi',
      'badge': '+50 XP',
      'category': 'Fokus',
      'icon': CupertinoIcons.timer,
      'color': MLPColors.warning,
      'time': '1 soat oldin',
      'isSystem': false,
    },
    {
      'id': 'notif_3',
      'title': 'Yangi yutuq',
      'subtitle': '«Fokuschi» nishoni qo‘lga kiritildi!',
      'badge': 'Mukofot',
      'category': 'Tizim',
      'icon': CupertinoIcons.rosette,
      'color': Color(0xFFB388FF),
      'time': 'Kecha',
      'isSystem': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final e = widget.e;
    return ListenableBuilder(
      listenable: Listenable.merge([e.ui, e.store]),
      builder: (context, _) {
        final notificationsEnabled = e.ui.preferences.notifications;

        // Dynamic items from schedules
        final dynamicItems = <Map<String, dynamic>>[];
        for (var offset = 0; offset < 2; offset++) {
          final day = e.store.today.add(Duration(days: offset));
          for (final s in e.ui.schedules.where(
            (s) =>
                s.occursOn(day) &&
                s.reminderMinutes != null &&
                !s.endOn(day).isBefore(e.clock()),
          )) {
            final id = 'sched_${s.id}_$offset';
            dynamicItems.add({
              'id': id,
              'title': s.title,
              'subtitle': '${s.reminderMinutes} daqiqa oldin · ${mlpDayKey(day)}',
              'badge': 'Jadval',
              'category': 'Reja',
              'icon': CupertinoIcons.calendar,
              'color': MLPColors.primaryLight,
              'time': mlpTime(s.startMinute),
              'isSystem': false,
            });
          }
        }

        final allItems = [..._sampleNotifications, ...dynamicItems];

        final filteredItems = allItems.where((item) {
          final id = item['id'] as String;
          final isRead = _readIds.contains(id);
          final isSystem = item['isSystem'] as bool;

          if (_selectedFilter == 1) return !isRead; // O'qilmagan
          if (_selectedFilter == 2) return isSystem; // Tizim
          return true; // Barchasi
        }).toList();

        return MLPPage(
          title: 'Bildirishnomalar',
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  for (final item in allItems) {
                    _readIds.add(item['id'] as String);
                  }
                });
                MLPToast.show(context, 'Barchasi o‘qilgan deb belgilandi');
              },
              child: const Text(
                'O‘qilgan',
                style: TextStyle(color: MLPColors.turquoise, fontSize: 13),
              ),
            ),
          ],
          children: [
            // Switch for Notifications Setting
            _GlassSwitch(
              title: 'Bildirishnomalarni yoqish',
              subtitle: notificationsEnabled
                  ? 'Eslatmalar va ogohlantirishlar faol'
                  : 'Bildirishnomalar o‘chirilgan',
              value: notificationsEnabled,
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

            // Filter Tabs (Screen 24 Poster Match: Barchasi, O'qilmagan, Tizim)
            MLPSegmented(
              labels: const ['Barchasi', 'O‘qilmagan', 'Tizim'],
              selected: _selectedFilter,
              onChanged: (idx) => setState(() => _selectedFilter = idx),
            ),
            const SizedBox(height: 16),

            if (filteredItems.isEmpty)
              const MLPEmptyState(
                title: 'Bildirishnomalar yo‘q',
                message: 'Hozircha sizda yangi eslatmalar mavjud emas.',
              ),

            for (final notif in filteredItems) ...[
              _NotificationCard(
                title: notif['title'] as String,
                subtitle: notif['subtitle'] as String,
                badge: notif['badge'] as String,
                time: notif['time'] as String,
                icon: notif['icon'] as IconData,
                color: notif['color'] as Color,
                isUnread: !_readIds.contains(notif['id']),
                onTap: () {
                  setState(() => _readIds.add(notif['id'] as String));
                },
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.time,
    required this.icon,
    required this.color,
    required this.isUnread,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badge;
  final String time;
  final IconData icon;
  final Color color;
  final bool isUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MLPLiquidSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      tint: isUnread ? MLPColors.turquoise.withValues(alpha: .12) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: .3)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: MLPColors.text,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          color: MLPColors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: MLPColors.secondaryText,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: MLPColors.turquoise,
                  boxShadow: [
                    BoxShadow(
                      color: MLPColors.turquoise,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: _GlassMenuGroup(
      children: [
        _GlassMenuRow(title: title, icon: icon, onTap: onTap, detail: subtitle),
      ],
    ),
  );
}
