//+------------------------------------------------------------------+
//|                                        Raven Cost Averaging.mq5 |
//|                                                 Randi Apriliyadi |
//|                              https://github.com/randiapriliyadiR |
//+------------------------------------------------------------------+
#property copyright "Randi Apriliyadi"
#property link      "https://github.com/randiapriliyadiR"
#property version   "3.20"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

#define PAIR_COUNT           7
#define SMA_PERIOD           200
#define PANEL_PREFIX         "RCA_"
#define BTN_PAUSE            "RCA_BTN_PAUSE"
#define BTN_SMA              "RCA_BTN_SMA"
#define PANEL_BG             "RCA_BG"
#define PANEL_TITLE          "RCA_TITLE"
#define PANEL_CREDIT         "RCA_CREDIT"
#define PANEL_STATUS         "RCA_STATUS"
#define PANEL_EXPOSURE       "RCA_EXPOSURE"
#define PANEL_TOTAL_FLOAT    "RCA_TOTAL_FLOAT"
#define PANEL_HDR            "RCA_HDR"
#define PANEL_TBL            "RCA_TBL"
#define PANEL_THD            "RCA_THD"
#define PANEL_X              8
#define PANEL_Y              12
#define PANEL_PAD            10
#define PANEL_UI_MS          250
#define PANEL_HISTORY_MS     1500
#define GV_PAUSE_KEY         "RCA_PAUSE_STATE"
#define GV_SMA_KEY           "RCA_SMA_STATE"
#define TABLE_HDR_H          20
#define TABLE_ROW_H          18
#define TABLE_LEFT_PAD       10
#define TABLE_COLS           8
#define FONT_CHAR_W          7   // Consolas ~9pt pixel width (no Canvas dependency)

//--- Max Layer Scope
enum ENUM_MAX_LAYER_SCOPE
  {
   MAX_LAYER_MAGIC_ONLY,  // Magic Only (this symbol)
   MAX_LAYER_ALL_ACCOUNT  // All account trades
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
   string   sma_status;
   double   closed_profit;
  };

//--- Input Parameters: General
input string               InpSectionGeneral      = "=== General ===";
input int                  MaxLayers              = 0;                   // Max Layers (0 = no limit)
input ENUM_MAX_LAYER_SCOPE MaxLayerScope          = MAX_LAYER_MAGIC_ONLY; // Max Layer Scope
input string               SymbolSuffix           = "c";                 // Symbol Suffix (empty = none)

//--- Operations
input string               InpSectionOps          = "=== Operations ===";
input bool                 ShowPanel              = true;                // Show Panel

//--- Entry Filter
input string               InpSectionEntry        = "=== Entry Filter ===";
input bool                 UseSmaEntryFilter      = true;                // SMA200 entry filter (default)
input ENUM_TIMEFRAMES      SmaTimeframe           = PERIOD_M15;          // SMA200 timeframe

//--- EURUSD
input string               InpSectionEURUSD       = "=== EURUSD ===";
input bool                 EURUSD_Enable          = true;                // Enable EURUSD
input double               EURUSD_Lot             = 0.1;                 // Lot EURUSD
input int                  EURUSD_PipStep         = 10;                  // Pip Step EURUSD
input ulong                EURUSD_Magic           = 111111;              // Magic EURUSD

//--- GBPUSD
input string               InpSectionGBPUSD       = "=== GBPUSD ===";
input bool                 GBPUSD_Enable          = true;                // Enable GBPUSD
input double               GBPUSD_Lot             = 0.1;                 // Lot GBPUSD
input int                  GBPUSD_PipStep         = 14;                  // Pip Step GBPUSD
input ulong                GBPUSD_Magic           = 222222;              // Magic GBPUSD

//--- USDCHF
input string               InpSectionUSDCHF       = "=== USDCHF ===";
input bool                 USDCHF_Enable          = true;                // Enable USDCHF
input double               USDCHF_Lot             = 0.1;                 // Lot USDCHF
input int                  USDCHF_PipStep         = 9;                   // Pip Step USDCHF
input ulong                USDCHF_Magic           = 333333;              // Magic USDCHF

//--- NZDUSD
input string               InpSectionNZDUSD       = "=== NZDUSD ===";
input bool                 NZDUSD_Enable          = true;                // Enable NZDUSD
input double               NZDUSD_Lot             = 0.1;                 // Lot NZDUSD
input int                  NZDUSD_PipStep         = 8;                   // Pip Step NZDUSD
input ulong                NZDUSD_Magic           = 444444;              // Magic NZDUSD

//--- AUDUSD
input string               InpSectionAUDUSD       = "=== AUDUSD ===";
input bool                 AUDUSD_Enable          = true;                // Enable AUDUSD
input double               AUDUSD_Lot             = 0.1;                 // Lot AUDUSD
input int                  AUDUSD_PipStep         = 9;                   // Pip Step AUDUSD
input ulong                AUDUSD_Magic           = 555555;              // Magic AUDUSD

//--- USDJPY
input string               InpSectionUSDJPY       = "=== USDJPY ===";
input bool                 USDJPY_Enable          = true;                // Enable USDJPY
input double               USDJPY_Lot             = 0.1;                 // Lot USDJPY
input int                  USDJPY_PipStep         = 130;                 // Pip Step USDJPY
input ulong                USDJPY_Magic           = 666666;              // Magic USDJPY

//--- USDCAD
input string               InpSectionUSDCAD       = "=== USDCAD ===";
input bool                 USDCAD_Enable          = true;                // Enable USDCAD
input double               USDCAD_Lot             = 0.1;                 // Lot USDCAD
input int                  USDCAD_PipStep         = 11;                  // Pip Step USDCAD
input ulong                USDCAD_Magic           = 777777;              // Magic USDCAD

//--- Global Variables
CTrade         trade;
CPositionInfo  m_position;
PairConfig     g_pairs[PAIR_COUNT];
bool           g_trading_pause = true;
bool           g_sma_filter = true;
uint           g_last_panel_ms = 0;
uint           g_last_history_ms = 0;
const int      TRADE_RETRY_COUNT = 2;

void ProcessAllPairs();
void ApplyTPToExistingEAOrders(const int pair_index);
void ManageGridAndGlobalTP(const int pair_index);
void SyncBasketTP(const string symbol, const ulong magic, const double first_buy_price, const double first_sell_price, const double gap);
void GetLayerCounts(const string symbol, const ulong magic, int &buy_layers, int &sell_layers);
void CloseAllDirection(const string symbol, const ulong magic, ENUM_POSITION_TYPE type);
double PipToPrice(const string symbol, const double pips);
double NormalizeLot(const string symbol, double lot);
void SetTradeMagic(const ulong magic);
bool IsEaMagic(const ulong magic);
bool CanAddLayer(const int layer_count);
bool IsSmaTouched(const int pair_index);
void CreateSmaHandles();
void ReleaseSmaHandles();
void InitPairConfigs();
void ResolvePairSymbols();
void ApplyRuntimeSettings();
void CreatePanel();
void DeletePanel();
void UpdatePanel();
void MaybeUpdatePanel(const bool force);
void RefreshClosedProfits();
void SetPairAction(const int pair_index, const string action);
void SetLabelText(const string name, const string text);
void SetLabelColor(const string name, const color clr);
void CreateLabel(const string name, const int x, const int y, const int fontsize, const color clr);
void CreateRectLabel(const string name, const int x, const int y, const int w, const int h,
                     const color bg, const color border);
void CreateTableFrame(const int table_x, const int table_y, const int table_w, const int table_h);
string FormatTableHeader();
string FormatTableRow(const int pair_index, const int buys, const int sells, const double pf);
string PauseGvName();
string SmaGvName();
string PeriodToShort(const ENUM_TIMEFRAMES tf);
string StatusLineText();
void SavePauseState();
void SaveSmaFilterState();
void RestoreOrInitPauseState();
void ApplySmaFilterFromInput();
void CreateSoftButton(const string name, const int x, const int y, const int w, const int h);
void RefreshControlButtons();
void RefreshStatusLine();

//+------------------------------------------------------------------+
string PauseGvName()
  {
   return GV_PAUSE_KEY + "_" + IntegerToString((int)ChartID());
  }

string SmaGvName()
  {
   return GV_SMA_KEY + "_" + IntegerToString((int)ChartID());
  }

string PeriodToShort(const ENUM_TIMEFRAMES tf)
  {
   switch(tf)
     {
      case PERIOD_M1:  return "M1";
      case PERIOD_M2:  return "M2";
      case PERIOD_M3:  return "M3";
      case PERIOD_M4:  return "M4";
      case PERIOD_M5:  return "M5";
      case PERIOD_M6:  return "M6";
      case PERIOD_M10: return "M10";
      case PERIOD_M12: return "M12";
      case PERIOD_M15: return "M15";
      case PERIOD_M20: return "M20";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H2:  return "H2";
      case PERIOD_H3:  return "H3";
      case PERIOD_H4:  return "H4";
      case PERIOD_H6:  return "H6";
      case PERIOD_H8:  return "H8";
      case PERIOD_H12: return "H12";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return IntegerToString((int)tf);
     }
  }

string StatusLineText()
  {
   return StringFormat("Status:%s | SMA:%s %s",
                       g_trading_pause ? "Paused" : "Active",
                       g_sma_filter ? "ON" : "OFF",
                       PeriodToShort(SmaTimeframe));
  }

void SavePauseState()
  {
   GlobalVariableSet(PauseGvName(), g_trading_pause ? 1.0 : 0.0);
  }

void SaveSmaFilterState()
  {
   GlobalVariableSet(SmaGvName(), g_sma_filter ? 1.0 : 0.0);
  }

void RestoreOrInitPauseState()
  {
   int prev = UninitializeReason();
   string key = PauseGvName();

   if(prev == REASON_PARAMETERS || prev == REASON_RECOMPILE)
     {
      if(GlobalVariableCheck(key))
         g_trading_pause = (GlobalVariableGet(key) > 0.5);
      else
         g_trading_pause = true;
     }
   else
      g_trading_pause = true;
  }

void ApplySmaFilterFromInput()
  {
   // Input is source of truth whenever settings are (re)applied
   g_sma_filter = UseSmaEntryFilter;
  }

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

bool CanAddLayer(const int layer_count)
  {
   return (MaxLayers <= 0 || layer_count < MaxLayers);
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

   Print("Buy failed after ", TRADE_RETRY_COUNT + 1, " attempts. ", symbol,
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

   Print("Sell failed after ", TRADE_RETRY_COUNT + 1, " attempts. ", symbol,
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

   Print("Modify failed after ", TRADE_RETRY_COUNT + 1, " attempts. Ticket: ", ticket,
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

   Print("Close failed after ", TRADE_RETRY_COUNT + 1, " attempts. Ticket: ", ticket,
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
bool IsSmaTouched(const int pair_index)
  {
   if(!g_sma_filter)
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
   double high = iHigh(symbol, SmaTimeframe, 0);
   double low  = iLow(symbol, SmaTimeframe, 0);
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

      g_pairs[i].sma_handle = iMA(g_pairs[i].resolved, SmaTimeframe, SMA_PERIOD, 0, MODE_SMA, PRICE_CLOSE);
      if(g_pairs[i].sma_handle == INVALID_HANDLE)
        {
         Print("Failed to create SMA handle: ", g_pairs[i].resolved, " TF=", PeriodToShort(SmaTimeframe));
         g_pairs[i].sma_status = "WAIT";
        }
      else
         g_pairs[i].sma_status = g_sma_filter ? "WAIT" : "OK";
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
      g_pairs[i].closed_profit   = 0.0;
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
         Print("Symbol not found / Select failed: ", symbol,
               " — pair ", g_pairs[i].base_symbol, " disabled.");
         g_pairs[i].enabled = false;
         continue;
        }

      if(!SymbolInfoInteger(symbol, SYMBOL_SELECT))
        {
         Print("Symbol unavailable: ", symbol,
               " — pair ", g_pairs[i].base_symbol, " disabled.");
         g_pairs[i].enabled = false;
         continue;
        }

      Print("Active pair: ", symbol, " | Lot=", g_pairs[i].lot,
            " | PipStep=", g_pairs[i].pip_step, " | Magic=", g_pairs[i].magic);
     }
  }

void ApplyRuntimeSettings()
  {
   ApplySmaFilterFromInput();
   ReleaseSmaHandles();
   InitPairConfigs();
   ResolvePairSymbols();
   CreateSmaHandles();

   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(g_pairs[i].enabled)
         ApplyTPToExistingEAOrders(i);
     }

   g_last_history_ms = 0;
   RefreshClosedProfits();

   if(ShowPanel)
     {
      CreatePanel();
      MaybeUpdatePanel(true);
     }
   else
      DeletePanel();
  }

//+------------------------------------------------------------------+
//| Panel                                                            |
//+------------------------------------------------------------------+
void DeletePanel()
  {
   ObjectsDeleteAll(0, PANEL_PREFIX);
  }

void SetLabelText(const string name, const string text)
  {
   if(ObjectGetString(0, name, OBJPROP_TEXT) != text)
      ObjectSetString(0, name, OBJPROP_TEXT, text);
  }

void SetLabelColor(const string name, const color clr)
  {
   if((color)ObjectGetInteger(0, name, OBJPROP_COLOR) != clr)
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
  }

void CreateLabel(const string name, const int x, const int y, const int fontsize, const color clr)
  {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
  }

void CreateRectLabel(const string name, const int x, const int y, const int w, const int h,
                     const color bg, const color border)
  {
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, border);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
  }

string FormatTableHeader()
  {
   return StringFormat("%-12s %-8s %6s %5s %4s %4s %9s %10s",
                       "Symbol", "Magic", "Lot", "Pips", "Buy", "Sell", "Float", "Profit");
  }

string FormatTableRow(const int pair_index, const int buys, const int sells, const double pf)
  {
   return StringFormat("%-12s %-8s %6.2f %5d %4d %4d %9.2f %10.2f",
                       g_pairs[pair_index].resolved,
                       IntegerToString((int)g_pairs[pair_index].magic),
                       g_pairs[pair_index].lot,
                       g_pairs[pair_index].pip_step,
                       buys,
                       sells,
                       pf,
                       g_pairs[pair_index].closed_profit);
  }

void CreateTableFrame(const int table_x, const int table_y, const int table_w, const int table_h)
  {
   // Outer frame + fill
   CreateRectLabel(PANEL_TBL, table_x, table_y, table_w, table_h, C'28,32,40', C'100,112,128');

   // Header band
   CreateRectLabel(PANEL_THD, table_x + 1, table_y + 1, table_w - 2, TABLE_HDR_H - 1,
                   C'42,48,58', C'42,48,58');

   // Horizontal row lines (below header + after each data row)
   for(int i = 0; i <= PAIR_COUNT; i++)
     {
      int y = table_y + TABLE_HDR_H + i * TABLE_ROW_H;
      CreateRectLabel(PANEL_PREFIX + "HL" + IntegerToString(i),
                      table_x + 1, y, table_w - 2, 1,
                      C'70,80,95', C'70,80,95');
     }

   // Vertical column guides — widths match FormatTableHeader gaps
   int cw = FONT_CHAR_W;
   int col_chars[TABLE_COLS];
   col_chars[0] = 12;
   col_chars[1] = 8;
   col_chars[2] = 6;
   col_chars[3] = 5;
   col_chars[4] = 4;
   col_chars[5] = 4;
   col_chars[6] = 9;
   col_chars[7] = 10;
   int x = table_x + TABLE_LEFT_PAD;
   for(int c = 0; c < TABLE_COLS - 1; c++)
     {
      x += col_chars[c] * cw + cw; // column width + gap
      CreateRectLabel(PANEL_PREFIX + "VL" + IntegerToString(c),
                      x - (cw / 2), table_y + 1, 1, table_h - 2,
                      C'70,80,95', C'70,80,95');
     }
  }

void CreateSoftButton(const string name, const int x, const int y, const int w, const int h)
  {
   if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
      Print("Failed to create button: ", name);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetString(0, name, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'70,80,95');
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
  }

void RefreshStatusLine()
  {
   SetLabelText(PANEL_STATUS, StatusLineText());
  }

void RefreshControlButtons()
  {
   if(ObjectFind(0, BTN_PAUSE) >= 0)
     {
      ObjectSetString(0, BTN_PAUSE, OBJPROP_TEXT, g_trading_pause ? "Resume" : "Pause");
      ObjectSetInteger(0, BTN_PAUSE, OBJPROP_BGCOLOR, g_trading_pause ? C'52,96,64' : C'96,60,60');
      ObjectSetInteger(0, BTN_PAUSE, OBJPROP_COLOR, g_trading_pause ? C'180,220,190' : C'220,190,190');
     }

   if(ObjectFind(0, BTN_SMA) >= 0)
     {
      ObjectSetString(0, BTN_SMA, OBJPROP_TEXT, g_sma_filter ? "SMA ON" : "SMA OFF");
      ObjectSetInteger(0, BTN_SMA, OBJPROP_BGCOLOR, g_sma_filter ? C'52,86,110' : C'70,70,78');
      ObjectSetInteger(0, BTN_SMA, OBJPROP_COLOR, g_sma_filter ? C'180,210,230' : C'170,170,178');
     }

   RefreshStatusLine();
  }

void CreatePanel()
  {
   DeletePanel();

   string header = FormatTableHeader();
   int text_w = StringLen(header) * FONT_CHAR_W;
   if(text_w < 500)
      text_w = 500;

   // Panel width fits table + equal side padding (no oversized empty background)
   int table_w = text_w + TABLE_LEFT_PAD * 2;
   int panel_w = table_w + PANEL_PAD * 2;
   int table_x = PANEL_X + PANEL_PAD;
   int table_y = PANEL_Y + 128;
   int table_h = TABLE_HDR_H + PAIR_COUNT * TABLE_ROW_H + 2;
   int panel_h = table_y - PANEL_Y + table_h + PANEL_PAD;

   ObjectCreate(0, PANEL_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XDISTANCE, PANEL_X);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YDISTANCE, PANEL_Y);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XSIZE, panel_w);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YSIZE, panel_h);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BGCOLOR, C'24,28,36');
   ObjectSetInteger(0, PANEL_BG, OBJPROP_COLOR, C'70,80,95');
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BACK, false);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_ZORDER, 0);

   // More breathing room between title and credit
   CreateLabel(PANEL_TITLE, PANEL_X + PANEL_PAD, PANEL_Y + 10, 15, clrWhite);
   ObjectSetString(0, PANEL_TITLE, OBJPROP_TEXT, "Raven Cost Averaging v3.2");

   CreateLabel(PANEL_CREDIT, PANEL_X + PANEL_PAD, PANEL_Y + 40, 8, C'150,158,170');
   ObjectSetString(0, PANEL_CREDIT, OBJPROP_TEXT, "EA developed by Randi Apriliyadi - 2026");

   CreateLabel(PANEL_STATUS, PANEL_X + PANEL_PAD, PANEL_Y + 62, 9, clrWhite);
   CreateLabel(PANEL_EXPOSURE, PANEL_X + PANEL_PAD, PANEL_Y + 80, 9, clrWhite);
   CreateLabel(PANEL_TOTAL_FLOAT, PANEL_X + PANEL_PAD + 200, PANEL_Y + 80, 9, clrWhite);

   CreateSoftButton(BTN_PAUSE, PANEL_X + PANEL_PAD, PANEL_Y + 102, 72, 18);
   CreateSoftButton(BTN_SMA, PANEL_X + PANEL_PAD + 80, PANEL_Y + 102, 78, 18);
   RefreshControlButtons();

   CreateTableFrame(table_x, table_y, table_w, table_h);

   CreateLabel(PANEL_HDR, table_x + TABLE_LEFT_PAD, table_y + 3, 9, C'180,190,205');
   ObjectSetString(0, PANEL_HDR, OBJPROP_TEXT, header);
   ObjectSetInteger(0, PANEL_HDR, OBJPROP_ZORDER, 2);

   for(int i = 0; i < PAIR_COUNT; i++)
     {
      string name = PANEL_PREFIX + "R" + IntegerToString(i);
      int row_y = table_y + TABLE_HDR_H + 2 + i * TABLE_ROW_H;
      CreateLabel(name, table_x + TABLE_LEFT_PAD, row_y, 9, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
     }
  }

void RefreshClosedProfits()
  {
   for(int i = 0; i < PAIR_COUNT; i++)
      g_pairs[i].closed_profit = 0.0;

   if(!HistorySelect(0, TimeCurrent()))
      return;

   int total = HistoryDealsTotal();
   for(int d = 0; d < total; d++)
     {
      ulong ticket = HistoryDealGetTicket(d);
      if(ticket == 0)
         continue;

      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY)
         continue;

      string deal_symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
      ulong  deal_magic  = (ulong)HistoryDealGetInteger(ticket, DEAL_MAGIC);
      double pnl = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                   + HistoryDealGetDouble(ticket, DEAL_SWAP)
                   + HistoryDealGetDouble(ticket, DEAL_COMMISSION);

      for(int i = 0; i < PAIR_COUNT; i++)
        {
         if(g_pairs[i].magic == deal_magic && g_pairs[i].resolved == deal_symbol)
           {
            g_pairs[i].closed_profit += pnl;
            break;
           }
        }
     }
  }

void UpdatePanel()
  {
   if(!ShowPanel)
      return;

   if(ObjectFind(0, PANEL_BG) < 0)
      return;

   uint now = GetTickCount();
   if(now - g_last_history_ms >= PANEL_HISTORY_MS || g_last_history_ms == 0)
     {
      RefreshClosedProfits();
      g_last_history_ms = now;
     }

   int buys[PAIR_COUNT];
   int sells[PAIR_COUNT];
   double floats[PAIR_COUNT];
   int layers = 0;
   double lots = 0.0;
   double floating = 0.0;

   ArrayInitialize(buys, 0);
   ArrayInitialize(sells, 0);
   ArrayInitialize(floats, 0.0);

   for(int p = 0; p < PositionsTotal(); p++)
     {
      if(!m_position.SelectByIndex(p))
         continue;
      if(!IsEaMagic(m_position.Magic()))
         continue;

      layers++;
      lots += m_position.Volume();
      double pf = m_position.Profit() + m_position.Swap() + m_position.Commission();
      floating += pf;

      for(int i = 0; i < PAIR_COUNT; i++)
        {
         if(m_position.Symbol() != g_pairs[i].resolved || m_position.Magic() != g_pairs[i].magic)
            continue;
         if(m_position.PositionType() == POSITION_TYPE_BUY)
            buys[i]++;
         else if(m_position.PositionType() == POSITION_TYPE_SELL)
            sells[i]++;
         floats[i] += pf;
         break;
        }
     }

   string btn_text = g_trading_pause ? "Resume" : "Pause";
   if(ObjectGetString(0, BTN_PAUSE, OBJPROP_TEXT) != btn_text)
      ObjectSetString(0, BTN_PAUSE, OBJPROP_TEXT, btn_text);

   color btn_bg = g_trading_pause ? C'52,96,64' : C'96,60,60';
   color btn_fg = g_trading_pause ? C'180,220,190' : C'220,190,190';
   if((color)ObjectGetInteger(0, BTN_PAUSE, OBJPROP_BGCOLOR) != btn_bg)
      ObjectSetInteger(0, BTN_PAUSE, OBJPROP_BGCOLOR, btn_bg);
   if((color)ObjectGetInteger(0, BTN_PAUSE, OBJPROP_COLOR) != btn_fg)
      ObjectSetInteger(0, BTN_PAUSE, OBJPROP_COLOR, btn_fg);

   string sma_text = g_sma_filter ? "SMA ON" : "SMA OFF";
   if(ObjectGetString(0, BTN_SMA, OBJPROP_TEXT) != sma_text)
      ObjectSetString(0, BTN_SMA, OBJPROP_TEXT, sma_text);
   color sma_bg = g_sma_filter ? C'52,86,110' : C'70,70,78';
   color sma_fg = g_sma_filter ? C'180,210,230' : C'170,170,178';
   if((color)ObjectGetInteger(0, BTN_SMA, OBJPROP_BGCOLOR) != sma_bg)
      ObjectSetInteger(0, BTN_SMA, OBJPROP_BGCOLOR, sma_bg);
   if((color)ObjectGetInteger(0, BTN_SMA, OBJPROP_COLOR) != sma_fg)
      ObjectSetInteger(0, BTN_SMA, OBJPROP_COLOR, sma_fg);

   RefreshStatusLine();

   SetLabelText(PANEL_EXPOSURE, StringFormat("Layers:%d  Lot:%.2f", layers, lots));

   SetLabelText(PANEL_TOTAL_FLOAT, StringFormat("Total Float:%.2f", floating));
   SetLabelColor(PANEL_TOTAL_FLOAT, floating >= 0.0 ? clrLime : clrTomato);

   for(int i = 0; i < PAIR_COUNT; i++)
     {
      SetLabelText(PANEL_PREFIX + "R" + IntegerToString(i),
                   FormatTableRow(i, buys[i], sells[i], floats[i]));
     }

   ChartRedraw(0);
  }

void MaybeUpdatePanel(const bool force)
  {
   if(!ShowPanel)
     {
      if(ObjectFind(0, PANEL_BG) >= 0)
         DeletePanel();
      return;
     }

   uint now = GetTickCount();
   if(!force && g_last_panel_ms != 0 && (now - g_last_panel_ms) < PANEL_UI_MS)
      return;

   g_last_panel_ms = now;
   UpdatePanel();
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   RestoreOrInitPauseState();
   ApplyRuntimeSettings();
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   SavePauseState();
   SaveSmaFilterState();
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
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(sparam == BTN_PAUSE)
     {
      g_trading_pause = !g_trading_pause;
      ObjectSetInteger(0, BTN_PAUSE, OBJPROP_STATE, false);
      SavePauseState();
      Print("Trading status: ", g_trading_pause ? "Paused" : "Active");
      RefreshControlButtons();
      ChartRedraw(0);
      return;
     }

   if(sparam == BTN_SMA)
     {
      g_sma_filter = !g_sma_filter;
      ObjectSetInteger(0, BTN_SMA, OBJPROP_STATE, false);
      SaveSmaFilterState();
      Print("SMA filter: ", g_sma_filter ? "ON" : "OFF", " TF=", PeriodToShort(SmaTimeframe));
      RefreshControlButtons();
      ChartRedraw(0);
     }
  }

//+------------------------------------------------------------------+
void ProcessAllPairs()
  {
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(!g_pairs[i].enabled)
         continue;

      ManageGridAndGlobalTP(i);
     }

   MaybeUpdatePanel(false);
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

   // --- RULE 1: INITIAL ENTRY ---
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

      if(CanAddLayer(buy_layer_count) && CanAddLayer(sell_layer_count))
        {
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

   // Existing positions: sync TP even while paused
   SyncBasketTP(symbol, magic, anchor_buy_price, anchor_sell_price, gap);

   // --- RULE 2: GRID LAYERING (no SMA filter) ---
   if(!g_trading_pause)
     {
      if(total_buys > 0 && CanAddLayer(buy_layer_count) && ask <= (lowest_buy_price - gap))
        {
         if(TimeCurrent() - g_pairs[pair_index].last_trade_time > 3)
           {
            double grid_buy_tp = NormalizeDouble(anchor_buy_price + gap, digits);
            BuyWithRetry(lot, symbol, ask, 0, grid_buy_tp, "Grid Buy Layer");
            g_pairs[pair_index].last_trade_time = TimeCurrent();
            SetPairAction(pair_index, "GridBuy");
           }
        }

      if(total_sells > 0 && CanAddLayer(sell_layer_count) && bid >= (highest_sell_price + gap))
        {
         if(TimeCurrent() - g_pairs[pair_index].last_trade_time > 3)
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

   // --- RULE 3: GLOBAL TP ---
   if(total_buys > 0)
     {
      double global_tp_buy = anchor_buy_price + PipToPrice(symbol, pip_step);
      if(bid >= global_tp_buy)
        {
         CloseAllDirection(symbol, magic, POSITION_TYPE_BUY);
         SetPairAction(pair_index, "TP Buy");
         Print("Global TP Buy hit [", symbol, "].");
        }
     }

   if(total_sells > 0)
     {
      double global_tp_sell = anchor_sell_price - PipToPrice(symbol, pip_step);
      if(ask <= global_tp_sell)
        {
         CloseAllDirection(symbol, magic, POSITION_TYPE_SELL);
         SetPairAction(pair_index, "TP Sell");
         Print("Global TP Sell hit [", symbol, "].");
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

//+------------------------------------------------------------------+
