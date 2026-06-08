import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/constants/app_packages.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/widgets/permission_banner.dart';
import '../../../../data/models/app_usage.dart';

class UsageScreen extends ConsumerWidget {
  const UsageScreen({super.key});

  static const _socialOrder = AppPackages.socialMediaApps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageAsync = ref.watch(todayUsageProvider);
    final permissionAsync = ref.watch(permissionStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Screen Time'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: usageAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          final socialRecords = records
              .where((r) => AppPackages.socialMediaApps.contains(r.packageName))
              .toList()
            ..sort((a, b) {
              final ai = _socialOrder.indexOf(a.packageName);
              final bi = _socialOrder.indexOf(b.packageName);
              if (ai != bi) return ai.compareTo(bi);
              return b.usageMinutes.compareTo(a.usageMinutes);
            });

          final socialMinutes = socialRecords.fold<int>(
            0,
            (sum, r) => sum + r.usageMinutes,
          );

          return RefreshIndicator(
            onRefresh: () async {
              await PermissionService().recheckUsageStatsAfterSettings();
              await ref.read(usageStatsServiceProvider).syncUsageData(days: 1);
              ref.invalidate(todayUsageProvider);
              ref.invalidate(permissionStatusProvider);
              ref.invalidate(dashboardProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                permissionAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (perm) => PermissionBanner(
                    usageGranted: perm.usageStatsGranted,
                    accessibilityGranted: perm.accessibilityGranted,
                    overlayGranted: perm.overlayGranted,
                    onGrantUsage: () async {
                      await PermissionService().requestUsageStats();
                      ref.invalidate(permissionStatusProvider);
                    },
                    onGrantAccessibility: () async {
                      await PermissionService().openAccessibilitySettings();
                      ref.invalidate(permissionStatusProvider);
                    },
                    onGrantOverlay: () async {
                      await PermissionService().requestOverlayPermission();
                      ref.invalidate(permissionStatusProvider);
                    },
                  ),
                ),
                _SummaryCard(
                  title: 'Total Social Screen Time',
                  value: _formatMinutes(socialMinutes),
                  color: AppColors.critical,
                  icon: Icons.public,
                  subtitle: 'Instagram · YouTube · LinkedIn · X · Facebook',
                ),
                const SizedBox(height: 24),
                Text(
                  'By App',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                if (socialRecords.isEmpty)
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline,
                              size: 48,
                              color: Theme.of(context).hintColor),
                          const SizedBox(height: 12),
                          Text(
                            'No usage yet for Instagram, YouTube, LinkedIn, X, or Facebook. Enable Usage Access and pull to refresh.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Theme.of(context).hintColor),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () async {
                              await PermissionService().requestUsageStats();
                              ref.invalidate(permissionStatusProvider);
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Open Usage Access Settings'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...socialRecords.map(
                    (record) => _AppUsageTile(
                      record: record,
                      totalMinutes: socialMinutes > 0 ? socialMinutes : 1,
                    ),
                  ),
                const SizedBox(height: 24),
                ..._socialOrder
                    .where((pkg) =>
                        !socialRecords.any((r) => r.packageName == pkg))
                    .map(
                      (pkg) => _EmptySocialTile(
                        appName: AppPackages.displayName(pkg),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).hintColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppUsageTile extends StatelessWidget {
  const _AppUsageTile({
    required this.record,
    required this.totalMinutes,
  });

  final AppUsageRecord record;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalMinutes > 0 ? record.usageMinutes / totalMinutes : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.critical.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.public,
                    color: AppColors.critical,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    record.appName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _formatMinutes(record.usageMinutes),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 4,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.critical),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }
}

class _EmptySocialTile extends StatelessWidget {
  const _EmptySocialTile({required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                appName,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ),
            Text(
              '0m',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
