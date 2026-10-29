double? _d(Object? v) => (v as num?)?.toDouble();

class MarketQuote {
  final String id;
  final String name;
  final double price;
  final double? change1d;
  final double? change1m;
  final double? change1y;
  final bool? above200dma;
  final List<double> spark;

  MarketQuote.fromJson(Map<String, dynamic> j)
      : id = j['id'],
        name = j['name'],
        price = _d(j['price'])!,
        change1d = _d(j['change_1d']),
        change1m = _d(j['change_1m']),
        change1y = _d(j['change_1y']),
        above200dma = j['above_200dma'],
        spark = [for (final v in j['spark'] as List) _d(v)!];
}

class Signals {
  final double? niftyPe;
  final String valuation; // cheap | fair | expensive | unknown
  final String? goldTrend; // up | down
  final double? vix;
  final String rateTrend; // falling | rising | neutral

  Signals.fromJson(Map<String, dynamic> j)
      : niftyPe = _d(j['nifty_pe']),
        valuation = j['valuation'],
        goldTrend = j['gold_trend'],
        vix = _d(j['vix']),
        rateTrend = j['rate_trend'];
}

class FundStat {
  final int code;
  final String name;
  final double nav;
  final String navDate;
  final double? ret1y;
  final double? ret3y;
  final double? ret5y;
  final double? rolling1yAvg;
  final double? rolling1yMin;
  final double? volatility;
  final double? maxDrawdown;
  final double? sharpe;
  final int score;

  FundStat.fromJson(Map<String, dynamic> j)
      : code = j['code'],
        name = j['name'],
        nav = _d(j['nav'])!,
        navDate = j['nav_date'],
        ret1y = _d(j['ret_1y']),
        ret3y = _d(j['ret_3y']),
        ret5y = _d(j['ret_5y']),
        rolling1yAvg = _d(j['rolling_1y_avg']),
        rolling1yMin = _d(j['rolling_1y_min']),
        volatility = _d(j['volatility']),
        maxDrawdown = _d(j['max_drawdown']),
        sharpe = _d(j['sharpe']),
        score = j['score'];
}

enum DataSource { live, cached, sample }

class MarketData {
  final DateTime generatedAt;
  final List<MarketQuote> markets;
  final Signals signals;
  final List<String> notes;
  final Map<String, Map<String, int>> allocations;
  final Map<String, Map<String, double>> buckets;
  final Map<String, List<FundStat>> funds;
  final String? summary;
  final DataSource source;

  MarketData.fromJson(Map<String, dynamic> j, this.source)
      : generatedAt = DateTime.parse(j['generated_at']).toLocal(),
        markets = [for (final m in j['markets'] as List) MarketQuote.fromJson(m)],
        signals = Signals.fromJson(j['signals']),
        notes = List<String>.from(j['notes']),
        allocations = {
          for (final e in (j['allocations'] as Map<String, dynamic>).entries)
            e.key: Map<String, int>.from(e.value),
        },
        buckets = {
          for (final e in (j['buckets'] as Map<String, dynamic>).entries)
            e.key: {
              for (final b in (e.value as Map<String, dynamic>).entries) b.key: _d(b.value)!,
            },
        },
        funds = {
          for (final e in (j['funds'] as Map<String, dynamic>).entries)
            e.key: [for (final f in e.value as List) FundStat.fromJson(f)],
        },
        summary = j['summary'];
}

const categoryLabels = {
  'index': 'Nifty 50 Index',
  'flexi_cap': 'Flexi Cap',
  'mid_cap': 'Mid Cap',
  'small_cap': 'Small Cap',
  'elss': 'ELSS (Tax Saver)',
  'short_term_debt': 'Short-Term Debt',
  'gilt': 'Gilt (Govt Bonds)',
  'gold': 'Gold',
  'liquid': 'Liquid (Cash)',
};

const assetLabels = {'equity': 'Equity', 'debt': 'Debt', 'gold': 'Gold', 'cash': 'Cash'};

const riskProfiles = ['conservative', 'moderate', 'aggressive'];
