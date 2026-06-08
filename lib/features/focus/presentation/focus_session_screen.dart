import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../data/models/focus_session.dart';
import '../../../../data/repositories/repositories.dart';

class FocusSessionScreen extends ConsumerStatefulWidget {
  const FocusSessionScreen({
    super.key,
    required this.mode,
    required this.duration,
    this.isMonkMode = false,
  });

  final String mode;
  final int duration;
  final bool isMonkMode;

  @override
  ConsumerState<FocusSessionScreen> createState() =>
      _FocusSessionScreenState();
}

class _FocusSessionScreenState extends ConsumerState<FocusSessionScreen>
    with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _isCompleted = false;
  final _notesController = TextEditingController();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  Future<void> _startSession() async {
    const uuid = Uuid();
    final session = FocusSession(
      id: uuid.v4(),
      mode: widget.mode,
      startTime: DateTime.now(),
      plannedDurationMinutes: widget.duration,
      isMonkMode: widget.isMonkMode,
    );
    await ref.read(activeFocusSessionProvider.notifier).startSession(session);
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    _startTimer();
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    final actualMinutes = widget.duration - (_remainingSeconds / 60).ceil();
    final xp = AppConstants.xpFocusSession +
        (widget.isMonkMode ? AppConstants.xpMonkModeBonus : 0);

    await ref.read(activeFocusSessionProvider.notifier).completeSession(
          actualMinutes > 0 ? actualMinutes : widget.duration,
          notes: _notesController.text,
        );

    final progress = GamificationRepository().getProgress();
    progress.totalFocusSessions++;
    progress.totalFocusMinutes += actualMinutes;
    if (widget.isMonkMode) progress.monkModeSessions++;

    final today = DateTime.now();
    if (progress.lastFocusDate != null) {
      final diff = today.difference(progress.lastFocusDate!).inDays;
      if (diff == 1) {
        progress.focusStreak++;
      } else if (diff > 1) {
        progress.focusStreak = 1;
      }
    } else {
      progress.focusStreak = 1;
    }
    if (progress.focusStreak > progress.longestFocusStreak) {
      progress.longestFocusStreak = progress.focusStreak;
    }
    progress.lastFocusDate = today;
    await GamificationRepository().saveProgress(progress);
    await GamificationRepository().addXp(xp);

    setState(() => _isCompleted = true);
  }

  Future<void> _cancelSession() async {
    _timer?.cancel();
    ref.read(activeFocusSessionProvider.notifier).cancelSession();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final progress = 1 - (_remainingSeconds / (widget.duration * 60));

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: _isCompleted ? _buildCompletedView() : _buildActiveView(
            minutes, seconds, progress,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveView(int minutes, int seconds, double progress) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _cancelSession,
                icon: const Icon(Icons.close),
              ),
              Text(
                _modeDisplayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: 0.2 + _pulseController.value * 0.1,
                      ),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 260,
                      height: 260,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Spacer(),
          if (!_isRunning && !_isPaused)
            GradientButton(label: 'Start', onPressed: _startTimer)
          else if (_isPaused)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelSession,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GradientButton(
                    label: 'Resume',
                    onPressed: _resumeTimer,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _pauseTimer,
                  icon: const Icon(Icons.pause_circle_filled, size: 64),
                  color: AppColors.primary,
                ),
              ],
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Session notes (optional)',
              prefixIcon: Icon(Icons.note_outlined),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompletedView() {
    final xp = AppConstants.xpFocusSession +
        (widget.isMonkMode ? AppConstants.xpMonkModeBonus : 0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 32),
            Text(
              'Session Complete!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '+$xp XP earned',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              label: 'Done',
              onPressed: () {
                ref.invalidate(dashboardProvider);
                context.go('/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  String get _modeDisplayName {
    return FocusModeType.values
        .firstWhere(
          (e) => e.name == widget.mode,
          orElse: () => FocusModeType.pomodoro,
        )
        .name;
  }
}
