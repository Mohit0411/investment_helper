import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../data/market_repository.dart';
import '../option_math.dart';

class PayoffScreen extends ConsumerStatefulWidget {
  const PayoffScreen({super.key});

  @override
  ConsumerState<PayoffScreen> createState() => _PayoffScreenState();
}

class _PayoffScreenState extends ConsumerState<PayoffScreen> {
  Strategy _strategy = Strategy.longCall;
  double _vol = 15;
  double _days = 30;
  double _lotSize = 75;
  double? _expiryAt;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final nifty = ref.watch(marketDataProvider).value?.markets.where((m) => m.id == 'nifty').firstOrNull?.price;
    final spot = ((nifty ?? 24000) / 50).round() * 50.0;
    final lo = spot * 0.9, hi = spot * 1.1;
    final expiryAt = (_expiryAt ?? spot).clamp(lo, hi);

    final legs = buildStrategy(_strategy, spot, vol: _vol / 100, days: _days.round());
    final points = [for (var i = 0; i <= 120; i++) lo + (hi - lo) * i / 120];
    final pnl = [for (final s in points) strategyPayoff(legs, s)];
    final bes = breakevens(legs, lo, hi);
    // Still sloping at a chart edge means the profit or loss keeps growing beyond it.
    final leftSlope = pnl[1] - pnl.first, rightSlope = pnl.last - pnl[pnl.length - 2];
    const eps = 1e-6;
    // Upside is unbounded; downside stops at a price of zero, so call it "very large".
    final maxProfit = rightSlope > eps
        ? 'Unlimited*'
        : leftSlope < -eps
            ? 'Very large*'
            : rupees(pnl.reduce(max) * _lotSize);
    final maxLoss = rightSlope < -eps
        ? 'Unlimited*'
        : leftSlope > eps
            ? 'Very large*'
            : rupees(pnl.reduce(min) * _lotSize);
    final netPremium = legs.where((l) => l.type != LegType.underlying).fold(0.0, (a, l) => a + (l.long ? -l.premium : l.premium));

    return Scaffold(
      appBar: AppBar(title: const Text('Option payoff')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<Strategy>(
          initialValue: _strategy,
          decoration: const InputDecoration(labelText: 'Strategy', border: OutlineInputBorder()),
          items: [for (final s in Strategy.values) DropdownMenuItem(value: s, child: Text(s.label))],
          onChanged: (s) => setState(() => _strategy = s!),
        ),
        const SizedBox(height: 8),
        Text(_strategy.description, style: t.bodyMedium),
        const SizedBox(height: 8),
        Text('Nifty now: ${spot.toStringAsFixed(0)}', style: t.bodySmall),
        for (final l in legs)
          Text(
            l.type == LegType.underlying
                ? '• Own Nifty at ${l.strike.toStringAsFixed(0)}'
                : '• ${l.long ? 'Buy' : 'Sell'} ${l.strike.toStringAsFixed(0)} ${l.type.name.toUpperCase()} @ ₹${l.premium.toStringAsFixed(1)}',
            style: t.bodySmall,
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: LineChart(LineChartData(
            minX: lo,
            maxX: hi,
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (v, meta) => Text(v.toStringAsFixed(0), style: t.labelSmall),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (hi - lo) / 4,
                  getTitlesWidget: (v, meta) => Text(v.toStringAsFixed(0), style: t.labelSmall),
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [HorizontalLine(y: 0, color: cs.outline, strokeWidth: 1)],
              verticalLines: [
                VerticalLine(x: spot, color: cs.outline, dashArray: [4, 4]),
                VerticalLine(x: expiryAt, color: cs.tertiary, strokeWidth: 2),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [for (var i = 0; i < points.length; i++) FlSpot(points[i], pnl[i])],
                dotData: const FlDotData(show: false),
                color: cs.primary,
                barWidth: 3,
                belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.15), cutOffY: 0, applyCutOffY: true),
                aboveBarData: BarAreaData(show: true, color: cs.error.withValues(alpha: 0.15), cutOffY: 0, applyCutOffY: true),
              ),
            ],
          )),
        ),
        const SizedBox(height: 8),
        Text('Nifty at expiry: ${expiryAt.toStringAsFixed(0)}  →  P&L per lot ${rupees(strategyPayoff(legs, expiryAt) * _lotSize)}',
            style: t.titleSmall),
        Slider(value: expiryAt, min: lo, max: hi, onChanged: (v) => setState(() => _expiryAt = v)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          Chip(label: Text('Max profit: $maxProfit')),
          Chip(label: Text('Max loss: $maxLoss')),
          Chip(label: Text('Breakeven: ${bes.isEmpty ? '—' : bes.map((b) => b.toStringAsFixed(0)).join(' / ')}')),
          Chip(label: Text('${netPremium >= 0 ? 'Premium received' : 'Premium paid'}: ${rupees(netPremium.abs() * _lotSize)}')),
        ]),
        const SizedBox(height: 16),
        _slider('Days to expiry', _days, 1, 90, '${_days.round()}', (v) => setState(() => _days = v)),
        _slider('Volatility (IV)', _vol, 8, 40, '${_vol.round()}%', (v) => setState(() => _vol = v)),
        _slider('Lot size', _lotSize, 25, 150, '${_lotSize.round()}', (v) => setState(() => _lotSize = v)),
        Text(
          'Premiums are Black-Scholes estimates, not live quotes. *Keeps growing beyond the ±10% shown. '
          'NSE revises lot sizes periodically; check the current one.',
          style: t.bodySmall,
        ),
      ]),
    );
  }

  Widget _slider(String label, double v, double min, double max, String shown, ValueChanged<double> on) => Row(children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(child: Slider(value: v, min: min, max: max, onChanged: on)),
        SizedBox(width: 44, child: Text(shown, textAlign: TextAlign.end)),
      ]);
}
