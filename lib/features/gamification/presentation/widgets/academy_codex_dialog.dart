import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../user_stats_provider.dart';

// ─── Level metadata ───────────────────────────────────────────────────────────

class _LevelMeta {
  final int level;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String assetPath; // asset path to the level document file

  const _LevelMeta({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.assetPath,
  });
}

const _levels = <_LevelMeta>[
  _LevelMeta(
    level: 0,
    title: 'THE ACADEMY',
    subtitle: 'Life Support',
    accent: Color(0xFF4FC3F7),
    icon: Icons.school_outlined,
    assetPath: 'lib/assets/documents/level0',
  ),
  _LevelMeta(
    level: 1,
    title: 'GROUND SCHOOL',
    subtitle: 'The Shipyard',
    accent: Color(0xFF81C784),
    icon: Icons.construction_outlined,
    assetPath: 'lib/assets/documents/level1',
  ),
  _LevelMeta(
    level: 2,
    title: 'NAVIGATION',
    subtitle: 'Star Mapping',
    accent: Color(0xFFFFD54F),
    icon: Icons.explore_outlined,
    assetPath: 'lib/assets/documents/level2',
  ),
  _LevelMeta(
    level: 3,
    title: 'ENGINEERING',
    subtitle: 'Reactor Diagnostics',
    accent: Color(0xFFFF8A65),
    icon: Icons.engineering_outlined,
    assetPath: 'lib/assets/documents/level3',
  ),
  _LevelMeta(
    level: 4,
    title: 'HYPERDRIVE',
    subtitle: 'Warp Speed',
    accent: Color(0xFFE040FB),
    icon: Icons.rocket_launch_outlined,
    assetPath: 'lib/assets/documents/level4',
  ),
  _LevelMeta(
    level: 5,
    title: 'CRISIS MANAGEMENT',
    subtitle: 'Asteroid Field',
    accent: Color(0xFFEF5350),
    icon: Icons.warning_amber_outlined,
    assetPath: 'lib/assets/documents/level5',
  ),
  _LevelMeta(
    level: 6,
    title: 'THE OUTER RIM',
    subtitle: 'Uncharted Space',
    accent: Color(0xFF7E57C2),
    icon: Icons.language_outlined,
    assetPath: 'lib/assets/documents/level6',
  ),
];

// Fallback content from docu when per-level file is empty
const _fallbackContent = <int, String>{
  0: '''LEVEL 0: THE ACADEMY (Life Support)
Before you can fly the ship, you must power the ship.

0.1 Power Generation (Income Dynamics)
Active Income: Trading hours for credits (salary, freelancing). The baseline engine.
Passive Income: Credits generated without active input — rental yield, royalties, dividends.
Portfolio Income: Capital gains and dividends from paper assets.
Mission Directive: Financial independence is achieved when Passive + Portfolio Income > Living Expenses.

0.2 Hull Breaches (Budgeting & Leakage)
The 50/30/20 Rule: 50% Needs · 30% Wants · 20% Savings/Investing.
Inflation: The invisible cosmic radiation that slowly erodes the purchasing power of idle cash.
Type A — Life Support (Needs): Oxygen (Rent), Rations (Food). Cannot cut, only optimize.
Type B — The Void (Wants): Energy leaking into nothingness. If Void expenses > 30% of income, your ship stalls.

0.3 The Flow Gauge (Balance Sheets & Cash Flow)
Assets vs Liabilities: An asset puts money in your pocket; a liability takes it out. A car bought on a loan is a liability, not an asset.
Net Worth = Total Assets − Total Liabilities.
🟢 Positive Flow: Charging batteries (wealth creation).
🔴 Negative Flow: Draining reserves (debt spiral).
⚪ Neutral Flow: Stagnant — one asteroid hit will destroy you.
Cash Flow Quadrant: Employee → Self-Employed → Business Owner → Investor.

0.4 Emergency Shields (The Safety Net)
The 6-Month Rule: Build a liquid fund equal to 6 months of absolute basic living expenses before investing.
Placement: High-Yield Savings Accounts or Liquid Mutual Funds. NEVER in volatile equities.

0.5 Gravitational Drag (Debt Management)
Good Debt: buys income-producing assets (business loan).
Bad Debt: finances depreciating consumer goods (credit card debt for clothes).
Credit Scores (CIBIL): Your financial reputation in the galaxy.

⚔️ Boss Fight (Unlock Level 1): The Survival Test.
Audit a simulated character's monthly expenses, correctly identify liabilities vs. assets, and calculate the exact size of the emergency fund required before investing.''',

  1: '''LEVEL 1: GROUND SCHOOL (The Shipyard)
Welcome to the Shipyard. This is where fleets are built.

1.1 The Shipyard (Market Ecosystem)
What is a Stock/Equity? Fractional ownership of a real business.
The Regulators (SEBI): The "Federation" that prevents fraud and protects retail cadets.
Exchanges (NSE/BSE): Where trades happen.
Depositories (NSDL/CDSL): Where digital shares are stored in your Demat account.

1.2 The Launch (Primary Markets)
IPO (Initial Public Offering): Why companies go public — to raise capital or pay off debt.
A new ship leaving the factory for the first time. Risk: High. Reward: Rich Captains if it succeeds.
Market Capitalization = Share Price × Total Outstanding Shares.
Large-Cap (Blue-chip, low risk, slow growth) · Mid-Cap · Small-Cap (High risk, high potential).

1.3 Orbital Mechanics (Secondary Markets)
The Order Book: Buyers (Bidders) vs Sellers (Askers).
Bid-Ask Spread: Difference between highest bid and lowest ask.
Market Orders: Buy immediately at any price — fast but imprecise.
Limit Orders: Buy only at a specific price — precise but may not execute.
NIFTY 50 / SENSEX: The flagship fleet — Fleet Green = safe, Fleet Red = turbulence.

1.4 Convoy Protocols (Mutual Funds & ETFs)
Diversification: Never put all your reactor cores in one basket.
Active vs Passive: Fund managers (high fees) vs Index Funds (low fees). Passive historically wins over 20 years.
Expense Ratios (TER): The annual AMC fee. A 1% difference costs millions over 30 years of compounding.
SIP (Systematic Investment Plan): Rupee-Cost Averaging — invest a fixed amount monthly to ignore volatility.

⚔️ Boss Fight (Unlock Level 2): The Market Mechanic.
Calculate the market cap of a fictional company. Explain why low-cost Index Funds historically beat active stock picking.''',

  2: '''LEVEL 2: NAVIGATION (Star Mapping)
You cannot fly blind. You need maps. We call them Charts.

2.1 Star Charts (Candlestick Anatomy)
OHLC: Open · High · Low · Close. Each candle = a battle between Bulls (buyers) and Bears (sellers).
Green Candle: Buyers won (price went UP).
Red Candle: Sellers won (price went DOWN).
Wicks/Tails: How far the price tried to go but failed.
Timeframes: Micro (1m, 5m for day trading) vs Macro (1D, 1W for investing).
Patterns: Bullish Engulfing, Hammer, Doji (indecision in the market).

2.2 Gravitational Pull (Trend Analysis)
Dow Theory: The market moves in trends.
Uptrend: Higher Highs (HH) + Higher Lows (HL). Strategy: Buy.
Downtrend: Lower Highs (LH) + Lower Lows (LL). Strategy: Sell/Wait.
Sideways/Consolidation: Gathering energy. Strategy: Do nothing.

2.3 Shield & Ceiling Placements (Support & Resistance)
Support: An invisible floor where buyers step in and price bounces up.
Resistance: An invisible ceiling where sellers dump and price gets pushed down.
Breakout: Price pierces resistance with high volume = real move.
Fakeout: Price briefly crosses resistance then fails = trap.
Role Reversal: Once broken, resistance becomes the new support.

2.4 Navigation Tools (Indicators)
Moving Averages (SMA/EMA): Smooth price data to find the trend.
50-day MA (medium-term) and 200-day MA (long-term).
Golden Cross (50 crosses above 200) = bullish signal.
RSI (Relative Strength Index): Momentum oscillator 0–100.
> 70 = Overbought (prepare for a drop). < 30 = Oversold (prepare for a bounce).
Volume: The fuel behind any move. A breakout without volume is a trap.

⚔️ Boss Fight (Unlock Level 3): The Navigator.
Draw Support/Resistance zones on a raw candlestick chart. Identify the trend and decide entry/exit based on RSI data.''',

  3: '''LEVEL 3: ENGINEERING (Reactor Diagnostics)
Check the engine before you buy the ship.

3.1 Hull Integrity (Financial Statements)
Income Statement (P&L): Top Line (Revenue) vs Bottom Line (Net Profit). Watch for shrinking margins.
Balance Sheet: Assets = Liabilities + Shareholder Equity. A snapshot of what the company owns vs owes.
Cash Flow Statement: The ultimate truth. A company can fake profits but cannot fake cash in the bank.
Always check Operating Cash Flow first.

3.2 Efficiency Ratios (Valuation)
P/E Ratio (Price-to-Earnings): How much you pay for ₹1 of earnings. Compare against industry peers.
High P/E = Expensive luxury ship. Low P/E = Bargain junker — or a hidden gem.
P/B Ratio (Price-to-Book): What the company is worth if liquidated tomorrow. P/B < 1 can signal undervaluation.
ROE (Return on Equity): How well management generates returns on shareholder money. > 15% is generally good.
Debt-to-Equity Ratio: D/E > 1 is a warning sign in non-banking sectors.

3.3 Cargo Harvest (Corporate Actions)
Dividends: Cash payouts. Dividend Yield = Annual Dividend / Current Price.
Stock Splits & Bonuses: Cutting the pizza into more slices — increases liquidity.
Buybacks: Company buys its own shares, reducing supply and signaling management confidence. Increases EPS.

3.4 Core Design (Economic Moats)
Competitive Advantages (why the company survives 20 years):
• Brand power (Apple, Coca-Cola)
• Network effects (WhatsApp, LinkedIn)
• High switching costs (Oracle software)
• Cost advantages / natural monopolies

⚔️ Boss Fight (Unlock Level 4): The Auditor.
Compare two rival tech companies' fundamental dashboards. Choose the superior long-term investment by analyzing P/E, Debt ratios, and Free Cash Flow.''',

  4: '''LEVEL 4: HYPERDRIVE (Warp Speed)
Class-S Weaponry. Expert Pilots Only.

4.1 Afterburners (Leverage & Margin)
Margin Trading: Borrowing credits from the broker to control larger positions than your capital allows.
⚠️ DANGER: If the ship moves 1% against you, you can lose 10% instantly.
Margin Call & Liquidation: If your losses eat your original capital, the broker forcibly sells your assets.

4.2 Space Contracts (Futures)
Obligation: A binding contract to buy/sell an asset at a future date at a pre-agreed price.
Lot Sizes & Expiry: Futures are traded in fixed lots and expire on the last Thursday of the month (India).
Mark-to-Market (MTM): Daily settlement of profits and losses — you gain/lose every day, not just at expiry.
Metaphor: You agree to buy a ship next month at today's price. If price rises, you profit. If it falls, you lose.

4.3 Strategic Shields (Options Mechanics)
Call (CE): Right to BUY at strike price. Used when bullish.
Put (PE): Right to SELL at strike price. Used when bearish or to hedge a portfolio.
Option Premiums: The price paid to buy the contract.
Buyer: Limited risk (premium) with unlimited reward.
Seller/Writer: Unlimited risk with limited reward.

4.4 The Space-Time Continuum (The Greeks)
Delta: How much the option price moves for every ₹1 move in the underlying stock.
Theta (Time Decay): Options lose value every day. Time is the enemy of buyers and the friend of sellers.
Vega (Volatility): How implied volatility inflates option prices. High VIX = expensive options.

⚔️ Boss Fight (Unlock Level 5): The Warp Core Test.
Hedge a dropping portfolio by calculating which Put Option strike price to buy, factoring in premium cost and Theta decay.''',

  5: '''LEVEL 5: CRISIS MANAGEMENT (Asteroid Field)
The enemy is not the market. It is You.

5.1 Cosmic Storms (Macroeconomics)
Interest Rates (RBI Repo Rate): The gravity of the financial world.
When rates rise → borrowing expensive → business slows → markets fall.
When rates fall → money cheap → markets rally.
Inflation (CPI): Central banks raise rates to fight rising prices — this hurts markets short-term.
Geopolitics & FIIs: Foreign Institutional Investors moving capital out of emerging markets tanks local indices.
Watch DXY (Dollar Index) strength.

5.2 Space Madness (Trading Psychology)
FOMO: Buying at the top because "everyone else is." Result: you buy the peak.
Panic Selling: Ejecting immediately when you see red. Result: you sell the bottom.
Revenge Trading: Trying to instantly win back losses by increasing position size. The market owes you nothing.
Loss Aversion: The pain of losing ₹1000 is twice as strong as the joy of gaining ₹1000.
This asymmetry causes catastrophically irrational decisions.
Confirmation Bias: Only reading news that agrees with the trade you already took.

5.3 Auto-Eject (Risk & Capital Management)
⚡ The 1% Rule: Never risk more than 1–2% of total trading capital on a single trade.
If you have ₹1,00,000 → max loss per trade = ₹1,000. If wrong, 98% remains.
Stop-Loss (Auto-Eject): Pre-programmed command to sell if price drops to a set level.
Better to lose a finger (small loss) than an arm (blown account).
Risk-to-Reward (R:R): Only take trades where potential profit ≥ 2× potential loss.
R:R of 1:2 means even with a 40% win rate, you are profitable.

⚔️ Boss Fight (Unlock Level 6): The Captain's Trial.
Experience a simulated flash crash. Calculate position size using the 1% rule and set a hard mathematical Stop-Loss.''',
};

// ─── Dialog widget ────────────────────────────────────────────────────────────

class AcademyCodexDialog extends ConsumerStatefulWidget {
  const AcademyCodexDialog({super.key});

  @override
  ConsumerState<AcademyCodexDialog> createState() =>
      _AcademyCodexDialogState();
}

class _AcademyCodexDialogState extends ConsumerState<AcademyCodexDialog>
    with TickerProviderStateMixin {
  int _selectedLevel = 0;
  bool _navCollapsed = false; // collapsible nav for small screens
  final Map<int, String> _loadedContent = {};
  bool _isLoading = true;

  late final AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late final AnimationController _navCtrl;
  late Animation<double> _navAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);

    _navCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _navAnim = CurvedAnimation(parent: _navCtrl, curve: Curves.easeInOut);
    _navCtrl.value = 1.0; // nav starts expanded

    _loadAllContent();
  }

  Future<void> _loadAllContent() async {
    final futures = <Future<void>>[];
    for (final meta in _levels) {
      futures.add(_loadLevel(meta));
    }
    await Future.wait(futures);
    if (mounted) {
      setState(() => _isLoading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _loadLevel(_LevelMeta meta) async {
    try {
      final text = await rootBundle.loadString(meta.assetPath);
      final trimmed = text.trim();
      if (trimmed.isNotEmpty) {
        _loadedContent[meta.level] = trimmed;
        return;
      }
    } catch (_) {}
    // Fall back to built-in content
    _loadedContent[meta.level] =
        _fallbackContent[meta.level] ?? 'Content coming soon.';
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _navCtrl.dispose();
    super.dispose();
  }

  void _selectLevel(int level) {
    _fadeCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _selectedLevel = level);
        _fadeCtrl.forward();
      }
    });
  }

  void _toggleNav() {
    setState(() => _navCollapsed = !_navCollapsed);
    if (_navCollapsed) {
      _navCtrl.reverse();
    } else {
      _navCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userStats = ref.watch(userStatsProvider).valueOrNull;
    final isDevMode = ref.watch(devModeProvider);
    final currentLevel = isDevMode ? 6 : (userStats?.currentLevel ?? 1);
    final size = MediaQuery.of(context).size;
    final meta = _levels[_selectedLevel];
    final isNarrow = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.025,
        vertical: size.height * 0.025,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size.width * 0.95,
          height: size.height * 0.95,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0E14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF00D9FF).withOpacity(0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D9FF).withOpacity(0.12),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(context, isDevMode, isNarrow),
              Expanded(
                child: Stack(
                  children: [
                    // ── Main content ──────────────────────────────────
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.only(
                        left: _navCollapsed || isNarrow ? 0 : 200,
                      ),
                      child: _isLoading
                          ? _buildLoading(meta.accent)
                          : FadeTransition(
                              opacity: _fadeAnim,
                              child: _buildContent(meta, currentLevel),
                            ),
                    ),

                    // ── Nav rail overlay ──────────────────────────────
                    _buildNavOverlay(currentLevel, isNarrow),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      BuildContext context, bool isDevMode, bool isNarrow) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(
          bottom: BorderSide(
              color: const Color(0xFF00D9FF).withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Nav toggle button
          GestureDetector(
            onTap: _toggleNav,
            child: Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(
                _navCollapsed ? Icons.menu : Icons.menu_open,
                color: const Color(0xFF00D9FF),
                size: 18,
              ),
            ),
          ),

          const Icon(Icons.auto_stories_outlined,
              color: Color(0xFF00D9FF), size: 18),
          const SizedBox(width: 8),
          if (!isNarrow)
            Text(
              "CAPTAIN'S LOG  ·  U.G.F. OPERATIONS MANUAL",
              style: GoogleFonts.orbitron(
                color: const Color(0xFF00D9FF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            )
          else
            Text(
              "CAPTAIN'S LOG",
              style: GoogleFonts.orbitron(
                color: const Color(0xFF00D9FF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),

          const Spacer(),

          // Dev mode badge
          if (isDevMode) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                border: Border.all(
                    color: Colors.amber.withOpacity(0.5), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.developer_mode,
                      color: Colors.amber, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'DEV',
                    style: GoogleFonts.shareTechMono(
                        color: Colors.amber, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              border: Border.all(
                  color: Colors.green.withOpacity(0.35), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'ONLINE',
              style: GoogleFonts.shareTechMono(
                  color: Colors.green, fontSize: 10),
            ),
          ),
          const SizedBox(width: 10),

          // Close
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(Icons.close, color: Colors.white38, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nav overlay ───────────────────────────────────────────────────────────

  Widget _buildNavOverlay(int currentLevel, bool isNarrow) {
    return AnimatedBuilder(
      animation: _navCtrl,
      builder: (_, __) {
        final frac = _navCtrl.value; // 0 = collapsed, 1 = expanded
        final navWidth = 200.0;
        final leftOffset = (frac - 1) * navWidth; // slides in from left

        return Positioned(
          top: 0,
          bottom: 0,
          left: leftOffset,
          width: navWidth,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF080B10),
              border: Border(
                right: BorderSide(
                    color: const Color(0xFF00D9FF).withOpacity(0.15),
                    width: 1),
              ),
              boxShadow: isNarrow || _navCollapsed
                  ? [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16)
                    ]
                  : [],
            ),
            child: Column(
              children: [
                // Label
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Row(
                    children: [
                      Text(
                        'MISSION LEVELS',
                        style: GoogleFonts.orbitron(
                          color: Colors.white24,
                          fontSize: 8,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 4),

                // Level items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: _levels
                        .map((l) => _buildNavItem(l, currentLevel))
                        .toList(),
                  ),
                ),

                // Footer
                Container(
                    height: 1, color: Colors.white.withOpacity(0.05)),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'U.G.F. CLEARANCE: ALL RANKS',
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white24,
                      fontSize: 8,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(_LevelMeta meta, int currentLevel) {
    final isSelected = _selectedLevel == meta.level;
    final isLocked = meta.level > currentLevel;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              _selectLevel(meta.level);
              // On narrow screens collapse nav after selecting
              final size = MediaQuery.of(context).size;
              if (size.width < 600 && !_navCollapsed) {
                _toggleNav();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color:
              isSelected ? meta.accent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: isSelected ? meta.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.white.withOpacity(0.03)
                    : meta.accent
                        .withOpacity(isSelected ? 0.2 : 0.07),
                border: Border.all(
                  color: isLocked
                      ? Colors.white12
                      : meta.accent
                          .withOpacity(isSelected ? 0.6 : 0.2),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isLocked
                  ? const Icon(Icons.lock,
                      color: Colors.white24, size: 11)
                  : Center(
                      child: Text(
                        '${meta.level}',
                        style: GoogleFonts.orbitron(
                          color: meta.accent
                              .withOpacity(isSelected ? 1.0 : 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: GoogleFonts.shareTechMono(
                      color: isLocked
                          ? Colors.white24
                          : isSelected
                              ? meta.accent
                              : Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isLocked ? 'LOCKED' : meta.subtitle,
                    style: GoogleFonts.shareTechMono(
                      color: isLocked ? Colors.white12 : Colors.white24,
                      fontSize: 8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading state ─────────────────────────────────────────────────────────

  Widget _buildLoading(Color accent) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: accent,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'LOADING TRANSMISSION...',
            style: GoogleFonts.orbitron(
                color: accent.withOpacity(0.6),
                fontSize: 11,
                letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  // ── Right content area ────────────────────────────────────────────────────

  Widget _buildContent(_LevelMeta meta, int currentLevel) {
    final isLocked = meta.level > currentLevel;
    final rawText = _loadedContent[meta.level] ?? 'Content loading...';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level chip row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: meta.accent.withOpacity(0.1),
                        border: Border.all(
                            color: meta.accent.withOpacity(0.4)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(meta.icon, color: meta.accent, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            'LEVEL ${meta.level}',
                            style: GoogleFonts.orbitron(
                              color: meta.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      meta.subtitle.toUpperCase(),
                      style: GoogleFonts.shareTechMono(
                        color: Colors.white30,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  meta.title,
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),

                // Accent divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      meta.accent.withOpacity(0.5),
                      Colors.transparent,
                    ]),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),

        if (isLocked)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      color: Colors.white24, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'CLEARANCE REQUIRED',
                    style: GoogleFonts.orbitron(
                      color: Colors.white24,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete previous level to unlock',
                    style: GoogleFonts.shareTechMono(
                        color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                _parseAndBuildContent(rawText, meta.accent),
              ),
            ),
          ),
      ],
    );
  }

  // ── Text parser — renders the plain text with smart formatting ────────────

  List<Widget> _parseAndBuildContent(String rawText, Color accent) {
    final lines = rawText.split('\n');
    final widgets = <Widget>[];
    final buffer = StringBuffer();

    void flushBuffer() {
      final t = buffer.toString().trim();
      if (t.isNotEmpty) {
        widgets.add(_buildBodyCard(t, accent));
      }
      buffer.clear();
    }

    for (final raw in lines) {
      final line = raw.trim();

      // Empty line = paragraph break
      if (line.isEmpty) {
        flushBuffer();
        continue;
      }

      // Boss fight / special callout block
      if (line.startsWith('⚔️') || line.startsWith('🎓')) {
        flushBuffer();
        widgets.add(_buildBossCard(line, accent));
        continue;
      }

      // Section headings (lines like "1.1 Foo (Bar)" or "LEVEL 0: …")
      final headingMatch = RegExp(
              r'^(?:LEVEL\s+\d+.*|[\d]+\.\d+[\s\S]+|#{1,3}\s.+)$')
          .hasMatch(line);
      if (headingMatch && buffer.toString().trim().isEmpty) {
        flushBuffer();
        widgets.add(_buildSectionHeading(line, accent));
        continue;
      }

      buffer.writeln(line);
    }
    flushBuffer();
    return widgets;
  }

  Widget _buildSectionHeading(String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text.replaceAll(RegExp(r'^#{1,3}\s*'), ''),
        style: GoogleFonts.orbitron(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildBodyCard(String text, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        text,
        style: GoogleFonts.shareTechMono(
          color: Colors.white60,
          fontSize: 12,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildBossCard(String text, Color accent) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.shareTechMono(
                color: accent.withOpacity(0.9),
                fontSize: 12,
                height: 1.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
