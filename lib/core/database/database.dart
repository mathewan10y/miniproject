import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Re-export models so existing providers don't need import changes ─────────
export '../../core/models/expense_model.dart' show ExpenseModel;
export '../../core/models/income_model.dart' show Income, IncomeModel;

// ─── Expense model (used by providers via database.dart import) ───────────────

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category,
    'is_want': isWant, // snake_case for Supabase column names
    'timestamp': timestamp.toIso8601String(),
    'is_synced': isSynced,
  };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    isWant: json['is_want'] as bool? ?? false,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isSynced: json['is_synced'] as bool? ?? false,
  );

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

// ─── Income model ─────────────────────────────────────────────────────────────

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    'is_synced': isSynced,
  };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    isSynced: json['is_synced'] as bool? ?? false,
  );

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

// ─── AppDatabase — Supabase-backed CRUD ──────────────────────────────────────

class AppDatabase {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Expense API ─────────────────────────────────────────────────────────────

  Future<void> addExpense(Expense expense) async {
    try {
      await _client.from('expenses').insert(expense.toJson());
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  Future<List<Expense>> getAllExpenses() async {
    try {
      final rows = await _client
          .from('expenses')
          .select()
          .order('timestamp', ascending: false);
      return (rows as List)
          .map((r) => Expense.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load expenses: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _client.from('expenses').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _client
          .from('expenses')
          .update(expense.toJson())
          .eq('id', expense.id);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  Future<List<Expense>> getExpensesByCategory(String category) async {
    try {
      final rows = await _client
          .from('expenses')
          .select()
          .eq('category', category)
          .order('timestamp', ascending: false);
      return (rows as List)
          .map((r) => Expense.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses by category: $e');
    }
  }

  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final rows = await _client
          .from('expenses')
          .select()
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false);
      return (rows as List)
          .map((r) => Expense.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get expenses by date range: $e');
    }
  }

  // ── Income API ──────────────────────────────────────────────────────────────

  Future<void> addIncome(Income income) async {
    try {
      await _client.from('incomes').insert(income.toJson());
    } catch (e) {
      throw Exception('Failed to add income: $e');
    }
  }

  Future<List<Income>> getAllIncomes() async {
    try {
      final rows = await _client
          .from('incomes')
          .select()
          .order('timestamp', ascending: false);
      return (rows as List)
          .map((r) => Income.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load incomes: $e');
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await _client.from('incomes').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete income: $e');
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      await _client.from('incomes').update(income.toJson()).eq('id', income.id);
    } catch (e) {
      throw Exception('Failed to update income: $e');
    }
  }

  Future<List<Income>> getIncomesByCategory(String category) async {
    try {
      final rows = await _client
          .from('incomes')
          .select()
          .eq('category', category)
          .order('timestamp', ascending: false);
      return (rows as List)
          .map((r) => Income.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get incomes by category: $e');
    }
  }

  Future<List<Income>> getIncomesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final rows = await _client
          .from('incomes')
          .select()
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String())
          .order('timestamp', ascending: false);
      return (rows as List)
          .map((r) => Income.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get incomes by date range: $e');
    }
  }
}
