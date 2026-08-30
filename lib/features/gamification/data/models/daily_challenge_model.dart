class DailyChallengeModel {
 final String id;
 final DateTime challengeDate;
 final String themeTitle;
 final String themeEmoji;
 final String tagName;
 final String? description;
 final int rewardPoints;

 const DailyChallengeModel({
   required this.id,
   required this.challengeDate,
   required this.themeTitle,
   required this.themeEmoji,
   required this.tagName,
   this.description,
   required this.rewardPoints,
});

 factory DailyChallengeModel.fromJson(Map<String, dynamic> json) {
   return DailyChallengeModel(
     id: json['id'] as String,
     challengeDate: DateTime.parse(json['challenge_date'] as String),
     themeTitle: json['theme_title'] as String,
     themeEmoji: json['theme_emoji'] as String? ?? '📸',
     tagName: json['tag_name'] as String,
     description: json['description'] as String?,
     rewardPoints: json['reward_points'] as int? ?? 0,
   );
 }

 @override
 String toString() => 'DailyChallengeModel(theme: $themeTitle, tag: $tagName)';
}