import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design/mlp_colors.dart';
import '../../core/design/mlp_text_styles.dart';
import '../../core/providers/app_providers.dart';
import '../../core/widgets/mlp_button.dart';
import '../../core/widgets/demo_banner.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController(text: '+998');
  String? _gender;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Iltimos, ismingizni kiriting")),
      );
      return;
    }
    setState(() => _isLoading = true);
    await ref.read(userProvider.notifier).createUser(
          name: name,
          phone: _phoneCtrl.text.trim(),
          gender: _gender,
        );
    await ref.read(sharedPrefsProvider).setBool('mlp_onboarded', true);
    ref.read(isOnboardedProvider.notifier).state = true;
    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/goal-setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MlpColors.bg1,
      body: Column(
        children: [
          const DemoBanner(),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text("Salom!\nO'zingizni tanishtiring", style: MlpTextStyles.h2),
                    const SizedBox(height: 8),
                    Text("Demo akkaunt yaratilmoqda", style: MlpTextStyles.body2),
                    const SizedBox(height: 32),

                    Text("Ismingiz", style: MlpTextStyles.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: MlpColors.text1),
                      decoration: const InputDecoration(
                        hintText: "Masalan: Alibek",
                        prefixIcon: Icon(Icons.person_outline_rounded, color: MlpColors.text3),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text("Telefon", style: MlpTextStyles.label),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: MlpColors.text1),
                      decoration: const InputDecoration(
                        hintText: "+998 90 123 45 67",
                        prefixIcon: Icon(Icons.phone_outlined, color: MlpColors.text3),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text("Jins (ixtiyoriy)", style: MlpTextStyles.label),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _GenderCard(
                            label: "O'G'IL",
                            emoji: '👦',
                            isSelected: _gender == "O'G'IL",
                            onTap: () => setState(() => _gender = _gender == "O'G'IL" ? null : "O'G'IL"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GenderCard(
                            label: "QIZ",
                            emoji: '👧',
                            isSelected: _gender == "QIZ",
                            onTap: () => setState(() => _gender = _gender == "QIZ" ? null : "QIZ"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),

                    MlpButton(
                      label: "Davom etish",
                      icon: Icons.arrow_forward_rounded,
                      isLoading: _isLoading,
                      onPressed: _continue,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Hech qanday haqiqiy ma\'lumot saqlanmaydi',
                        style: MlpTextStyles.caption,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    required this.label, required this.emoji,
    required this.isSelected, required this.onTap,
  });
  final String label, emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? MlpColors.purple.withValues(alpha: 0.2) : MlpColors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MlpColors.purple : MlpColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: isSelected ? MlpColors.purpleLight : MlpColors.text2,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            )),
          ],
        ),
      ),
    );
  }
}
