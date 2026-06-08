class PackageFilter {
  PackageFilter._();

  static bool isUserApp(String packageName) {
    if (packageName.isEmpty) return false;
    if (packageName == 'com.ashutoshmishra.scrollless') return false;
    if (packageName == 'android') return false;

    const allowedSystem = {
      'com.android.chrome',
      'com.google.android.youtube',
      'com.google.android.apps.youtube.music',
    };

    if (allowedSystem.contains(packageName)) return true;

    if (packageName.startsWith('com.android.systemui')) return false;
    if (packageName.startsWith('com.android.settings')) return false;
    if (packageName.startsWith('com.android.phone')) return false;
    if (packageName.startsWith('com.android.dialer')) return false;
    if (packageName.startsWith('com.android.vending')) return false;
    if (packageName.startsWith('com.google.android.gms')) return false;
    if (packageName.startsWith('com.google.android.inputmethod')) return false;
    if (packageName.contains('launcher')) return false;
    if (packageName.contains('.inputmethod.')) return false;

    return true;
  }

  static bool wasUsedToday(int? lastTimeUsedMs, DateTime dayStart) {
    if (lastTimeUsedMs == null || lastTimeUsedMs <= 0) return true;
    return lastTimeUsedMs >= dayStart.millisecondsSinceEpoch;
  }
}
