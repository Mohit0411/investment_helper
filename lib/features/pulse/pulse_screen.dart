import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/format.dart';
import '../../data/market_repository.dart';
import '../../data/models.dart';

class PulseScreen extends ConsumerWidget {
  const PulseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(marketDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Market Pulse')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load data\n$e', textAlign: TextAlign.center)),
        data: (d) => RefreshIndicator(
          onRefresh: () => ref.refresh(marketDataProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _UpdatedLine(d),
              if (d.summary != null) ...[const SizedBox(height: 12), _SummaryCard(d.summary!)],
              const SizedBox(height: 12),
              _SignalsCard(d.signals, d.notes),
              const SizedBox(height: 12),
              for (final m in d.markets) _QuoteTile(m),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpdatedLine extends StatelessWidget {
  final MarketData d;
  const _UpdatedLine(this.d);

  @override
  Widget build(BuildContext context) {
    final source = switch (d.source) {
      DataSource.live => 'live',
      DataSource.cached => 'offline copy',
      DataSource.sample => 'bundled sample — set DATA_URL for daily data',
    };
    return Text(
      'Updated ${DateFormat('d MMM, h:mm a').format(d.generatedAt)} · $source',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String text;
  const _SummaryCard(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.auto_awesome, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Text("Today's take", style: Theme.of(context).textTheme.titleSmall),
            ]),
            const SizedBox(height: 8),
            Text(text, style: TextStyle(color: cs.onPrimaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _SignalsCard extends StatelessWidget {
  final Signals s;
  final List<String> notes;
  const _SignalsCard(this.s, this.notes);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signals', style: t.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('Nifty P/E', s.niftyPe?.toStringAsFixed(1) ?? '—', s.valuation),
              _chip('Gold trend', s.goldTrend ?? '—', null),
              _chip('India VIX', s.vix?.toStringAsFixed(1) ?? '—', (s.vix ?? 0) > 20 ? 'high' : 'normal'),
              _chip('Rates', s.rateTrend, null),
            ]),
            const SizedBox(height: 12),
            if (notes.isEmpty)
              Text('No adjustments this month: SIP split follows your base profile.', style: t.bodySmall)
            else
              for (final n in notes)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• '),
                    Expanded(child: Text(n, style: t.bodySmall)),
                  ]),
                ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, String? tag) =>
      Chip(label: Text(tag == null ? '$label: $value' : '$label: $value ($tag)'));
}

class _QuoteTile extends StatelessWidget {
  final MarketQuote q;
  const _QuoteTile(this.q);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final up = (q.change1m ?? 0) >= 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Expanded(
            flex: 5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.name, style: t.titleSmall),
              Text(NumberFormat('#,##,##0.00', 'en_IN').format(q.price), style: t.titleLarge),
              Text(
                '1D ${pct(q.change1d)}  ·  1M ${pct(q.change1m)}  ·  1Y ${pct(q.change1y)}',
                style: t.bodySmall?.copyWith(color: changeColor(q.change1d, cs)),
              ),
            ]),
          ),
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: LineChart(LineChartData(
                titlesData: const FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [for (var i = 0; i < q.spark.length; i++) FlSpot(i.toDouble(), q.spark[i])],
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    barWidth: 2,
                    color: up ? Colors.green.shade600 : cs.error,
                  ),
                ],
              )),
            ),
          ),
        ]),
      ),
    );
  }
}
