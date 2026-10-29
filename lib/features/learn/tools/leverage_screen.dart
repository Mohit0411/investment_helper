import 'package:flutter/material.dart';

import '../../../core/format.dart';

class LeverageScreen extends StatefulWidget {
  const LeverageScreen({super.key});

  @override
  State<LeverageScreen> createState() => _LeverageScreenState();
}

class _LeverageScreenState extends State<LeverageScreen> {
  double _margin = 100000;
  double _leverage = 6;
  double _move = -3;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final exposure = _margin * _leverage;
    final pnl = exposure * _move / 100;
    final onMargin = pnl / _margin * 100;
    final wipeOut = 100 / _leverage;

    return Scaffold(
      appBar: AppBar(title: const Text('Leverage simulator')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Futures let you control a large position with a small margin. Move the sliders to see what that does.',
            style: t.bodyMedium),
        const SizedBox(height: 16),
        _slider('Your margin', _margin, 25000, 500000, rupeesCompact(_margin), (v) => setState(() => _margin = (v / 5000).round() * 5000)),
        _slider('Leverage', _leverage, 1, 10, '${_leverage.toStringAsFixed(0)}x', (v) => setState(() => _leverage = v.roundToDouble())),
        _slider('Market move', _move, -10, 10, pct(_move), (v) => setState(() => _move = (v * 2).round() / 2)),
        const SizedBox(height: 16),
        Card(
          color: pnl >= 0 ? Colors.green.withValues(alpha: 0.12) : cs.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Position size: ${rupeesCompact(exposure)}', style: t.titleSmall),
              const SizedBox(height: 4),
              Text('Profit / loss: ${rupees(pnl)}', style: t.headlineSmall),
              Text('That is ${pct(onMargin)} of your margin, from a ${pct(_move)} market move.', style: t.bodyMedium),
              if (onMargin <= -100)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Your entire margin is gone, and you owe the broker more.',
                      style: t.bodyMedium?.copyWith(color: cs.error, fontWeight: FontWeight.bold)),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'At ${_leverage.toStringAsFixed(0)}x leverage, a ${wipeOut.toStringAsFixed(1)}% move against you wipes out 100% of your margin. '
          'Nifty moves more than 1% in a day fairly often. Brokers ask for more margin (a margin call) or close your position long before that.',
          style: t.bodyMedium,
        ),
      ]),
    );
  }

  Widget _slider(String label, double v, double min, double max, String shown, ValueChanged<double> on) => Row(children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(child: Slider(value: v, min: min, max: max, onChanged: on)),
        SizedBox(width: 72, child: Text(shown, textAlign: TextAlign.end)),
      ]);
}
