# Investment Helper

Personal Flutter app that shows the daily market picture for India, splits a monthly SIP across equity / debt / gold / cash based on today's signals, ranks mutual funds by consistency, and teaches stocks and F&O with interactive tools.

> Personal project, not investment advice. Rules and fund lists are my own and live in `backend/config.json`.

## Screens

| Tab | What it does |
|---|---|
| **Pulse** | Nifty, Sensex, Bank Nifty, gold, silver, VIX with 1D/1M/1Y moves; valuation and trend signals; optional Claude-written daily note |
| **Plan** | Enter a monthly amount and risk profile → split by fund category with the top-ranked fund in each; ELSS toggle; projection with yearly step-up |
| **Funds** | Direct-growth funds per category ranked 0–100 (rolling 1Y consistency 50%, Sharpe 30%, max drawdown 20%) |
| **Learn** | 10 lessons (stock basics, F&O) with quizzes and progress; option payoff visualiser, leverage simulator, theta demo |

## How it works

```
GitHub Action (weekdays 17:00 IST)
  backend/fetch_data.py
    ├─ Yahoo Finance  → index / gold / silver / VIX prices
    ├─ NSE            → Nifty P/E
    ├─ mfapi.in       → full NAV history per fund
    ├─ rules.py       → signals → tilts → allocation per profile → fund scores
    └─ Claude (optional, ANTHROPIC_API_KEY) → 3–4 sentence summary
  → commits data/market.json
Flutter app → fetches DATA_URL → caches it → falls back to assets/sample_market.json
```

### Allocation rules (`backend/config.json`)

- Base split per profile (conservative 30/50/15/5, moderate 55/25/15/5, aggressive 75/10/10/5 for equity/debt/gold/cash).
- Nifty P/E below 19 → +5% equity from debt; above 23 → −5% equity to debt.
- Gold above its 200-day average → +3% gold from debt.
- VIX above 20 → note to stagger lump sums (no allocation change).
- `rate_trend: "falling"` (set by hand) → half of debt goes to gilt funds.
- Tilts are capped at ±10% per asset.

## Run it

```bash
# backend
python3 -m unittest discover -s backend
python3 backend/fetch_data.py data/market.json          # add ANTHROPIC_API_KEY for the summary

# app
flutter test
flutter run                                              # uses bundled sample data
flutter run --dart-define=DATA_URL=https://raw.githubusercontent.com/USER/investment_helper/main/data/market.json
```

To refresh the bundled sample: `cp data/market.json assets/sample_market.json`.

## GitHub setup

1. Push this repo. The raw URL above only works without auth if the repo is **public** (or host `data/market.json` somewhere public).
2. Optional: add `ANTHROPIC_API_KEY` under *Settings → Secrets → Actions*.
3. Run the *Daily market data* workflow once manually from the Actions tab.
