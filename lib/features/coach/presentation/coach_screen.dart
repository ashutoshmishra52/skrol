import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/services/app_services.dart';
import '../../../../data/models/gamification.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(coachMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.coachName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(coachPromptReplyProvider.notifier).state = null;
              ref.invalidate(coachMessagesProvider);
            },
          ),
        ],
      ),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (messages) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AetherisHeader(),
            const SizedBox(height: 24),
            ...messages.asMap().entries.map((entry) {
              final index = entry.key;
              final message = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MessageBubble(message: message)
                    .animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideX(begin: -0.05),
              );
            }),
            const SizedBox(height: 24),
            _QuickPrompts(ref: ref),
          ],
        ),
      ),
    );
  }
}

class _AetherisHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.accent.withValues(alpha: 0.1),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.coachName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.coachTagline,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(message.type);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon(message.type), size: 16, color: typeColor),
              const SizedBox(width: 8),
              Text(
                message.type.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message.message,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          if (message.actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (message.actionRoute != null) {
                  context.push(message.actionRoute!);
                }
              },
              child: Text(message.actionLabel!),
            ),
          ],
        ],
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'warning':
        return AppColors.poor;
      case 'success':
        return AppColors.accent;
      case 'motivation':
        return AppColors.secondary;
      case 'tip':
        return AppColors.primary;
      default:
        return AppColors.textSecondaryDark;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning_amber;
      case 'success':
        return Icons.celebration;
      case 'motivation':
        return Icons.local_fire_department;
      case 'tip':
        return Icons.lightbulb;
      default:
        return Icons.chat;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _QuickPrompts extends StatelessWidget {
  const _QuickPrompts({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    const prompts = [
      'How am I doing today?',
      'Start a focus sprint',
      'Show my progress',
      'Give me a tip',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Prompts',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prompts.map((prompt) {
            return ActionChip(
              label: Text(prompt),
              onPressed: () async {
                final reply =
                    await ref.read(aetherisCoachProvider).respondToPrompt(prompt);
                ref.read(coachPromptReplyProvider.notifier).state = reply;
                ref.invalidate(coachMessagesProvider);
              },
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              labelStyle: const TextStyle(color: AppColors.primary),
            );
          }).toList(),
        ),
      ],
    );
  }
}
