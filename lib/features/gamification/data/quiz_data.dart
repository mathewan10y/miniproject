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
      question: "BOSS: What is your current level?",
      options: ["Level 0", "Level 1", "Level 2"],
      correctIndex: 0,
    );
  }

  static List<QuizQuestion> getBossQuizzes(int levelId) {
    if (_bossQuizLists.containsKey(levelId)) {
      return _bossQuizLists[levelId]!;
    }
    // Fallback: create 3 questions from the single boss quiz
    final singleQuiz = getBossQuiz(levelId);
    return [
      singleQuiz,
      const QuizQuestion(
        question: "BOSS: What is the primary principle of risk management?",
        options: ["Go all in", "Diversify your positions", "Never trade"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: When should you take profits?",
        options: ["Never", "When you reach your target", "When your friend says so"],
        correctIndex: 1,
      ),
    ];
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
      const QuizQuestion(
        question: "What is the difference between an Asset and a Liability?",
        options: ["Assets make money, liabilities cost money", "Both are the same", "Assets cost money, liabilities make money"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "How many months of expenses should your Emergency Shield contain?",
        options: ["1-2 months", "6 months", "12 months"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "What type of debt should you pay off immediately?",
        options: ["Good debt (low interest)", "Bad debt (high interest)", "No debt"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "What is your Net Worth?",
        options: ["Total Assets minus Total Liabilities", "Total monthly income", "Total savings"],
        correctIndex: 0,
      ),
    ],
    1: [
      const QuizQuestion(
        question: "An 'Index Fund' is best described as...",
        options: ["A single risky asteroid", "A basket of top 50 companies", "A pirate clan"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "When you execute a 'Market Order', you buy asset at...",
        options: ["The current asking price immediately", "A discounted price", "Tomorrow's price"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Market Capitalization'?",
        options: ["Total shares × share price", "Daily trading volume", "Company revenue"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What does 'Blue Chip' stock mean?",
        options: ["New startup company", "Large, stable company with good reputation", "Penny stock"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "What is a 'Dividend'?",
        options: ["Company profit sharing with shareholders", "Stock price increase", "Bonus for employees"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Diversification'?",
        options: ["Putting all money in one stock", "Spreading investments across different assets", "Only buying government bonds"],
        correctIndex: 1,
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
      const QuizQuestion(
        question: "What is 'Support' in technical analysis?",
        options: ["Price level where buying pressure overcomes selling pressure", "Maximum price reached", "Minimum trading volume"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What does 'Resistance' mean?",
        options: ["Price level where selling pressure overcomes buying pressure", "Stock split announcement", "Dividend payment date"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is a 'Bullish' trend?",
        options: ["Prices generally rising", "Prices generally falling", "Prices moving sideways"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is a 'Bearish' trend?",
        options: ["Prices generally rising", "Prices generally falling", "Prices moving sideways"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "What is 'Dow Theory'?",
        options: ["Market moves randomly", "Markets move in established trends", "Only tech stocks matter"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "What does 'Uptrend' mean?",
        options: ["Higher highs and higher lows", "Lower highs and lower lows", "Equal highs and equal lows"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Downtrend'?",
        options: ["Higher highs and higher lows", "Lower highs and lower lows", "Equal highs and equal lows"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "What is 'Trend Line'?",
        options: ["A line connecting highs and lows", "A line connecting only highs", "A line connecting only lows"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Chart Pattern'?",
        options: ["A shape formed by price action", "A line connecting highs and lows", "A prediction of future price"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Breakout'?",
        options: ["When price breaks above resistance", "When price breaks below support", "When price moves sideways"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'False Breakout'?",
        options: ["When price breaks above resistance but then falls back", "When price breaks below support but then rises back", "When price moves sideways"],
        correctIndex: 0,
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
      const QuizQuestion(
        question: "What is 'Return on Equity' (ROE)?",
        options: ["Net income ÷ Shareholder equity", "Total revenue ÷ Total assets", "Stock price ÷ Earnings per share"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What does 'EPS' stand for?",
        options: ["Earnings Per Share", "Equity Per Stock", "Enterprise Per Share"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "A company with 'positive earnings' means...",
        options: ["It is profitable", "It has positive cash flow", "Stock price is rising"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Book Value'?",
        options: ["Company's net worth on balance sheet", "Current market price", "Annual revenue"],
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
      const QuizQuestion(
        question: "What is 'Stop-Loss' order?",
        options: ["To guarantee profit", "To automatically sell before a total crash", "To buy more at a low price"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "What does 'Long Position' mean?",
        options: ["Buying an asset expecting price to rise", "Selling an asset expecting price to fall", "Holding cash"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What does 'Short Position' mean?",
        options: ["Buying an asset expecting price to rise", "Selling an asset expecting price to fall", "Holding cash"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "What is 'Risk Management'?",
        options: ["Taking maximum risk for maximum profit", "Protecting capital while seeking returns", "Only investing in safe assets"],
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
      const QuizQuestion(
        question: "What is 'Position Sizing'?",
        options: ["How many shares to buy based on risk", "Physical size of stock certificate", "Market value of company"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What does 'Risk/Reward Ratio' measure?",
        options: ["Potential profit vs potential loss", "Company's financial health", "Stock volatility"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Take Profit' order?",
        options: ["To sell when target price reached", "To buy at lowest price", "To hold forever"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Emotional Trading'?",
        options: ["Making decisions based on fear/greed", "Following technical analysis", "Using fundamental analysis"],
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
      const QuizQuestion(
        question: "What is 'HODL' in crypto?",
        options: ["Hold on for dear life", "Sell immediately", "Trade daily"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'DeFi'?",
        options: ["Decentralized Finance", "Digital currency", "Banking app"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is a 'Wallet' in crypto?",
        options: ["Digital storage for cryptocurrencies", "Physical wallet", "Bank account"],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "What is 'Blockchain'?",
        options: ["Distributed ledger technology", "Cryptocurrency", "Payment method"],
        correctIndex: 0,
      ),
    ],
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

  static final Map<int, List<QuizQuestion>> _bossQuizLists = {
    0: [
      const QuizQuestion(
        question: "BOSS: I am the Gravity Well of Inflation. If you keep 100% of your power in cash, what happens over time?",
        options: ["It grows infinitely", "It slowly loses purchasing power", "It remains exactly the same"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: What is the primary principle of risk management?",
        options: ["Go all in", "Diversify your positions", "Never trade"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: When should you take profits?",
        options: ["Never", "When you reach your target", "When your friend says so"],
        correctIndex: 1,
      ),
    ],
    1: [
      const QuizQuestion(
        question: "BOSS: I am the Volatility Swarm. You bought a single penny stock that crashed 90%. What should you have done?",
        options: ["Borrowed more to average down", "Bought a diversified Index Fund", "Deleted the app"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: What is the primary principle of risk management?",
        options: ["Go all in", "Diversify your positions", "Never trade"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: When should you take profits?",
        options: ["Never", "When you reach your target", "When your friend says so"],
        correctIndex: 1,
      ),
    ],
    2: [
      const QuizQuestion(
        question: "BOSS: The Market Maker. A massive red candlestick breaches support on heavy volume. Do you buy the dip immediately?",
        options: ["Yes, always buy red", "No, wait for confirmation of a new 'Floor'", "Yes, use max leverage"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: What is the primary principle of risk management?",
        options: ["Go all in", "Diversify your positions", "Never trade"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: When should you take profits?",
        options: ["Never", "When you reach your target", "When your friend says so"],
        correctIndex: 1,
      ),
    ],
    3: [
      const QuizQuestion(
        question: "BOSS: The Auditor. A company's P/E is 500, and Debt is 3.5. Their CEO posted a rocket emoji. What is your assessment?",
        options: ["Fundamentals are terrible, avoid.", "The rocket emoji guarantees profit.", "Buy on margin."],
        correctIndex: 0,
      ),
      const QuizQuestion(
        question: "BOSS: What is the primary principle of risk management?",
        options: ["Go all in", "Diversify your positions", "Never trade"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: When should you take profits?",
        options: ["Never", "When you reach your target", "When your friend says so"],
        correctIndex: 1,
      ),
    ],
    4: [
      const QuizQuestion(
        question: "BOSS: The Margin Caller. If you are 10x leveraged and the market drops 5%, what is your actual portfolio loss?",
        options: ["5%", "10%", "50%"],
        correctIndex: 2,
      ),
      const QuizQuestion(
        question: "BOSS: What is the primary principle of risk management?",
        options: ["Go all in", "Diversify your positions", "Never trade"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: When should you take profits?",
        options: ["Never", "When you reach your target", "When your friend says so"],
        correctIndex: 1,
      ),
    ],
    5: [
      const QuizQuestion(
        question: "BOSS: The Black Swan. A catastrophic asteroid event crashes all markets instantly. What protocol saves your ship?",
        options: ["Panic Selling manually", "A pre-placed Stop-Loss order", "Hoping it goes back up"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: What is the primary principle of risk management?",
        options: ["Go all in", "Diversify your positions", "Never trade"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: When should you take profits?",
        options: ["Never", "When you reach your target", "When your friend says so"],
        correctIndex: 1,
      ),
    ],
    6: [
      const QuizQuestion(
        question: "BOSS: The IRS Dreadnought. You made \$10,000 trading Doge-Asteroids, but lost \$5,000 on Terra-Luna. What do you owe 30% tax on?",
        options: ["The net \$5,000 profit", "The full \$10,000 profit (Offset not allowed)", "Nothing, Crypto is unregulated"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: What is the primary principle of risk management?",
        options: ["Go all in", "Diversify your positions", "Never trade"],
        correctIndex: 1,
      ),
      const QuizQuestion(
        question: "BOSS: When should you take profits?",
        options: ["Never", "When you reach your target", "When your friend says so"],
        correctIndex: 1,
      ),
    ],
  };
}
