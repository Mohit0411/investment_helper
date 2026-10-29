import unittest
from datetime import date, timedelta

import rules

RULES = {
    "max_tilt": 10, "nifty_pe_cheap": 19, "nifty_pe_expensive": 23, "valuation_tilt": 5,
    "gold_trend_tilt": 3, "vix_high": 20, "rate_trend": "neutral", "gilt_share_when_rates_falling": 50,
}
MODERATE = {"equity": 55, "debt": 25, "gold": 15, "cash": 5}


class AllocationTest(unittest.TestCase):
    def test_expensive_market_moves_equity_to_debt(self):
        tilts, notes = rules.compute_tilts({"nifty_pe": 24.0, "valuation": "expensive"}, RULES)
        self.assertEqual(rules.apply_tilts(MODERATE, tilts), {"equity": 50, "debt": 30, "gold": 15, "cash": 5})
        self.assertEqual(len(notes), 1)

    def test_cheap_market_and_gold_uptrend(self):
        tilts, _ = rules.compute_tilts({"nifty_pe": 18.0, "valuation": "cheap", "gold_trend": "up"}, RULES)
        self.assertEqual(rules.apply_tilts(MODERATE, tilts), {"equity": 60, "debt": 17, "gold": 18, "cash": 5})

    def test_tilts_are_capped(self):
        cfg = {**RULES, "valuation_tilt": 30}
        tilts, _ = rules.compute_tilts({"nifty_pe": 30.0, "valuation": "expensive"}, cfg)
        self.assertEqual(tilts["equity"], -10)

    def test_apply_tilts_never_negative_and_sums_to_100(self):
        alloc = rules.apply_tilts({"equity": 75, "debt": 2, "gold": 18, "cash": 5}, {"debt": -10, "gold": 3})
        self.assertGreaterEqual(min(alloc.values()), 0)
        self.assertEqual(sum(alloc.values()), 100)

    def test_unknown_pe_is_neutral(self):
        self.assertEqual(rules.classify_valuation(None, RULES), "unknown")
        tilts, notes = rules.compute_tilts({"nifty_pe": None, "valuation": "unknown"}, RULES)
        self.assertEqual(set(tilts.values()), {0})
        self.assertEqual(notes, [])

    def test_buckets_split_debt_when_rates_falling(self):
        alloc = {"equity": 50, "debt": 30, "gold": 15, "cash": 5}
        b = rules.category_buckets(alloc, {"index": 60, "flexi_cap": 40}, {**RULES, "rate_trend": "falling"})
        self.assertEqual(b, {"index": 30, "flexi_cap": 20, "gilt": 15, "short_term_debt": 15, "gold": 15, "liquid": 5})
        self.assertAlmostEqual(sum(b.values()), 100)


class FundMetricsTest(unittest.TestCase):
    def series(self, years, annual_growth):
        start = date(2020, 1, 1)
        daily = (1 + annual_growth) ** (1 / 365)
        return [(start + timedelta(days=i), 100 * daily ** i) for i in range(int(365 * years))]

    def test_cagr_of_steady_growth(self):
        m = rules.fund_metrics(self.series(6, 0.12), 6.5)
        self.assertAlmostEqual(m["ret_3y"], 12.0, delta=0.2)
        self.assertAlmostEqual(m["ret_5y"], 12.0, delta=0.2)
        self.assertEqual(m["max_drawdown"], 0.0)

    def test_short_history_has_no_5y_return(self):
        self.assertIsNone(rules.fund_metrics(self.series(2, 0.1), 6.5)["ret_5y"])

    def test_score_prefers_better_fund(self):
        good = {"name": "good", "rolling_1y_avg": 15, "sharpe": 1.2, "max_drawdown": -10}
        bad = {"name": "bad", "rolling_1y_avg": 9, "sharpe": 0.4, "max_drawdown": -25}
        ranked = rules.score_category([bad, good])
        self.assertEqual([f["name"] for f in ranked], ["good", "bad"])
        self.assertEqual((ranked[0]["score"], ranked[1]["score"]), (100, 0))


if __name__ == "__main__":
    unittest.main()
