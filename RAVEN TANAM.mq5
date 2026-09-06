//+------------------------------------------------------------------+
//|                                                  RAVEN TANAM.mq5 |
//|                                                 Randi Apriliyadi |
//|                              https://github.com/randiapriliyadiR |
//+------------------------------------------------------------------+
#property copyright "Randi Apriliyadi"
#property link      "https://github.com/randiapriliyadiR"
#property version   "3.10"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

#define PAIR_COUNT 7
#define SMA_PERIOD 200
#define PANEL_PREFIX "RT_"
#define BTN_PAUSE    "RT_BTN_PAUSE"
#define PANEL_BG     "RT_BG"
#define PANEL_X      8
#define PANEL_Y      12
#define PANEL_W      560
#define PANEL_H      200

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
   string   last_action;
   int      sma_handle;
   string   sma_status;   // WAIT / OK / -
  };

//--- Input Parameters: Umum
input string               Deskripsi_Umum         = "=== Pengaturan Umum ===";
input ENUM_ACCOUNT_TYPE    AccountType            = ACCOUNT_CENT;        // Account Type
input int                  MaxLayers              = 100;                 // Max Layers
input ENUM_MAX_LAYER_SCOPE MaxLayerScope          = MAX_LAYER_MAGIC_ONLY; // Max Layer Scope
input string               SymbolSuffix           = "c";                 // Symbol Suffix (cent=c, kosong=tanpa)

input string               Deskripsi_Ops          = "=== Kontrol Operasi ===";
input bool                 TradingPause           = false;               // Pause Trading (no new opens)
input int                  MaxTotalLayers         = 50;                  // Max Total Layers (all pairs)
input double               MaxTotalLots           = 10.0;                // Max Total Lots (all pairs)

input string               Deskripsi_Entry        = "=== Entry Filter ===";
input bool                 UseSmaEntryFilter      = true;                // Entry awal hanya saat sentuh SMA200 M15

input string               Deskripsi_Basket       = "=== Basket Close ===";
input bool                 UseBasketClose         = true;                // Aktifkan Basket Close
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
input int                  USDJPY_PipStep         = 130;                 // PipStep USDJPY
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
bool           g_trading_pause = false;
const int      TRADE_RETRY_COUNT = 2;

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
bool IsEaMagic(const ulong magic);
void GetEaExposure(int &layers, double &lots, double &floating);
bool CanOpenExposure(const int add_layers, const double add_lots);
bool IsSmaTouched(const int pair_index);
void CreateSmaHandles();
void ReleaseSmaHandles();
void CreatePanel();
void DeletePanel();
void UpdatePanel();
void SetPairAction(const int pair_index, const string action);

//+------------------------------------------------------------------+
void SetTradeMagic(const ulong magic)
  {
   trade.SetExpertMagicNumber(magic);
  }

void SetPairAction(const int pair_index, const string action)
  {
   g_pairs[pair_index].last_action = action;
  }

bool IsEaMagic(const ulong magic)
  {
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(g_pairs[i].magic == magic)
         return true;
     }
   return false;
  }

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
void GetEaExposure(int &layers, double &lots, double &floating)
  {
   layers = 0;
   lots = 0.0;
   floating = 0.0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(!IsEaMagic(m_position.Magic()))
         continue;

      layers++;
      lots += m_position.Volume();
      floating += m_position.Profit() + m_position.Swap() + m_position.Commission();
     }
  }

bool CanOpenExposure(const int add_layers, const double add_lots)
  {
   int layers = 0;
   double lots = 0.0;
   double floating = 0.0;
   GetEaExposure(layers, lots, floating);

   if(layers + add_layers > MaxTotalLayers)
      return false;
   if(lots + add_lots > MaxTotalLots + 1e-8)
      return false;
   return true;
  }

//+------------------------------------------------------------------+
//| Candle M15 bar0 high/low menyentuh SMA200                        |
//+------------------------------------------------------------------+
bool IsSmaTouched(const int pair_index)
  {
   if(!UseSmaEntryFilter)
     {
      g_pairs[pair_index].sma_status = "OK";
      return true;
     }

   int handle = g_pairs[pair_index].sma_handle;
   if(handle == INVALID_HANDLE)
     {
      g_pairs[pair_index].sma_status = "WAIT";
      return false;
     }

   double ma[];
   ArraySetAsSeries(ma, true);
   if(CopyBuffer(handle, 0, 0, 1, ma) < 1)
     {
      g_pairs[pair_index].sma_status = "WAIT";
      return false;
     }

   string symbol = g_pairs[pair_index].resolved;
   double high = iHigh(symbol, PERIOD_M15, 0);
   double low  = iLow(symbol, PERIOD_M15, 0);
   if(high <= 0.0 || low <= 0.0)
     {
      g_pairs[pair_index].sma_status = "WAIT";
      return false;
     }

   bool touch = (low <= ma[0] && high >= ma[0]);
   g_pairs[pair_index].sma_status = touch ? "OK" : "WAIT";
   return touch;
  }

void CreateSmaHandles()
  {
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      g_pairs[i].sma_handle = INVALID_HANDLE;
      g_pairs[i].sma_status = "-";

      if(!g_pairs[i].enabled)
         continue;

      g_pairs[i].sma_handle = iMA(g_pairs[i].resolved, PERIOD_M15, SMA_PERIOD, 0, MODE_SMA, PRICE_CLOSE);
      if(g_pairs[i].sma_handle == INVALID_HANDLE)
        {
         Print("Gagal buat SMA handle: ", g_pairs[i].resolved);
         g_pairs[i].sma_status = "WAIT";
        }
      else
         g_pairs[i].sma_status = UseSmaEntryFilter ? "WAIT" : "OK";
     }
  }

void ReleaseSmaHandles()
  {
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(g_pairs[i].sma_handle != INVALID_HANDLE)
        {
         IndicatorRelease(g_pairs[i].sma_handle);
         g_pairs[i].sma_handle = INVALID_HANDLE;
        }
     }
  }

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
      g_pairs[i].last_action     = "-";
      g_pairs[i].sma_handle      = INVALID_HANDLE;
      g_pairs[i].sma_status      = "-";
     }
  }

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
//| Panel                                                            |
//+------------------------------------------------------------------+
void DeletePanel()
  {
   ObjectsDeleteAll(0, PANEL_PREFIX);
  }

void CreatePanel()
  {
   DeletePanel();

   // Background panel
   ObjectCreate(0, PANEL_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XDISTANCE, PANEL_X);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YDISTANCE, PANEL_Y);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XSIZE, PANEL_W);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YSIZE, PANEL_H);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BGCOLOR, C'24,28,36');
   ObjectSetInteger(0, PANEL_BG, OBJPROP_COLOR, C'70,80,95');
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BACK, false);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_ZORDER, 0);

   // Pause button
   if(!ObjectCreate(0, BTN_PAUSE, OBJ_BUTTON, 0, 0, 0))
      Print("Gagal buat tombol pause");
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_XDISTANCE, PANEL_X + 8);
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_YDISTANCE, PANEL_Y + 8);
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_XSIZE, 120);
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_YSIZE, 24);
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_HIDDEN, true);
   ObjectSetString(0, BTN_PAUSE, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_ZORDER, 2);

   // Header + rows as labels
   for(int i = 0; i < PAIR_COUNT + 2; i++)
     {
      string name = PANEL_PREFIX + "L" + IntegerToString(i);
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, PANEL_X + 8);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, PANEL_Y + 38 + i * 16);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
     }

   UpdatePanel();
  }

void UpdatePanel()
  {
   int layers = 0;
   double lots = 0.0;
   double floating = 0.0;
   GetEaExposure(layers, lots, floating);

   ObjectSetString(0, BTN_PAUSE, OBJPROP_TEXT, g_trading_pause ? "RESUME" : "PAUSE");
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_BGCOLOR, g_trading_pause ? clrDarkGreen : clrFireBrick);
   ObjectSetInteger(0, BTN_PAUSE, OBJPROP_COLOR, clrWhite);

   string header1 = StringFormat("RAVEN TANAM v3.10 | Pause:%s | SMA Filter:%s",
                                 g_trading_pause ? "ON" : "OFF",
                                 UseSmaEntryFilter ? "ON" : "OFF");
   string header2 = StringFormat("Exposure L:%d/%d  Lot:%.2f/%.2f  Float:%.2f",
                                 layers, MaxTotalLayers, lots, MaxTotalLots, floating);

   ObjectSetString(0, PANEL_PREFIX + "L0", OBJPROP_TEXT, header1);
   ObjectSetString(0, PANEL_PREFIX + "L1", OBJPROP_TEXT, header2);

   for(int i = 0; i < PAIR_COUNT; i++)
     {
      int buys = 0;
      int sells = 0;
      double pf = 0.0;

      if(g_pairs[i].enabled)
        {
         for(int p = 0; p < PositionsTotal(); p++)
           {
            if(!m_position.SelectByIndex(p))
               continue;
            if(m_position.Symbol() != g_pairs[i].resolved || m_position.Magic() != g_pairs[i].magic)
               continue;
            if(m_position.PositionType() == POSITION_TYPE_BUY)
               buys++;
            else if(m_position.PositionType() == POSITION_TYPE_SELL)
               sells++;
            pf += m_position.Profit() + m_position.Swap() + m_position.Commission();
           }

         // Refresh SMA status for panel when waiting entry
         if(buys == 0 && sells == 0 && UseSmaEntryFilter)
            IsSmaTouched(i);
         else if(!UseSmaEntryFilter)
            g_pairs[i].sma_status = "OK";
         else if(buys > 0 || sells > 0)
            g_pairs[i].sma_status = "OK";
        }
      else
         g_pairs[i].sma_status = "-";

      string line = StringFormat("%s | %s | B:%d S:%d | F:%.2f | SMA:%s | %s",
                                 g_pairs[i].resolved,
                                 g_pairs[i].enabled ? "ON" : "OFF",
                                 buys, sells, pf,
                                 g_pairs[i].sma_status,
                                 g_pairs[i].last_action);
      ObjectSetString(0, PANEL_PREFIX + "L" + IntegerToString(i + 2), OBJPROP_TEXT, line);
     }

   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   g_trading_pause = TradingPause;

   InitPairConfigs();
   ResolvePairSymbols();
   CreateSmaHandles();

   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(g_pairs[i].enabled)
         ApplyTPToExistingEAOrders(i);
     }

   CreatePanel();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   ReleaseSmaHandles();
   DeletePanel();
  }

void OnTick()
  {
   ProcessAllPairs();
  }

void OnTimer()
  {
   ProcessAllPairs();
  }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == BTN_PAUSE)
     {
      g_trading_pause = !g_trading_pause;
      ObjectSetInteger(0, BTN_PAUSE, OBJPROP_STATE, false);
      Print("Trading pause: ", g_trading_pause ? "ON" : "OFF");
      UpdatePanel();
     }
  }

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

   UpdatePanel();
  }

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

double PipToPrice(const string symbol, const double pips)
  {
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);

   if(digits == 3 || digits == 5)
      return pips * 10.0 * point;
   return pips * point;
  }

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
      SetPairAction(pair_index, "Basket");
      Print("Basket close tercapai [", symbol, "]. Total profit: ", basket_profit,
            " | Target: ", target_value);
     }
  }

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

   // --- ATURAN 1: ENTRY AWAL ---
   if(total_buys == 0 && total_sells == 0)
     {
      if(g_trading_pause)
        {
         SetPairAction(pair_index, "Pause");
         return;
        }

      if(!IsSmaTouched(pair_index))
        {
         SetPairAction(pair_index, "SMA wait");
         return;
        }

      if(buy_layer_count < MaxLayers && sell_layer_count < MaxLayers)
        {
         // Initial hedge = 2 posisi
         if(!CanOpenExposure(2, lot * 2.0))
           {
            SetPairAction(pair_index, "MaxExp");
            return;
           }

         if(TimeCurrent() - g_pairs[pair_index].last_trade_time > 3)
           {
            double initial_buy_tp = NormalizeDouble(ask + gap, digits);
            double initial_sell_tp = NormalizeDouble(bid - gap, digits);

            BuyWithRetry(lot, symbol, ask, 0, initial_buy_tp, "Initial Buy");
            SellWithRetry(lot, symbol, bid, 0, initial_sell_tp, "Initial Sell");
            g_pairs[pair_index].last_trade_time = TimeCurrent();
            SetPairAction(pair_index, "Initial");
           }
        }
      return;
     }

   // Posisi sudah ada: sync TP & manage tetap jalan meski pause
   SyncBasketTP(symbol, magic, anchor_buy_price, anchor_sell_price, gap);

   // --- ATURAN 2: GRID LAYERING (tanpa filter SMA) ---
   if(!g_trading_pause)
     {
      if(total_buys > 0 && buy_layer_count < MaxLayers && ask <= (lowest_buy_price - gap))
        {
         if(!CanOpenExposure(1, lot))
            SetPairAction(pair_index, "MaxExp");
         else if(TimeCurrent() - g_pairs[pair_index].last_trade_time > 3)
           {
            double grid_buy_tp = NormalizeDouble(anchor_buy_price + gap, digits);
            BuyWithRetry(lot, symbol, ask, 0, grid_buy_tp, "Grid Buy Layer");
            g_pairs[pair_index].last_trade_time = TimeCurrent();
            SetPairAction(pair_index, "GridBuy");
           }
        }

      if(total_sells > 0 && sell_layer_count < MaxLayers && bid >= (highest_sell_price + gap))
        {
         if(!CanOpenExposure(1, lot))
            SetPairAction(pair_index, "MaxExp");
         else if(TimeCurrent() - g_pairs[pair_index].last_trade_time > 3)
           {
            double grid_sell_tp = NormalizeDouble(anchor_sell_price - gap, digits);
            SellWithRetry(lot, symbol, bid, 0, grid_sell_tp, "Grid Sell Layer");
            g_pairs[pair_index].last_trade_time = TimeCurrent();
            SetPairAction(pair_index, "GridSell");
           }
        }
     }
   else
      SetPairAction(pair_index, "Pause");

   // --- ATURAN 3: TP GLOBAL ---
   if(total_buys > 0)
     {
      double global_tp_buy = anchor_buy_price + PipToPrice(symbol, pip_step);
      if(bid >= global_tp_buy)
        {
         CloseAllDirection(symbol, magic, POSITION_TYPE_BUY);
         SetPairAction(pair_index, "TP Buy");
         Print("TP Global Buy Terpenuhi [", symbol, "].");
        }
     }

   if(total_sells > 0)
     {
      double global_tp_sell = anchor_sell_price - PipToPrice(symbol, pip_step);
      if(ask <= global_tp_sell)
        {
         CloseAllDirection(symbol, magic, POSITION_TYPE_SELL);
         SetPairAction(pair_index, "TP Sell");
         Print("TP Global Sell Terpenuhi [", symbol, "].");
        }
     }
  }

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
