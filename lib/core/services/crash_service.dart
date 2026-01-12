import '../models/expense_model.dart';

class CrashService {
  // Returns a cynical roast based on the user's expense.
  String getRoast(ExpenseModel expense) {
    if (expense.isWant) {
      if (expense.amount > 100) {
        return "Another hundred dollars gone. You're really making your ancestors proud, huh?";
      }
      return "Ah, another 'want'. Because adulting is just buying things you don't need with money you don't have.";
    } else {
      return "A 'need'? Sure, jan. Let's see how long that excuse lasts.";
    }
  }
}
