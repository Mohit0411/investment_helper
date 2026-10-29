"""Daily job: pull market + mutual fund data, compute signals and allocations, write market.json.

Usage: python backend/fetch_data.py [output_path]
Set ANTHROPIC_API_KEY to also generate a plain-English summary with Claude.
"""

import http.client
import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from http.cookiejar import CookieJar
from pathlib import Path

import rules

UA = {"User-Agent": "Mozilla/5.0", "Accept": "*/*"}
HERE = Path(__file__).parent


def get_json(url, opener=None, headers=None, attempts=3):
    req = urllib.request.Request(url, headers={**UA, **(headers or {})})
    for attempt in range(attempts):
        try:
            with (opener or urllib.request.build_opener()).open(req, timeout=60) as resp:
                return json.load(resp)
        except (TimeoutError, OSError, http.client.IncompleteRead):
            if attempt == attempts - 1:
                raise
            time.sleep(2 * (attempt + 1))


def yahoo_closes(symbol):
    url = f"https://query1.finance.yahoo.com/v8/finance/chart/{urllib.request.quote(symbol)}?range=1y&interval=1d"
    result = get_json(url)["chart"]["result"][0]
    return [c for c in result["indicators"]["quote"][0]["close"] if c is not None]


def nifty_pe():
    """NSE sets cookies on its homepage (even when that page answers 403); the API wants them."""
    try:
        opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(CookieJar()))
        try:
            opener.open(urllib.request.Request("https://www.nseindia.com", headers=UA), timeout=30).read()
        except urllib.error.HTTPError:
            pass
        data = get_json("https://www.nseindia.com/api/allIndices", opener, {"Accept": "application/json"})
        row = next(x for x in data["data"] if x["index"] == "NIFTY 50")
        return float(row["pe"])
    except Exception as e:  # NSE blocks some cloud IPs; the valuation signal just goes neutral.
        print(f"warn: Nifty P/E unavailable ({e})", file=sys.stderr)
        return None


def fund_series(code):
    data = get_json(f"https://api.mfapi.in/mf/{code}")["data"]
    series = [(rules.parse_mfapi_date(d["date"]), float(d["nav"])) for d in data if float(d["nav"]) > 0]
    return sorted(series)


def claude_summary(payload):
    if not os.environ.get("ANTHROPIC_API_KEY"):
        return None
    try:
        import anthropic

        client = anthropic.Anthropic()
        facts = {k: payload[k] for k in ("markets", "signals", "notes", "allocations")}
        for m in facts["markets"]:
            m.pop("spark", None)
        response = client.beta.messages.create(
            model="claude-opus-5-5",
            max_tokens=16000,
            output_config={"effort": "low"},
            betas=["server-side-fallback-2026-07-01"],
            fallbacks="default",
            system=("You write a short daily market note for an Indian retail investor's personal app. "
                    "Use only the data given. 3-4 plain sentences, no headings or bullet points: what moved "
                    "today, what the signals mean, and how this month's SIP split changed and why. "
                    "Don't predict prices."),
            messages=[{"role": "user", "content": json.dumps(facts)}],
        )
        if response.stop_reason == "refusal":
            return None
        return "".join(b.text for b in response.content if b.type == "text").strip() or None
    except Exception as e:
        print(f"warn: Claude summary failed ({e})", file=sys.stderr)
        return None


def main(out_path):
    config = json.loads((HERE / "config.json").read_text())
    rule_cfg = config["rules"]

    markets = []
    closes_by_id = {}
    for m in config["markets"]:
        try:
            closes = yahoo_closes(m["symbol"])
            closes_by_id[m["id"]] = closes
            markets.append({"id": m["id"], "name": m["name"], **rules.summarise_series(closes)})
        except Exception as e:
            print(f"warn: {m['symbol']} failed ({e})", file=sys.stderr)

    pe = nifty_pe()
    gold = next((m for m in markets if m["id"] == "gold"), None)
    vix = next((m for m in markets if m["id"] == "vix"), None)
    signals = {
        "nifty_pe": pe,
        "valuation": rules.classify_valuation(pe, rule_cfg),
        "gold_trend": None if not gold or gold["above_200dma"] is None
        else ("up" if gold["above_200dma"] else "down"),
        "vix": vix["price"] if vix else None,
        "rate_trend": rule_cfg["rate_trend"],
    }
    tilts, notes = rules.compute_tilts(signals, rule_cfg)

    allocations, buckets = {}, {}
    for profile, base in config["base_allocation"].items():
        alloc = rules.apply_tilts(base, tilts)
        allocations[profile] = alloc
        buckets[profile] = rules.category_buckets(alloc, config["equity_split"][profile], rule_cfg)

    funds = {}
    for category, entries in config["funds"].items():
        scored = []
        for f in entries:
            try:
                metrics = rules.fund_metrics(fund_series(f["code"]), config["risk_free_rate"])
                scored.append({"code": f["code"], "name": f["name"], **metrics})
            except Exception as e:
                print(f"warn: fund {f['code']} failed ({e})", file=sys.stderr)
        funds[category] = rules.score_category(scored)

    payload = {
        "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "markets": markets,
        "signals": signals,
        "notes": notes,
        "allocations": allocations,
        "buckets": buckets,
        "funds": funds,
    }
    payload["summary"] = claude_summary(json.loads(json.dumps(payload)))

    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    Path(out_path).write_text(json.dumps(payload, indent=1))
    print(f"wrote {out_path}: {len(markets)} markets, {sum(len(v) for v in funds.values())} funds")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else str(HERE.parent / "data" / "market.json"))
