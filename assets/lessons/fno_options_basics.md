# Options: calls and puts

An option gives the buyer the **right, but not the obligation**, to buy or sell at a set price (the **strike**) on or before expiry. The buyer pays a **premium** to the seller for this right.

## Calls and puts

| | **Call** | **Put** |
|---|---|---|
| Buyer's right | Buy at the strike | Sell at the strike |
| Buyer wants | Price to go **up** | Price to go **down** |
| Buyer's max loss | Premium paid | Premium paid |
| Seller's max loss | **Unlimited** | Very large (strike − premium) |

## Example

Nifty is at 24,000. You buy a **24,000 call** for ₹200 (× 75 lot = ₹15,000).

- Nifty expires at 24,600 → worth 600 → profit (600 − 200) × 75 = **₹30,000**
- Nifty expires at 24,200 → worth 200 → you break even
- Nifty expires at 23,800 → worth 0 → you lose the full **₹15,000**

The **breakeven** is strike + premium = 24,200. Nifty doesn't just have to rise. It has to rise **enough, and soon enough**.

## Moneyness

- **ITM (in the money)**: it would be worth something if it expired now (a call with strike below the price).
- **ATM (at the money)**: strike ≈ current price.
- **OTM (out of the money)**: worth nothing if it expired now (a call with strike above the price). Cheap, and it usually expires worthless.

## What the premium is made of

Premium = **intrinsic value** (how far ITM it is) + **time value** (the chance it could still become profitable). Time value shrinks to zero by expiry. That's *theta*, covered in the next lesson.

Open the **payoff visualiser** and pick "Buy Call", then "Buy Put", to see these shapes.
