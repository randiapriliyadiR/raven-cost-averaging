# Raven Cost Averaging

MetaTrader 5 multi-major grid hedge EA with broker-side Take Profit, chart control panel, and a daily-pivot filter for the first entry.

**Version:** 3.7  
**Platform:** MetaTrader 5 (MQL5)  
**Author:** [Randi Apriliyadi](https://github.com/randiapriliyadiR)

---

## Features

- **Multi-pair** — 7 majors start on; 10 crosses start off
- **Lot & Pip Step per pair** — independent spacing and lot size
- **Magic number per pair** — isolated positions and closed profit tracking
- **Symbol Suffix** — works with cent accounts (`c`) or other broker suffixes
- **Daily pivot entry** — optional; when ON, initial Buy+Sell only when the live mid price is within 2 pips of yesterday’s daily pivot `(High + Low + Close) / 3`; default OFF; grid layers unrestricted
- **Chart panel** — title, pause and pivot controls, layers/lot/total float, per-pair table
- **Max Layers** — optional per-direction cap (`0` = unlimited)
- **Trading pause** — starts paused; resume from chart button (no input)
- **Broker-side TP** — remains active even if EA is detached
- **OnTick + OnTimer** — non-chart pairs processed every 1 second
- **Trade retry** — open / modify / close retried up to 2 times on failure

---

## Install

1. Copy `Raven Cost Averaging.mq5` into:
   ```
   MetaTrader 5\MQL5\Experts\
   ```
2. Compile (required before commit/release):
   ```powershell
   .\compile.ps1
   ```
   Or MetaEditor → Compile (`F7`). Must show **0 errors**.
3. Restart MetaTrader 5 (or refresh Navigator)
4. Attach the EA to **any single chart**
5. Set parameters (pair enable, suffix, lot, pip step), then click **OK**
6. Press **RESUME** on the panel to allow new entries

Requirements:

- **AutoTrading** enabled
- Hedging account
- Major symbols (+ suffix) visible in Market Watch

---

## Inputs

### General

| Parameter | Default | Description |
|-----------|---------|-------------|
| `MaxLayers` | `0` | Max layers per direction (`0` = no limit) |
| `MaxLayerScope` | Magic Only | How layer counts are measured |
| `SymbolSuffix` | `c` | Symbol suffix (`EURUSDc`). Leave empty if none |

### Operations

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ShowPanel` | `true` | Show/hide chart panel |
| `PanelRemark` | empty | Optional label in the top-right of the panel. Red text. Leave blank to show nothing |
| `ForceActive` | `false` | Start trading immediately. Use `true` in the tester, where the panel button cannot be clicked |

Trading starts **paused** on first attach when `ForceActive` is false. Changing other inputs keeps the current Pause/Resume state. While paused: no new entries/layers; TP sync and global TP still run.

### Entry filter

| Parameter | Default | Description |
|-----------|---------|-------------|
| `UsePivotEntryFilter` | `false` | Daily pivot filter for the first Buy+Sell. Also toggled from the panel button |

When the filter is OFF, a flat pair can open the first Buy+Sell without waiting for the pivot. When ON, entry waits until the live mid price is within 2 pips of yesterday’s daily pivot:

```
pivot = (High + Low + Close) of yesterday’s Daily candle / 3
mid   = (Bid + Ask) / 2
entry = absolute distance from mid to pivot <= 2 pips
```

A wick that touched the pivot earlier in the minute does not count. The orders are sent only while the live price is still inside that 2-pip band. If yesterday’s high, low, or close is missing while the filter is ON, the pair waits. After the basket closes, a new initial entry waits until price returns to that band when the filter is ON. Grid layers do not use this filter. Confirming OK on inputs reloads the input default; the panel **Pivot ON/OFF** button toggles it live.

### Default Per Pair

| Pair | Enable | Lot | Pip Step | Magic |
|------|--------|-----|----------|-------|
| EURUSD | ON | 0.1 | 10 | 111111 |
| GBPUSD | ON | 0.1 | 14 | 222222 |
| USDCHF | ON | 0.1 | 9 | 333333 |
| NZDUSD | ON | 0.1 | 8 | 444444 |
| AUDUSD | ON | 0.1 | 9 | 555555 |
| USDJPY | ON | 0.1 | 130 | 666666 |
| USDCAD | ON | 0.1 | 11 | 777777 |
| AUDCAD | OFF | 0.1 | 12 | 888888 |
| NZDCAD | OFF | 0.1 | 12 | 999999 |
| EURAUD | OFF | 0.1 | 16 | 121212 |
| GBPCAD | OFF | 0.1 | 18 | 131313 |
| AUDJPY | OFF | 0.1 | 110 | 141414 |
| CADCHF | OFF | 0.1 | 12 | 151515 |
| AUDCHF | OFF | 0.1 | 12 | 161616 |
| CADJPY | OFF | 0.1 | 110 | 171717 |
| GBPAUD | OFF | 0.1 | 18 | 181818 |
| EURCAD | OFF | 0.1 | 14 | 191919 |

Cross pip steps are starter values. The table lists only pairs whose Enable is true. A pair set to false stays out of the table and is not traded.

Changing any input and confirming OK reloads runtime settings and refreshes the panel immediately.

### Max Layers

The cap is **per side**. Buy positions and Sell positions are counted apart. `0` means no cap.

| Scope | What the cap counts |
|--------|---------------------|
| **Per pair (symbol + magic)** | Each pair can open up to `Max Layers` Buys and `Max Layers` Sells of its own |
| **Whole account** | Every Buy on the account shares one cap, and every Sell shares one cap. Trades from outside this EA count too |

A side that has reached the cap gets no new order. The other side, take profit, and pause still run. The first Buy+Sell is allowed when both sides are still under the cap.

The panel count on the left is every open position of this EA. The text after it is the cap, for example `Layers  14   10/side per pair`. That 14 is not “14 out of 10.”

---

## Chart Panel

Top-left on the chart:

- Title: **RAVEN COST AVERAGING V3.7** in gold
- Optional **Panel Remark** at the top-right, red, hidden when the input is empty
- Credit: EA developed by Randi Apriliyadi - 2026
- Status: **Active** / **Paused** and **Pivot ON** / **OFF**
- **Layers** (open positions of this EA, plus the per-side cap and its scope when a limit is set), Lot, **Total Float** (green if ≥ 0, red if < 0)
- Compact **Pause** / **Resume** and **Pivot ON** / **Pivot OFF** buttons
- Table sized to the enabled pairs only
- **Pivot** column: while a pair is flat, signed distance in pips from the mid price to yesterday’s daily pivot (`+` = price above the pivot, `-` = price below). When the filter is ON, the first entry fires when that absolute value is 2.0 or less. A basket in progress shows `-` because the filter no longer applies

`Profit` is closed/realized P/L for that pair magic. `Pips` is that pair’s grid step, not the distance to the pivot. Panel UI refresh is throttled (~250 ms); closed profit history is cached (~1.5 s).

---

## Trading Logic (summary)

```
OnInit
  ├─ Restore pause (if parameters changed) or start paused
  ├─ ApplyRuntimeSettings (pairs, TP sync, panel)
  └─ Timer 1s

OnTick / OnTimer
  └─ For each enabled pair:
       └─ Manage Grid
            ├─ Flat
            │    ├─ Paused? → skip
            │    ├─ Pivot filter ON & live mid more than 2 pips away? → wait
            │    └─ Open Buy + Sell
            ├─ Has positions → Sync TP
            ├─ (!Paused) Grid layers (no pivot filter)
            └─ Global TP → close that direction
  └─ MaybeUpdatePanel
```

### Anchor entry

- **Buy anchor** = highest Buy open price
- **Sell anchor** = lowest Sell open price
- Same-direction layers share TP from anchor + pair `Pip Step`

---

## Files

```
Raven Cost Averaging/
├── Raven Cost Averaging.mq5    # EA source
├── Raven Cost Averaging.mqproj # MetaEditor project
├── Raven Cost Averaging.ex5    # Binary (after compile)
└── README.md
```

---

## Disclaimer

For education and experimentation. Forex/CFD trading involves substantial risk. Test on demo first and take full responsibility for your trading decisions.

---

## License

Private project — © Randi Apriliyadi.
