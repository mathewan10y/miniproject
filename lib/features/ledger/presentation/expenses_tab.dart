import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/database/database.dart';
import '../expense_provider.dart';

class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);

    return Row(
      children: [
        // Calendar on the left
        SizedBox(
          width: 300,
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
        ),
        // Expense list on the right
        Expanded(
          child: expensesAsync.when(
            data: (expenses) {
              final selectedDayExpenses = expenses.where((e) => isSameDay(e.timestamp, _selectedDay)).toList();
              if (selectedDayExpenses.isEmpty) {
                return const Center(child: Text('No expenses for this day.'));
              }
              return ListView.builder(
                itemCount: selectedDayExpenses.length,
                itemBuilder: (ctx, index) {
                  final expense = selectedDayExpenses[index];
                  return ListTile(
                    title: Text(expense.category),
                    subtitle: Text(expense.isWant ? 'Want' : 'Need'),
                    trailing: Text('\$${expense.amount.toStringAsFixed(2)}'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }
}
