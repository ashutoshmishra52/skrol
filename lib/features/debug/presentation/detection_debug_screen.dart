import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/native_stats_service.dart';
import '../../../../core/providers/feed_stats_notifier.dart';
import '../../../../core/theme/app_colors.dart';

final detectionDebugProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) async* {
  while (true) {
    yield await NativeStatsService.getDetectionDebug();
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
});

class DetectionDebugScreen extends ConsumerWidget {
  const DetectionDebugScreen({super.key});

  String _formatTime(dynamic ts) {
    if (ts == null) return '—';
    final ms = (ts as num).toInt();
    if (ms <= 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugAsync = ref.watch(detectionDebugProvider);
    final feedStats = ref.watch(feedStatsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(feedStatsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: debugAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Unified hash counter — Reels uses identical pipeline as Shorts',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            _SummaryCard(
              isDark: isDark,
              currentApp: '${data['currentApp'] ?? '—'}',
              currentScreen: '${data['currentScreen'] ?? '—'}',
              lastEvent: '${data['lastEventType'] ?? '—'}',
              totalReels: feedStats.reelsCount,
              totalShorts: feedStats.shortsCount,
            ),
            const SizedBox(height: 16),
            _ReelsDetectionDebugger(
              isDark: isDark,
              instagramActive: data['instagramPackageActive'] == true,
              currentPackage: '${data['currentPackage'] ?? '—'}',
              currentActivity: '${data['currentActivity'] ?? '—'}',
              visibleTexts: '${data['visibleTexts'] ?? ''}',
              visibleDescriptions: '${data['visibleDescriptions'] ?? ''}',
              nodeCount: (data['nodeCount'] as num?)?.toInt() ?? 0,
              hierarchyDepth: (data['hierarchyDepth'] as num?)?.toInt() ?? 0,
              reelsActive: data['reelsActive'] == true,
              rejectCode: '${data['reelsRejectCode'] ?? ''}',
              rejectDetail: '${data['reelsRejectDetail'] ?? ''}',
              acceptReason: '${data['reelsAcceptReason'] ?? ''}',
            ),
            const SizedBox(height: 16),
            _ReelsCountDebugPanel(
              isDark: isDark,
              active: data['reelsActive'] == true,
              currentCount: feedStats.reelsCount,
              pendingEvents: (data['reelsPendingEvents'] as num?)?.toInt() ?? 0,
              eventQueueSize: (data['reelsEventQueueSize'] as num?)?.toInt() ?? 0,
              lastHashChange: _formatTime(data['reelsLastHashChangeTime']),
              lastCountTime: _formatTime(data['reelsLastCountTime']),
              currentHash: '${data['reelsCurrentHash'] ?? ''}',
              previousHash: '${data['reelsPreviousHash'] ?? ''}',
              absorbedTransitions: (data['reelsAbsorbedTransitions'] as num?)?.toInt() ?? 0,
              burstWarning: '${data['reelsBurstWarning'] ?? ''}',
              lastTrigger: '${data['reelsLastTrigger'] ?? ''}',
            ),
            const SizedBox(height: 16),
            _PlatformSection(
              title: 'YouTube Shorts',
              isDark: isDark,
              active: data['shortsActive'] == true,
              currentHash: '${data['shortsCurrentHash'] ?? ''}',
              previousHash: '${data['shortsPreviousHash'] ?? ''}',
              pendingHash: '${data['shortsPendingHash'] ?? ''}',
              lastCountTime: _formatTime(data['shortsLastCountTime']),
              lastTrigger: '${data['shortsLastTrigger'] ?? ''}',
              total: feedStats.shortsCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.isDark,
    required this.currentApp,
    required this.currentScreen,
    required this.lastEvent,
    required this.totalReels,
    required this.totalShorts,
  });

  final bool isDark;
  final String currentApp;
  final String currentScreen;
  final String lastEvent;
  final int totalReels;
  final int totalShorts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Row('Current App', currentApp),
          _Row('Current Screen', currentScreen),
          _Row('Last Event', lastEvent),
          _Row('Total Reels', '$totalReels'),
          _Row('Total Shorts', '$totalShorts'),
        ],
      ),
    );
  }
}

class _ReelsDetectionDebugger extends StatelessWidget {
  const _ReelsDetectionDebugger({
    required this.isDark,
    required this.instagramActive,
    required this.currentPackage,
    required this.currentActivity,
    required this.visibleTexts,
    required this.visibleDescriptions,
    required this.nodeCount,
    required this.hierarchyDepth,
    required this.reelsActive,
    required this.rejectCode,
    required this.rejectDetail,
    required this.acceptReason,
  });

  final bool isDark;
  final bool instagramActive;
  final String currentPackage;
  final String currentActivity;
  final String visibleTexts;
  final String visibleDescriptions;
  final int nodeCount;
  final int hierarchyDepth;
  final bool reelsActive;
  final String rejectCode;
  final String rejectDetail;
  final String acceptReason;

  @override
  Widget build(BuildContext context) {
    final statusColor = reelsActive ? AppColors.metricGreen : AppColors.coral;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reels Detection Debugger',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _Row('Instagram Active', instagramActive ? 'Yes' : 'No'),
          _Row('Current Package', currentPackage),
          _Row('Current Activity', currentActivity),
          _Row('Reels Active', reelsActive ? 'Yes' : 'No'),
          _Row('Node Count', '$nodeCount'),
          _Row('Hierarchy Depth', '$hierarchyDepth'),
          if (rejectCode.isNotEmpty) ...[
            _Row('Reject Code', rejectCode),
            _Row('Reject Detail', rejectDetail),
          ],
          if (acceptReason.isNotEmpty) _Row('Accept Reason', acceptReason),
          const SizedBox(height: 8),
          Text(
            'Visible Text',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            visibleTexts.isEmpty ? '—' : visibleTexts,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Content Descriptions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            visibleDescriptions.isEmpty ? '—' : visibleDescriptions,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reelsActive ? 'REELS SESSION ACTIVE' : 'REELS SESSION INACTIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelsCountDebugPanel extends StatelessWidget {
  const _ReelsCountDebugPanel({
    required this.isDark,
    required this.active,
    required this.currentCount,
    required this.pendingEvents,
    required this.eventQueueSize,
    required this.lastHashChange,
    required this.lastCountTime,
    required this.currentHash,
    required this.previousHash,
    required this.absorbedTransitions,
    required this.burstWarning,
    required this.lastTrigger,
  });

  final bool isDark;
  final bool active;
  final int currentCount;
  final int pendingEvents;
  final int eventQueueSize;
  final String lastHashChange;
  final String lastCountTime;
  final String currentHash;
  final String previousHash;
  final int absorbedTransitions;
  final String burstWarning;
  final String lastTrigger;

  @override
  Widget build(BuildContext context) {
    final statusColor = active ? AppColors.metricGreen : AppColors.coral;
    final queueWarning = eventQueueSize > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: queueWarning ? AppColors.coral : statusColor.withValues(alpha: 0.3),
          width: queueWarning ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Instagram Reels Counter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  active ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row('Current Reels Count', '$currentCount'),
          _Row('Pending Events', '$pendingEvents'),
          _Row('Event Queue Size', '$eventQueueSize'),
          if (queueWarning)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '⚠ Queue size > 1 — batching detected (should never happen)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coral,
                ),
              ),
            ),
          _Row('Last Reel Change', lastHashChange),
          _Row('Last Count Time', lastCountTime),
          _Row('Absorbed (debounce)', '$absorbedTransitions'),
          _Row('Current Hash', currentHash.isEmpty ? '—' : currentHash),
          _Row('Previous Hash', previousHash.isEmpty ? '—' : previousHash),
          _Row('Last Trigger', lastTrigger.isEmpty ? '—' : lastTrigger),
          if (burstWarning.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '⚠ $burstWarning',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coral,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlatformSection extends StatelessWidget {
  const _PlatformSection({
    required this.title,
    required this.isDark,
    required this.active,
    required this.currentHash,
    required this.previousHash,
    required this.pendingHash,
    required this.lastCountTime,
    required this.lastTrigger,
    required this.total,
  });

  final String title;
  final bool isDark;
  final bool active;
  final String currentHash;
  final String previousHash;
  final String pendingHash;
  final String lastCountTime;
  final String lastTrigger;
  final int total;

  @override
  Widget build(BuildContext context) {
    final statusColor = active ? AppColors.metricGreen : AppColors.coral;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  active ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Row('Session Active', active ? 'Yes' : 'No'),
          _Row('Current Hash', currentHash.isEmpty ? '—' : currentHash),
          _Row('Previous Hash', previousHash.isEmpty ? '—' : previousHash),
          _Row('Pending Hash', pendingHash.isEmpty ? '—' : pendingHash),
          _Row('Last Count Time', lastCountTime),
          _Row('Last Trigger', lastTrigger.isEmpty ? '—' : lastTrigger),
          _Row('Total Count', '$total'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: label.contains('Hash') ? 'monospace' : null,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
