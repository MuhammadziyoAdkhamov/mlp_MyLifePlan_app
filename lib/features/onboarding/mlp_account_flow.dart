import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router/mlp_routes.dart';
import '../../app/theme/mlp_design_system.dart';
import '../../core/design_system/mlp_widgets.dart';
import '../../data/repositories/mlp_ui_repository.dart';

Future<void> _open(BuildContext context, MLPScreen screen, Widget child) =>
    Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: screen.path),
        transitionDuration: MLPDimensions.motion(context, route: true),
        reverseTransitionDuration: MLPDimensions.motion(context, route: true),
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
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
    body: Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MLPAvatarOrb(),
            SizedBox(height: 24),
            Text(
              'MLP',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text('Maqsaddan natijaga'),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
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
  Widget build(BuildContext context) => _AccountPage(
    title: null,
    children: [
      const SizedBox(height: 16),
      const Center(child: MLPAvatarOrb(size: 144)),
      const SizedBox(height: 28),
      Text(
        'Maqsadlaringni natijaga aylantir.',
        style: Theme.of(context).textTheme.displaySmall,
      ),
      const SizedBox(height: 16),
      const Text(
        'MLP bilan rejalashtir, bajar va rivojlanishingni kuzat.',
        style: TextStyle(
          color: MLPColors.secondaryText,
          fontSize: 16,
          height: 1.6,
        ),
      ),
      const SizedBox(height: 24),
      const _DemoNotice(
        'Demo rejim: ma’lumotlar shu qurilmada saqlanadi. Haqiqiy AI va SMS tasdig‘i ulanmagan.',
      ),
      const SizedBox(height: 28),
      MLPPrimaryButton(
        label: 'Boshlash',
        onPressed: busy
            ? null
            : () => _open(
                context,
                MLPScreen.registration,
                MLPRegistrationScreen(repository: widget.repository),
              ),
        icon: Icons.arrow_forward_rounded,
      ),
      const SizedBox(height: 12),
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
      const SizedBox(height: 8),
      TextButton(
        onPressed: busy ? null : _guest,
        child: Text(busy ? 'Saqlanmoqda…' : 'Mehmon sifatida kirish'),
      ),
      if (error != null) _DemoNotice(error!, error: true),
      const SizedBox(height: 16),
      const Text(
        'Mavjud vazifa va maqsadlaringiz saqlanadi. Sinov uchun haqiqiy telefon raqamingizni kiritishingiz shart emas.',
        style: TextStyle(
          color: MLPColors.secondaryText,
          fontSize: 12,
          height: 1.6,
        ),
      ),
    ],
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
  String gender = 'Ko‘rsatmaslik';
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
              'Demo profil saqlanmadi. Ma’lumotlaringizni tekshirib qayta urinib ko‘ring.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _AccountPage(
    title: 'Demo profil yaratish',
    children: [
      const _DemoNotice(
        'Bu mahalliy demo profil. Telefon SMS orqali tasdiqlanmaydi va serverga yuborilmaydi.',
      ),
      const SizedBox(height: 24),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MLPTextField(
              controller: name,
              label: 'Ism',
              maxLength: 60,
              validator: (v) => (v ?? '').trim().length < 2
                  ? 'Kamida 2 belgilik ism kiriting.'
                  : null,
            ),
            const SizedBox(height: 16),
            MLPPhoneField(controller: phone),
            const SizedBox(height: 24),
            Text(
              'Jins (ixtiyoriy)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...[
              ('O‘g‘il', 'O‘g‘il'),
              ('Qiz', 'Qiz'),
              ('Ko‘rsatmaslik', 'Ko‘rsatmaslikni afzal ko‘raman'),
            ].map(
              (v) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: gender == v.$1,
                title: Text(v.$2),
                onChanged: busy ? null : (_) => setState(() => gender = v.$1),
              ),
            ),
            const Text(
              'Bu tanlov maqsadlar, kasblar yoki funksiyalaringizni cheklamaydi.',
              style: TextStyle(color: MLPColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 24),
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
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value ~/ 60, minute: value % 60),
      helpText: first ? 'Boshlanish soati' : 'Tugash soati',
      cancelText: 'Bekor qilish',
      confirmText: 'Tanlash',
    );
    if (result != null) {
      setState(() {
        if (first) {
          start = result.hour * 60 + result.minute;
        } else {
          finish = result.hour * 60 + result.minute;
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

  @override
  Widget build(BuildContext context) => _AccountPage(
    title: 'Mening tanlovlarim',
    children: [
      const Text(
        'Bu tanlovlarni keyin Profil bo‘limida o‘zgartira olasiz.',
        style: TextStyle(color: MLPColors.secondaryText),
      ),
      const SizedBox(height: 24),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.language_rounded),
              title: Text('Ilova tili'),
              subtitle: Text('O‘zbekcha · lotin yozuvi'),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 20),
            Text(
              'Qulay mashg‘ulot vaqti',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                MLPSecondaryButton(
                  label: 'Boshlash · ${_time(start)}',
                  icon: Icons.schedule,
                  onPressed: () => _pick(true),
                ),
                MLPSecondaryButton(
                  label: 'Tugatish · ${_time(finish)}',
                  icon: Icons.schedule,
                  onPressed: () => _pick(false),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: notifications,
              title: const Text('Eslatma xohishi'),
              subtitle: const Text(
                'Tanlov saqlanadi. Haqiqiy bildirishnoma ruxsati va yetkazish hali ulanmagan.',
              ),
              onChanged: busy ? null : (v) => setState(() => notifications = v),
            ),
            const SizedBox(height: 20),
            MLPTextField(
              controller: nickname,
              label: 'USTOZ AI uchun nom',
              hint: 'Masalan: Ziyo',
              maxLength: 30,
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Ustoz uchun nom kiriting.' : null,
            ),
            const SizedBox(height: 12),
            const _DemoNotice(
              'Ustoz nomi — shaxsiy tanlov. Yordamchi javoblari demo bo‘ladi; haqiqiy AI ulanmagan.',
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
            ),
          ],
        ),
      ),
    ],
  );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice(this.message, {this.error = false});
  final String message;
  final bool error;
  @override
  Widget build(BuildContext context) => MLPGlassCard(
    padding: 16,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          error ? Icons.error_outline_rounded : Icons.info_outline_rounded,
          size: 20,
          color: error ? MLPColors.warning : MLPColors.turquoise,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ),
      ],
    ),
  );
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({required this.title, required this.children});
  final String? title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => MLPScaffold(
    title: title,
    body: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ),
  );
}
