import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PermissionBanner extends StatelessWidget {
  const PermissionBanner({
    super.key,
    required this.usageGranted,
    required this.accessibilityGranted,
    required this.overlayGranted,
    required this.onGrantUsage,
    required this.onGrantAccessibility,
    required this.onGrantOverlay,
  });

  final bool usageGranted;
  final bool accessibilityGranted;
  final bool overlayGranted;
  final VoidCallback onGrantUsage;
  final VoidCallback onGrantAccessibility;
  final VoidCallback onGrantOverlay;

  @override
  Widget build(BuildContext context) {
    if (usageGranted && accessibilityGranted && overlayGranted) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!usageGranted) _UsageBanner(onGrantUsage: onGrantUsage),
        if (usageGranted && (!accessibilityGranted || !overlayGranted))
          _ReelCounterBanner(
            accessibilityGranted: accessibilityGranted,
            overlayGranted: overlayGranted,
            onGrantAccessibility: onGrantAccessibility,
            onGrantOverlay: onGrantOverlay,
          ),
      ],
    );
  }
}

class _UsageBanner extends StatelessWidget {
  const _UsageBanner({required this.onGrantUsage});

  final VoidCallback onGrantUsage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Usage Access needed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Allow so SKROL can show your real screen time.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).hintColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _PermissionRow(
            label: 'Usage Access',
            subtitle: 'Required for screen time tracking',
            onTap: onGrantUsage,
          ),
        ],
      ),
    );
  }
}

class _ReelCounterBanner extends StatelessWidget {
  const _ReelCounterBanner({
    required this.accessibilityGranted,
    required this.overlayGranted,
    required this.onGrantAccessibility,
    required this.onGrantOverlay,
  });

  final bool accessibilityGranted;
  final bool overlayGranted;
  final VoidCallback onGrantAccessibility;
  final VoidCallback onGrantOverlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Reels/Shorts counter (optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enable only if you want the on-screen counter while scrolling.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).hintColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          if (!accessibilityGranted) ...[
            _PermissionRow(
              label: 'Accessibility',
              subtitle: 'Counts Reels & Shorts scrolls',
              onTap: onGrantAccessibility,
            ),
            const SizedBox(height: 8),
          ],
          if (!overlayGranted)
            _PermissionRow(
              label: 'Display over other apps',
              subtitle: 'Shows counter on Instagram & YouTube',
              onTap: onGrantOverlay,
            ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.arrow_forward_ios, color: AppColors.primary, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Enable',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
