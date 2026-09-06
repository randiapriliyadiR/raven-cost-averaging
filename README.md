# RAVEN TANAM

Expert Advisor (EA) MetaTrader 5 multi-major: grid hedge dengan basket close (opsional), Take Profit broker-side, panel kontrol, dan filter entry SMA200 M15.

**Versi:** 3.10  
**Platform:** MetaTrader 5 (MQL5)  
**Author:** [Randi Apriliyadi](https://github.com/randiapriliyadiR)

---

## Fitur Utama

- **Multi-major** — satu attach EA mengelola 7 major sekaligus (on/off per pair)
- **Lot & PipStep per pair** — jarak layer dan lot bisa beda tiap major
- **Magic number per pair** — posisi tiap pair terpisah
- **SymbolSuffix** — cocok untuk akun cent (`c`) atau suffix broker lain
- **Filter entry SMA200 M15** — entry awal Buy+Sell hanya saat candle M15 menyentuh SMA200 (default ON); layer grid tetap biasa
- **Panel chart** — status per pair, exposure, floating, tombol Pause/Resume
- **Max exposure** — batas total layer & total lot semua pair EA
- **Trading pause** — stop buka order baru tanpa detach EA (input + tombol chart)
- **Basket Close** — evaluasi **per pair**; target USD dari **satu** input bersama
- **TP Broker-side** — TP di server broker (tetap aktif meski EA mati)
- **OnTick + OnTimer** — pair non-chart tetap diproses setiap 1 detik
- **Trade Retry** — open / modify / close diulang maksimal 2x jika gagal

---

## Cara Install

1. Salin file `RAVEN TANAM.mq5` ke folder:
   ```
   MetaTrader 5\MQL5\Experts\
   ```
2. Buka MetaEditor → Compile (`F7`)
3. Restart MetaTrader 5 (atau refresh Navigator)
4. Drag EA ke **satu chart apa saja**
5. Atur parameter (enable pair, suffix, lot, PipStep), lalu klik **OK**

Pastikan:
- **AutoTrading** aktif
- Broker mengizinkan hedge (account hedging)
- Symbol major (+ suffix) ada di Market Watch

---

## Parameter Input

### Pengaturan Umum

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `AccountType` | Cents | Cent atau Standard (konversi target basket) |
| `MaxLayers` | `100` | Batas maksimum layer per arah (scope) |
| `MaxLayerScope` | Magic Only | Scope penghitungan batas layer |
| `SymbolSuffix` | `c` | Suffix symbol (cent → `EURUSDc`). Kosongkan jika tanpa suffix |

### Kontrol Operasi

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `TradingPause` | `false` | Pause buka order baru (tombol chart juga bisa toggle) |
| `MaxTotalLayers` | `50` | Maks total posisi EA di semua pair |
| `MaxTotalLots` | `10.0` | Maks total lot EA di semua pair |

Saat pause: tidak buka entry/layer baru; basket close, sync TP, dan TP global tetap jalan.

### Entry Filter

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `UseSmaEntryFilter` | `true` | Entry awal hanya jika high/low candle M15 bar 0 menyentuh SMA200 |

Filter ini **hanya** untuk initial Buy+Sell saat pair kosong. Layer berikutnya tidak menunggu SMA.

### Basket Close

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `UseBasketClose` | `true` | On/Off basket close |
| `BasketCloseUSD` | `20.0` | Target profit per pair (USD) |

Basket dievaluasi **per pair**. Jika EURUSD mencapai target, hanya posisi EURUSD yang ditutup.

### Default Per Pair

| Pair | Enable | Lot | PipStep | Magic |
|------|--------|-----|---------|-------|
| EURUSD | ON | 0.1 | 10 | 111111 |
| GBPUSD | ON | 0.1 | 14 | 222222 |
| USDCHF | ON | 0.1 | 9 | 333333 |
| NZDUSD | ON | 0.1 | 8 | 444444 |
| AUDUSD | ON | 0.1 | 9 | 555555 |
| USDJPY | ON | 0.1 | 130 | 666666 |
| USDCAD | ON | 0.1 | 11 | 777777 |

Tiap pair punya input: `Enable`, `Lot`, `PipStep`, `Magic`.

### Max Layer Scope

| Opsi | Arti |
|------|------|
| **Hanya Magic Number EA (Symbol Ini)** | Hitung layer hanya posisi magic + symbol pair itu |
| **Semua Trade di Akun** | Hitung semua posisi buy/sell di seluruh akun |

---

## Panel Chart

Di sudut kiri atas chart:

- Tombol **PAUSE / RESUME**
- Header: versi, status pause, SMA filter, exposure (layer/lot), floating total
- Baris per pair: `Symbol | ON/OFF | B/S | Float | SMA:WAIT/OK/- | last action`

Contoh `last action`: `Initial`, `GridBuy`, `GridSell`, `Basket`, `TP Buy`, `Pause`, `MaxExp`, `SMA wait`.

---

## Logika Trading (Ringkas)

```
OnInit
  ├─ Resolve symbol = base + SymbolSuffix → SymbolSelect
  ├─ Buat handle SMA200 M15 per pair
  ├─ Pasang TP ke posisi lama
  └─ Buat panel + tombol pause

OnTick / OnTimer(1s)
  └─ Untuk setiap pair ON:
       ├─ Basket close (jika ON)
       └─ Manage Grid
            ├─ Belum ada posisi
            │    ├─ Pause? → skip open
            │    ├─ SMA filter ON & belum sentuh? → tunggu
            │    ├─ Max exposure? → skip
            │    └─ Open Buy + Sell
            ├─ Ada posisi → Sync TP
            ├─ (!Pause) Layer grid seperti biasa (tanpa SMA)
            └─ TP global → Close arah tersebut
  └─ Update panel
```

### Anchor Entry

- **Buy anchor** = harga open Buy tertinggi (entry awal buy)
- **Sell anchor** = harga open Sell terendah (entry awal sell)
- Semua layer arah yang sama memakai **TP yang sama** berdasarkan anchor + `PipStep` pair itu

### Konversi Basket (Cent vs Standard)

| Account Type | Target `$20` dihitung sebagai |
|--------------|-------------------------------|
| Standard | `20` |
| Cent | `2000` (`20 × 100`) |

---

## Struktur File

```
RAVEN TANAM/
├── RAVEN TANAM.mq5   # Source code EA
├── RAVEN TANAM.ex5   # Binary (compile di MetaEditor)
└── README.md         # Dokumentasi ini
```

---

## Disclaimer

EA ini untuk tujuan edukasi dan eksperimen. Trading forex/CFD berisiko tinggi. Gunakan di akun demo dulu, uji parameter dengan hati-hati, dan bertanggung jawab penuh atas keputusan trading Anda.

---

## License

Proyek pribadi — © Randi Apriliyadi.  
Silakan sesuaikan license jika repo akan dipublikasikan secara terbuka.
