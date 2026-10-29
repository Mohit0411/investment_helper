import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../option_math.dart';

class TimeDecayScreen extends StatefulWidget {
  const TimeDecayScreen({super.key});

  @override
  State<TimeDecayScreen> createState() => _TimeDecayScreenState();
}

class _TimeDecayScreenState extends State<TimeDecayScreen> {
  static const _spot = 24000.0;
  double _strikeOffset = 0; // % away from spot
  double _vol = 15;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final strike = ((_spot * (1 + _strikeOffset / 100)) / 50).round() * 50.0;
    double price(int days) => bsPrice(isCall: true, spot: _spot, strike: strike, years: days / 365, vol: _vol / 100);
    final curve = [for (var d = 60; d >= 0; d--) FlSpot((60 - d).toDouble(), price(d))];
    final p30 = price(30), p7 = price(7), p1 = price(1), atExpiry = price(0);
    final timeValue30 = p30 - atExpiry;

    return Scaffold(
      appBar: AppBar(title: const Text('Time decay (theta)')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Price of a Nifty $strike call while Nifty stays at ${_spot.toStringAsFixed(0)}. '
            'Nothing moves, yet the option keeps losing value.', style: t.bodyMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: LineChart(LineChartData(
            minY: 0,
            gridData: const FlGridData(drawVerticalLine: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, meta) => Text(v.toStringAsFixed(0), style: t.labelSmall),
                ),
              ),
              bottomTitles: AxisTitles(
                axisNameWidget: Text('days left to expiry', style: t.labelSmall),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 10,
                  getTitlesWidget: (v, meta) => Text('${60 - v.toInt()}', style: t.labelSmall),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(spots: curve, dotData: const FlDotData(show: false), color: cs.primary, barWidth: 3),
            ],
          )),
        ),
        const SizedBox(height: 16),
        Text('30 days left: ₹${p30.toStringAsFixed(0)}  ·  7 days: ₹${p7.toStringAsFixed(0)}  ·  1 day: ₹${p1.toStringAsFixed(0)}',
            style: t.titleSmall),
        Text('The final week burns ${timeValue30 > 0 ? ((p7 - atExpiry) / timeValue30 * 100).toStringAsFixed(0) : 0}% of the '
            'time value the option had with 30 days left. '
            'Decay speeds up near expiry, which is why most short-dated bought options expire worthless.', style: t.bodyMedium),
        const SizedBox(height: 16),
        Row(children: [
          const SizedBox(width: 120, child: Text('Strike vs spot')),
          Expanded(child: Slider(value: _strikeOffset, min: -3, max: 3, divisions: 12, onChanged: (v) => setState(() => _strikeOffset = v))),
          SizedBox(width: 48, child: Text('${_strikeOffset > 0 ? '+' : ''}${_strikeOffset.toStringAsFixed(1)}%')),
        ]),
        Row(children: [
          const SizedBox(width: 120, child: Text('Volatility (IV)')),
          Expanded(child: Slider(value: _vol, min: 8, max: 40, onChanged: (v) => setState(() => _vol = v))),
          SizedBox(width: 48, child: Text('${_vol.round()}%')),
        ]),
      ]),
    );
  }
}
