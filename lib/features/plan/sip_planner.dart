import '../../data/models.dart';

/// Rough long-run return assumptions (% per year) used only for projections.
const expectedReturns = {
  'index': 11.0,
  'flexi_cap': 12.0,
  'elss': 12.0,
  'mid_cap': 13.0,
  'small_cap': 14.0,
  'short_term_debt': 7.0,
  'gilt': 7.0,
  'gold': 8.0,
  'liquid': 6.5,
};

const minSipAmount = 500;

class SipLine {
  final String category;
  final double percent;
  final int amount;
  final FundStat? fund;

  const SipLine(this.category, this.percent, this.amount, this.fund);
}

/// Splits [monthly] across fund categories using today's [buckets] (category -> %).
///
/// Amounts are multiples of ₹100. Categories that would get less than the usual
/// ₹500 minimum SIP are folded into the rest, smallest first.
List<SipLine> planSip(
  int monthly,
  Map<String, double> buckets,
  Map<String, List<FundStat>> funds, {
  bool taxSaving = false,
}) {
  final weights = Map<String, double>.of(buckets);
  if (taxSaving && weights.containsKey('flexi_cap')) {
    weights['elss'] = weights.remove('flexi_cap')!;
  }

  while (weights.length > 1) {
    final total = weights.values.fold(0.0, (a, b) => a + b);
    final smallest = weights.entries.reduce((a, b) => a.value <= b.value ? a : b);
    if (monthly * smallest.value / total >= minSipAmount) break;
    weights.remove(smallest.key);
  }

  final total = weights.values.fold(0.0, (a, b) => a + b);
  final units = monthly ~/ 100;
  final exact = {for (final e in weights.entries) e.key: units * e.value / total};
  final alloc = {for (final e in exact.entries) e.key: e.value.floor()};
  var leftover = units - alloc.values.fold(0, (a, b) => a + b);
  final byRemainder = exact.keys.toList()
    ..sort((a, b) => (exact[b]! - alloc[b]!).compareTo(exact[a]! - alloc[a]!));
  for (final k in byRemainder) {
    if (leftover-- <= 0) break;
    alloc[k] = alloc[k]! + 1;
  }

  final lines = [
    for (final e in weights.entries)
      SipLine(
        e.key,
        e.value * 100 / total,
        alloc[e.key]! * 100,
        (funds[e.key]?.isNotEmpty ?? false) ? funds[e.key]!.first : null,
      ),
  ]..sort((a, b) => b.amount.compareTo(a.amount));
  return lines;
}

double blendedReturn(List<SipLine> lines) {
  final total = lines.fold(0, (a, l) => a + l.amount);
  if (total == 0) return 0;
  return lines.fold(0.0, (a, l) => a + l.amount * (expectedReturns[l.category] ?? 8)) / total;
}

class Projection {
  final double invested;
  final double value;
  const Projection(this.invested, this.value);
}

/// Value at the end of each year of a monthly SIP that grows by [stepUpPct] every year.
List<Projection> projectSip(int monthly, int years, double annualReturnPct, double stepUpPct) {
  final r = annualReturnPct / 100 / 12;
  var sip = monthly.toDouble();
  var value = 0.0;
  var invested = 0.0;
  final out = <Projection>[];
  for (var y = 0; y < years; y++) {
    for (var m = 0; m < 12; m++) {
      value = (value + sip) * (1 + r);
      invested += sip;
    }
    out.add(Projection(invested, value));
    sip *= 1 + stepUpPct / 100;
  }
  return out;
}
