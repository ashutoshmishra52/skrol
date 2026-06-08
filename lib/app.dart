import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/permission_service.dart';
import 'core/services/usage_stats_service.dart';
import 'core/widgets/app_launch_screen.dart';

class SkrolApp extends ConsumerStatefulWidget {
  const SkrolApp({super.key});

  @override
  ConsumerState<SkrolApp> createState() => _SkrolAppState();
}

class _SkrolAppState extends ConsumerState<SkrolApp> with WidgetsBindingObserver {
  DateTime? _lastFullSync;
  bool _showLaunch = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshOnLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOnResume();
    }
  }

  Future<void> _refreshOnLaunch() async {
    final permissionService = PermissionService();
    await permissionService.recheckUsageStatsAfterSettings();
    await permissionService.checkAll();
    await UsageStatsService().syncUsageData(days: 1);
    _lastFullSync = DateTime.now();
    if (mounted) {
      ref.invalidate(permissionStatusProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(todayUsageProvider);
    }
  }

  Future<void> _refreshOnResume() async {
    final permissionService = PermissionService();
    await permissionService.recheckUsageStatsAfterSettings();
    await permissionService.checkAll();

    final now = DateTime.now();
    final shouldSync = _lastFullSync == null ||
        now.difference(_lastFullSync!) > const Duration(minutes: 5);
    if (shouldSync) {
      await UsageStatsService().syncUsageData(days: 1);
      _lastFullSync = now;
    }

    if (mounted) {
      ref.invalidate(permissionStatusProvider);
      if (shouldSync) {
        ref.invalidate(dashboardProvider);
        ref.invalidate(todayUsageProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (_showLaunch)
              AppLaunchScreen(
                onComplete: () {
                  if (mounted) setState(() => _showLaunch = false);
                },
              ),
          ],
        );
      },
    );
  }
}
