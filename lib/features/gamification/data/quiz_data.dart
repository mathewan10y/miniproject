class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}

class QuizData {
  static QuizQuestion getSubLevelQuiz(int levelId, int subLevelIndex) {
    if (_subLevelQuizzes.containsKey(levelId) && _subLevelQuizzes[levelId]!.length > subLevelIndex) {
      return _subLevelQuizzes[levelId]![subLevelIndex];
    }
    // Generic fallback
    return const QuizQuestion(
      question: "System Override Active. Identify the primary objective.",
      options: ["Panic", "Survive and generate FUEL", "Sleep"],
      correctIndex: 1,
    );
  }

  static QuizQuestion getBossQuiz(int levelId) {
    if (_bossQuizzes.containsKey(levelId)) {
      return _bossQuizzes[levelId]!;
    }
    return const QuizQuestion(
      question: "BOSS: Are you ready to advance to the next sector?",
      options: ["No", "Yes"],
      correctIndex: 1,
    );
  }

  static final Map<int, List<QuizQuestion>> _subLevelQuizzes = {
    0: [
      const QuizQuestion(
        question: "What happens if your 'Needs' (Life Support) exceed 50% of your power budget?",
        options: ["The ship flies faster", "The ship stalls", "You get a bonus"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "If you spend money on a luxury item, it is classified as a...",
        options: ["Need", "Want", "Emergency"],
        correctIndex: 1,
      ),
    ],
    1: [
      const QuizQuestion(
        question: "An 'Index Fund' is best described as...",
        options: ["A single risky asteroid", "A basket of the top 50 companies", "A pirate clan"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "When you execute a 'Market Order', you buy the asset at...",
        options: ["The current asking price immediately", "A discounted price", "Tomorrow's price"],
        correctIndex: 0,
      ),
    ],
    2: [
      const QuizQuestion(
        question: "On a Japanese Candlestick chart, what does a GREEN body indicate?",
        options: ["Sellers won", "Buyers won", "No trades occurred"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "To find the macroscopic trend of an asset, which timeframe should you consult first?",
        options: ["1-Minute", "1-Hour", "1-Day (1D)"],
        correctIndex: 2,
      ),
    ],
    3: [
      const QuizQuestion(
        question: "What does a high P/E (Price-to-Earnings) ratio imply?",
        options: ["The company is very cheap", "It will take many years to earn back the price", "The company pays high dividends"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "If a company has a Debt-to-Equity ratio above 1.0, it means...",
        options: ["It is flying on borrowed fuel (high debt)", "It has no debt", "It is extremely safe"],
        correctIndex: 0,
      ),
    ],
    4: [
      const QuizQuestion(
        question: "If you use 5x Leverage and the stock drops by 20%, what happens?",
        options: ["You lose 20%", "Your entire account is wiped out (liquidated)", "You still make profit"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "Where do the extra funds come from when using Margin/Leverage?",
        options: ["A bank grant", "Borrowed from the broker", "Crypto mining"],
        correctIndex: 1,
      ),
    ],
    5: [
      const QuizQuestion(
        question: "What is the purpose of a 'Stop-Loss' order?",
        options: ["To guarantee profit", "To automatically sell before a total crash", "To buy more at a low price"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "Trading psychology warns against 'FOMO', which means...",
        options: ["Fear Of Missing Out", "Financial Order Market Optimization", "Fired On Monday Options"],
        correctIndex: 0,
      ),
    ],
    6: [
      const QuizQuestion(
        question: "What is the flat tax rate 'The Empire' takes on digital asset profits?",
        options: ["10%", "30%", "0%"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "Can you offset your crypto losses against other gains?",
        options: ["Yes, up to \$3,000", "No, losses cannot be offset", "Yes, unlimited"],
        correctIndex: 1,
      ),
    ]
  };

  static final Map<int, QuizQuestion> _bossQuizzes = {
    0: const QuizQuestion(
      question: "BOSS: I am the Gravity Well of Inflation. If you keep 100% of your power in cash, what happens over time?",
      options: ["It grows infinitely", "It slowly loses purchasing power", "It remains exactly the same"],
      correctIndex: 1,
    ),
    1: const QuizQuestion(
      question: "BOSS: I am the Volatility Swarm. You bought a single penny stock that crashed 90%. What should you have done?",
      options: ["Borrowed more to average down", "Bought a diversified Index Fund", "Deleted the app"],
      correctIndex: 1,
    ),
    2: const QuizQuestion(
      question: "BOSS: The Market Maker. A massive red candlestick breaches support on heavy volume. Do you buy the dip immediately?",
      options: ["Yes, always buy red", "No, wait for confirmation of a new 'Floor'", "Yes, use max leverage"],
      correctIndex: 1,
    ),
    3: const QuizQuestion(
      question: "BOSS: The Auditor. A company's P/E is 500, and Debt is 3.5. Their CEO posted a rocket emoji. What is your assessment?",
      options: ["Fundamentals are terrible, avoid.", "The rocket emoji guarantees profit.", "Buy on margin."],
      correctIndex: 0,
    ),
    4: const QuizQuestion(
      question: "BOSS: The Margin Caller. If you are 10x leveraged and the market drops 5%, what is your actual portfolio loss?",
      options: ["5%", "10%", "50%"],
      correctIndex: 2,
    ),
    5: const QuizQuestion(
      question: "BOSS: The Black Swan. A catastrophic asteroid event crashes all markets instantly. What protocol saves your ship?",
      options: ["Panic Selling manually", "A pre-placed Stop-Loss order", "Hoping it goes back up"],
      correctIndex: 1,
    ),
    6: const QuizQuestion(
      question: "BOSS: The IRS Dreadnought. You made \$10,000 trading Doge-Asteroids, but lost \$5,000 on Terra-Luna. What do you owe 30% tax on?",
      options: ["The net \$5,000 profit", "The full \$10,000 profit (Offset not allowed)", "Nothing, Crypto is unregulated"],
      correctIndex: 1,
    ),
  };
}
