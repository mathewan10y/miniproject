class ExpenseModel {
  final String id;
  final double amount;
  final String category;
  final bool isWant;
  final DateTime timestamp;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.isWant,
    required this.timestamp,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'category': category,
        'isWant': isWant,
        'timestamp': timestamp.toIso8601String(),
      };

  // Create from JSON
  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        isWant: json['isWant'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  // Copy with method
  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? category,
    bool? isWant,
    DateTime? timestamp,
  }) =>
      ExpenseModel(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        isWant: isWant ?? this.isWant,
        timestamp: timestamp ?? this.timestamp,
      );
}
