import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/skrol_logo.dart';
import '../../../../core/providers/feed_stats_notifier.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../data/repositories/repositories.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '1.0.0';
  int _versionTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = info.version);
  }

  String _profileBrainStatus(int reels) {
    if (reels >= 70) return 'Brain exhausted';
    if (reels >= 45) return 'Brain very tired';
    if (reels >= 25) return 'Brain getting tired';
    if (reels >= 10) return 'Brain slightly tired';
    return 'Brain well rested';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final feedStats = ref.watch(feedStatsNotifierProvider);
    final name = settings.userName.isNotEmpty ? settings.userName : 'User';

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      child: Row(
                        children: [
                          SkrolLogoAvatar(size: 64),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profileBrainStatus(feedStats.reelsCount),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brainStateColor(
                                      feedStats.reelsCount,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${feedStats.reelsCount} reels today',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Appearance'),
                    GlassCard(
                      child: Column(
                        children: [
                          _ThemeTile(
                            title: 'Light Mode',
                            icon: Icons.light_mode,
                            selected: settings.themeMode == 'light',
                            onTap: () => ref
                                .read(settingsProvider.notifier)
                                .setThemeMode('light'),
                          ),
                          const Divider(height: 1),
                          _ThemeTile(
                            title: 'Dark Mode',
                            icon: Icons.dark_mode,
                            selected: settings.themeMode == 'dark',
                            onTap: () => ref
                                .read(settingsProvider.notifier)
                                .setThemeMode('dark'),
                          ),
                          const Divider(height: 1),
                          _ThemeTile(
                            title: 'System Default',
                            icon: Icons.brightness_auto,
                            selected: settings.themeMode == 'system',
                            onTap: () => ref
                                .read(settingsProvider.notifier)
                                .setThemeMode('system'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Goals'),
                    GlassCard(
                      child: Column(
                        children: [
                          _SliderSetting(
                            label: 'Daily Screen Time Goal',
                            value: settings.dailyScreenTimeGoalMinutes
                                .toDouble(),
                            min: 60,
                            max: 480,
                            unit: 'min',
                            onChanged: (v) async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(settings.copyWith(
                                    dailyScreenTimeGoalMinutes: v.round(),
                                  ));
                            },
                          ),
                          const Divider(height: 1),
                          _SliderSetting(
                            label: 'Social Media Limit',
                            value: settings.dailySocialMediaLimitMinutes
                                .toDouble(),
                            min: 15,
                            max: 180,
                            unit: 'min',
                            onChanged: (v) async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(settings.copyWith(
                                    dailySocialMediaLimitMinutes: v.round(),
                                  ));
                            },
                          ),
                          const Divider(height: 1),
                          _SliderSetting(
                            label: 'Daily Focus Goal',
                            value:
                                settings.dailyFocusGoalMinutes.toDouble(),
                            min: 30,
                            max: 360,
                            unit: 'min',
                            onChanged: (v) async {
                              await ref
                                  .read(settingsProvider.notifier)
                                  .updateSettings(settings.copyWith(
                                    dailyFocusGoalMinutes: v.round(),
                                  ));
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Permissions'),
                    _PermissionsSection(
                      onChanged: () {
                        ref.invalidate(permissionStatusProvider);
                        ref.invalidate(settingsProvider);
                        ref.invalidate(dashboardProvider);
                      },
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Notifications'),
                    GlassCard(
                      child: SwitchListTile(
                        title: const Text('Smart Notifications'),
                        subtitle: const Text(
                          'Streak reminders and goal alerts',
                        ),
                        value: settings.notificationsEnabled,
                        onChanged: (v) async {
                          await ref
                              .read(settingsProvider.notifier)
                              .updateSettings(
                                settings.copyWith(notificationsEnabled: v),
                              );
                        },
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle(title: 'Data'),
                    GlassCard(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.upload,
                                color: AppColors.primary),
                            title: const Text('Export Data'),
                            subtitle: const Text('Share your data as JSON'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                ExportImportRepository().shareExport(),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip,
                                color: AppColors.accent),
                            title: const Text('Privacy Policy'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showPolicy(context, 'Privacy Policy',
                                _privacyPolicy),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.description,
                                color: AppColors.secondary),
                            title: const Text('Terms of Service'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showPolicy(context, 'Terms of Service',
                                _termsOfService),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'S',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppConstants.appName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            AppConstants.tagline,
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _versionTapCount++;
                              if (_versionTapCount >= 7) {
                                _versionTapCount = 0;
                                context.push('/debug/detection');
                              }
                            },
                            child: Text(
                              'Version $_appVersion',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'by ${AppConstants.developer}',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.website,
                            style: TextStyle(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicy(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Text(content),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _privacyPolicy = '''
SKROL Privacy Policy

Last updated: June 2026

SKROL is committed to protecting your privacy. This app is designed with privacy as a core principle.

Data Collection
We do NOT collect any personal data. All information is stored locally on your device.

Data Storage
All app usage data, focus sessions, habits, and preferences are stored exclusively on your device using local storage (Hive database).

No Accounts
SKROL does not require account creation or login.

No Analytics
We do not use any external analytics services. Your behavior is never tracked or sent to third parties.

No Ads
SKROL is completely ad-free.

Permissions
- Usage Stats: Used to track app usage for wellness insights
- Notifications: Used for focus reminders and streak alerts
- Accessibility (optional): Used for Monk Mode app blocking

Contact
Developer: Ashutosh Mishra
''';

  static const _termsOfService = '''
SKROL Terms of Service

Last updated: June 2026

By using SKROL, you agree to these terms.

Service Description
SKROL is a digital wellness application designed to help users reduce screen time and improve focus.

Free Service
SKROL is completely free with no subscriptions, in-app purchases, or advertisements.

User Responsibilities
You are responsible for configuring the app according to your preferences and granting necessary permissions.

Disclaimer
SKROL provides wellness tools and insights but is not a substitute for professional medical or psychological advice.

Data Ownership
All data created within the app belongs to you and remains on your device.

Modifications
We may update these terms. Continued use constitutes acceptance of updated terms.

Contact
Developer: Ashutosh Mishra
''';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PermissionsSection extends ConsumerWidget {
  const _PermissionsSection({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permAsync = ref.watch(permissionStatusProvider);
    final service = PermissionService();

    return permAsync.when(
      loading: () => const GlassCard(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (perm) => GlassCard(
        child: Column(
          children: [
            _PermListTile(
              title: 'Usage Access',
              subtitle: perm.usageStatsGranted
                  ? 'Enabled — real screen time active'
                  : 'Required — tap to open settings & Allow',
              granted: perm.usageStatsGranted,
              onTap: () async {
                await service.requestUsageStats();
                onChanged();
              },
            ),
            const Divider(height: 1),
            _PermListTile(
              title: 'Notifications',
              subtitle: perm.notificationGranted
                  ? 'Enabled'
                  : 'Tap Allow for reminders',
              granted: perm.notificationGranted,
              onTap: () async {
                await service.requestNotifications();
                onChanged();
              },
            ),
            const Divider(height: 1),
            _PermListTile(
              title: 'Accessibility (SKROL)',
              subtitle: perm.accessibilityGranted
                  ? 'Enabled — Reels/Shorts counting active'
                  : 'Required for scroll counting',
              granted: perm.accessibilityGranted,
              onTap: () async {
                await service.openAccessibilitySettings();
                onChanged();
              },
            ),
            const Divider(height: 1),
            _PermListTile(
              title: 'Display over other apps',
              subtitle: perm.overlayGranted
                  ? 'Enabled — live counter on screen'
                  : 'Required for Reels/Shorts overlay',
              granted: perm.overlayGranted,
              onTap: () async {
                await service.requestOverlayPermission();
                onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PermListTile extends StatelessWidget {
  const _PermListTile({
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        granted ? Icons.check_circle : Icons.error_outline,
        color: granted ? AppColors.accent : AppColors.poor,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: granted
          ? null
          : Text(
              'Allow',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.primary : null),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? AppColors.primary : null,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                '${value.round()} $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 15).round(),
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
