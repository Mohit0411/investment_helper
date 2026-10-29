import 'package:flutter_test/flutter_test.dart';
import 'package:investment_helper/features/plan/sip_planner.dart';

void main() {
  const buckets = {
    'index': 24.0,
    'flexi_cap': 18.0,
    'mid_cap': 12.0,
    'small_cap': 6.0,
    'short_term_debt': 20.0,
    'gold': 15.0,
    'liquid': 5.0,
  };

  test('amounts are multiples of 100 and add up to the monthly amount', () {
    final lines = planSip(25000, buckets, {});
    expect(lines.fold(0, (a, l) => a + l.amount), 25000);
    expect(lines.every((l) => l.amount % 100 == 0), isTrue);
    expect(lines.first.category, 'index');
  });

  test('small amounts drop categories below the ₹500 minimum SIP', () {
    final lines = planSip(5000, buckets, {});
    expect(lines.every((l) => l.amount >= minSipAmount), isTrue);
    expect(lines.fold(0, (a, l) => a + l.amount), 5000);
    expect(lines.map((l) => l.category), isNot(contains('liquid')));
  });

  test('tax saving swaps flexi cap for ELSS', () {
    final cats = planSip(25000, buckets, {}, taxSaving: true).map((l) => l.category);
    expect(cats, contains('elss'));
    expect(cats, isNot(contains('flexi_cap')));
  });

  test('projection with no return equals money invested', () {
    final p = projectSip(10000, 2, 0, 10);
    expect(p.last.invested, closeTo(120000 + 132000, 0.01));
    expect(p.last.value, closeTo(p.last.invested, 0.01));
  });

  test('₹10k/month at 12% for 10 years is about ₹23 lakh', () {
    expect(projectSip(10000, 10, 12, 0).last.value, closeTo(2323391, 1000));
  });
}
