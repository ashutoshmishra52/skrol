import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/native_stats_service.dart';

/// Real-time Reels/Shorts counts — updated instantly via EventChannel.
class FeedStatsNotifier extends StateNotifier<FeedStats> {
  FeedStatsNotifier() : super(FeedStats.empty) {
    _init();
  }

  StreamSubscription<FeedStats>? _sub;

  Future<void> _init() async {
    state = await NativeStatsService.getFeedStats();
    _sub = NativeStatsService.feedStatsStream.listen(
      (stats) => state = stats,
      onError: (_) {},
    );
  }

  Future<void> refresh() async {
    state = await NativeStatsService.getFeedStats();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final feedStatsNotifierProvider =
    StateNotifierProvider<FeedStatsNotifier, FeedStats>((ref) {
  return FeedStatsNotifier();
});

/// Backward-compatible alias — prefer feedStatsNotifierProvider.
final liveFeedStatsProvider = Provider<FeedStats>((ref) {
  return ref.watch(feedStatsNotifierProvider);
});
