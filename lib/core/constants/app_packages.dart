/// Known Android package IDs and human-readable app names.
class AppPackages {
  AppPackages._();

  static const String instagram = 'com.instagram.android';
  static const String snapchat = 'com.snapchat.android';
  static const String youtube = 'com.google.android.youtube';
  static const String facebook = 'com.facebook.katana';
  static const String twitter = 'com.twitter.android';
  static const String linkedin = 'com.linkedin.android';
  static const String reddit = 'com.reddit.frontpage';
  static const String chrome = 'com.android.chrome';
  static const String whatsapp = 'com.whatsapp';
  static const String tiktok = 'com.zhiliaoapp.musically';

  /// Tracked social media apps for accurate UsageStats breakdown.
  static const List<String> socialMediaApps = [
    instagram,
    youtube,
    facebook,
    'com.facebook.lite',
    twitter,
    snapchat,
    linkedin,
    reddit,
    tiktok,
    'com.ss.android.ugc.trill',
  ];

  static const List<String> primarySocialApps = [
    instagram,
    youtube,
    facebook,
    twitter,
    snapchat,
  ];

  /// Apps where short-form video (reels) is commonly consumed.
  static const List<String> reelApps = [
    instagram,
    youtube,
    tiktok,
    'com.ss.android.ugc.trill',
  ];

  static bool isReelApp(String packageName) => reelApps.contains(packageName);

  static bool isSocialApp(String packageName) =>
      socialMediaApps.contains(packageName);

  /// Primary apps blocked in Monk Mode by default.
  static const List<String> coreDistractingApps = socialMediaApps;

  static const Map<String, String> displayNames = {
    instagram: 'Instagram',
    snapchat: 'Snapchat',
    youtube: 'YouTube',
    facebook: 'Facebook',
    'com.facebook.lite': 'Facebook Lite',
    twitter: 'X (Twitter)',
    linkedin: 'LinkedIn',
    reddit: 'Reddit',
    chrome: 'Chrome',
    whatsapp: 'WhatsApp',
    tiktok: 'TikTok',
    'com.ss.android.ugc.trill': 'TikTok',
    'com.spotify.music': 'Spotify',
    'com.netflix.mediaclient': 'Netflix',
  };

  static String displayName(String packageName) {
    if (displayNames.containsKey(packageName)) {
      return displayNames[packageName]!;
    }
    final parts = packageName.split('.');
    if (parts.isEmpty) return packageName;
    final name = parts.last.replaceAll('_', ' ');
    if (name.isEmpty) return packageName;
    return name[0].toUpperCase() + name.substring(1);
  }

  static List<String> withCoreApps(List<String> packages) {
    return [
      ...socialMediaApps,
      ...packages.where((p) => !socialMediaApps.contains(p)),
    ];
  }
}
