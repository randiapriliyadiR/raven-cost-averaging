# RAVEN TANAM

Expert Advisor (EA) MetaTrader 5 untuk strategi grid hedge dengan basket close dan Take Profit broker-side.

**Versi:** 2.00  
**Platform:** MetaTrader 5 (MQL5)  
**Author:** [Randi Apriliyadi](https://github.com/randiapriliyadiR)

---

## Fitur Utama

- **Entry awal hedge** — membuka Buy + Sell secara bersamaan saat belum ada posisi EA
- **Grid layering** — menambah layer Buy saat harga turun / Sell saat harga naik (jarak `PipStep`)
- **Basket Close** — menutup semua posisi EA jika total profit basket mencapai target USD (bisa on/off)
- **TP Broker-side** — setiap posisi mendapat Take Profit di server broker (tetap aktif meski EA mati/disconnect)
- **TP untuk posisi lama** — saat EA di-attach/restart, posisi yang sudah ada langsung dipasangi TP
- **Max Layer Scope** — batas layer bisa dihitung dari Magic Number saja atau semua trade di akun
- **Trade Retry** — open / modify / close otomatis diulang maksimal 2x jika gagal

---

## Cara Install

1. Salin file `RAVEN TANAM.mq5` ke folder:
   ```
   MetaTrader 5\MQL5\Experts\
   ```
2. Buka MetaEditor → Compile (`F7`)
3. Restart MetaTrader 5 (atau refresh Navigator)
4. Drag EA ke chart yang diinginkan
5. Atur parameter input, lalu klik **OK**

Pastikan:
- **AutoTrading** aktif
- Broker mengizinkan hedge (account hedging)

---

## Parameter Input

### Pengaturan Dasar

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `AccountType` | Cents | Tipe akun: **Cents** atau **Standard** (pengaruh konversi target basket) |
| `BaseLot` | `0.1` | Lot per trade |
| `PipStep` | `10` | Jarak antar layer + jarak TP dari entry awal (pips) |
| `MaxLayers` | `100` | Batas maksimum layer |
| `MaxLayerScope` | Magic Only | Scope penghitungan batas layer |
| `MagicNumber` | `111111` | Magic number unik EA |

### Basket Close

| Parameter | Default | Keterangan |
|-----------|---------|------------|
| `UseBasketClose` | `true` | On/Off fitur basket close |
| `BasketCloseUSD` | `20.0` | Target profit total basket (USD) |

### Max Layer Scope

| Opsi | Arti |
|------|------|
| **Hanya Magic Number EA (Symbol Ini)** | Hitung layer hanya posisi EA di symbol chart |
| **Semua Trade di Akun** | Hitung semua posisi buy/sell yang terbuka di seluruh akun |

---

## Logika Trading (Ringkas)

```
OnInit
  └─ Pasang TP ke posisi EA yang sudah ada

OnTick
  ├─ [Jika UseBasketClose ON]
  │    └─ Total profit basket >= target → Close semua posisi EA
  └─ Manage Grid
       ├─ Belum ada posisi → Open Buy + Sell (dengan TP)
       ├─ Sinkronkan TP semua layer ke anchor entry awal
       ├─ Harga turun PipStep dari buy terendah → Layer Buy baru
       ├─ Harga naik PipStep dari sell tertinggi → Layer Sell baru
       └─ Harga mencapai TP global → Close arah tersebut
```

### Anchor Entry

- **Buy anchor** = harga open Buy tertinggi (entry awal buy)
- **Sell anchor** = harga open Sell terendah (entry awal sell)
- Semua layer arah yang sama memakai **TP yang sama** berdasarkan anchor + `PipStep`

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
└── README.md         # Dokumentasi ini
```

---

## Upload ke GitHub

### Opsi A — Repository baru (disarankan)

```bash
cd "path/ke/RAVEN TANAM"
git init
git add "RAVEN TANAM.mq5" README.md
git commit -m "Initial commit: RAVEN TANAM EA v2.00"
git branch -M main
git remote add origin https://github.com/USERNAME/REPO_NAME.git
git push -u origin main
```

### Opsi B — Tambah ke repo yang sudah ada

```bash
git add "RAVEN TANAM.mq5" README.md
git commit -m "Add RAVEN TANAM EA v2.00"
git push
```

### Catatan sebelum push

- Jangan commit file `.ex5` (hasil compile) kecuali memang ingin menyertakan binary
- Jangan commit data akun, login, atau file terminal pribadi
- Pastikan `MagicNumber` default aman / diganti sesuai kebutuhan sebelum live

---

## Disclaimer

EA ini untuk tujuan edukasi dan eksperimen. Trading forex/CFD berisiko tinggi. Gunakan di akun demo dulu, uji parameter dengan hati-hati, dan bertanggung jawab penuh atas keputusan trading Anda.

---

## License

Proyek pribadi — © Randi Apriliyadi.  
Silakan sesuaikan license jika repo akan dipublikasikan secara terbuka.
