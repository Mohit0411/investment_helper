import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Track { stocks, fno }

enum LearnTool { payoff, leverage, timeDecay }

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String why;
  const QuizQuestion(this.question, this.options, this.answer, this.why);
}

class Lesson {
  final String id;
  final Track track;
  final String title;
  final String blurb;
  final LearnTool? tool;
  final List<QuizQuestion> quiz;
  const Lesson(this.id, this.track, this.title, this.blurb, this.quiz, {this.tool});

  String get asset => 'assets/lessons/$id.md';
}

const lessons = [
  Lesson('stocks_how_it_works', Track.stocks, 'How the stock market works',
      'Shares, exchanges, brokers, demat and placing an order', [
    QuizQuestion('Where are your shares actually held?', ['With your broker', 'In your demat account at CDSL/NSDL', 'At the company'], 1,
        'Shares sit in your demat account with a depository. The broker only passes on your orders.'),
    QuizQuestion('You buy on Monday. When do the shares reach your demat?', ['Same day', 'Tuesday (T+1)', 'Thursday (T+3)'], 1,
        'India settles equity trades on T+1: one trading day after the trade.'),
    QuizQuestion('Which order guarantees the price but not the fill?', ['Market order', 'Limit order', 'Stop-loss market'], 1,
        'A limit order only executes at your price or better, so it may not fill at all.'),
  ]),
  Lesson('stocks_reading_a_stock', Track.stocks, 'Reading a stock page', 'P/E, EPS, ROE, debt and what they tell you', [
    QuizQuestion('A P/E of 40 means…', ['The stock fell 40%', 'You pay ₹40 for every ₹1 of yearly profit', 'It pays a 40% dividend'], 1,
        'P/E = price ÷ earnings per share.'),
    QuizQuestion('Which usually signals a well-run business?', ['ROE consistently above 15%', 'Debt-to-equity of 3', 'Falling EPS'], 0,
        'High, steady ROE means the company earns well on shareholders\' money.'),
  ]),
  Lesson('stocks_index_vs_picking', Track.stocks, 'Index funds vs picking stocks', 'Why most investors end up with an index fund', [
    QuizQuestion('What does a Nifty 50 index fund do?', ['Picks the best 50 stocks each month', 'Holds the 50 Nifty companies in index weights', 'Trades F&O on Nifty'], 1,
        'It simply copies the index, so costs are low and you get the market return.'),
    QuizQuestion('A sensible stock-picking slice for a beginner is…', ['100% of savings', '10–20% of the portfolio, rest in funds', 'Borrowed money'], 1,
        'Keep the core in diversified funds; learn with a small satellite.'),
  ]),
  Lesson('stocks_taxes', Track.stocks, 'Tax on equity investments', 'STCG, LTCG, dividends and harvesting', [
    QuizQuestion('Shares held for 8 months then sold at a profit are taxed as…', ['LTCG', 'STCG', 'Tax-free'], 1,
        'Listed equity held 12 months or less is short-term.'),
    QuizQuestion('Dividends you receive are…', ['Tax-free', 'Added to your income and taxed at slab rate', 'Taxed at 10% flat'], 1,
        'Dividends are taxed in your hands at your slab rate.'),
  ]),
  Lesson('fno_futures', Track.fno, 'Derivatives and futures', 'Lots, margin, mark-to-market and leverage', [
    QuizQuestion('With 5x leverage, the market moves 4% against you. Your margin…', ['Drops 4%', 'Drops 20%', 'Is safe until expiry'], 1,
        'Leverage multiplies the move: 4% × 5 = 20% of your margin.'),
    QuizQuestion('Mark-to-market means…', ['Profit/loss is settled daily', 'You pay only at expiry', 'The exchange sets your price'], 0,
        'Futures P&L is credited or debited every day.'),
  ], tool: LearnTool.leverage),
  Lesson('fno_options_basics', Track.fno, 'Options: calls and puts', 'Strike, premium, ITM/ATM/OTM', [
    QuizQuestion('You buy a call. The most you can lose is…', ['Unlimited', 'The premium paid', 'The strike price'], 1,
        'An option buyer\'s loss is capped at the premium.'),
    QuizQuestion('Nifty at 24,000. A 24,500 call is…', ['In the money', 'At the money', 'Out of the money'], 2,
        'A call is OTM when the strike is above the current price.'),
  ], tool: LearnTool.payoff),
  Lesson('fno_greeks', Track.fno, 'The Greeks in plain language', 'Delta, theta, vega and why time hurts buyers', [
    QuizQuestion('Theta is…', ['How fast an option loses value each day', 'The option\'s strike', 'Exchange fee'], 0,
        'Theta measures daily time decay, which speeds up near expiry.'),
    QuizQuestion('Volatility jumps before results. Option premiums usually…', ['Fall', 'Rise', 'Don\'t change'], 1,
        'Higher implied volatility (vega) raises premiums for calls and puts.'),
  ], tool: LearnTool.timeDecay),
  Lesson('fno_strategies', Track.fno, 'Buying vs selling and common strategies', 'Spreads, straddles, covered calls', [
    QuizQuestion('Which has unlimited risk?', ['Bull call spread', 'Short straddle', 'Long put'], 1,
        'Selling a naked call (part of a short straddle) has no cap on losses.'),
    QuizQuestion('A bull call spread is cheaper than a plain call because…', ['You also sell a higher call', 'The exchange discounts it', 'It has no expiry'], 0,
        'The premium from the sold call offsets part of the cost, and caps your profit.'),
  ], tool: LearnTool.payoff),
  Lesson('fno_hedging', Track.fno, 'Using options to protect investments', 'Protective puts and covered calls for long-term investors', [
    QuizQuestion('A protective put works like…', ['Insurance on your portfolio', 'A loan', 'A dividend'], 0,
        'You pay a premium so losses below the strike are covered.'),
  ], tool: LearnTool.payoff),
  Lesson('fno_reality_check', Track.fno, 'What the data says about F&O traders', "SEBI's study and why most traders lose", [
    QuizQuestion("Roughly what share of individual F&O traders lost money in SEBI's FY22–24 study?", ['About 30%', 'About 50%', 'About 90%'], 2,
        "SEBI found about 93% of individual traders lost money over the three years."),
    QuizQuestion('The healthiest place for F&O in a long-term plan is…', ['Main source of returns', 'Occasional hedging, small and defined-risk', 'Monthly income'], 1,
        'Use it, if at all, to manage risk on investments you already hold.'),
  ]),
];

class ProgressNotifier extends AsyncNotifier<Set<String>> {
  static const _key = 'completed_lessons';

  @override
  Future<Set<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<void> markDone(String id) async {
    final done = {...?state.value, id};
    state = AsyncData(done);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, done.toList());
  }
}

final progressProvider = AsyncNotifierProvider<ProgressNotifier, Set<String>>(ProgressNotifier.new);
