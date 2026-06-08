/// No-op — overlay/accessibility open only when user taps Allow in UI.
class ReelWatchService {
  ReelWatchService._();
  static final ReelWatchService instance = ReelWatchService._();

  Future<void> prepare() async {}
}
