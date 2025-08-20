class Room {
  final String type;
  final String direction;
  final int score;
  final List<String> remedies;
  final String recommendation;
  final List<String> colorRecommendations;
  
  Room({
    required this.type,
    required this.direction,
    required this.score,
    required this.remedies,
    required this.recommendation,
    required this.colorRecommendations,
  });
  
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      type: json['roomType'] ?? '',
      direction: json['direction'] ?? '',
      score: json['score'] ?? 0,
      remedies: List<String>.from(json['remedies'] ?? []),
      recommendation: json['recommendation'] ?? '',
      colorRecommendations: List<String>.from(json['color_recommendations'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'roomType': type,
      'direction': direction,
      'score': score,
      'remedies': remedies,
      'recommendation': recommendation,
      'color_recommendations': colorRecommendations,
    };
  }
  
  // Helper method to get a visual representation of the score
  String getScoreEmoji() {
    if (score >= 8) return '🔆'; // Excellent
    if (score >= 6) return '✅'; // Good
    if (score >= 4) return '⚠️'; // Average
    return '❌'; // Poor
  }
}
