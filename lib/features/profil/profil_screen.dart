import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/mlp_button.dart';
import '../../core/widgets/mlp_card.dart';

class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  bool _editingName = false;
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final user = ref.read(userProvider);
    if (user == null) return;
    await ref.read(userProvider.notifier).updateUser(user.copyWith(name: _nameCtrl.text.trim()));
    setState(() => _editingName = false);
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MlpColors.bg2,
        title: const Text('Ma\'lumotlarni o\'chirish', style: TextStyle(color: MlpColors.text1)),
        content: const Text('Barcha demo ma\'lumotlar o\'chadi. Davom etasizmi?',
            style: TextStyle(color: MlpColors.text2)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor qilish', style: TextStyle(color: MlpColors.text3))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('O\'chirish', style: TextStyle(color: MlpColors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(userProvider.notifier).signOut();
      if (!mounted) return;
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profil', style: MlpTextStyles.h2),
              const SizedBox(height: 24),
              MlpCard(
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [MlpColors.purple, MlpColors.blue]),
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_editingName)
                            TextField(
                              controller: _nameCtrl,
                              autofocus: true,
                              style: MlpTextStyles.h4,
                              onSubmitted: (_) => _saveName(),
                              decoration: const InputDecoration(
                                isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            )
                          else
                            Text(user.name, style: MlpTextStyles.h3),
                          Text(user.phone.isEmpty ? 'Telefon kiritilmagan' : user.phone,
                              style: MlpTextStyles.body2),
                          if (user.gender != null)
                            Text(user.gender!, style: MlpTextStyles.caption),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _editingName ? _saveName : () => setState(() => _editingName = true),
                      child: Icon(_editingName ? Icons.check_rounded : Icons.edit_rounded,
                          color: MlpColors.purpleLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _MiniStat(label: 'Daraja', value: '${user.level}')),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStat(label: 'XP', value: '${user.xp}')),
                  const SizedBox(width: 10),
                  Expanded(child: _MiniStat(label: 'Coin', value: '${user.coins}')),
                ],
              ),
              const SizedBox(height: 24),
              Text('Sozlamalar', style: MlpTextStyles.label.copyWith(color: MlpColors.text2)),
              const SizedBox(height: 12),
              const _SettingTile(icon: Icons.palette_outlined, label: 'Mavzu', sublabel: 'Qorong\'u (tez kunda)'),
              const SizedBox(height: 8),
              const _SettingTile(icon: Icons.language_outlined, label: 'Til', sublabel: 'O\'zbek (tez kunda)'),
              const SizedBox(height: 8),
              const _SettingTile(icon: Icons.notifications_outlined, label: 'Bildirishnomalar', sublabel: 'Yoqilgan (tez kunda)'),
              const SizedBox(height: 32),
              MlpButton(
                label: 'Ma\'lumotlarni o\'chirish',
                icon: Icons.delete_outline_rounded,
                colors: [MlpColors.error.withValues(alpha: 0.8), MlpColors.error],
                onPressed: _resetData,
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'MYLife Plan 3.0 — DEMO prototip',
                  style: MlpTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return MlpCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: MlpColors.text1, fontSize: 22, fontWeight: FontWeight.w800)),
          Text(label, style: MlpTextStyles.caption),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.label, required this.sublabel});
  final IconData icon;
  final String label, sublabel;

  @override
  Widget build(BuildContext context) {
    return MlpCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: MlpColors.purpleLight, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: MlpTextStyles.body1)),
          Text(sublabel, style: MlpTextStyles.body2),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: MlpColors.text3, size: 18),
        ],
      ),
    );
  }
}
