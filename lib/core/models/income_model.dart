class Income {
  final String id;
  final double amount;
  final String category;
  final DateTime timestamp;
  final bool isSynced;

  Income({
    required this.id,
    required this.amount,
    required this.category,
    required this.timestamp,
    this.isSynced = false,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    'isSynced': isSynced,
  };

  // Create from JSON
  factory Income.fromJson(Map<String, dynamic> json) => Income(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isSynced: json['isSynced'] as bool? ?? false,
  );

  // Copy with method
  Income copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? timestamp,
    bool? isSynced,
  }) => Income(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    timestamp: timestamp ?? this.timestamp,
    isSynced: isSynced ?? this.isSynced,
  );
}

class IncomeModel {
  final String id;
  final double amount;
  final String category;
  final DateTime timestamp;

  IncomeModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.timestamp,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
  };

  // Create from JSON
  factory IncomeModel.fromJson(Map<String, dynamic> json) => IncomeModel(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  // Copy with method
  IncomeModel copyWith({
    String? id,
    double? amount,
    String? category,
    DateTime? timestamp,
  }) => IncomeModel(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    timestamp: timestamp ?? this.timestamp,
  );
}
