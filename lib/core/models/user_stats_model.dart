class UserStatsModel {
  final String userId;
  int xp;
  int currentLevel;
  double tradingCredits;
  int totalExpenses;
  double totalSpent;
  DateTime lastUpdated;

  UserStatsModel({
    required this.userId,
    this.xp = 0,
    this.currentLevel = 1,
    this.tradingCredits = 0.0,
    this.totalExpenses = 0,
    this.totalSpent = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'userId': userId,
        'xp': xp,
        'currentLevel': currentLevel,
        'tradingCredits': tradingCredits,
        'totalExpenses': totalExpenses,
        'totalSpent': totalSpent,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  // Create from JSON
  factory UserStatsModel.fromJson(Map<String, dynamic> json) => UserStatsModel(
        userId: json['userId'] as String,
        xp: json['xp'] as int? ?? 0,
        currentLevel: json['currentLevel'] as int? ?? 1,
        tradingCredits: (json['tradingCredits'] as num?)?.toDouble() ?? 0.0,
        totalExpenses: json['totalExpenses'] as int? ?? 0,
        totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'] as String)
            : null,
      );

  // Copy with method
  UserStatsModel copyWith({
    String? userId,
    int? xp,
    int? currentLevel,
    double? tradingCredits,
    int? totalExpenses,
    double? totalSpent,
    DateTime? lastUpdated,
  }) =>
      UserStatsModel(
        userId: userId ?? this.userId,
        xp: xp ?? this.xp,
        currentLevel: currentLevel ?? this.currentLevel,
        tradingCredits: tradingCredits ?? this.tradingCredits,
        totalExpenses: totalExpenses ?? this.totalExpenses,
        totalSpent: totalSpent ?? this.totalSpent,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}
