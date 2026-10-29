import 'package:flutter_test/flutter_test.dart';
import 'package:investment_helper/features/learn/option_math.dart';

void main() {
  test('normCdf matches known values', () {
    expect(normCdf(0), closeTo(0.5, 1e-7));
    expect(normCdf(1.96), closeTo(0.975, 1e-4));
    expect(normCdf(-1), closeTo(0.1587, 1e-4));
  });

  test('Black-Scholes matches textbook example and put-call parity', () {
    // Hull: S=42, K=40, r=10%, vol=20%, T=0.5 -> call 4.76, put 0.81
    final c = bsPrice(isCall: true, spot: 42, strike: 40, years: 0.5, vol: 0.2, rate: 0.1);
    final p = bsPrice(isCall: false, spot: 42, strike: 40, years: 0.5, vol: 0.2, rate: 0.1);
    expect(c, closeTo(4.76, 0.01));
    expect(p, closeTo(0.81, 0.01));
  });

  test('options lose value as expiry approaches (theta)', () {
    double price(int days) => bsPrice(isCall: true, spot: 24000, strike: 24000, years: days / 365, vol: 0.15);
    expect(price(30), greaterThan(price(10)));
    expect(price(10), greaterThan(price(1)));
  });

  test('long call payoff: loss capped at premium, breakeven = strike + premium', () {
    const leg = OptionLeg(LegType.call, true, 24000, 300);
    expect(leg.payoff(23000), -300);
    expect(leg.payoff(24300), 0);
    expect(breakevens([leg], 22000, 26000).single, closeTo(24300, 1));
  });

  test('long straddle has two breakevens', () {
    final legs = buildStrategy(Strategy.longStraddle, 24000);
    expect(breakevens(legs, 20000, 28000), hasLength(2));
  });

  test('protective put limits the loss', () {
    final legs = buildStrategy(Strategy.protectivePut, 24000);
    expect(strategyPayoff(legs, 15000), strategyPayoff(legs, 20000));
  });
}
