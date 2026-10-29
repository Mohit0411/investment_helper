# Buying vs selling, and common strategies

## Buyers and sellers

| | Option buyer | Option seller (writer) |
|---|---|---|
| Pays or receives premium | Pays | Receives |
| Win rate | Low: most OTM options expire worthless | High: wins small, often |
| When wrong | Loses the premium (capped) | Can lose many times the premium |
| Capital needed | Just the premium | Large margin |

Selling "feels" safe because it wins most weeks. Then one big move takes back months of profit. **Never sell naked options without a defined-risk hedge.**

## Strategies to explore in the visualiser

- **Buy call / buy put**: simple directional bets with capped loss.
- **Bull call spread**: buy an ATM call and sell a higher call. Cheaper than a plain call, and both profit and loss are capped. A sensible defined-risk structure.
- **Long straddle**: buy a call and a put at the same strike. You profit from a big move either way, but lose if the market stays quiet (theta hurts).
- **Short straddle**: sell both. You profit if the market stays still. **Unlimited risk.** Many retail blow-ups come from this.
- **Covered call**: own the shares and sell an OTM call. You earn extra income, but give up gains above the strike.
- **Protective put**: own the shares and buy a put. Insurance, covered in the next lesson.

## Hidden costs

Every trade pays brokerage, STT, exchange fees, stamp duty and GST, plus the **bid-ask spread**. For frequent traders, these costs alone can be a large part of their capital each year.

Open the **payoff visualiser** and compare *Bull Call Spread* with *Buy Call*, and *Short Straddle* with *Long Straddle*.
