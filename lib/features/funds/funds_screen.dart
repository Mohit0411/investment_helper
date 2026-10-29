import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/market_repository.dart';
import '../../data/models.dart';

class FundsScreen extends ConsumerWidget {
  const FundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(marketDataProvider).when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
          data: (d) {
            final cats = d.funds.keys.where((k) => d.funds[k]!.isNotEmpty).toList();
            return DefaultTabController(
              length: cats.length,
              child: Scaffold(
                appBar: AppBar(
                  title: const Text('Fund Rankings'),
                  actions: [
                    IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _explain(context)),
                  ],
                  bottom: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [for (final c in cats) Tab(text: categoryLabels[c] ?? c)],
                  ),
                ),
                body: TabBarView(children: [
                  for (final c in cats)
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (var i = 0; i < d.funds[c]!.length; i++) _FundCard(d.funds[c]![i], i + 1),
                      ],
                    ),
                ]),
              ),
            );
          },
        );
  }

  void _explain(BuildContext context) => showModalBottomSheet(
        context: context,
        builder: (_) => const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Score (0–100) ranks funds within a category:\n\n'
            '• 50% consistency: average of every 1-year return over the last 3 years\n'
            '• 30% Sharpe ratio: return earned per unit of volatility\n'
            '• 20% max drawdown: smallest worst fall from a peak\n\n'
            'All funds shown are Direct–Growth plans. Expense ratio is not yet included: '
            'check it on the AMC site before investing.',
          ),
        ),
      );
}

class _FundCard extends StatelessWidget {
  final FundStat f;
  final int rank;
  const _FundCard(this.f, this.rank);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    Widget metric(String label, String value, [double? colorBy]) => Expanded(
          child: Column(children: [
            Text(value, style: t.titleSmall?.copyWith(color: colorBy == null ? null : changeColor(colorBy, cs))),
            Text(label, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 14, child: Text('$rank')),
            const SizedBox(width: 12),
            Expanded(child: Text(f.name, style: t.titleSmall)),
            Text('${f.score}', style: t.headlineSmall?.copyWith(color: cs.primary)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            metric('1Y', pct(f.ret1y), f.ret1y),
            metric('3Y/yr', pct(f.ret3y), f.ret3y),
            metric('5Y/yr', pct(f.ret5y), f.ret5y),
            metric('Worst 1Y', pct(f.rolling1yMin), f.rolling1yMin),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            metric('Volatility', pct(f.volatility, sign: false)),
            metric('Max fall', pct(f.maxDrawdown)),
            metric('Sharpe', f.sharpe?.toStringAsFixed(2) ?? '—'),
            metric('NAV', f.nav.toStringAsFixed(2)),
          ]),
        ]),
      ),
    );
  }
}
