//+------------------------------------------------------------------+
//|                                        Raven Cost Averaging.mq5 |
//|                                                 Randi Apriliyadi |
//|                              https://github.com/randiapriliyadiR |
//+------------------------------------------------------------------+
#property copyright "Randi Apriliyadi"
#property link      "https://github.com/randiapriliyadiR"
#property version   "3.60"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

#define PAIR_COUNT           17
#define PANEL_PREFIX         "RCA_"
#define BTN_PAUSE            "RCA_BTN_PAUSE"
#define BTN_PIVOT            "RCA_BTN_PIVOT"
#define PANEL_BG             "RCA_BG"
#define PANEL_TITLE          "RCA_TITLE"
#define PANEL_CREDIT         "RCA_CREDIT"
#define PANEL_STATUS         "RCA_STATUS"
#define PANEL_EXPOSURE       "RCA_EXPOSURE"
#define PANEL_LOT            "RCA_LOT"
#define PANEL_TOTAL_FLOAT    "RCA_TOTAL_FLOAT"
#define PANEL_REMARK         "RCA_REMARK"
#define PANEL_TBL            "RCA_TBL"
#define PANEL_THD            "RCA_THD"
#define PANEL_X              12
#define PANEL_Y              12
#define PANEL_PAD            20
#define PANEL_UI_MS          250
#define PANEL_HISTORY_MS     1500
#define GV_PAUSE_KEY         "RCA_PAUSE_STATE"
#define GV_PIVOT_KEY         "RCA_PIVOT_STATE"
#define PIVOT_ENTRY_PIPS     2.0
#define TABLE_HDR_H          28
#define TABLE_ROW_H          26
#define TABLE_COLS           9
#define TABLE_LINE           1
#define TABLE_CELL_PAD       10
#define FONT_UI              "Calibri"
#define FONT_NUM             "Consolas"
#define CLR_BG               C'17,19,24'
#define CLR_CARD             C'24,26,33'
#define CLR_HEADER           C'30,34,44'
#define CLR_ROW_A            C'24,26,33'
#define CLR_ROW_B            C'28,31,40'
#define CLR_LINE             C'52,56,68'
#define CLR_TEXT             C'228,230,236'
#define CLR_MUTED            C'138,146,160'
#define CLR_GOLD             C'214,176,84'
#define CLR_REMARK           C'226,72,68'
#define CLR_ACCENT           C'196,164,98'
#define CLR_POS              C'92,196,148'
#define CLR_NEG              C'224,118,112'
#define CLR_BTN_GO_BG        C'42,78,62'
#define CLR_BTN_GO_FG        C'176,214,190'
#define CLR_BTN_STOP_BG      C'82,48,50'
#define CLR_BTN_STOP_FG      C'220,188,186'

//--- Max Layer Scope
enum ENUM_MAX_LAYER_SCOPE
  {
   MAX_LAYER_MAGIC_ONLY,  // Per pair (symbol + magic)
   MAX_LAYER_ALL_ACCOUNT  // Whole account
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
   double   closed_profit;
  };

//--- Input Parameters: General
input string               InpSectionGeneral      = "=== General ===";
input int                  MaxLayers              = 0;                   // Max Layers per side (0 = no limit)
input ENUM_MAX_LAYER_SCOPE MaxLayerScope          = MAX_LAYER_MAGIC_ONLY; // Max Layer Scope
input string               SymbolSuffix           = "c";                 // Symbol Suffix (empty = none)

//--- Operations
input string               InpSectionOps          = "=== Operations ===";
input bool                 ShowPanel              = true;                // Show Panel
input string               PanelRemark            = "";                  // Panel Remark (optional)
input bool                 ForceActive            = false;               // Force Active (start trading; for tester)

//--- Entry Filter
input string               InpSectionEntry        = "=== Entry Filter ===";
input bool                 UsePivotEntryFilter    = false;               // Use Daily Pivot Entry Filter

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

//--- AUDCAD
input string               InpSectionAUDCAD       = "=== AUDCAD ===";
input bool                 AUDCAD_Enable          = false;               // Enable AUDCAD
input double               AUDCAD_Lot             = 0.1;                 // Lot AUDCAD
input int                  AUDCAD_PipStep         = 12;                  // Pip Step AUDCAD
input ulong                AUDCAD_Magic           = 888888;              // Magic AUDCAD

//--- NZDCAD
input string               InpSectionNZDCAD       = "=== NZDCAD ===";
input bool                 NZDCAD_Enable          = false;               // Enable NZDCAD
input double               NZDCAD_Lot             = 0.1;                 // Lot NZDCAD
input int                  NZDCAD_PipStep         = 12;                  // Pip Step NZDCAD
input ulong                NZDCAD_Magic           = 999999;              // Magic NZDCAD

//--- EURAUD
input string               InpSectionEURAUD       = "=== EURAUD ===";
input bool                 EURAUD_Enable          = false;               // Enable EURAUD
input double               EURAUD_Lot             = 0.1;                 // Lot EURAUD
input int                  EURAUD_PipStep         = 16;                  // Pip Step EURAUD
input ulong                EURAUD_Magic           = 121212;              // Magic EURAUD

//--- GBPCAD
input string               InpSectionGBPCAD       = "=== GBPCAD ===";
input bool                 GBPCAD_Enable          = false;               // Enable GBPCAD
input double               GBPCAD_Lot             = 0.1;                 // Lot GBPCAD
input int                  GBPCAD_PipStep         = 18;                  // Pip Step GBPCAD
input ulong                GBPCAD_Magic           = 131313;              // Magic GBPCAD

//--- AUDJPY
input string               InpSectionAUDJPY       = "=== AUDJPY ===";
input bool                 AUDJPY_Enable          = false;               // Enable AUDJPY
input double               AUDJPY_Lot             = 0.1;                 // Lot AUDJPY
input int                  AUDJPY_PipStep         = 110;                 // Pip Step AUDJPY
input ulong                AUDJPY_Magic           = 141414;              // Magic AUDJPY

//--- CADCHF
input string               InpSectionCADCHF       = "=== CADCHF ===";
input bool                 CADCHF_Enable          = false;               // Enable CADCHF
input double               CADCHF_Lot             = 0.1;                 // Lot CADCHF
input int                  CADCHF_PipStep         = 12;                  // Pip Step CADCHF
input ulong                CADCHF_Magic           = 151515;              // Magic CADCHF

//--- AUDCHF
input string               InpSectionAUDCHF       = "=== AUDCHF ===";
input bool                 AUDCHF_Enable          = false;               // Enable AUDCHF
input double               AUDCHF_Lot             = 0.1;                 // Lot AUDCHF
input int                  AUDCHF_PipStep         = 12;                  // Pip Step AUDCHF
input ulong                AUDCHF_Magic           = 161616;              // Magic AUDCHF

//--- CADJPY
input string               InpSectionCADJPY       = "=== CADJPY ===";
input bool                 CADJPY_Enable          = false;               // Enable CADJPY
input double               CADJPY_Lot             = 0.1;                 // Lot CADJPY
input int                  CADJPY_PipStep         = 110;                 // Pip Step CADJPY
input ulong                CADJPY_Magic           = 171717;              // Magic CADJPY

//--- GBPAUD
input string               InpSectionGBPAUD       = "=== GBPAUD ===";
input bool                 GBPAUD_Enable          = false;               // Enable GBPAUD
input double               GBPAUD_Lot             = 0.1;                 // Lot GBPAUD
input int                  GBPAUD_PipStep         = 18;                  // Pip Step GBPAUD
input ulong                GBPAUD_Magic           = 181818;              // Magic GBPAUD

//--- EURCAD
input string               InpSectionEURCAD       = "=== EURCAD ===";
input bool                 EURCAD_Enable          = false;               // Enable EURCAD
input double               EURCAD_Lot             = 0.1;                 // Lot EURCAD
input int                  EURCAD_PipStep         = 14;                  // Pip Step EURCAD
input ulong                EURCAD_Magic           = 191919;              // Magic EURCAD

//--- Global Variables
CTrade         trade;
CPositionInfo  m_position;
PairConfig     g_pairs[PAIR_COUNT];
bool           g_trading_pause = true;
bool           g_pivot_filter = false;
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
bool IsDailyPivotTouched(const int pair_index);
double DailyPivot(const string symbol);
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
void CreateLabel(const string name, const int x, const int y, const int fontsize, const color clr, const string font);
void CreateRectLabel(const string name, const int x, const int y, const int w, const int h,
                     const color bg, const color border);
void CreateTableFrame(const int table_x, const int table_y, const int table_w, const int table_h, const int rows);
int TableColX(const int table_x, const int col);
int TableWidth();
string CellName(const int row, const int col);
string MoneyText(const double value);
string PauseGvName();
string PivotGvName();
string StatusLineText();
void SavePauseState();
void SavePivotFilterState();
void RestoreOrInitPauseState();
void ApplyPivotFilterFromInput();
void CreateSoftButton(const string name, const int x, const int y, const int w, const int h);
void RefreshControlButtons();
void RefreshStatusLine();

//+------------------------------------------------------------------+
string PauseGvName()
  {
   return GV_PAUSE_KEY + "_" + IntegerToString((int)ChartID());
  }

string PivotGvName()
  {
   return GV_PIVOT_KEY + "_" + IntegerToString((int)ChartID());
  }

string StatusLineText()
  {
   return StringFormat("Status  %s      Pivot  %s",
                       g_trading_pause ? "Paused" : "Active",
                       g_pivot_filter ? "ON" : "OFF");
  }

void SavePauseState()
  {
   GlobalVariableSet(PauseGvName(), g_trading_pause ? 1.0 : 0.0);
  }

void SavePivotFilterState()
  {
   GlobalVariableSet(PivotGvName(), g_pivot_filter ? 1.0 : 0.0);
  }

void ApplyPivotFilterFromInput()
  {
   g_pivot_filter = UsePivotEntryFilter;
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

   if(ForceActive)
      g_trading_pause = false;
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
double DailyPivot(const string symbol)
  {
   double high  = iHigh(symbol, PERIOD_D1, 1);
   double low   = iLow(symbol, PERIOD_D1, 1);
   double close = iClose(symbol, PERIOD_D1, 1);
   if(high <= 0.0 || low <= 0.0 || close <= 0.0)
      return 0.0;
   return (high + low + close) / 3.0;
  }

double PriceToPips(const string symbol, const double price_dist)
  {
   int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
   double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
   if(point <= 0.0)
      return 0.0;

   double pip = ((digits == 3 || digits == 5) ? 10.0 * point : point);
   if(pip <= 0.0)
      return 0.0;
   return price_dist / pip;
  }

bool MidPivotGap(const string symbol, double &gap_pips)
  {
   gap_pips = 0.0;
   double pivot = DailyPivot(symbol);
   if(pivot <= 0.0)
      return false;

   double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
   if(bid <= 0.0 || ask <= 0.0)
      return false;

   double mid = (bid + ask) / 2.0;
   gap_pips = PriceToPips(symbol, mid - pivot);
   return true;
  }

bool IsDailyPivotTouched(const int pair_index)
  {
   if(!g_pivot_filter)
      return true;

   double gap_pips = 0.0;
   if(!MidPivotGap(g_pairs[pair_index].resolved, gap_pips))
      return false;
   return (MathAbs(gap_pips) <= PIVOT_ENTRY_PIPS);
  }

string PivotGapText(const string symbol, const int buys, const int sells)
  {
   if(buys > 0 || sells > 0)
      return "-";

   double gap_pips = 0.0;
   if(!MidPivotGap(symbol, gap_pips))
      return "-";
   return StringFormat("%+.1f", gap_pips);
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

   g_pairs[7].base_symbol = "AUDCAD";
   g_pairs[7].enabled     = AUDCAD_Enable;
   g_pairs[7].lot         = AUDCAD_Lot;
   g_pairs[7].pip_step    = AUDCAD_PipStep;
   g_pairs[7].magic       = AUDCAD_Magic;

   g_pairs[8].base_symbol = "NZDCAD";
   g_pairs[8].enabled     = NZDCAD_Enable;
   g_pairs[8].lot         = NZDCAD_Lot;
   g_pairs[8].pip_step    = NZDCAD_PipStep;
   g_pairs[8].magic       = NZDCAD_Magic;

   g_pairs[9].base_symbol = "EURAUD";
   g_pairs[9].enabled     = EURAUD_Enable;
   g_pairs[9].lot         = EURAUD_Lot;
   g_pairs[9].pip_step    = EURAUD_PipStep;
   g_pairs[9].magic       = EURAUD_Magic;

   g_pairs[10].base_symbol = "GBPCAD";
   g_pairs[10].enabled     = GBPCAD_Enable;
   g_pairs[10].lot         = GBPCAD_Lot;
   g_pairs[10].pip_step    = GBPCAD_PipStep;
   g_pairs[10].magic       = GBPCAD_Magic;

   g_pairs[11].base_symbol = "AUDJPY";
   g_pairs[11].enabled     = AUDJPY_Enable;
   g_pairs[11].lot         = AUDJPY_Lot;
   g_pairs[11].pip_step    = AUDJPY_PipStep;
   g_pairs[11].magic       = AUDJPY_Magic;

   g_pairs[12].base_symbol = "CADCHF";
   g_pairs[12].enabled     = CADCHF_Enable;
   g_pairs[12].lot         = CADCHF_Lot;
   g_pairs[12].pip_step    = CADCHF_PipStep;
   g_pairs[12].magic       = CADCHF_Magic;

   g_pairs[13].base_symbol = "AUDCHF";
   g_pairs[13].enabled     = AUDCHF_Enable;
   g_pairs[13].lot         = AUDCHF_Lot;
   g_pairs[13].pip_step    = AUDCHF_PipStep;
   g_pairs[13].magic       = AUDCHF_Magic;

   g_pairs[14].base_symbol = "CADJPY";
   g_pairs[14].enabled     = CADJPY_Enable;
   g_pairs[14].lot         = CADJPY_Lot;
   g_pairs[14].pip_step    = CADJPY_PipStep;
   g_pairs[14].magic       = CADJPY_Magic;

   g_pairs[15].base_symbol = "GBPAUD";
   g_pairs[15].enabled     = GBPAUD_Enable;
   g_pairs[15].lot         = GBPAUD_Lot;
   g_pairs[15].pip_step    = GBPAUD_PipStep;
   g_pairs[15].magic       = GBPAUD_Magic;

   g_pairs[16].base_symbol = "EURCAD";
   g_pairs[16].enabled     = EURCAD_Enable;
   g_pairs[16].lot         = EURCAD_Lot;
   g_pairs[16].pip_step    = EURCAD_PipStep;
   g_pairs[16].magic       = EURCAD_Magic;

   for(int i = 0; i < PAIR_COUNT; i++)
     {
      g_pairs[i].resolved        = g_pairs[i].base_symbol + SymbolSuffix;
      g_pairs[i].last_trade_time = 0;
      g_pairs[i].last_action     = "-";
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
   ApplyPivotFilterFromInput();
   InitPairConfigs();
   ResolvePairSymbols();

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

void CreateLabel(const string name, const int x, const int y, const int fontsize, const color clr, const string font)
  {
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
   ObjectSetString(0, name, OBJPROP_FONT, font);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
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

int TableColWidth(const int col)
  {
   switch(col)
     {
      case 0: return 124; // Symbol
      case 1: return 84;  // Magic
      case 2: return 64;  // Lot
      case 3: return 58;  // Pips
      case 4: return 72;  // Pivot gap
      case 5: return 52;  // Buy
      case 6: return 52;  // Sell
      case 7: return 100; // Float
      case 8: return 100; // Profit
     }
   return 56;
  }

int TableWidth()
  {
   int w = TABLE_LINE;
   for(int c = 0; c < TABLE_COLS; c++)
      w += TableColWidth(c) + TABLE_LINE;
   return w;
  }

int TableColX(const int table_x, const int col)
  {
   int x = table_x + TABLE_LINE;
   for(int c = 0; c < col; c++)
      x += TableColWidth(c) + TABLE_LINE;
   return x;
  }

string CellName(const int row, const int col)
  {
   return PANEL_PREFIX + "C" + IntegerToString(row) + "_" + IntegerToString(col);
  }

string MoneyText(const double value)
  {
   return StringFormat("%.2f", value);
  }

int VisiblePairCount()
  {
   int rows = 0;
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(g_pairs[i].enabled)
         rows++;
     }
   return rows;
  }

string RemarkText()
  {
   string remark = PanelRemark;
   StringTrimLeft(remark);
   StringTrimRight(remark);
   return remark;
  }

string LayerTotalText(const int layers)
  {
   if(MaxLayers <= 0)
      return StringFormat("Layers  %d", layers);
   if(MaxLayerScope == MAX_LAYER_MAGIC_ONLY)
      return StringFormat("Layers  %d   %d/side per pair", layers, MaxLayers);
   return StringFormat("Layers  %d   %d/side account", layers, MaxLayers);
  }

void CreateTableFrame(const int table_x, const int table_y, const int table_w, const int table_h, const int rows)
  {
   CreateRectLabel(PANEL_TBL, table_x, table_y, table_w, table_h, CLR_CARD, CLR_LINE);

   CreateRectLabel(PANEL_THD, table_x + TABLE_LINE, table_y + TABLE_LINE,
                   table_w - TABLE_LINE * 2, TABLE_HDR_H,
                   CLR_HEADER, CLR_HEADER);

   for(int i = 0; i < rows; i++)
     {
      int y = table_y + TABLE_LINE + TABLE_HDR_H + i * TABLE_ROW_H;
      color row_bg = ((i % 2) == 0) ? CLR_ROW_A : CLR_ROW_B;
      CreateRectLabel(PANEL_PREFIX + "RB" + IntegerToString(i),
                      table_x + TABLE_LINE, y, table_w - TABLE_LINE * 2, TABLE_ROW_H,
                      row_bg, row_bg);
     }

   CreateRectLabel(PANEL_PREFIX + "HL0",
                   table_x + TABLE_LINE, table_y + TABLE_LINE + TABLE_HDR_H,
                   table_w - TABLE_LINE * 2, TABLE_LINE,
                   CLR_LINE, CLR_LINE);

   for(int c = 1; c < TABLE_COLS; c++)
     {
      int x = TableColX(table_x, c) - TABLE_LINE;
      CreateRectLabel(PANEL_PREFIX + "VL" + IntegerToString(c),
                      x, table_y + TABLE_LINE, TABLE_LINE, table_h - TABLE_LINE * 2,
                      CLR_LINE, CLR_LINE);
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
   ObjectSetString(0, name, OBJPROP_FONT, FONT_UI);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, CLR_LINE);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 3);
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
      ObjectSetInteger(0, BTN_PAUSE, OBJPROP_BGCOLOR, g_trading_pause ? CLR_BTN_GO_BG : CLR_BTN_STOP_BG);
      ObjectSetInteger(0, BTN_PAUSE, OBJPROP_COLOR, g_trading_pause ? CLR_BTN_GO_FG : CLR_BTN_STOP_FG);
     }

   if(ObjectFind(0, BTN_PIVOT) >= 0)
     {
      ObjectSetString(0, BTN_PIVOT, OBJPROP_TEXT, g_pivot_filter ? "Pivot ON" : "Pivot OFF");
      ObjectSetInteger(0, BTN_PIVOT, OBJPROP_BGCOLOR, g_pivot_filter ? CLR_BTN_GO_BG : CLR_BTN_STOP_BG);
      ObjectSetInteger(0, BTN_PIVOT, OBJPROP_COLOR, g_pivot_filter ? CLR_BTN_GO_FG : CLR_BTN_STOP_FG);
     }

   RefreshStatusLine();
  }

void CreatePanel()
  {
   DeletePanel();

   int rows = VisiblePairCount();
   int table_w = TableWidth();
   int table_h = TABLE_LINE + TABLE_HDR_H + rows * TABLE_ROW_H + TABLE_LINE;
   int table_x = PANEL_X + PANEL_PAD;
   int table_y = PANEL_Y + 168;
   int panel_w = table_w + PANEL_PAD * 2;
   int panel_h = table_y - PANEL_Y + table_h + PANEL_PAD;

   ObjectCreate(0, PANEL_BG, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XDISTANCE, PANEL_X);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YDISTANCE, PANEL_Y);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_XSIZE, panel_w);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_YSIZE, panel_h);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BGCOLOR, CLR_BG);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_COLOR, CLR_LINE);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_BACK, false);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, PANEL_BG, OBJPROP_ZORDER, 0);

   CreateLabel(PANEL_TITLE, PANEL_X + PANEL_PAD, PANEL_Y + 14, 16, CLR_GOLD, "Arial Black");
   ObjectSetString(0, PANEL_TITLE, OBJPROP_TEXT, "RAVEN COST AVERAGING  V3.6");

   string remark = RemarkText();
   if(remark != "")
     {
      CreateLabel(PANEL_REMARK, PANEL_X + panel_w - PANEL_PAD, PANEL_Y + 18, 12, CLR_REMARK, "Arial Bold");
      ObjectSetInteger(0, PANEL_REMARK, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetString(0, PANEL_REMARK, OBJPROP_TEXT, remark);
     }

   CreateLabel(PANEL_CREDIT, PANEL_X + PANEL_PAD, PANEL_Y + 44, 9, CLR_MUTED, FONT_UI);
   ObjectSetString(0, PANEL_CREDIT, OBJPROP_TEXT, "EA developed by Randi Apriliyadi - 2026");

   CreateLabel(PANEL_STATUS, PANEL_X + PANEL_PAD, PANEL_Y + 78, 10, CLR_TEXT, FONT_UI);
   CreateLabel(PANEL_EXPOSURE, PANEL_X + PANEL_PAD, PANEL_Y + 102, 10, CLR_MUTED, FONT_UI);
   CreateLabel(PANEL_LOT, PANEL_X + PANEL_PAD + 260, PANEL_Y + 102, 10, CLR_MUTED, FONT_UI);
   CreateLabel(PANEL_TOTAL_FLOAT, PANEL_X + PANEL_PAD + 380, PANEL_Y + 102, 10, CLR_TEXT, FONT_UI);

   CreateSoftButton(BTN_PAUSE, PANEL_X + PANEL_PAD, PANEL_Y + 130, 88, 26);
   CreateSoftButton(BTN_PIVOT, PANEL_X + PANEL_PAD + 104, PANEL_Y + 130, 96, 26);
   RefreshControlButtons();

   CreateTableFrame(table_x, table_y, table_w, table_h, rows);

   string headers[TABLE_COLS];
   headers[0] = "Symbol";
   headers[1] = "Magic";
   headers[2] = "Lot";
   headers[3] = "Pips";
   headers[4] = "Pivot";
   headers[5] = "Buy";
   headers[6] = "Sell";
   headers[7] = "Float";
   headers[8] = "Profit";

   int header_y = table_y + TABLE_LINE + 6;
   for(int c = 0; c < TABLE_COLS; c++)
     {
      string hname = PANEL_PREFIX + "H" + IntegerToString(c);
      CreateLabel(hname, TableColX(table_x, c) + TABLE_CELL_PAD, header_y, 9, CLR_MUTED, FONT_UI);
      ObjectSetString(0, hname, OBJPROP_TEXT, headers[c]);
     }

   int row = 0;
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(!g_pairs[i].enabled)
         continue;

      int row_y = table_y + TABLE_LINE + TABLE_HDR_H + row * TABLE_ROW_H + 5;
      for(int c = 0; c < TABLE_COLS; c++)
        {
         string font = (c <= 1) ? FONT_UI : FONT_NUM;
         CreateLabel(CellName(row, c), TableColX(table_x, c) + TABLE_CELL_PAD, row_y, 9, CLR_TEXT, font);
        }
      row++;
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

   RefreshControlButtons();

   SetLabelText(PANEL_EXPOSURE, LayerTotalText(layers));
   SetLabelText(PANEL_LOT, StringFormat("Lot  %s", MoneyText(lots)));
   SetLabelText(PANEL_TOTAL_FLOAT, StringFormat("Total Float  %s", MoneyText(floating)));
   SetLabelColor(PANEL_TOTAL_FLOAT, floating >= 0.0 ? CLR_POS : CLR_NEG);
   if(RemarkText() == "")
      ObjectDelete(0, PANEL_REMARK);
   else
      SetLabelText(PANEL_REMARK, RemarkText());

   int row = 0;
   for(int i = 0; i < PAIR_COUNT; i++)
     {
      if(!g_pairs[i].enabled)
         continue;

      SetLabelText(CellName(row, 0), g_pairs[i].resolved);
      SetLabelText(CellName(row, 1), IntegerToString((int)g_pairs[i].magic));
      SetLabelText(CellName(row, 2), MoneyText(g_pairs[i].lot));
      SetLabelText(CellName(row, 3), IntegerToString(g_pairs[i].pip_step));
      SetLabelText(CellName(row, 4), PivotGapText(g_pairs[i].resolved, buys[i], sells[i]));
      SetLabelText(CellName(row, 5), IntegerToString(buys[i]));
      SetLabelText(CellName(row, 6), IntegerToString(sells[i]));
      SetLabelText(CellName(row, 7), MoneyText(floats[i]));
      SetLabelText(CellName(row, 8), MoneyText(g_pairs[i].closed_profit));
      SetLabelColor(CellName(row, 7), floats[i] >= 0.0 ? CLR_POS : CLR_NEG);
      SetLabelColor(CellName(row, 8), g_pairs[i].closed_profit >= 0.0 ? CLR_POS : CLR_NEG);
      row++;
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
   SavePivotFilterState();
   EventKillTimer();
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

   if(sparam == BTN_PIVOT)
     {
      g_pivot_filter = !g_pivot_filter;
      ObjectSetInteger(0, BTN_PIVOT, OBJPROP_STATE, false);
      SavePivotFilterState();
      Print("Pivot filter: ", g_pivot_filter ? "ON" : "OFF");
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

      if(!IsDailyPivotTouched(pair_index))
        {
         SetPairAction(pair_index, "Pivot wait");
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

   // --- RULE 2: GRID LAYERING (no pivot filter) ---
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
