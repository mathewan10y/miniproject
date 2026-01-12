import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../expense_provider.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  final Function(double amount)? onExpenseAdded;

  const AddExpenseSheet({super.key, this.onExpenseAdded});

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Food';
  bool _isWant = true;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Fun',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitExpense() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      
      // Input validation and limits
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Amount must be greater than 0')),
        );
        return;
      }
      
      if (amount > 1000000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum storage capacity exceeded.')),
        );
        return;
      }

      ref
          .read(expenseProvider.notifier)
          .addExpense(amount, _selectedCategory, _isWant);
      
      // Call the callback if provided
      widget.onExpenseAdded?.call(amount);
      
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0E27),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'ADD EXPENSE',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(letterSpacing: 2),
                ),
                const SizedBox(height: 20),
                // Amount input
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Color(0xFFE0FFFF)),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: const TextStyle(color: Color(0xFFBBDEFF)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF00D9FF),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                        color: Color(0xFF00D9FF),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Category chips
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Category',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF00D9FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children:
                      _categories.map((category) {
                        return ChoiceChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color:
                                  _selectedCategory == category
                                      ? Colors.white
                                      : const Color(0xFFBBDEFF),
                            ),
                          ),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.black.withOpacity(0.3),
                          selectedColor: const Color(0xFF00D9FF),
                          side: BorderSide(
                            color:
                                _selectedCategory == category
                                    ? const Color(0xFF00D9FF)
                                    : Colors.white24,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                // Want/Need toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      'Is this a "Want"?',
                      style: TextStyle(color: Color(0xFFE0FFFF)),
                    ),
                    value: _isWant,
                    onChanged: (value) {
                      setState(() {
                        _isWant = value;
                      });
                    },
                    activeColor: const Color(0xFF00D9FF),
                    activeTrackColor: const Color(0xFF00B8D4),
                  ),
                ),
                const SizedBox(height: 20),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ADD EXPENSE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
