# Raven Cost Averaging

MetaTrader 5 multi-major grid hedge EA with broker-side Take Profit, chart control panel, and optional SMA200 M15 entry filter.

**Version:** 3.2  
**Platform:** MetaTrader 5 (MQL5)  
**Author:** [Randi Apriliyadi](https://github.com/randiapriliyadiR)

---

## Features

- **Multi-major** — one EA manages 7 majors (enable per pair)
- **Lot & Pip Step per pair** — independent spacing and lot size
- **Magic number per pair** — isolated positions and closed profit tracking
- **Symbol Suffix** — works with cent accounts (`c`) or other broker suffixes
- **SMA200 M15 entry filter** — initial Buy+Sell only when M15 candle touches SMA200 (default ON); grid layers unrestricted
- **Chart panel** — title, pause control, layers/lot/total float, per-pair table
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
2. Open MetaEditor → Compile (`F7`)
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

Trading always starts **paused** on first attach. Changing inputs keeps the current Pause/Resume state. While paused: no new entries/layers; TP sync and global TP still run.

### Entry Filter

| Parameter | Default | Description |
|-----------|---------|-------------|
| `UseSmaEntryFilter` | `true` | Initial entry only when M15 bar 0 high/low touches SMA200 |

Applies only to the first Buy+Sell when a pair is flat. Grid layers do not wait for SMA.

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

Each pair has: `Enable`, `Lot`, `Pip Step`, `Magic`.

Changing any input and confirming OK reloads runtime settings and refreshes the panel immediately.

### Max Layer Scope

| Option | Meaning |
|--------|---------|
| **Magic Only (this symbol)** | Count layers for this pair magic + symbol only |
| **All account trades** | Count all buy/sell positions on the account |

---

## Chart Panel

Top-left on the chart:

- Title: **Raven Cost Averaging v3.2**
- Credit: EA developed by Randi Apriliyadi - 2026
- Status: Pause / SMA Filter
- Layers, Lot, **Total Float** (green if ≥ 0, red if < 0)
- **PAUSE / RESUME** button
- Table: `Symbol | Magic | Lot | Pips | Buy | Sell | Float | Profit`

`Profit` is closed/realized P/L for that pair magic. Panel UI refresh is throttled (~250 ms); closed profit history is cached (~1.5 s).

---

## Trading Logic (summary)

```
OnInit
  ├─ Restore pause (if parameters changed) or start paused
  ├─ ApplyRuntimeSettings (pairs, SMA, TP sync, panel)
  └─ Timer 1s

OnTick / OnTimer
  └─ For each enabled pair:
       └─ Manage Grid
            ├─ Flat
            │    ├─ Paused? → skip
            │    ├─ SMA filter ON & no touch? → wait
            │    └─ Open Buy + Sell
            ├─ Has positions → Sync TP
            ├─ (!Paused) Grid layers (no SMA)
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
