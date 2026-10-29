import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/funds/funds_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/plan/plan_screen.dart';
import 'features/pulse/pulse_screen.dart';

void main() => runApp(const ProviderScope(child: InvestmentHelperApp()));

class InvestmentHelperApp extends StatelessWidget {
  const InvestmentHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B7F5B), brightness: b),
          useMaterial3: true,
        );
    return MaterialApp(
      title: 'Investment Helper',
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _screens = [PulseScreen(), PlanScreen(), FundsScreen(), LearnScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Pulse'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), label: 'Funds'),
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Learn'),
        ],
      ),
    );
  }
}
