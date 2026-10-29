"""Pure allocation and scoring logic. No network access, so it is easy to test."""

from datetime import date, timedelta
from statistics import mean, pstdev

ASSETS = ("equity", "debt", "gold", "cash")


def classify_valuation(pe, rules):
    if pe is None:
        return "unknown"
    if pe < rules["nifty_pe_cheap"]:
        return "cheap"
    if pe > rules["nifty_pe_expensive"]:
        return "expensive"
    return "fair"


def compute_tilts(signals, rules):
    """Return ({asset: tilt_pct}, [human-readable notes]) from today's signals."""
    tilts = {a: 0 for a in ASSETS}
    notes = []

    valuation = signals.get("valuation")
    step = rules["valuation_tilt"]
    if valuation == "expensive":
        tilts["equity"] -= step
        tilts["debt"] += step
        notes.append(f"Nifty P/E {signals['nifty_pe']:.2f} is above {rules['nifty_pe_expensive']}: "
                     f"equity trimmed {step}%, moved to debt.")
    elif valuation == "cheap":
        tilts["equity"] += step
        tilts["debt"] -= step
        notes.append(f"Nifty P/E {signals['nifty_pe']:.2f} is below {rules['nifty_pe_cheap']}: "
                     f"equity raised {step}% from debt.")

    if signals.get("gold_trend") == "up":
        step = rules["gold_trend_tilt"]
        tilts["gold"] += step
        tilts["debt"] -= step
        notes.append(f"Gold is above its 200-day average (uptrend): gold raised {step}% from debt.")

    vix = signals.get("vix")
    if vix is not None and vix > rules["vix_high"]:
        notes.append(f"India VIX {vix:.1f} is high: keep SIPs running; stagger any lump sum over 3-6 months.")

    cap = rules["max_tilt"]
    tilts = {a: max(-cap, min(cap, t)) for a, t in tilts.items()}
    return tilts, notes


def apply_tilts(base, tilts):
    """Add tilts to a base allocation, clamp at zero and renormalise to 100 (integers)."""
    raw = {a: max(0, base[a] + tilts.get(a, 0)) for a in ASSETS}
    total = sum(raw.values())
    scaled = {a: raw[a] * 100 / total for a in ASSETS}
    out = {a: int(scaled[a]) for a in ASSETS}
    # Hand leftover points to the largest fractional parts so the sum is exactly 100.
    leftover = 100 - sum(out.values())
    for a in sorted(ASSETS, key=lambda a: scaled[a] - out[a], reverse=True)[:leftover]:
        out[a] += 1
    return out


def category_buckets(alloc, equity_split, rules):
    """Break an asset allocation into fund-category percentages."""
    buckets = {}
    for cat, share in equity_split.items():
        buckets[cat] = alloc["equity"] * share / 100
    if rules["rate_trend"] == "falling":
        gilt = alloc["debt"] * rules["gilt_share_when_rates_falling"] / 100
        buckets["gilt"] = gilt
        buckets["short_term_debt"] = alloc["debt"] - gilt
    else:
        buckets["short_term_debt"] = alloc["debt"]
    buckets["gold"] = alloc["gold"]
    buckets["liquid"] = alloc["cash"]
    return {k: round(v, 2) for k, v in buckets.items() if v > 0}


# ---------- price series helpers ----------

def pct_change(new, old):
    return (new / old - 1) * 100 if old else None


def moving_average(values, n):
    return mean(values[-n:]) if len(values) >= n else None


def summarise_series(closes):
    """closes: list of floats, oldest first, one per trading day."""
    last = closes[-1]
    dma200 = moving_average(closes, 200)
    return {
        "price": round(last, 2),
        "change_1d": _r(pct_change(last, closes[-2])) if len(closes) > 1 else None,
        "change_1m": _r(pct_change(last, closes[-22])) if len(closes) > 22 else None,
        "change_1y": _r(pct_change(last, closes[0])) if len(closes) > 200 else None,
        "above_200dma": last > dma200 if dma200 else None,
        "spark": [round(c, 2) for c in closes[-30:]],
    }


# ---------- mutual fund metrics ----------

def _nav_on_or_before(series, target):
    """series: list of (date, nav) oldest first. Returns the last NAV on/before target."""
    lo, hi, found = 0, len(series) - 1, None
    while lo <= hi:
        mid = (lo + hi) // 2
        if series[mid][0] <= target:
            found = series[mid][1]
            lo = mid + 1
        else:
            hi = mid - 1
    return found


def cagr(series, years, today=None):
    today = today or series[-1][0]
    start = today - timedelta(days=round(365.25 * years))
    if series[0][0] > start:
        return None
    old = _nav_on_or_before(series, start)
    return ((series[-1][1] / old) ** (1 / years) - 1) * 100


def fund_metrics(series, risk_free):
    """series: list of (date, nav) oldest first."""
    today = series[-1][0]
    window_start = today - timedelta(days=3 * 365)

    # Rolling 1-year returns, sampled monthly over the last 3 years.
    rolling = []
    d = window_start
    while d <= today - timedelta(days=365):
        a = _nav_on_or_before(series, d)
        b = _nav_on_or_before(series, d + timedelta(days=365))
        if a and b:
            rolling.append((b / a - 1) * 100)
        d += timedelta(days=30)

    recent = [nav for dt, nav in series if dt >= window_start]
    weekly = recent[::5]
    weekly_returns = [weekly[i] / weekly[i - 1] - 1 for i in range(1, len(weekly))]
    vol = pstdev(weekly_returns) * (52 ** 0.5) * 100 if len(weekly_returns) > 10 else None

    peak, max_dd = recent[0] if recent else 0, 0.0
    for nav in recent:
        peak = max(peak, nav)
        max_dd = min(max_dd, (nav / peak - 1) * 100)

    r3 = cagr(series, 3)
    sharpe = (r3 - risk_free) / vol if r3 is not None and vol else None
    return {
        "nav": round(series[-1][1], 4),
        "nav_date": today.isoformat(),
        "ret_1y": _r(cagr(series, 1)),
        "ret_3y": _r(r3),
        "ret_5y": _r(cagr(series, 5)),
        "rolling_1y_avg": _r(mean(rolling)) if rolling else None,
        "rolling_1y_min": _r(min(rolling)) if rolling else None,
        "volatility": _r(vol),
        "max_drawdown": _r(max_dd),
        "sharpe": _r(sharpe, 2),
    }


def score_category(funds):
    """Rank funds in one category 0-100 by consistency, risk-adjusted return and drawdown."""
    weights = {"rolling_1y_avg": 0.5, "sharpe": 0.3, "max_drawdown": 0.2}  # higher is better for all three
    for f in funds:
        f["score"] = 0.0
    for key, w in weights.items():
        ranked = sorted((f for f in funds if f.get(key) is not None), key=lambda f: f[key])
        n = len(ranked)
        for i, f in enumerate(ranked):
            f["score"] += w * (100 * i / (n - 1) if n > 1 else 100)
    for f in funds:
        f["score"] = round(f["score"])
    return sorted(funds, key=lambda f: f["score"], reverse=True)


def _r(x, digits=1):
    return round(x, digits) if x is not None else None


def parse_mfapi_date(s):
    d, m, y = s.split("-")
    return date(int(y), int(m), int(d))
