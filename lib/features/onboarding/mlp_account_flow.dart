import '../../app/mlp_environment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_liquid_glass.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../core/design_system/mlp_brand.dart';
import '../ai_companion/mlp_ai_orb.dart';
import '../../data/repositories/mlp_ui_repository.dart';

Future<void> _open(BuildContext context, MLPScreen screen, Widget child) =>
    Navigator.of(context).push<void>(
      MediaQuery.disableAnimationsOf(context)
          ? PageRouteBuilder<void>(
              settings: RouteSettings(name: screen.path),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
              pageBuilder: (_, __, ___) => child,
            )
          : CupertinoPageRoute<void>(
              settings: RouteSettings(name: screen.path),
              builder: (_) => child,
            ),
    );

class MLPEntryGate extends StatefulWidget {
  const MLPEntryGate({
    super.key,
    required this.prefs,
    required this.homeBuilder,
  });
  final SharedPreferences prefs;
  final Widget Function(MLPLocalUiRepository) homeBuilder;
  @override
  State<MLPEntryGate> createState() => _MLPEntryGateState();
}

class _MLPEntryGateState extends State<MLPEntryGate> {
  late final MLPLocalUiRepository repository;
  late final Future<void> loading;
  @override
  void initState() {
    super.initState();
    repository = MLPLocalUiRepository(widget.prefs);
    loading = repository.init();
  }

  @override
  void dispose() {
    repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const MLPSplashScreen();
      }
      return ListenableBuilder(
        listenable: repository,
        builder: (context, _) {
          if (repository.requiresRecovery) {
            return MLPScaffold(
              title: 'Mahalliy ma’lumot',
              body: SingleChildScrollView(
                child: MLPEmptyState(
                  title: 'Tanlovlarni o‘qib bo‘lmadi',
                  message:
                      '${repository.error} Asosiy vazifa va maqsadlaringiz o‘chirilmaydi.',
                  action: 'UI tanlovlarini tiklash',
                  onAction: () async {
                    final yes = await MLPConfirmationSheet.show(
                      context,
                      title: 'UI tanlovlari tozalansinmi?',
                      message:
                          'Mahalliy demo profil va yangi UI tanlovlari tozalanadi. Asosiy vazifa va maqsadlar saqlanadi.',
                    );
                    if (yes) {
                      try {
                        await repository.resetUiData();
                      } catch (_) {
                        if (context.mounted) {
                          MLPToast.show(
                            context,
                            'Tiklash bajarilmadi. Qayta urinib ko‘ring.',
                          );
                        }
                      }
                    }
                  },
                  icon: Icons.error_outline_rounded,
                ),
              ),
            );
          }
          return repository.onboarded
              ? widget.homeBuilder(repository)
              : MLPWelcomeScreen(repository: repository);
        },
      );
    },
  );
}

class MLPSplashScreen extends StatelessWidget {
  const MLPSplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const MLPScaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        _AccountScenery(),
        Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MLPWordmark(),
                SizedBox(height: 30),
                MLPLiquidSurface(
                  radius: 24,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoActivityIndicator(color: MLPColors.turquoise),
                      SizedBox(width: 12),
                      Flexible(child: Text('Maqsaddan natijaga')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class MLPWelcomeScreen extends StatefulWidget {
  const MLPWelcomeScreen({super.key, required this.repository});
  final MLPLocalUiRepository repository;
  @override
  State<MLPWelcomeScreen> createState() => _MLPWelcomeScreenState();
}

class _MLPWelcomeScreenState extends State<MLPWelcomeScreen> {
  bool busy = false;
  String? error;
  Future<void> _guest() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.enterGuest();
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'Mehmon rejimini saqlab bo‘lmadi. Qayta urinib ko‘ring.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => MLPScaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        const _AccountScenery(),
        LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewport.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: (viewport.maxHeight * .09).clamp(16.0, 76.0),
                        ),
                        const Text(
                          'Maqsadlaringni\nnatijaga aylantir.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'MLP bilan rejalashtir, bajar va rivojlanishingni kuzat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: MLPColors.secondaryText,
                            height: 1.5,
                          ),
                        ),
                        const MLPAINebula(height: 210),
                        const Text(
                          'Yaxshiroq versiyangiz sari\nhar kuni bir qadam.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        MLPPrimaryButton(
                          label: 'Boshlash',
                          onPressed: busy
                              ? null
                              : () => _open(
                                  context,
                                  MLPScreen.registration,
                                  MLPRegistrationScreen(
                                    repository: widget.repository,
                                  ),
                                ),
                          icon: Icons.arrow_forward_rounded,
                        ),
                        const SizedBox(height: 10),
                        MLPSecondaryButton(
                          label: 'Hisobim bor',
                          onPressed: busy
                              ? null
                              : () => _open(
                                  context,
                                  MLPScreen.login,
                                  MLPLoginScreen(repository: widget.repository),
                                ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: busy ? null : _guest,
                          child: Text(
                            busy ? 'Saqlanmoqda…' : 'Mehmon sifatida kirish',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          _DemoNotice(error!, error: true),
                        ],
                        const SizedBox(height: 14),
                        const Text(
                          'Demo rejim: ma’lumotlar shu qurilmada saqlanadi. '
                          'Haqiqiy AI va SMS tasdig‘i ulanmagan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: MLPColors.secondaryText,
                            fontSize: 11,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Mavjud vazifa va maqsadlaringiz saqlanadi. Sinov uchun '
                          'haqiqiy telefon raqamingizni kiritishingiz shart emas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: MLPColors.secondaryText,
                            fontSize: 10,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class MLPRegistrationScreen extends StatefulWidget {
  const MLPRegistrationScreen({super.key, required this.repository});
  final MLPLocalUiRepository repository;
  @override
  State<MLPRegistrationScreen> createState() => _MLPRegistrationScreenState();
}

class _MLPRegistrationScreenState extends State<MLPRegistrationScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController name, phone;
  String gender = 'O‘g‘il';
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final current = widget.repository.profile;
    name = TextEditingController(
      text: current?.guest == false ? current?.name : '',
    );
    phone = TextEditingController(
      text: current?.guest == false ? current?.phone : '+998',
    );
    gender = current?.gender ?? gender;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.registerDemo(
        name: name.text,
        phone: phone.text,
        gender: gender,
      );
      if (mounted) {
        await _open(
          context,
          MLPScreen.preferences,
          MLPPreferencesScreen(
            repository: widget.repository,
            finishingOnboarding: true,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Profil saqlanmadi. Ma’lumotlaringizni tekshirib qayta urinib ko‘ring.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AccountPage(
    title: 'Ro‘yxatdan o‘tish',
    children: [
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            MLPTextField(
              controller: name,
              label: 'Ismingiz',
              hint: 'Azizbek',
              maxLength: 60,
              validator: (v) => (v ?? '').trim().length < 2
                  ? 'Kamida 2 belgilik ism kiriting.'
                  : null,
            ),
            const SizedBox(height: 16),
            MLPPhoneField(controller: phone),
            const SizedBox(height: 24),
            Text(
              'Jins',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: busy ? null : () => setState(() => gender = 'O‘g‘il'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: gender == 'O‘g‘il'
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                            : const Color(0xFF131D38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: gender == 'O‘g‘il'
                              ? const Color(0xFF00E5FF)
                              : Colors.white.withValues(alpha: 0.1),
                          width: gender == 'O‘g‘il' ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: gender == 'O‘g‘il'
                                ? const Color(0xFF00E5FF)
                                : Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'O‘g‘il',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: busy ? null : () => setState(() => gender = 'Qiz'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: gender == 'Qiz'
                            ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                            : const Color(0xFF131D38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: gender == 'Qiz'
                              ? const Color(0xFF00E5FF)
                              : Colors.white.withValues(alpha: 0.1),
                          width: gender == 'Qiz' ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: gender == 'Qiz'
                                ? const Color(0xFF00E5FF)
                                : Colors.transparent,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Qiz',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: busy ? null : () => setState(() => gender = 'Ko‘rsatmaslik'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Icon(
                      gender == 'Ko‘rsatmaslik'
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 20,
                      color: gender == 'Ko‘rsatmaslik'
                          ? const Color(0xFF00E5FF)
                          : MLPColors.secondaryText,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Ko‘rsatmaslik',
                      style: TextStyle(color: MLPColors.secondaryText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (error != null) ...[
              _DemoNotice(error!, error: true),
              const SizedBox(height: 16),
            ],
            MLPPrimaryButton(
              label: 'Davom etish',
              busy: busy,
              onPressed: _save,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    ],
  );
}

class MLPLoginScreen extends StatefulWidget {
  const MLPLoginScreen({super.key, required this.repository});
  final MLPLocalUiRepository repository;
  @override
  State<MLPLoginScreen> createState() => _MLPLoginScreenState();
}

class _MLPLoginScreenState extends State<MLPLoginScreen> {
  final form = GlobalKey<FormState>();
  final phone = TextEditingController(text: '+998');
  bool busy = false;
  String? message;
  @override
  void dispose() {
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AccountPage(
    title: 'Hisobga kirish',
    children: [
      const _DemoNotice(
        'Telefon va Google orqali haqiqiy kirish ushbu UI prototipida ulanmagan. SMS yuborilmaydi.',
      ),
      const SizedBox(height: 24),
      Form(
        key: form,
        child: MLPPhoneField(controller: phone),
      ),
      const SizedBox(height: 20),
      MLPPrimaryButton(
        label: 'Telefon bilan kirish',
        onPressed: () {
          if (form.currentState!.validate()) {
            setState(
              () => message =
                  'SMS xizmati ulanmagan. Demo profil yoki mehmon rejimidan foydalaning.',
            );
          }
        },
      ),
      const SizedBox(height: 12),
      MLPSecondaryButton(
        label: 'Google orqali kirish',
        onPressed: () => setState(
          () => message =
              'Google adapteri eski kodda bor, lekin joriy prototipga ulanmagan. Kirish bajarilmadi.',
        ),
      ),
      if (message != null) ...[
        const SizedBox(height: 20),
        _DemoNotice(message!),
      ],
      const SizedBox(height: 24),
      MLPSecondaryButton(
        label: 'Demo profil yaratish',
        onPressed: () => _open(
          context,
          MLPScreen.registration,
          MLPRegistrationScreen(repository: widget.repository),
        ),
      ),
      const SizedBox(height: 12),
      MLPPrimaryButton(
        label: 'Mehmon sifatida kirish',
        busy: busy,
        onPressed: () async {
          setState(() => busy = true);
          try {
            await widget.repository.enterGuest();
            if (context.mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          } catch (_) {
            if (mounted) {
              setState(
                () =>
                    message = 'Mehmon rejimi saqlanmadi. Qayta urinib ko‘ring.',
              );
            }
          } finally {
            if (mounted) setState(() => busy = false);
          }
        },
      ),
    ],
  );
}

class MLPPreferencesScreen extends StatefulWidget {
  const MLPPreferencesScreen({
    super.key,
    required this.repository,
    this.finishingOnboarding = false,
  });
  final MLPLocalUiRepository repository;
  final bool finishingOnboarding;
  @override
  State<MLPPreferencesScreen> createState() => _MLPPreferencesScreenState();
}

class _MLPPreferencesScreenState extends State<MLPPreferencesScreen> {
  final form = GlobalKey<FormState>();
  late final TextEditingController minutes, nickname;
  late MLPUserPreferences initial;
  late bool notifications;
  late int start, finish;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    initial = widget.repository.preferences;
    minutes = TextEditingController(text: '${initial.minutes}');
    nickname = TextEditingController(text: initial.nickname);
    notifications = initial.notifications;
    start = initial.startMinute;
    finish = initial.endMinute;
  }

  @override
  void dispose() {
    minutes.dispose();
    nickname.dispose();
    super.dispose();
  }

  String _time(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
  Future<void> _pick(bool first) async {
    final value = first ? start : finish;
    var picked = value;
    final result = await mlpShowSheet<int>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: MLPColors.muted,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                first ? 'Boshlanish soati' : 'Tugash soati',
                textAlign: TextAlign.center,
                style: Theme.of(sheet).textTheme.titleMedium,
              ),
              SizedBox(
                height: 216,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(
                    2026,
                    1,
                    1,
                    value ~/ 60,
                    value % 60,
                  ),
                  onDateTimeChanged: (date) =>
                      picked = date.hour * 60 + date.minute,
                ),
              ),
              MLPPrimaryButton(
                label: 'Tanlash',
                onPressed: () => Navigator.pop(sheet, picked),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheet),
                child: const Text('Bekor qilish'),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (first) {
          start = result;
        } else {
          finish = result;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!form.currentState!.validate() || busy) return;
    if (finish <= start) {
      setState(() => error = 'Tugash soati boshlanishdan keyin bo‘lsin.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.savePreferences(
        MLPUserPreferences(
          minutes: int.parse(minutes.text),
          nickname: nickname.text.trim(),
          startMinute: start,
          endMinute: finish,
          notifications: notifications,
          tone: initial.tone,
          allowContext: initial.allowContext,
          muted: initial.muted,
          voice: initial.voice,
        ),
      );
      if (widget.finishingOnboarding) {
        await widget.repository.finishOnboarding();
      }
      if (!mounted) return;
      MLPToast.show(context, 'Tanlovlar saqlandi.');
      if (widget.finishingOnboarding) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Tanlovlar saqlanmadi. Qayta urinib ko‘ring.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

    final selectedInterests = <String>{'Ta’lim', 'Ingliz tili', 'Dasturlash'};

  @override
  Widget build(BuildContext context) => _AccountPage(
    title: 'Sozlamalar',
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Text(
              'Qaysi vaqtlarda odatda bo‘sh bo‘lasiz?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00E5FF)),
            ),
            child: const Text(
              '3 soat / kun',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MLPTextField(
              controller: minutes,
              label: 'Kunlik bo‘sh vaqt (daqiqa)',
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return n == null || n < 5 || n > 720
                    ? '5–720 oralig‘idagi daqiqa kiriting.'
                    : null;
              },
            ),
            const SizedBox(height: 18),
            Text(
              'Asosiy vaqtlar',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pick(true),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131D38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Boshlanish',
                            style: TextStyle(
                              color: MLPColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _time(start),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _pick(false),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131D38),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tugash',
                            style: TextStyle(
                              color: MLPColors.secondaryText,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _time(finish),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Qiziqishlaringiz nimalar?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                'Ta’lim',
                'Ingliz tili',
                'Dasturlash',
                'Sog‘lom turmush',
                'Kasb',
                'Moliya',
                'Shaxsiy rivojlanish',
                '+ Boshqa',
              ].map((interest) {
                final isSelected = selectedInterests.contains(interest);
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedInterests.remove(interest);
                      } else {
                        selectedInterests.add(interest);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                          : const Color(0xFF131D38),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : Colors.white.withValues(alpha: 0.12),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : MLPColors.secondaryText,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            MLPTextField(
              controller: nickname,
              label: 'Taqdosh AI nomi',
              hint: 'Ziyo',
              maxLength: 30,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Ustoz uchun nom kiriting.' : null,
            ),
            const SizedBox(height: 24),
            if (error != null) ...[
              _DemoNotice(error!, error: true),
              const SizedBox(height: 16),
            ],
            MLPPrimaryButton(
              label: widget.finishingOnboarding ? 'MLPni boshlash' : 'Saqlash',
              busy: busy,
              onPressed: _save,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    ],
  );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice(this.text, {this.error = false});
  final String text;
  final bool error;
  @override
  Widget build(BuildContext context) => MLPNotice(text, warning: error);
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({required this.title, required this.children});
  final String? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => MLPScaffold(
    title: title,
    body: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 360 ? 16 : 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  _AccountHeading(title: title!),
                  const SizedBox(height: 24),
                ],
                MLPLiquidSurface(
                  radius: 26,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _AccountScenery extends StatelessWidget {
  const _AccountScenery();
  @override
  Widget build(BuildContext context) => const IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(.3, -.4),
          radius: 1.1,
          colors: [Color(0x22162C8E), Colors.transparent],
        ),
      ),
    ),
  );
}

class _MLPWordmark extends StatelessWidget {
  const _MLPWordmark();
  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MLPBrandMark(size: 145),
      SizedBox(height: 18),
      Text(
        'MLP',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      SizedBox(height: 12),
      Text(
        'Maqsadlaringni\nnatijaga aylantir',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: MLPColors.secondaryText,
        ),
      ),
    ],
  );
}

class _AccountHeading extends StatelessWidget {
  const _AccountHeading({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4, bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title == 'Mening tanlovlarim'
                ? 'Kun tartibingiz'
                : title == 'Hisobga kirish'
                ? 'Xush kelibsiz'
                : 'Siz haqingizda',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
          ),
        ),
        const Icon(
          CupertinoIcons.person_crop_circle,
          size: 26,
          color: MLPColors.secondaryText,
        ),
      ],
    ),
  );
}

