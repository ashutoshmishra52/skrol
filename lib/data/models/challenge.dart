enum ChallengeStatus { active, completed, failed }

enum ChallengeType {
  noReelsTillNoon,
  socialLimit1h,
  weekendDetox,
  focus7Day,
}

class FocusChallenge {
  FocusChallenge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.badgeEmoji,
    required this.startDate,
    this.endDate,
    this.status = ChallengeStatus.active,
    this.progress = 0,
    this.target = 100,
  });

  final String id;
  final ChallengeType type;
  final String title;
  final String description;
  final String badgeEmoji;
  final DateTime startDate;
  final DateTime? endDate;
  ChallengeStatus status;
  int progress;
  final int target;

  double get progressPercent => (progress / target).clamp(0.0, 1.0);

  bool get isComplete => status == ChallengeStatus.completed;
}

class ChallengeTemplates {
  static List<FocusChallenge> defaults() => [
        FocusChallenge(
          id: 'no_reels_noon',
          type: ChallengeType.noReelsTillNoon,
          title: 'No Reels till Noon',
          description: 'Skip short-form video before 12 PM',
          badgeEmoji: '🌅',
          startDate: DateTime.now(),
          target: 1,
        ),
        FocusChallenge(
          id: 'social_1h',
          type: ChallengeType.socialLimit1h,
          title: '1 Hour Social Limit',
          description: 'Stay under 60 min on social apps today',
          badgeEmoji: '⏱️',
          startDate: DateTime.now(),
          target: 60,
        ),
        FocusChallenge(
          id: 'weekend_detox',
          type: ChallengeType.weekendDetox,
          title: 'Weekend Detox',
          description: 'Under 30 min social media Sat & Sun',
          badgeEmoji: '🏕️',
          startDate: DateTime.now(),
          target: 30,
        ),
        FocusChallenge(
          id: 'focus_7day',
          type: ChallengeType.focus7Day,
          title: '7-Day Focus Challenge',
          description: 'Complete a focus session every day for 7 days',
          badgeEmoji: '🔥',
          startDate: DateTime.now(),
          target: 7,
        ),
      ];
}
