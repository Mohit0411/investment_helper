import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lesson_screen.dart';
import 'lessons.dart';
import 'tools/leverage_screen.dart';
import 'tools/payoff_screen.dart';
import 'tools/time_decay_screen.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(progressProvider).value ?? {};
    final t = Theme.of(context).textTheme;

    Widget section(String title, Track track) {
      final items = lessons.where((l) => l.track == track).toList();
      final completed = items.where((l) => done.contains(l.id)).length;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(children: [
            Expanded(child: Text(title, style: t.titleMedium)),
            Text('$completed/${items.length}', style: t.bodySmall),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(value: completed / items.length),
        ),
        for (final (i, l) in items.indexed)
          ListTile(
            leading: done.contains(l.id)
                ? const Icon(Icons.check_circle, color: Colors.green)
                : CircleAvatar(radius: 12, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
            title: Text(l.title),
            subtitle: Text(l.blurb),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(l))),
          ),
      ]);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Learn')),
      body: ListView(children: [
        section('Stock market basics', Track.stocks),
        section('Futures & Options', Track.fno),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
          child: Text('Try it yourself', style: t.titleMedium),
        ),
        for (final tool in LearnTool.values) ToolTile(tool),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class ToolTile extends StatelessWidget {
  final LearnTool tool;
  const ToolTile(this.tool, {super.key});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, Widget screen) = switch (tool) {
      LearnTool.payoff => (Icons.ssid_chart, 'Option payoff visualiser', 'See profit/loss at expiry for 8 strategies', const PayoffScreen()),
      LearnTool.leverage => (Icons.speed, 'Leverage simulator', 'What a small market move does to your margin', const LeverageScreen()),
      LearnTool.timeDecay => (Icons.hourglass_bottom, 'Time decay (theta)', 'Watch an option lose value as expiry nears', const TimeDecayScreen()),
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
