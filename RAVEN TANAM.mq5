//+------------------------------------------------------------------+
//|                                                  RAVEN TANAM.mq5 |
//|                                                 Randi Apriliyadi |
//|                              https://github.com/randiapriliyadiR |
//+------------------------------------------------------------------+
#property copyright "Randi Apriliyadi"
#property link      "https://github.com/randiapriliyadiR"
#property version   "3.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

#define PAIR_COUNT 7

//--- Enumerasi Tipe Akun
enum ENUM_ACCOUNT_TYPE
  {
   ACCOUNT_CENT,    // Cents
   ACCOUNT_STANDARD // Standard
  };

//--- Enumerasi Scope Max Layer
enum ENUM_MAX_LAYER_SCOPE
  {
   MAX_LAYER_MAGIC_ONLY,  // Hanya Magic Number EA (Symbol Ini)
   MAX_LAYER_ALL_ACCOUNT  // Semua Trade di Akun
  };

//--- Pair config runtime
struct PairConfig
  {
   string   base_symbol;
   bool     enabled;
   double   lot;
   int      pip_step;
   ulong    magic;
   string   resolved;
   datetime last_trade_time;
  };

//--- Input Parameters: Umum
input string               Deskripsi_Umum         = "=== Pengaturan Umum ===";
input ENUM_ACCOUNT_TYPE    AccountType            = ACCOUNT_CENT;        // Account Type
input int                  MaxLayers              = 100;                 // Max Layers
input ENUM_MAX_LAYER_SCOPE MaxLayerScope          = MAX_LAYER_MAGIC_ONLY; // Max Layer Scope
input string               SymbolSuffix           = "c";                 // Symbol Suffix (cent=c, kosong=tanpa)
input string               Deskripsi_Basket       = "=== Basket Close ===";
input bool                 UseBasketClose         = true;               // Aktifkan Basket Close
input double               BasketCloseUSD         = 20.0;                // Basket Close Profit Target (USD)

//--- EURUSD
input string               Deskripsi_EURUSD       = "=== EURUSD ===";
input bool                 EURUSD_Enable          = true;                // Enable EURUSD
input double               EURUSD_Lot             = 0.1;                 // Lot EURUSD
input int                  EURUSD_PipStep         = 10;                  // PipStep EURUSD
input ulong                EURUSD_Magic           = 111111;              // Magic EURUSD

//--- GBPUSD
input string               Deskripsi_GBPUSD       = "=== GBPUSD ===";
input bool                 GBPUSD_Enable          = true;                // Enable GBPUSD
input double               GBPUSD_Lot             = 0.1;                 // Lot GBPUSD
input int                  GBPUSD_PipStep         = 14;                  // PipStep GBPUSD
input ulong                GBPUSD_Magic           = 222222;              // Magic GBPUSD

//--- USDCHF
input string               Deskripsi_USDCHF       = "=== USDCHF ===";
input bool                 USDCHF_Enable          = true;                // Enable USDCHF
input double               USDCHF_Lot             = 0.1;                 // Lot USDCHF
input int                  USDCHF_PipStep         = 9;                   // PipStep USDCHF
input ulong                USDCHF_Magic           = 333333;              // Magic USDCHF

//--- NZDUSD
input string               Deskripsi_NZDUSD       = "=== NZDUSD ===";
input bool                 NZDUSD_Enable          = true;                // Enable NZDUSD
input double               NZDUSD_Lot             = 0.1;                 // Lot NZDUSD
input int                  NZDUSD_PipStep         = 8;                   // PipStep NZDUSD
input ulong                NZDUSD_Magic           = 444444;              // Magic NZDUSD

//--- AUDUSD
input string               Deskripsi_AUDUSD       = "=== AUDUSD ===";
input bool                 AUDUSD_Enable          = true;                // Enable AUDUSD
input double               AUDUSD_Lot             = 0.1;                 // Lot AUDUSD
input int                  AUDUSD_PipStep         = 9;                   // PipStep AUDUSD
input ulong                AUDUSD_Magic           = 555555;              // Magic AUDUSD

//--- USDJPY
input string               Deskripsi_USDJPY       = "=== USDJPY ===";
input bool                 USDJPY_Enable          = true;                // Enable USDJPY
input double               USDJPY_Lot             = 0.1;                 // Lot USDJPY
input int                  USDJPY_PipStep         = 13;                  // PipStep USDJPY
input ulong                USDJPY_Magic           = 666666;              // Magic USDJPY

//--- USDCAD
input string               Deskripsi_USDCAD       = "=== USDCAD ===";
input bool                 USDCAD_Enable          = true;                // Enable USDCAD
input double               USDCAD_Lot             = 0.1;                 // Lot USDCAD
input int                  USDCAD_PipStep         = 11;                  // PipStep USDCAD
input ulong                USDCAD_Magic           = 777777;              // Magic USDCAD

//--- Global Variables
CTrade         trade;
CPositionInfo  m_position;
PairConfig     g_pairs[PAIR_COUNT];
const int      TRADE_RETRY_COUNT = 2; // 1 percobaan awal + 2 retry

void ProcessAllPairs();
void ApplyTPToExistingEAOrders(const int pair_index);
void ManageGridAndGlobalTP(const int pair_index);
void CheckBasketProfit(const int pair_index);
void SyncBasketTP(const string symbol, const ulong magic, const double first_buy_price, const double first_sell_price, const double gap);
void GetLayerCounts(const string symbol, const ulong magic, int &buy_layers, int &sell_layers);
void CloseAllDirection(const string symbol, const ulong magic, ENUM_POSITION_TYPE type);
void CloseAllEAOrders(const string symbol, const ulong magic);
double PipToPrice(const string symbol, const double pips);
double NormalizeLot(const string symbol, double lot);
void SetTradeMagic(const ulong magic);

//+------------------------------------------------------------------+
//| Set magic sebelum operasi trade                                   |
//+------------------------------------------------------------------+
void SetTradeMagic(const ulong magic)
  {
   trade.SetExpertMagicNumber(magic);
  }

//+------------------------------------------------------------------+
//| Wrapper trade dengan retry terbatas                              |
//+------------------------------------------------------------------+
bool BuyWithRetry(double lot, string symbol, double price, double sl, double tp, string comment)
  {
   for(int attempt = 0; attempt <= TRADE_RETRY_COUNT; attempt++)
     {
      if(trade.Buy(lot, symbol, price, sl, tp, comment))
         return true;

      if(attempt < TRADE_RETRY_COUNT)
         Print("Buy retry ", attempt + 1, "/", TRADE_RETRY_COUNT, " ", symbol,
               ". Retcode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }

   Print("Buy gagal setelah ", TRADE_RETRY_COUNT + 1, " percobaan. ", symbol,
         " Retcode: ", trade.ResultRetcode());
   return false;
  }

bool SellWithRetry(double lot, string symbol, double price, double sl, double tp, string comment)
  {
   for(int attempt = 0; attempt <= TRADE_RETRY_COUNT; attempt++)
     {
      if(trade.Sell(lot, symbol, price, sl, tp, comment))
         return true;

      if(attempt < TRADE_RETRY_COUNT)
         Print("Sell retry ", attempt + 1, "/", TRADE_RETRY_COUNT, " ", symbol,
               ". Retcode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }

   Print("Sell gagal setelah ", TRADE_RETRY_COUNT + 1, " percobaan. ", symbol,
         " Retcode: ", trade.ResultRetcode());
   return false;
  }

bool PositionModifyWithRetry(ulong ticket, double sl, double tp)
  {
   for(int attempt = 0; attempt <= TRADE_RETRY_COUNT; attempt++)
     {
      if(trade.PositionModify(ticket, sl, tp))
         return true;

      if(attempt < TRADE_RETRY_COUNT)
         Print("Modify retry ", attempt + 1, "/", TRADE_RETRY_COUNT, " ticket ", ticket,
               ". Retcode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }

   Print("Modify gagal setelah ", TRADE_RETRY_COUNT + 1, " percobaan. Ticket: ", ticket,
         " Retcode: ", trade.ResultRetcode());
   return false;
  }

bool PositionCloseWithRetry(ulong ticket)
  {
   for(int attempt = 0; attempt <= TRADE_RETRY_COUNT; attempt++)
     {
      if(!PositionSelectByTicket(ticket))
         return true;

      if(trade.PositionClose(ticket))
         return true;

      if(attempt < TRADE_RETRY_COUNT)
         Print("Close retry ", attempt + 1, "/", TRADE_RETRY_COUNT, " ticket ", ticket,
               ". Retcode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }

   Print("Close gagal setelah ", TRADE_RETRY_COUNT + 1, " percobaan. Ticket: ", ticket,
         " Retcode: ", trade.ResultRetcode());
   return false;
  }

//+------------------------------------------------------------------+
//| Normalisasi lot sesuai spesifikasi symbol                        |
//+------------------------------------------------------------------+
double NormalizeLot(const string symbol, double lot)
  {
   double vmin  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

   if(vstep <= 0.0)
      vstep = 0.01;

   lot = MathFloor(lot / vstep + 1e-8) * vstep;
   if(lot < vmin)
      lot = vmin;
   if(lot > vmax)
      lot = vmax;

   int digits = 0;
   double step = vstep;
   while(step < 1.0 && digits < 8)
     {
      step *= 10.0;
      digits++;
     }

   return NormalizeDouble(lot, digits);
  }

//+------------------------------------------------------------------+
//| Isi array pair dari input                                        |
//+------------------------------------------------------------------+
void InitPairConfigs()
  {
   g_pairs[0].base_symbol = "EURUSD";
   g_pairs[0].enabled     = EURUSD_Enable;
   g_pairs[0].lot         = EURUSD_Lot;
   g_pairs[0].pip_step    = EURUSD_PipStep;
   g_pairs[0].magic       = EURUSD_Magic;

   g_pairs[1].base_symbol = "GBPUSD";
   g_pairs[1].enabled     = GBPUSD_Enable;
   g_pairs[1].lot         = GBPUSD_Lot;
   g_pairs[1].pip_step    = GBPUSD_PipStep;
   g_pairs[1].magic       = GBPUSD_Magic;

   g_pairs[2].base_symbol = "USDCHF";
   g_pairs[2].enabled     = USDCHF_Enable;
   g_pairs[2].lot         = USDCHF_Lot;
   g_pairs[2].pip_step    = USDCHF_PipStep;
   g_pairs[2].magic       = USDCHF_Magic;

   g_pairs[3].base_symbol = "NZDUSD";
   g_pairs[3].enabled     = NZDUSD_Enable;
   g_pairs[3].lot         = NZDUSD_Lot;
   g_pairs[3].pip_step    = NZDUSD_PipStep;
   g_pairs[3].magic       = NZDUSD_Magic;

   g_pairs[4].base_symbol = "AUDUSD";
   g_pairs[4].enabled     = AUDUSD_Enable;
   g_pairs[4].lot         = AUDUSD_Lot;
   g_pairs[4].pip_step    = AUDUSD_PipStep;
   g_pairs[4].magic       = AUDUSD_Magic;

   g_pairs[5].base_symbol = "USDJPY";
   g_pairs[5].enabled     = USDJPY_Enable;
   g_pairs[5].lot         = USDJPY_Lot;
   g_pairs[5].pip_step    = USDJPY_PipStep;
   g_pairs[5].magic       = USDJPY_Magic;

   g_pairs[6].base_symbol = "USDCAD";
   g_pairs[6].enabled     = USDCAD_Enable;
   g_pairs[6].lot         = USDCAD_Lot;
   g_pairs[6].pip_step    = USDCAD_PipStep;
   g_pairs[6].magic       = USDCAD_Magic;

   for(int i = 0; i < PAIR_COUNT; i++)
     {
      g_pairs[i].resolved        = g_pairs[i].base_symbol + SymbolSuffix;
      g_pairs[i].last_trade_time = 0;
     }
  }

//+------------------------------------------------------------------+
//| Resolve symbol ke Market Watch; disable jika gagal               |
//+------------------------------------------------------------------+
void ResolvePairSymbols()
  {
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(!g_pairs[i].enabled)
         continue;

      string symbol = g_pairs[i].resolved;

      if(!SymbolSelect(symbol, true))
        {
         Print("Symbol tidak ditemukan / gagal Select: ", symbol,
               " — pair ", g_pairs[i].base_symbol, " dinonaktifkan.");
         g_pairs[i].enabled = false;
         continue;
        }

      if(!SymbolInfoInteger(symbol, SYMBOL_SELECT))
        {
         Print("Symbol tidak tersedia: ", symbol,
               " — pair ", g_pairs[i].base_symbol, " dinonaktifkan.");
         g_pairs[i].enabled = false;
         continue;
        }

      Print("Pair aktif: ", symbol, " | Lot=", g_pairs[i].lot,
            " | PipStep=", g_pairs[i].pip_step, " | Magic=", g_pairs[i].magic);
     }
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   InitPairConfigs();
   ResolvePairSymbols();

   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(g_pairs[i].enabled)
         ApplyTPToExistingEAOrders(i);
     }

   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   ProcessAllPairs();
  }

//+------------------------------------------------------------------+
//| Timer — pastikan pair non-chart tetap diproses                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ProcessAllPairs();
  }

//+------------------------------------------------------------------+
//| Proses semua pair yang aktif                                     |
//+------------------------------------------------------------------+
void ProcessAllPairs()
  {
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(!g_pairs[i].enabled)
         continue;

      if(UseBasketClose)
         CheckBasketProfit(i);

      ManageGridAndGlobalTP(i);
     }
  }

//+------------------------------------------------------------------+
//| Sinkronisasi TP agar tetap aktif walau EA mati                   |
//+------------------------------------------------------------------+
void SyncBasketTP(const string symbol, const ulong magic,
                  const double first_buy_price, const double first_sell_price, const double gap)
  {
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   double target_buy_tp = 0.0;
   double target_sell_tp = 0.0;

   if(first_buy_price > 0.0)
      target_buy_tp = NormalizeDouble(first_buy_price + gap, digits);
   if(first_sell_price > 0.0)
      target_sell_tp = NormalizeDouble(first_sell_price - gap, digits);

   SetTradeMagic(magic);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() != symbol || m_position.Magic() != magic)
         continue;

      double current_sl = m_position.StopLoss();
      double current_tp = m_position.TakeProfit();
      ulong ticket = m_position.Ticket();

      if(m_position.PositionType() == POSITION_TYPE_BUY && target_buy_tp > 0.0)
        {
         if(MathAbs(current_tp - target_buy_tp) > (point / 2.0))
            PositionModifyWithRetry(ticket, current_sl, target_buy_tp);
        }
      else if(m_position.PositionType() == POSITION_TYPE_SELL && target_sell_tp > 0.0)
        {
         if(MathAbs(current_tp - target_sell_tp) > (point / 2.0))
            PositionModifyWithRetry(ticket, current_sl, target_sell_tp);
        }
     }
  }

//+------------------------------------------------------------------+
//| Pasang TP untuk posisi lama saat EA attach/restart               |
//+------------------------------------------------------------------+
void ApplyTPToExistingEAOrders(const int pair_index)
  {
   string symbol = g_pairs[pair_index].resolved;
   ulong  magic  = g_pairs[pair_index].magic;
   int    pip_step = g_pairs[pair_index].pip_step;

   double anchor_buy_price = 0.0;
   double anchor_sell_price = 0.0;
   int total_buys = 0;
   int total_sells = 0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() != symbol || m_position.Magic() != magic)
         continue;

      double open_price = m_position.PriceOpen();

      if(m_position.PositionType() == POSITION_TYPE_BUY)
        {
         total_buys++;
         if(anchor_buy_price == 0.0 || open_price > anchor_buy_price)
            anchor_buy_price = open_price;
        }
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
        {
         total_sells++;
         if(anchor_sell_price == 0.0 || open_price < anchor_sell_price)
            anchor_sell_price = open_price;
        }
     }

   if(total_buys > 0 || total_sells > 0)
     {
      double gap = PipToPrice(symbol, pip_step);
      SyncBasketTP(symbol, magic, anchor_buy_price, anchor_sell_price, gap);
     }
  }

//+------------------------------------------------------------------+
//| Fungsi Konversi Pip ke Nilai Harga (per symbol)                  |
//+------------------------------------------------------------------+
double PipToPrice(const string symbol, const double pips)
  {
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   if(digits == 3 || digits == 5)
      return pips * 10.0 * point;
   return pips * point;
  }

//+------------------------------------------------------------------+
//| Cek profit basket per pair                                       |
//+------------------------------------------------------------------+
void CheckBasketProfit(const int pair_index)
  {
   if(!UseBasketClose)
      return;

   string symbol = g_pairs[pair_index].resolved;
   ulong  magic  = g_pairs[pair_index].magic;

   double target_value = 0.0;

   if(AccountType == ACCOUNT_CENT)
      target_value = BasketCloseUSD * 100.0;
   else
      target_value = BasketCloseUSD;

   double basket_profit = 0.0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() == symbol && m_position.Magic() == magic)
         basket_profit += m_position.Profit() + m_position.Swap() + m_position.Commission();
     }

   if(basket_profit >= target_value)
     {
      CloseAllEAOrders(symbol, magic);
      Print("Basket close tercapai [", symbol, "]. Total profit: ", basket_profit,
            " | Target: ", target_value);
     }
  }

//+------------------------------------------------------------------+
//| Hitung jumlah layer buy/sell sesuai scope MaxLayers              |
//+------------------------------------------------------------------+
void GetLayerCounts(const string symbol, const ulong magic, int &buy_layers, int &sell_layers)
  {
   buy_layers = 0;
   sell_layers = 0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(MaxLayerScope == MAX_LAYER_MAGIC_ONLY)
        {
         if(m_position.Symbol() != symbol || m_position.Magic() != magic)
            continue;
        }

      if(m_position.PositionType() == POSITION_TYPE_BUY)
         buy_layers++;
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
         sell_layers++;
     }
  }

//+------------------------------------------------------------------+
//| Manajemen Grid Layering dan TP Global per pair                   |
//+------------------------------------------------------------------+
void ManageGridAndGlobalTP(const int pair_index)
  {
   string symbol   = g_pairs[pair_index].resolved;
   ulong  magic    = g_pairs[pair_index].magic;
   double lot      = NormalizeLot(symbol, g_pairs[pair_index].lot);
   int    pip_step = g_pairs[pair_index].pip_step;
   int    digits   = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);

   int total_buys = 0;
   int total_sells = 0;
   int buy_layer_count = 0;
   int sell_layer_count = 0;

   double anchor_buy_price = 0.0;
   double lowest_buy_price = 999999.0;
   double anchor_sell_price = 0.0;
   double highest_sell_price = 0.0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() != symbol || m_position.Magic() != magic)
         continue;

      double open_price = m_position.PriceOpen();

      if(m_position.PositionType() == POSITION_TYPE_BUY)
        {
         total_buys++;
         if(anchor_buy_price == 0.0 || open_price > anchor_buy_price)
            anchor_buy_price = open_price;
         if(open_price < lowest_buy_price)
            lowest_buy_price = open_price;
        }
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
        {
         total_sells++;
         if(anchor_sell_price == 0.0 || open_price < anchor_sell_price)
            anchor_sell_price = open_price;
         if(open_price > highest_sell_price)
            highest_sell_price = open_price;
        }
     }

   GetLayerCounts(symbol, magic, buy_layer_count, sell_layer_count);

   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   if(ask <= 0.0 || bid <= 0.0)
      return;

   double gap = PipToPrice(symbol, pip_step);

   SetTradeMagic(magic);

   // --- ATURAN 1: KONDISI AWAL (Langsung Open Buy & Sell) ---
   if(total_buys == 0 && total_sells == 0)
     {
      if(buy_layer_count < MaxLayers && sell_layer_count < MaxLayers)
        {
         if(TimeCurrent() - g_pairs[pair_index].last_trade_time > 3)
           {
            double initial_buy_tp = NormalizeDouble(ask + gap, digits);
            double initial_sell_tp = NormalizeDouble(bid - gap, digits);

            BuyWithRetry(lot, symbol, ask, 0, initial_buy_tp, "Initial Buy");
            SellWithRetry(lot, symbol, bid, 0, initial_sell_tp, "Initial Sell");
            g_pairs[pair_index].last_trade_time = TimeCurrent();
           }
        }
      return;
     }

   SyncBasketTP(symbol, magic, anchor_buy_price, anchor_sell_price, gap);

   // --- ATURAN 2: GRID LAYERING ---
   if(total_buys > 0 && buy_layer_count < MaxLayers && ask <= (lowest_buy_price - gap))
     {
      if(TimeCurrent() - g_pairs[pair_index].last_trade_time > 3)
        {
         double grid_buy_tp = NormalizeDouble(anchor_buy_price + gap, digits);
         BuyWithRetry(lot, symbol, ask, 0, grid_buy_tp, "Grid Buy Layer");
         g_pairs[pair_index].last_trade_time = TimeCurrent();
        }
     }

   if(total_sells > 0 && sell_layer_count < MaxLayers && bid >= (highest_sell_price + gap))
     {
      if(TimeCurrent() - g_pairs[pair_index].last_trade_time > 3)
        {
         double grid_sell_tp = NormalizeDouble(anchor_sell_price - gap, digits);
         SellWithRetry(lot, symbol, bid, 0, grid_sell_tp, "Grid Sell Layer");
         g_pairs[pair_index].last_trade_time = TimeCurrent();
        }
     }

   // --- ATURAN 3: TP GLOBAL ---
   if(total_buys > 0)
     {
      double global_tp_buy = anchor_buy_price + PipToPrice(symbol, pip_step);
      if(bid >= global_tp_buy)
        {
         CloseAllDirection(symbol, magic, POSITION_TYPE_BUY);
         Print("TP Global Buy Terpenuhi [", symbol, "].");
        }
     }

   if(total_sells > 0)
     {
      double global_tp_sell = anchor_sell_price - PipToPrice(symbol, pip_step);
      if(ask <= global_tp_sell)
        {
         CloseAllDirection(symbol, magic, POSITION_TYPE_SELL);
         Print("TP Global Sell Terpenuhi [", symbol, "].");
        }
     }
  }

//+------------------------------------------------------------------+
//| Mass Close Per Arah Posisi                                       |
//+------------------------------------------------------------------+
void CloseAllDirection(const string symbol, const ulong magic, ENUM_POSITION_TYPE type)
  {
   SetTradeMagic(magic);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() == symbol && m_position.Magic() == magic && m_position.PositionType() == type)
         PositionCloseWithRetry(m_position.Ticket());
     }
  }

//+------------------------------------------------------------------+
//| Mass Close Semua Posisi EA untuk pair                            |
//+------------------------------------------------------------------+
void CloseAllEAOrders(const string symbol, const ulong magic)
  {
   SetTradeMagic(magic);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() == symbol && m_position.Magic() == magic)
         PositionCloseWithRetry(m_position.Ticket());
     }
  }
//+------------------------------------------------------------------+
