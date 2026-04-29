class ChallengeModel {
  final String challengeId;
  final String title;
  final String description;
  final String date; // YYYY-MM-DD
  final bool isActive;

  const ChallengeModel({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.date,
    required this.isActive,
  });

  factory ChallengeModel.fromMap(Map<String, dynamic> map, String id) {
    return ChallengeModel(
      challengeId: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      date: map['date'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challenge_id': challengeId,
      'title': title,
      'description': description,
      'date': date,
      'is_active': isActive,
    };
  }

  ChallengeModel copyWith({
    String? challengeId,
    String? title,
    String? description,
    String? date,
    bool? isActive,
  }) {
    return ChallengeModel(
      challengeId: challengeId ?? this.challengeId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      isActive: isActive ?? this.isActive,
    );
  }
}
