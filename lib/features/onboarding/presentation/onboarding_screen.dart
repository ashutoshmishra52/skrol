import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_packages.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/skrol_logo.dart';
import '../../../../core/widgets/skrol_background.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../data/repositories/repositories.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SkrolBackground(
        child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (state.currentPage > 0)
                    IconButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                        ref.read(onboardingProvider.notifier).previousPage();
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                  const Spacer(),
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 7,
                    effect: WormEffect(
                      dotColor: AppColors.primary.withValues(alpha: 0.2),
                      activeDotColor: AppColors.primary,
                      dotHeight: 8,
                      dotWidth: 8,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  ref.read(onboardingProvider.notifier).goToPage(page);
                },
                children: [
                  _NamePage(nameController: _nameController),
                  _AttentionPage(),
                  _StatsPage(),
                  _YearlyPage(),
                  _GoalsPage(),
                  _AppsPage(),
                  _PermissionsPage(onComplete: _completeOnboarding),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    final state = ref.read(onboardingProvider);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your name first.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        ref.read(onboardingProvider.notifier).goToPage(0);
      }
      return;
    }

    await SettingsRepository().completeOnboarding(
      userName: name,
      goals: state.selectedGoals,
      distractingApps: AppPackages.socialMediaApps,
    );

    ref.invalidate(settingsProvider);
    if (mounted) context.go('/home');
  }

  void _nextPage() {
    FocusManager.instance.primaryFocus?.unfocus();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    ref.read(onboardingProvider.notifier).nextPage();
  }
}

class _NamePage extends StatefulWidget {
  const _NamePage({required this.nameController});

  final TextEditingController nameController;

  @override
  State<_NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<_NamePage> {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 16, 32, 24 + bottomInset),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const SkrolBrandMark(
            logoSize: 130,
            animated: true,
            showWelcome: true,
          ),
          const SizedBox(height: 20),
          Text(
            'Track Reels.\nTrack Shorts.\nBeat Doomscrolling.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1.4,
                ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 28),
          Text(
            'What should we call you?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 28),
          TextField(
            controller: widget.nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.85),
              hintText: 'your name',
              hintStyle: TextStyle(
                color: AppColors.textSecondaryLight.withValues(alpha: 0.45),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon:
                  const Icon(Icons.person_rounded, color: AppColors.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _continue(context),
          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Continue',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _continue(context),
          ),
        ],
      ),
    );
  }

  void _continue(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (widget.nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    context.findAncestorStateOfType<_OnboardingScreenState>()?._nextPage();
  }
}

class _AttentionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 16, 32, 24 + bottomInset),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.psychology, size: 60, color: Colors.white),
          ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Text(
            'Your attention is your most valuable asset.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 16),
          Text(
            'SKROL helps you track short-form content and beat doomscrolling.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 40),
          GradientButton(
            label: 'Get Started',
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              final state =
                  (context.findAncestorStateOfType<_OnboardingScreenState>());
              state?._nextPage();
            },
          ),
        ],
      ),
    );
  }
}

class _StatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 16, 32, 24 + bottomInset),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'The Average Person',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Text(
            'Industry averages — not your personal data',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).hintColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _StatBubble(value: '4.2h', label: 'Avg. daily scrolling', color: AppColors.critical),
          const SizedBox(height: 16),
          _StatBubble(value: '2,520', label: 'Phone pickups/day', color: AppColors.poor),
          const SizedBox(height: 16),
          _StatBubble(value: '96', label: 'Times checking phone', color: AppColors.average),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Continue',
            onPressed: () {
              (context.findAncestorStateOfType<_OnboardingScreenState>())
                  ?._nextPage();
            },
          ),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  const _StatBubble({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }
}

class _YearlyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(32, 16, 32, 24 + bottomInset),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'Time Wasted Yearly',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.critical.withValues(alpha: 0.2),
                  AppColors.poor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  '38 days',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.critical,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'spent scrolling social media per year',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 24),
          Text(
            'That\'s enough time to learn a new skill, read 50 books, or travel the world.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          const SizedBox(height: 32),
          GradientButton(
            label: 'Take Control',
            onPressed: () {
              (context.findAncestorStateOfType<_OnboardingScreenState>())
                  ?._nextPage();
            },
          ),
        ],
      ),
    );
  }
}

class _GoalsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Goals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'What do you want to spend your reclaimed time on?',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: AppConstants.defaultGoals.length,
              itemBuilder: (context, index) {
                final goal = AppConstants.defaultGoals[index];
                final selected = state.selectedGoals.contains(goal);
                return GestureDetector(
                  onTap: () =>
                      ref.read(onboardingProvider.notifier).toggleGoal(goal),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        goal,
                        style: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          color: selected ? AppColors.primary : null,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          GradientButton(
            label: 'Continue',
            onPressed: () {
              (context.findAncestorStateOfType<_OnboardingScreenState>())
                  ?._nextPage();
            },
          ),
        ],
      ),
    );
  }
}

class _AppsPage extends ConsumerWidget {
  static const _apps = [
    ('Instagram', AppPackages.instagram),
    ('YouTube', AppPackages.youtube),
    ('LinkedIn', AppPackages.linkedin),
    ('X (Twitter)', AppPackages.twitter),
    ('Facebook', AppPackages.facebook),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Social Media Apps',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'SKROL tracks only these 5 apps — nothing else',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: _apps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final (name, package) = _apps[index];
                return _SocialAppTile(name: name, package: package);
              },
            ),
          ),
          GradientButton(
            label: 'Continue',
            onPressed: () {
              ref.read(onboardingProvider.notifier).setSocialAppsOnly();
              (context.findAncestorStateOfType<_OnboardingScreenState>())
                  ?._nextPage();
            },
          ),
        ],
      ),
    );
  }
}

class _SocialAppTile extends StatelessWidget {
  const _SocialAppTile({required this.name, required this.package});

  final String name;
  final String package;

  Color get _brandColor {
    switch (package) {
      case AppPackages.instagram:
        return const Color(0xFFE1306C);
      case AppPackages.youtube:
        return const Color(0xFFFF0000);
      case AppPackages.linkedin:
        return const Color(0xFF0A66C2);
      case AppPackages.twitter:
        return const Color(0xFF1DA1F2);
      case AppPackages.facebook:
        return const Color(0xFF1877F2);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _brandColor.withValues(alpha: 0.25), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _brandColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.public_rounded, color: _brandColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Icon(Icons.check_circle_rounded, color: _brandColor, size: 22),
        ],
      ),
    );
  }
}

class _PermissionsPage extends ConsumerStatefulWidget {
  const _PermissionsPage({required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<_PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends ConsumerState<_PermissionsPage>
    with WidgetsBindingObserver {
  bool _usageGranted = false;
  final _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    await _permissionService.recheckUsageStatsAfterSettings();
    final status = await _permissionService.checkAll();
    if (mounted) {
      setState(() {
        _usageGranted = status.usageStatsGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(32, 32, 32, 32 + bottomInset),
        children: [
          Text(
            'Permissions Setup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'SKROL needs Usage Access to track your screen time',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 32),
          _PermissionTile(
            title: 'Usage Access',
            subtitle: 'Settings → find SKROL → turn ON',
            icon: Icons.bar_chart,
            granted: _usageGranted,
            required: true,
            onTap: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await _permissionService.requestUsageStats();
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Reels/Shorts counter & overlay can be enabled later from Home when you need them.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).hintColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Start My Journey',
            icon: Icons.rocket_launch,
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();
              await _checkPermissions();
              if (!_usageGranted && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enable Usage Access for real screen time tracking.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              widget.onComplete();
            },
          ),
        ],
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.granted,
    required this.required,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool granted;
  final bool required;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      required ? '$title *' : title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (granted)
                const Icon(Icons.check_circle, color: AppColors.accent, size: 22)
              else
                Text(
                  'Allow',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
