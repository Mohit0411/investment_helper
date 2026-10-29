# The Greeks in plain language

The "Greeks" describe how an option's price reacts to change. You don't need the formulas, just the intuition.

## Delta: sensitivity to price

How much the option moves when the underlying moves ₹1.

- An ATM call has delta ≈ 0.5: Nifty +100 → call ≈ +50.
- A deep ITM call has delta close to 1. It behaves like the index itself.
- A far OTM call has delta close to 0. It barely reacts, so it's a lottery ticket.
- Puts have negative delta.

## Theta: time decay

How much value the option loses **each day** if nothing else changes.

- Time is always working **against the buyer** and **for the seller**.
- Decay is slow far from expiry and **speeds up sharply in the last week**.
- That's why cheap weekly options bought "for fun" usually go to zero.

## Vega: sensitivity to volatility

How much the option's price changes when expected volatility (IV) changes.

- Before big events (Budget, elections, results), IV rises and premiums get expensive.
- After the event, IV collapses (**IV crush**). A buyer can be right about direction and still lose money.

## Gamma: how fast delta changes

High near expiry for ATM options. Small price moves cause big swings in P&L, which is great for buyers when they're right and brutal for sellers.

## Summary

| You are… | Time | Volatility rising | Big sudden move |
|---|---|---|---|
| Option **buyer** | Hurts | Helps | Helps |
| Option **seller** | Helps | Hurts | Hurts badly |

See theta in action in the **time decay** tool below.
