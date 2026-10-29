import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/market_repository.dart';
import '../../data/models.dart';
import 'sip_planner.dart';

const _assetColors = {
  'equity': Color(0xFF1B7F5B),
  'debt': Color(0xFF3D6FB6),
  'gold': Color(0xFFD4A017),
  'cash': Color(0xFF8A8F98),
};

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  final _amount = TextEditingController(text: '10000');
  String _profile = 'moderate';
  bool _taxSaving = false;
  double _years = 10;
  double _stepUp = 10;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(marketDataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('SIP Planner')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: _body,
      ),
    );
  }

  Widget _body(MarketData d) {
    final t = Theme.of(context).textTheme;
    final monthly = int.tryParse(_amount.text) ?? 0;
    final alloc = d.allocations[_profile]!;
    final lines = monthly >= minSipAmount ? planSip(monthly, d.buckets[_profile]!, d.funds, taxSaving: _taxSaving) : <SipLine>[];
    final rate = blendedReturn(lines);
    final proj = monthly > 0 ? projectSip(monthly, _years.round(), rate, _stepUp).last : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _amount,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Monthly investment', prefixText: '₹ ', border: OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [for (final p in riskProfiles) ButtonSegment(value: p, label: Text(_cap(p)))],
          selected: {_profile},
          onSelectionChanged: (s) => setState(() => _profile = s.first),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Save tax under 80C (ELSS)'),
          subtitle: const Text('Only useful in the old tax regime'),
          value: _taxSaving,
          onChanged: (v) => setState(() => _taxSaving = v),
        ),
        const SizedBox(height: 8),
        Text("This month's split", style: t.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: Row(children: [
            Expanded(
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  for (final e in alloc.entries)
                    if (e.value > 0)
                      PieChartSectionData(
                        value: e.value.toDouble(),
                        color: _assetColors[e.key],
                        title: '${e.value}%',
                        radius: 40,
                        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                ],
              )),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final e in alloc.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Container(width: 12, height: 12, color: _assetColors[e.key]),
                      const SizedBox(width: 8),
                      Text('${assetLabels[e.key]}  ${e.value}%'),
                    ]),
                  ),
              ],
            ),
          ]),
        ),
        if (d.notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Adjusted for today: ${d.notes.join(' ')}', style: t.bodySmall),
          ),
        const SizedBox(height: 16),
        if (monthly < minSipAmount)
          Text('Enter at least ${rupees(minSipAmount)} to get a plan.', style: t.bodyMedium)
        else
          for (final l in lines) _LineTile(l),
        const SizedBox(height: 24),
        Text('Where this could take you', style: t.titleMedium),
        _slider('Years', _years, 1, 30, '${_years.round()} yrs', (v) => setState(() => _years = v)),
        _slider('Yearly step-up', _stepUp, 0, 25, '${_stepUp.round()}%', (v) => setState(() => _stepUp = v)),
        if (proj != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('Invested', rupeesCompact(proj.invested)),
                _stat('Could grow to', rupeesCompact(proj.value)),
                _stat('Assumed return', '${rate.toStringAsFixed(1)}%'),
              ]),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'Projections use long-run average returns per category. Real returns vary year to year and can be negative.',
          style: t.bodySmall,
        ),
      ],
    );
  }

  Widget _slider(String label, double v, double min, double max, String shown, ValueChanged<double> on) => Row(children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(child: Slider(value: v, min: min, max: max, divisions: (max - min).round(), onChanged: on)),
        SizedBox(width: 56, child: Text(shown, textAlign: TextAlign.end)),
      ]);

  Widget _stat(String label, String value) => Column(children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);

  String _cap(String s) => s[0].toUpperCase() + s.substring(1);
}

class _LineTile extends StatelessWidget {
  final SipLine l;
  const _LineTile(this.l);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: ListTile(
        title: Text(categoryLabels[l.category] ?? l.category),
        subtitle: Text(l.fund == null
            ? 'No fund data'
            : '${l.fund!.name}\n3Y ${pct(l.fund!.ret3y)} a year · score ${l.fund!.score}/100'),
        isThreeLine: l.fund != null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(rupees(l.amount), style: t.titleMedium),
            Text('${l.percent.toStringAsFixed(0)}%', style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}
