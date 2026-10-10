import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/app_state.dart';
import '../widgets/app_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<GuestDataChoice> _chooseGuestData(BuildContext context) async {
    return await showDialog<GuestDataChoice>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Account already has data'),
            content: const Text(
              'Choose what to do with this device’s guest data. Merge keeps cloud records when IDs conflict and combines habit completion history.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, GuestDataChoice.cancel),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, GuestDataChoice.useCloud),
                child: const Text('Use cloud'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, GuestDataChoice.keepGuest),
                child: const Text('Keep guest data'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, GuestDataChoice.merge),
                child: const Text('Merge'),
              ),
            ],
          ),
        ) ??
        GuestDataChoice.cancel;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final stats = app.stats;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          children: [
            const AppHeader(title: 'Profile', subtitle: 'Your growth identity'),
            const SizedBox(height: 24),
            _ProfileAvatar(
              name: app.profile.name,
              avatarUrl: app.profile.avatarUrl,
            ),
            const SizedBox(height: 12),
            Text(
              app.profile.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              app.profile.email,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  app.isCloudUser
                      ? Icons.cloud_done_rounded
                      : Icons.phone_android_rounded,
                  size: 15,
                  color: app.isCloudUser ? AppColors.emerald : AppColors.gold,
                ),
                const SizedBox(width: 6),
                Text(
                  app.syncStatusLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (app.isGuestUser) ...[
              _GuestBackupCard(
                onSignIn: () async {
                  final state = context.read<AppState>();
                  try {
                    await state.signInWithGoogle(
                      onExistingCloudData: () => _chooseGuestData(context),
                    );

                    if (context.mounted && state.isCloudUser) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cloud sync yoqildi.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  }
                },
              ),
              const SizedBox(height: 14),
            ],
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Habits',
                    value: '${stats.totalHabits}',
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Days',
                    value: '${stats.bestStreak}',
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'XP',
                    value: '${stats.totalXp}',
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: 'Current Streak',
                    value: '${stats.currentStreak} Days',
                    color: AppColors.rose,
                    icon: Icons.local_fire_department_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    title: 'Longest Streak',
                    value: '${stats.bestStreak} Days',
                    color: AppColors.gold,
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Account',
                    onTap: () => context.go('/settings'),
                  ),
                  _SettingsRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Reminders',
                    onTap: () => context.go('/settings'),
                  ),
                  _SettingsRow(
                    icon: Icons.sync_rounded,
                    title: 'Data & Sync',
                    onTap: () => context.go('/settings'),
                  ),
                  _SettingsRow(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    onTap: () => context.go('/settings'),
                  ),
                  _SettingsRow(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    danger: true,
                    onTap: () async {
                      await context.read<AppState>().signOut();

                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestBackupCard extends StatelessWidget {
  const _GuestBackupCard({required this.onSignIn});

  final Future<void> Function() onSignIn;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      glowColor: AppColors.cyan,
      borderColor: AppColors.cyan.withOpacity(0.28),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withOpacity(0.14),
              border: Border.all(color: AppColors.cyan.withOpacity(0.34)),
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guest Mode active',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your data is saved locally. Sign in with Google to back it up.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(onPressed: onSignIn, child: const Text('Backup')),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.surface3,
      backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      child: hasAvatar
          ? null
          : Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: Theme.of(context).textTheme.headlineLarge,
            ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.rose : AppColors.textSecondary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 21),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: danger ? AppColors.rose : null,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }
}
