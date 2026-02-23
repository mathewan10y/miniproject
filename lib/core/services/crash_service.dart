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

  String getVarsityRoast() {
    return """Oh, look at this cute little RPG you're building. 'Level 1: The Recruit.' 🥺 Aww. Is that where you learn how to lose your first ₹500?

Basically, here's the translation:

Level 1: For babies who don't know what Nifty is.

Level 2: Drawing imaginary lines on a chart and calling it 'science' (Astrology for bros). 🤡

Level 3: Reading boring PDFs because you think you're Warren Buffett.

Level 4: 'Options Trading' aka 'Speedrun to Bankruptcy.' 📉

Good luck unlocking Level 4. Most people quit at Level 2 when they realize 'Head and Shoulders' isn't just a shampoo.""";
  }
}
