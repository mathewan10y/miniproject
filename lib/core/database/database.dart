import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../../core/models/expense_model.dart';

class AppDatabase {
  static const String _dbName = 'stardust.db';
  late String _dbPath;

  Future<void> initialize() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    _dbPath = p.join(dbFolder.path, _dbName);
  }

  // For now, using in-memory list as a simple database
  static final List<Expense> _expenses = [];
  static final List<Income> _incomes = [];

  // Alias for backwards compatibility
  List<dynamic> get expenses => _expenses;

  // Add expense
  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    return List.from(_expenses);
  }

  // Delete expense
  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index >= 0) {
      _expenses[index] = expense;
    }
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    return _expenses.where((e) => e.category == category).toList();
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _expenses
        .where(
          (e) =>
              e.timestamp.isAfter(startDate) && e.timestamp.isBefore(endDate),
        )
        .toList();
  }

  // Income methods
  Future<void> addIncome(Income income) async {
    _incomes.add(income);
  }

  Future<List<Income>> getAllIncomes() async {
    return List.from(_incomes);
  }

  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((i) => i.id == id);
  }

  Future<void> updateIncome(Income income) async {
    final index = _incomes.indexWhere((i) => i.id == income.id);
    if (index >= 0) {
      _incomes[index] = income;
    }
  }

  Future<List<Income>> getIncomesByCategory(String category) async {
    return _incomes.where((i) => i.category == category).toList();
  }

  Future<List<Income>> getIncomesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _incomes
        .where(
          (i) =>
              i.timestamp.isAfter(startDate) && i.timestamp.isBefore(endDate),
        )
        .toList();
  }
}

class Expense {
  final String id;
  final double amount;
  final String category;
  final bool isWant;
  final DateTime timestamp;
  final bool isSynced;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.isWant,
    required this.timestamp,
    this.isSynced = false,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category,
    'isWant': isWant,
    'timestamp': timestamp.toIso8601String(),
    'isSynced': isSynced,
  };

  // Create from JSON
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    isWant: json['isWant'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isSynced: json['isSynced'] as bool? ?? false,
  );

  // Copy with method
  Expense copyWith({
    String? id,
    double? amount,
    String? category,
    bool? isWant,
    DateTime? timestamp,
    bool? isSynced,
  }) => Expense(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    isWant: isWant ?? this.isWant,
    timestamp: timestamp ?? this.timestamp,
    isSynced: isSynced ?? this.isSynced,
  );
}

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
