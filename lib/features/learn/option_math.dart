import 'dart:math';

/// Standard normal CDF (Abramowitz & Stegun 7.1.26, error < 1.5e-7).
double normCdf(double x) {
  final t = 1 / (1 + 0.3275911 * x.abs() / sqrt2);
  final poly = t * (0.254829592 + t * (-0.284496736 + t * (1.421413741 + t * (-1.453152027 + t * 1.061405429))));
  final erf = 1 - poly * exp(-x * x / 2);
  return x >= 0 ? (1 + erf) / 2 : (1 - erf) / 2;
}

/// Black-Scholes price of a European option. [years] to expiry, [vol] and [rate] as decimals.
double bsPrice({
  required bool isCall,
  required double spot,
  required double strike,
  required double years,
  required double vol,
  double rate = 0.065,
}) {
  if (years <= 0) return max(0, isCall ? spot - strike : strike - spot);
  final d1 = (log(spot / strike) + (rate + vol * vol / 2) * years) / (vol * sqrt(years));
  final d2 = d1 - vol * sqrt(years);
  final df = exp(-rate * years);
  return isCall
      ? spot * normCdf(d1) - strike * df * normCdf(d2)
      : strike * df * normCdf(-d2) - spot * normCdf(-d1);
}

enum LegType { call, put, underlying }

class OptionLeg {
  final LegType type;
  final bool long;
  final double strike; // entry price for the underlying
  final double premium;

  const OptionLeg(this.type, this.long, this.strike, [this.premium = 0]);

  /// Profit per unit at expiry when the underlying settles at [s].
  double payoff(double s) {
    final intrinsic = switch (type) {
      LegType.call => max(0.0, s - strike),
      LegType.put => max(0.0, strike - s),
      LegType.underlying => s - strike,
    };
    final pnl = intrinsic - premium;
    return long ? pnl : -pnl;
  }
}

double strategyPayoff(List<OptionLeg> legs, double s) => legs.fold(0.0, (a, l) => a + l.payoff(s));

enum Strategy {
  longCall('Buy Call', 'Bullish. Pay a premium; profit if the market rises above strike + premium. Max loss = premium.'),
  longPut('Buy Put', 'Bearish. Pay a premium; profit if the market falls below strike − premium. Max loss = premium.'),
  shortPut('Sell Put', 'Mildly bullish. Collect a premium; keep it if the market stays above strike. Large loss if it falls hard.'),
  coveredCall('Covered Call', 'Own the shares and sell a call above the price: extra income, but upside is capped.'),
  protectivePut('Protective Put', 'Own the shares and buy a put below the price: insurance that limits your loss.'),
  bullCallSpread('Bull Call Spread', 'Buy a call and sell a higher one: cheaper bullish bet with capped profit and capped loss.'),
  longStraddle('Long Straddle', 'Buy a call and a put at the same strike: profit from a big move in either direction.'),
  shortStraddle('Short Straddle', 'Sell a call and a put: profit if the market stays still. Unlimited risk on a big move.');

  final String label;
  final String description;
  const Strategy(this.label, this.description);
}

/// Builds the legs of [strategy] around [spot], pricing options with Black-Scholes.
List<OptionLeg> buildStrategy(Strategy strategy, double spot, {double vol = 0.15, int days = 30, double step = 0.03}) {
  final atm = _round50(spot);
  final up = _round50(spot * (1 + step));
  final down = _round50(spot * (1 - step));
  final t = days / 365;
  OptionLeg call(double k, bool long) =>
      OptionLeg(LegType.call, long, k, bsPrice(isCall: true, spot: spot, strike: k, years: t, vol: vol));
  OptionLeg put(double k, bool long) =>
      OptionLeg(LegType.put, long, k, bsPrice(isCall: false, spot: spot, strike: k, years: t, vol: vol));
  final stock = OptionLeg(LegType.underlying, true, spot);

  return switch (strategy) {
    Strategy.longCall => [call(atm, true)],
    Strategy.longPut => [put(atm, true)],
    Strategy.shortPut => [put(down, false)],
    Strategy.coveredCall => [stock, call(up, false)],
    Strategy.protectivePut => [stock, put(down, true)],
    Strategy.bullCallSpread => [call(atm, true), call(up, false)],
    Strategy.longStraddle => [call(atm, true), put(atm, true)],
    Strategy.shortStraddle => [call(atm, false), put(atm, false)],
  };
}

/// Prices where profit crosses zero, found by scanning [lo]..[hi].
List<double> breakevens(List<OptionLeg> legs, double lo, double hi, {int steps = 2000}) {
  final out = <double>[];
  var prevS = lo;
  var prev = strategyPayoff(legs, lo);
  for (var i = 1; i <= steps; i++) {
    final s = lo + (hi - lo) * i / steps;
    final v = strategyPayoff(legs, s);
    if ((prev < 0 && v >= 0) || (prev > 0 && v <= 0)) {
      out.add(prevS + (s - prevS) * prev.abs() / (prev.abs() + v.abs()));
    }
    prevS = s;
    prev = v;
  }
  return out;
}

double _round50(double x) => (x / 50).round() * 50;
