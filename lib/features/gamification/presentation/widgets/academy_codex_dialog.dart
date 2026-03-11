import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../user_stats_provider.dart';

// ─── Level content model ──────────────────────────────────────────────────────

class _CodexSection {
  final String heading;
  final List<_CodexEntry> entries;
  const _CodexSection(this.heading, this.entries);
}

class _CodexEntry {
  final String? subheading;
  final String body;
  const _CodexEntry(this.body, {this.subheading});
}

class _LevelCodex {
  final int level;
  final String title;
  final String subtitle;
  final String flavor; // italic opening line
  final Color accent;
  final IconData icon;
  final List<_CodexSection> sections;
  const _LevelCodex({
    required this.level,
    required this.title,
    required this.subtitle,
    required this.flavor,
    required this.accent,
    required this.icon,
    required this.sections,
  });
}

// ─── All level data ───────────────────────────────────────────────────────────

const _codexData = <_LevelCodex>[
  // ── LEVEL 0 ──────────────────────────────────────────────────────────────
  _LevelCodex(
    level: 0,
    title: 'THE ACADEMY',
    subtitle: 'Life Support',
    flavor: 'Before you can fly the ship, you must power the ship.',
    accent: Color(0xFF4FC3F7),
    icon: Icons.school_outlined,
    sections: [
      _CodexSection('0.1 · Power Generation (Income Dynamics)', [
        _CodexEntry(
          'Active Income: Trading hours for credits (salary, freelancing). The baseline engine.',
          subheading: 'Active Core',
        ),
        _CodexEntry(
          'Passive Income: Credits generated without active input (rental yield, royalties, dividends).',
          subheading: 'Automated Arrays',
        ),
        _CodexEntry(
          'Portfolio Income: Capital gains and dividends from paper assets.',
          subheading: 'Portfolio Arrays',
        ),
        _CodexEntry(
          'Financial independence is achieved when Passive + Portfolio Income > Living Expenses.',
          subheading: '⚡ Mission Directive',
        ),
      ]),
      _CodexSection('0.2 · Hull Breaches (Budgeting & Leakage)', [
        _CodexEntry(
          '50% Needs (Rent, Groceries) · 30% Wants (Dining, Entertainment) · 20% Savings/Investing.',
          subheading: 'The 50/30/20 Rule',
        ),
        _CodexEntry(
          'The invisible cosmic radiation that slowly erodes the purchasing power of idle cash.',
          subheading: 'Inflation',
        ),
        _CodexEntry(
          'Type A — Life Support (Needs): Oxygen (Rent), Rations (Food). Cannot cut, only optimize.\nType B — The Void (Wants): Energy escaping into nothingness (Netflix, dining out). If Void expenses > 30% of income, your ship stalls.',
          subheading: 'Breach Types',
        ),
      ]),
      _CodexSection('0.3 · The Flow Gauge (Balance Sheets & Cash Flow)', [
        _CodexEntry(
          'An asset puts money in your pocket; a liability takes it out. A car bought on a loan is a liability, not an asset.',
          subheading: 'Assets vs Liabilities',
        ),
        _CodexEntry(
          'Total Assets minus Total Liabilities.',
          subheading: 'Net Worth Formula',
        ),
        _CodexEntry(
          '🟢 Positive Flow: Charging batteries (wealth creation).\n🔴 Negative Flow: Draining reserves (debt spiral).\n⚪ Neutral Flow: Stagnant — one asteroid hit will destroy you.',
          subheading: 'Cash Flow States',
        ),
        _CodexEntry(
          'Understanding the transition: Employee → Self-Employed → Business Owner → Investor.',
          subheading: 'The Cash Flow Quadrant',
        ),
      ]),
      _CodexSection('0.4 · Emergency Shields (The Safety Net)', [
        _CodexEntry(
          'Build a liquid fund equal to 6 months of absolute basic living expenses before investing anything.',
          subheading: 'The 6-Month Rule',
        ),
        _CodexEntry(
          'Keep this fund in High-Yield Savings Accounts or Liquid Mutual Funds. NEVER in volatile equities.',
          subheading: '⚠️ Placement Protocol',
        ),
      ]),
      _CodexSection('0.5 · Gravitational Drag (Debt Management)', [
        _CodexEntry(
          'Good Debt: buys income-producing assets (business loan).\nBad Debt: finances depreciating consumer goods (credit card debt for clothes).',
          subheading: 'Good vs Bad Debt',
        ),
        _CodexEntry(
          'Your CIBIL score is your financial reputation in the galaxy. Guard it.',
          subheading: 'Credit Scores',
        ),
      ]),
    ],
  ),

  // ── LEVEL 1 ──────────────────────────────────────────────────────────────
  _LevelCodex(
    level: 1,
    title: 'GROUND SCHOOL',
    subtitle: 'The Shipyard',
    flavor: 'Welcome to the Shipyard. This is where fleets are built.',
    accent: Color(0xFF81C784),
    icon: Icons.construction_outlined,
    sections: [
      _CodexSection('1.1 · The Shipyard (Market Ecosystem)', [
        _CodexEntry(
          'A stock represents fractional ownership of a real business. You are literally buying a piece of the company.',
          subheading: 'What is a Stock?',
        ),
        _CodexEntry(
          'SEBI — the "Federation" that prevents fraud and protects retail cadets.',
          subheading: 'The Regulators',
        ),
        _CodexEntry(
          'NSE/BSE: where trades happen. NSDL/CDSL: where digital shares are stored in your Demat account.',
          subheading: 'Exchanges & Depositories',
        ),
        _CodexEntry(
          'The Stock Market is a massive automated Starship Dealership. Buyers and sellers trade ownership of ships. Your broker is the interface console to the Shipyard.',
          subheading: 'The Big Picture',
        ),
      ]),
      _CodexSection('1.2 · The Launch (Primary Markets / IPOs)', [
        _CodexEntry(
          'Why companies go public: to raise capital to build more factories or pay off debt. A new ship leaving the factory for the first time.',
          subheading: 'IPO Purpose',
        ),
        _CodexEntry(
          'Large-Cap (Blue-chip, low risk, slow growth) · Mid-Cap · Small-Cap (High risk, high potential reward).\n\nFormula: Share Price × Total Outstanding Shares',
          subheading: 'Market Capitalization',
        ),
        _CodexEntry(
          'Risk: High. Engines haven\'t been tested in deep space. Reward: Early buyers become rich Captains if the launch succeeds.',
          subheading: '⚡ Risk/Reward',
        ),
      ]),
      _CodexSection('1.3 · Orbital Mechanics (Secondary Markets)', [
        _CodexEntry(
          'Buyers (Bidders) and Sellers (Askers) constantly competing. The difference between highest bid and lowest ask is the Bid-Ask Spread.',
          subheading: 'The Order Book',
        ),
        _CodexEntry(
          'Market Orders: buy immediately at any price — fast but imprecise.\nLimit Orders: buy only at a specific price — precise but may not execute.',
          subheading: 'Order Types',
        ),
        _CodexEntry(
          'NIFTY 50 / SENSEX tracks the average speed of the top ships.\nFleet Green = safe sector. Fleet Red = expect turbulence.',
          subheading: 'The Index (The Fleet)',
        ),
      ]),
      _CodexSection('1.4 · Convoy Protocols (Mutual Funds & ETFs)', [
        _CodexEntry(
          'Never put all your reactor cores in one basket.',
          subheading: 'Diversification',
        ),
        _CodexEntry(
          'Active Funds: managers trying to beat the market (high fees).\nPassive/Index Funds: mirror the market (low fees). Historically, passive beats active over 20 years.',
          subheading: 'Active vs Passive',
        ),
        _CodexEntry(
          'The fee the AMC charges annually. A 1% difference can cost millions over 30 years of compounding.',
          subheading: 'Expense Ratios (TER)',
        ),
        _CodexEntry(
          'Investing a fixed amount monthly to automatically average out your purchase price across market cycles.',
          subheading: 'SIP (Rupee-Cost Averaging)',
        ),
      ]),
    ],
  ),

  // ── LEVEL 2 ──────────────────────────────────────────────────────────────
  _LevelCodex(
    level: 2,
    title: 'NAVIGATION',
    subtitle: 'Star Mapping',
    flavor: 'You cannot fly blind. You need maps. We call them Charts.',
    accent: Color(0xFFFFD54F),
    icon: Icons.explore_outlined,
    sections: [
      _CodexSection('2.1 · Star Charts (Candlestick Anatomy)', [
        _CodexEntry(
          'Each candle tells the story of a battle between Buyers (Bulls) and Sellers (Bears) in a specific time period.',
          subheading: 'The War Story',
        ),
        _CodexEntry(
          'OHLC: Open · High · Low · Close.\nGreen Candle: Buyers won (price went UP).\nRed Candle: Sellers won (price went DOWN).\nWicks/Tails: How far price tried to go but failed.',
          subheading: 'Anatomy',
        ),
        _CodexEntry(
          'Micro: 1m, 5m (day trading) vs Macro: 1D, 1W (long-term investing).\nBullish Engulfing, Hammer, Doji (indecision) — key patterns.',
          subheading: 'Timeframes & Patterns',
        ),
      ]),
      _CodexSection('2.2 · Gravitational Pull (Trend Analysis)', [
        _CodexEntry(
          'Uptrend: Higher Highs (HH) + Higher Lows (HL). Strategy: Buy.\nDowntrend: Lower Highs (LH) + Lower Lows (LL). Strategy: Sell/Wait.\nSideways/Consolidation: Gathering energy. Strategy: Do nothing.',
          subheading: 'The Three States',
        ),
        _CodexEntry(
          'The market moves in trends (Dow Theory). Trading with the trend massively increases probability of success.',
          subheading: '⚡ Core Rule',
        ),
      ]),
      _CodexSection('2.3 · Shield & Ceiling Placements (Support & Resistance)', [
        _CodexEntry(
          'Support: An invisible floor where buyers step in and price bounces up.\nResistance: An invisible ceiling where sellers dump and price gets pushed back down.',
          subheading: 'Definitions',
        ),
        _CodexEntry(
          'Breakout: Price pierces resistance with high volume = real move.\nFakeout: Price briefly passes resistance then fails and falls back = trap.',
          subheading: 'Breakouts vs Fakeouts',
        ),
        _CodexEntry(
          'When price breaks through resistance, that level often becomes the new support. The ceiling becomes the floor.',
          subheading: 'Role Reversal',
        ),
      ]),
      _CodexSection('2.4 · Navigation Tools (Indicators)', [
        _CodexEntry(
          'Smooth out price data to find the underlying trend.\n50-day MA (medium-term) and 200-day MA (long-term).\nGolden Cross (50 crosses above 200) = bullish signal.',
          subheading: 'Moving Averages (SMA/EMA)',
        ),
        _CodexEntry(
          'Momentum oscillator (0–100).\n> 70: Overbought — prepare for a drop.\n< 30: Oversold — prepare for a bounce.',
          subheading: 'RSI (Relative Strength Index)',
        ),
        _CodexEntry(
          'The fuel behind any price move. A breakout without volume is a trap. Volume confirms price action.',
          subheading: 'Volume',
        ),
      ]),
    ],
  ),

  // ── LEVEL 3 ──────────────────────────────────────────────────────────────
  _LevelCodex(
    level: 3,
    title: 'ENGINEERING',
    subtitle: 'Reactor Diagnostics',
    flavor: 'Check the engine before you buy the ship.',
    accent: Color(0xFFFF8A65),
    icon: Icons.engineering_outlined,
    sections: [
      _CodexSection('3.1 · Hull Integrity (Financial Statements)', [
        _CodexEntry(
          'Top Line (Revenue/Sales) vs Bottom Line (Net Profit). Watch for shrinking margins over multiple quarters.',
          subheading: 'Income Statement (P&L)',
        ),
        _CodexEntry(
          'Assets = Liabilities + Shareholder Equity. A snapshot of what the company owns vs owes.',
          subheading: 'Balance Sheet',
        ),
        _CodexEntry(
          'The ultimate truth. A company can fake profits on paper but it cannot fake cash in the bank. Always check Operating Cash Flow.',
          subheading: 'Cash Flow Statement ⚡',
        ),
      ]),
      _CodexSection('3.2 · Efficiency Ratios (Valuation)', [
        _CodexEntry(
          'How much you pay for ₹1 of earnings. Compare against industry peers, not in isolation.\nHigh P/E: Expensive luxury ship. Low P/E: Bargain junker — or a hidden gem.',
          subheading: 'P/E Ratio',
        ),
        _CodexEntry(
          'What the company is worth if it was liquidated tomorrow. P/B < 1 can signal undervaluation.',
          subheading: 'P/B Ratio (Price-to-Book)',
        ),
        _CodexEntry(
          'How well management generates returns on shareholder money. >15% is generally good.',
          subheading: 'ROE (Return on Equity)',
        ),
        _CodexEntry(
          'Is the company heavily leveraged? D/E > 1 is a warning sign in non-banking sectors.',
          subheading: 'Debt-to-Equity Ratio',
        ),
      ]),
      _CodexSection('3.3 · Cargo Harvest (Corporate Actions)', [
        _CodexEntry(
          'Cash payouts to shareholders. Dividend Yield = Annual Dividend / Current Price. Prefer consistent, growing dividends.',
          subheading: 'Dividends',
        ),
        _CodexEntry(
          'Cutting the pizza into more slices without changing the size — increases liquidity and accessibility.',
          subheading: 'Stock Splits & Bonuses',
        ),
        _CodexEntry(
          'When a company buys its own shares, reducing supply and signaling management confidence. Increases EPS.',
          subheading: 'Buybacks',
        ),
      ]),
      _CodexSection('3.4 · Core Design (Economic Moats)', [
        _CodexEntry(
          'Why the company will survive for 20 years:\n• Brand power (Apple, Coca-Cola)\n• Network effects (WhatsApp, LinkedIn)\n• High switching costs (Oracle software)\n• Cost advantages / natural monopolies',
          subheading: 'Competitive Advantages',
        ),
      ]),
    ],
  ),

  // ── LEVEL 4 ──────────────────────────────────────────────────────────────
  _LevelCodex(
    level: 4,
    title: 'HYPERDRIVE',
    subtitle: 'Warp Speed',
    flavor: 'Class-S Weaponry. Expert Pilots Only.',
    accent: Color(0xFFE040FB),
    icon: Icons.rocket_launch_outlined,
    sections: [
      _CodexSection('4.1 · Afterburners (Leverage & Margin)', [
        _CodexEntry(
          'Borrowing credits from the broker to take larger positions than your capital allows.',
          subheading: 'Margin Trading',
        ),
        _CodexEntry(
          '⚠️ Danger: If the ship moves 1% against you, you can lose 10% instantly.\nIf your losses eat your original capital, the broker forcibly liquidates your position.',
          subheading: 'Margin Call & Liquidation',
        ),
      ]),
      _CodexSection('4.2 · Space Contracts (Futures)', [
        _CodexEntry(
          'A binding obligation to buy/sell an asset at a future date at a pre-agreed price. Not a choice — a contract.',
          subheading: 'What are Futures?',
        ),
        _CodexEntry(
          'Traded in fixed lot sizes. Expire on the last Thursday of the month (India).',
          subheading: 'Lot Sizes & Expiry',
        ),
        _CodexEntry(
          'Daily settlement of profits and losses. You gain/lose money every day, not just at expiry.',
          subheading: 'Mark-to-Market (MTM)',
        ),
        _CodexEntry(
          'You agree to buy a ship next month at today\'s price. If price rises, you profit. If it falls, you lose.',
          subheading: 'The Metaphor',
        ),
      ]),
      _CodexSection('4.3 · Strategic Shields (Options Mechanics)', [
        _CodexEntry(
          'Call (CE): Right to BUY at strike price. Used when bullish.\nPut (PE): Right to SELL at strike price. Used when bearish or to hedge/insure a portfolio.',
          subheading: 'Call vs Put Options',
        ),
        _CodexEntry(
          'The price paid to buy an option contract.\nBuyer: Limited risk (premium) with unlimited reward potential.\nSeller/Writer: Unlimited risk with limited reward.',
          subheading: 'Option Premiums',
        ),
      ]),
      _CodexSection('4.4 · The Space-Time Continuum (The Greeks)', [
        _CodexEntry(
          'How much the option price moves for every ₹1 move in the underlying stock.',
          subheading: 'Delta',
        ),
        _CodexEntry(
          'Options lose value every day as expiry approaches. Time is the enemy of buyers and the friend of sellers.',
          subheading: 'Theta (Time Decay)',
        ),
        _CodexEntry(
          'How implied volatility inflates option prices. High VIX = expensive options.',
          subheading: 'Vega (Volatility)',
        ),
      ]),
    ],
  ),

  // ── LEVEL 5 ──────────────────────────────────────────────────────────────
  _LevelCodex(
    level: 5,
    title: 'CRISIS MANAGEMENT',
    subtitle: 'Asteroid Field',
    flavor: 'The enemy is not the market. It is You.',
    accent: Color(0xFFEF5350),
    icon: Icons.warning_amber_outlined,
    sections: [
      _CodexSection('5.1 · Cosmic Storms (Macroeconomics)', [
        _CodexEntry(
          'RBI Repo Rate: the gravity of the financial world.\nWhen rates rise → borrowing is expensive → business slows → markets fall.\nWhen rates fall → money is cheap → markets rally.',
          subheading: 'Interest Rates',
        ),
        _CodexEntry(
          'CPI measures rising consumer prices. Central banks raise rates to fight inflation — this hurts markets short-term.',
          subheading: 'Inflation (CPI)',
        ),
        _CodexEntry(
          'FIIs moving capital out of emerging markets (like India) tanks local indices. Watch DXY (Dollar Index) strength.',
          subheading: 'Geopolitics & FIIs',
        ),
      ]),
      _CodexSection('5.2 · Space Madness (Trading Psychology)', [
        _CodexEntry(
          'FOMO: Buying at the top because "everyone else is." Result: you buy the peak.\nPanic Selling: Ejecting immediately when you see red. Result: you sell the bottom.',
          subheading: 'Fear & Greed',
        ),
        _CodexEntry(
          'Trying to instantly win back losses by increasing position size. Result: larger losses. The market owes you nothing.',
          subheading: 'Revenge Trading',
        ),
        _CodexEntry(
          'The psychological pain of losing ₹1000 is twice as strong as the joy of making ₹1000. This asymmetry causes irrational decisions.',
          subheading: 'Loss Aversion',
        ),
        _CodexEntry(
          'Only reading news that agrees with the trade you already took. Forces you to ignore warning signs.',
          subheading: 'Confirmation Bias',
        ),
      ]),
      _CodexSection('5.3 · Auto-Eject (Risk & Capital Management)', [
        _CodexEntry(
          '⚡ The 1% Rule: Never risk more than 1–2% of total trading capital on a single trade.\nIf you have ₹1,00,000 → max loss per trade = ₹1,000. If wrong, 98% remains to fight another day.',
          subheading: 'Position Sizing',
        ),
        _CodexEntry(
          'Pre-programmed command to sell if price drops to a set level.\nBetter to lose a finger (small loss) than an arm (blown account).',
          subheading: 'Stop-Loss (Auto-Eject)',
        ),
        _CodexEntry(
          'Only take trades where potential profit ≥ 2× potential loss.\nR:R of 1:2 means even with a 40% win rate, you are profitable.',
          subheading: 'Risk-to-Reward Ratio',
        ),
      ]),
    ],
  ),

  // ── LEVEL 6 ──────────────────────────────────────────────────────────────
  _LevelCodex(
    level: 6,
    title: 'THE OUTER RIM',
    subtitle: 'Uncharted Space',
    flavor: 'Navigate the unregulated, high-volatility world of digital assets.',
    accent: Color(0xFF7E57C2),
    icon: Icons.language_outlined,
    sections: [
      _CodexSection('6.1 · Distributed Logs (Blockchain Basics)', [
        _CodexEntry(
          'A ledger maintained by thousands of nodes, not a central bank. No single point of failure or control.',
          subheading: 'Decentralization',
        ),
        _CodexEntry(
          'Proof of Work (Bitcoin mining — high energy) vs Proof of Stake (Ethereum validators — capital efficiency).',
          subheading: 'Consensus Mechanisms',
        ),
        _CodexEntry(
          'Self-executing code on the blockchain. Enables DeFi, NFTs, and DAOs without intermediaries.',
          subheading: 'Smart Contracts',
        ),
      ]),
      _CodexSection('6.2 · The Vaults (Custody & Security)', [
        _CodexEntry(
          'Public Key: your bank account number (share freely).\nPrivate Key: your PIN code (NEVER share — whoever has it owns your funds).',
          subheading: 'Keys',
        ),
        _CodexEntry(
          'Hot Wallets: software connected to the internet (Metamask) — convenient but hackable.\nCold Wallets: hardware drives offline (Ledger) — safest for large amounts.',
          subheading: 'Hot vs Cold Wallets',
        ),
        _CodexEntry(
          '⚠️ GOLDEN RULE: "Not your keys, not your coins." Leaving crypto on a centralized exchange (FTX, Binance) means you don\'t actually own it.',
          subheading: 'Self-Custody',
        ),
      ]),
      _CodexSection('6.3 · Rogue Tokens (Scam Identification)', [
        _CodexEntry(
          'Developers drain the liquidity pool of a new token, leaving buyers holding worthless coins overnight.',
          subheading: 'Rug Pulls',
        ),
        _CodexEntry(
          'Artificial hype by influencers who already hold large bags. They pump, retail buys in, they dump.',
          subheading: 'Pump & Dumps',
        ),
        _CodexEntry(
          'Check: max supply, founder allocation %, token utility, lock-up periods, and audit reports.',
          subheading: 'Tokenomics Checklist',
        ),
      ]),
      _CodexSection('6.4 · Imperial Tax (Indian Taxation Laws)', [
        _CodexEntry(
          'STCG (< 1 year): 20% tax.\nLTCG (> 1 year): 12.5% tax, with ₹1.25L annual exemption.\nOffset LTCG losses against LTCG gains.',
          subheading: 'Equity Taxation',
        ),
        _CodexEntry(
          'Flat 30% tax on ALL crypto profits regardless of holding period.\nNo offsetting of losses. Plus 1% TDS deducted on every transaction.',
          subheading: 'Crypto Taxation ⚠️',
        ),
        _CodexEntry(
          'Sell losing stocks before financial year end to offset taxes on winning positions. Legal and effective.',
          subheading: 'Tax-Loss Harvesting',
        ),
      ]),
    ],
  ),
];

// ─── Dialog widget ────────────────────────────────────────────────────────────

class AcademyCodexDialog extends ConsumerStatefulWidget {
  const AcademyCodexDialog({super.key});

  @override
  ConsumerState<AcademyCodexDialog> createState() =>
      _AcademyCodexDialogState();
}

class _AcademyCodexDialogState extends ConsumerState<AcademyCodexDialog>
    with SingleTickerProviderStateMixin {
  int _selectedLevel = 0;
  late final AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectLevel(int level) {
    _fadeCtrl.reverse().then((_) {
      setState(() => _selectedLevel = level);
      _fadeCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userStats = ref.watch(userStatsProvider).valueOrNull;
    final isDevMode = ref.watch(devModeProvider);
    // In dev mode unlock all levels; otherwise use the user's actual progress
    final currentLevel = isDevMode ? 6 : (userStats?.currentLevel ?? 1);

    final size = MediaQuery.of(context).size;
    final codex = _codexData[_selectedLevel];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width * 0.025,
        vertical: size.height * 0.025,
      ),
      child: Container(
        width: size.width * 0.95,
        height: size.height * 0.95,
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E14),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00D9FF).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00D9FF).withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Header bar ──────────────────────────────────────────────
              _buildHeader(context),

              // ── Body ────────────────────────────────────────────────────
              Expanded(
                child: Row(
                  children: [
                    // ── Left nav rail ──────────────────────────────────
                    _buildNavRail(currentLevel),

                    // ── Vertical divider ───────────────────────────────
                    Container(
                      width: 1,
                      color: const Color(0xFF00D9FF).withOpacity(0.15),
                    ),

                    // ── Right content area ─────────────────────────────
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildContent(codex),
                      ),
                    ),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        border: Border(
          bottom: BorderSide(
              color: const Color(0xFF00D9FF).withOpacity(0.25), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_stories_outlined,
              color: Color(0xFF00D9FF), size: 20),
          const SizedBox(width: 12),
          Text(
            "CAPTAIN'S LOG  ·  U.G.F. GALACTIC OPERATIONS MANUAL",
            style: GoogleFonts.orbitron(
              color: const Color(0xFF00D9FF),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Dev mode badge — shown when devModeProvider is active
          Consumer(
            builder: (_, ref, __) {
              final dev = ref.watch(devModeProvider);
              if (!dev) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.developer_mode, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text('DEV MODE — ALL UNLOCKED',
                        style: GoogleFonts.shareTechMono(
                            color: Colors.amber, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
              );
            },
          ),
          // Status indicator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border:
                  Border.all(color: Colors.green.withOpacity(0.4), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'STATUS: ONLINE',
              style: GoogleFonts.shareTechMono(
                color: Colors.green,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: Colors.white12, width: 1),
              ),
              child: const Icon(Icons.close,
                  color: Colors.white54, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Left Nav Rail ─────────────────────────────────────────────────────────

  Widget _buildNavRail(int currentLevel) {
    return Container(
      width: 200,
      color: const Color(0xFF080B10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'MISSION LEVELS',
              style: GoogleFonts.orbitron(
                color: Colors.white24,
                fontSize: 9,
                letterSpacing: 2,
              ),
            ),
          ),
          Container(height: 1, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 4),

          // Level list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: _codexData
                  .map((l) => _buildNavItem(l, currentLevel))
                  .toList(),
            ),
          ),

          // Footer
          Container(height: 1, color: Colors.white.withOpacity(0.05)),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'U.G.F. CLEARANCE: ALL RANKS',
              style: GoogleFonts.shareTechMono(
                color: Colors.white24,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(_LevelCodex codex, int currentLevel) {
    final isSelected = _selectedLevel == codex.level;
    final isLocked = codex.level > currentLevel;

    return GestureDetector(
      onTap: isLocked ? null : () => _selectLevel(codex.level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? codex.accent.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: isSelected ? codex.accent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Level badge
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.white.withOpacity(0.04)
                    : codex.accent.withOpacity(isSelected ? 0.2 : 0.08),
                border: Border.all(
                  color: isLocked
                      ? Colors.white12
                      : codex.accent.withOpacity(isSelected ? 0.6 : 0.25),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isLocked
                  ? const Icon(Icons.lock,
                      color: Colors.white24, size: 12)
                  : Center(
                      child: Text(
                        '${codex.level}',
                        style: GoogleFonts.orbitron(
                          color: codex.accent
                              .withOpacity(isSelected ? 1.0 : 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    codex.title,
                    style: GoogleFonts.shareTechMono(
                      color: isLocked
                          ? Colors.white24
                          : isSelected
                              ? codex.accent
                              : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLocked ? 'LOCKED' : codex.subtitle,
                    style: GoogleFonts.shareTechMono(
                      color: isLocked
                          ? Colors.white12
                          : Colors.white24,
                      fontSize: 9,
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

  // ── Right Content Area ────────────────────────────────────────────────────

  Widget _buildContent(_LevelCodex codex) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level header
          _buildLevelHeader(codex),
          const SizedBox(height: 28),

          // Sections
          ...codex.sections.map((s) => _buildSection(s, codex.accent)),
        ],
      ),
    );
  }

  Widget _buildLevelHeader(_LevelCodex codex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level chip
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: codex.accent.withOpacity(0.12),
                border: Border.all(
                    color: codex.accent.withOpacity(0.4), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(codex.icon, color: codex.accent, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'LEVEL ${codex.level}',
                    style: GoogleFonts.orbitron(
                      color: codex.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                codex.subtitle.toUpperCase(),
                style: GoogleFonts.shareTechMono(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          codex.title,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),

        // Flavor text
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: codex.accent.withOpacity(0.05),
            border: Border(
              left: BorderSide(color: codex.accent, width: 3),
            ),
          ),
          child: Text(
            '"${codex.flavor}"',
            style: GoogleFonts.shareTechMono(
              color: codex.accent.withOpacity(0.85),
              fontSize: 13,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
        ),

        const SizedBox(height: 16),
        // Top divider
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              codex.accent.withOpacity(0.4),
              Colors.transparent,
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(_CodexSection section, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section heading
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              section.heading,
              style: GoogleFonts.orbitron(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          // Entries
          ...section.entries.map((e) => _buildEntry(e, accent)),
        ],
      ),
    );
  }

  Widget _buildEntry(_CodexEntry entry, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.subheading != null) ...[
            Text(
              entry.subheading!,
              style: GoogleFonts.shareTechMono(
                color: accent.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            entry.body,
            style: GoogleFonts.shareTechMono(
              color: Colors.white60,
              fontSize: 12,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
