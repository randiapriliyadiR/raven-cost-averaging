//+------------------------------------------------------------------+
//|                                                  RAVEN TANAM.mq5 |
//|                                                 Randi Apriliyadi |
//|                              https://github.com/randiapriliyadiR |
//+------------------------------------------------------------------+
#property copyright "Randi Apriliyadi"
#property link      "https://github.com/randiapriliyadiR"
#property version   "2.00"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

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

//--- Input Parameters
input string               Deskripsi_1            = "=== Pengaturan Dasar ===";
input ENUM_ACCOUNT_TYPE    AccountType            = ACCOUNT_CENT;       // Account Type
input double               BaseLot                = 0.1;                // Lot per Trade
input int                  PipStep                = 10;                 // Layer Spacing & Global TP (Pips)
input int                  MaxLayers              = 100;                // Max Layers
input ENUM_MAX_LAYER_SCOPE MaxLayerScope         = MAX_LAYER_MAGIC_ONLY; // Max Layer Scope
input string               Deskripsi_2            = "=== Basket Close ===";
input bool                 UseBasketClose         = true;               // Aktifkan Basket Close
input double               BasketCloseUSD         = 20.0;               // Basket Close Profit Target (USD)
input ulong                MagicNumber            = 111111;             // Magic Number

//--- Global Variables
CTrade         trade;
CPositionInfo  m_position;
datetime       last_trade_time = 0;
const int      TRADE_RETRY_COUNT = 2; // 1 percobaan awal + 2 retry

void ApplyTPToExistingEAOrders();

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
         Print("Buy retry ", attempt + 1, "/", TRADE_RETRY_COUNT, ". Retcode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }

   Print("Buy gagal setelah ", TRADE_RETRY_COUNT + 1, " percobaan. Retcode: ", trade.ResultRetcode());
   return false;
  }

bool SellWithRetry(double lot, string symbol, double price, double sl, double tp, string comment)
  {
   for(int attempt = 0; attempt <= TRADE_RETRY_COUNT; attempt++)
     {
      if(trade.Sell(lot, symbol, price, sl, tp, comment))
         return true;

      if(attempt < TRADE_RETRY_COUNT)
         Print("Sell retry ", attempt + 1, "/", TRADE_RETRY_COUNT, ". Retcode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }

   Print("Sell gagal setelah ", TRADE_RETRY_COUNT + 1, " percobaan. Retcode: ", trade.ResultRetcode());
   return false;
  }

bool PositionModifyWithRetry(ulong ticket, double sl, double tp)
  {
   for(int attempt = 0; attempt <= TRADE_RETRY_COUNT; attempt++)
     {
      if(trade.PositionModify(ticket, sl, tp))
         return true;

      if(attempt < TRADE_RETRY_COUNT)
         Print("Modify retry ", attempt + 1, "/", TRADE_RETRY_COUNT, " ticket ", ticket, ". Retcode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }

   Print("Modify gagal setelah ", TRADE_RETRY_COUNT + 1, " percobaan. Ticket: ", ticket, " Retcode: ", trade.ResultRetcode());
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
         Print("Close retry ", attempt + 1, "/", TRADE_RETRY_COUNT, " ticket ", ticket, ". Retcode: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
     }

   Print("Close gagal setelah ", TRADE_RETRY_COUNT + 1, " percobaan. Ticket: ", ticket, " Retcode: ", trade.ResultRetcode());
   return false;
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);
   ApplyTPToExistingEAOrders();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(UseBasketClose)
      CheckBasketProfit();

   ManageGridAndGlobalTP();
  }

//+------------------------------------------------------------------+
//| Sinkronisasi TP agar tetap aktif walau EA mati                   |
//+------------------------------------------------------------------+
void SyncBasketTP(double first_buy_price, double first_sell_price, double gap)
  {
   double target_buy_tp = 0.0;
   double target_sell_tp = 0.0;

   if(first_buy_price > 0.0)
      target_buy_tp = NormalizeDouble(first_buy_price + gap, _Digits);
   if(first_sell_price > 0.0)
      target_sell_tp = NormalizeDouble(first_sell_price - gap, _Digits);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() != _Symbol || m_position.Magic() != MagicNumber)
            continue;

         double current_sl = m_position.StopLoss();
         double current_tp = m_position.TakeProfit();
         ulong ticket = m_position.Ticket();

         if(m_position.PositionType() == POSITION_TYPE_BUY && target_buy_tp > 0.0)
           {
            if(MathAbs(current_tp - target_buy_tp) > (_Point / 2.0))
               PositionModifyWithRetry(ticket, current_sl, target_buy_tp);
           }
         else if(m_position.PositionType() == POSITION_TYPE_SELL && target_sell_tp > 0.0)
           {
            if(MathAbs(current_tp - target_sell_tp) > (_Point / 2.0))
               PositionModifyWithRetry(ticket, current_sl, target_sell_tp);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Pasang TP untuk posisi lama saat EA attach/restart               |
//+------------------------------------------------------------------+
void ApplyTPToExistingEAOrders()
  {
   double anchor_buy_price = 0.0;
   double anchor_sell_price = 0.0;
   double lowest_buy_price = 999999.0;
   double highest_sell_price = 0.0;
   int total_buys = 0;
   int total_sells = 0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(m_position.Symbol() != _Symbol || m_position.Magic() != MagicNumber)
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

   if(total_buys > 0 || total_sells > 0)
     {
      double gap = PipToPrice(PipStep);
      SyncBasketTP(anchor_buy_price, anchor_sell_price, gap);
     }
  }

//+------------------------------------------------------------------+
//| Fungsi Konversi Pip ke Nilai Harga                               |
//+------------------------------------------------------------------+
double PipToPrice(double pips)
  {
   if(_Digits == 3 || _Digits == 5) return pips * 10.0 * _Point;
   return pips * _Point;
  }

//+------------------------------------------------------------------+
//| Fungsi Cek Profit Basket $20 (Dinamis Standar/Cent)               |
//+------------------------------------------------------------------+
void CheckBasketProfit()
  {
   if(!UseBasketClose)
      return;

   double target_value = 0.0;
   
   if(AccountType == ACCOUNT_CENT)
     {
      target_value = BasketCloseUSD * 100.0; // Cent account: $20 = 2000 cents
     }
   else if(AccountType == ACCOUNT_STANDARD)
     {
      target_value = BasketCloseUSD;         // Standard account: $20 = 20 USD
     }

   double basket_profit = 0.0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == MagicNumber)
           {
            basket_profit += m_position.Profit() + m_position.Swap() + m_position.Commission();
           }
        }
     }

   if(basket_profit >= target_value)
     {
      CloseAllEAOrders();
      Print("Basket close tercapai. Total profit: ", basket_profit, " | Target: ", target_value);
     }
  }

//+------------------------------------------------------------------+
//| Hitung jumlah layer buy/sell sesuai scope MaxLayers              |
//+------------------------------------------------------------------+
void GetLayerCounts(int &buy_layers, int &sell_layers)
  {
   buy_layers = 0;
   sell_layers = 0;

   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(!m_position.SelectByIndex(i))
         continue;

      if(MaxLayerScope == MAX_LAYER_MAGIC_ONLY)
        {
         if(m_position.Symbol() != _Symbol || m_position.Magic() != MagicNumber)
            continue;
        }

      if(m_position.PositionType() == POSITION_TYPE_BUY)
         buy_layers++;
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
         sell_layers++;
     }
  }

//+------------------------------------------------------------------+
//| Fungsi Manajemen Grid Layering dan TP Global                     |
//+------------------------------------------------------------------+
void ManageGridAndGlobalTP()
  {
   int total_buys = 0;
   int total_sells = 0;
   int buy_layer_count = 0;
   int sell_layer_count = 0;
   
   double anchor_buy_price = 0;   // Entry awal buy = harga buy tertinggi (layer pertama)
   double lowest_buy_price = 999999;
   double anchor_sell_price = 0;  // Entry awal sell = harga sell terendah (layer pertama)
   double highest_sell_price = 0;
   
   // --- SCANNING POSISI ---
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol)
           {
            if(m_position.Magic() == MagicNumber)
              {
               if(m_position.PositionType() == POSITION_TYPE_BUY)
                 {
                  double open_price = m_position.PriceOpen();
                  total_buys++;
                  if(anchor_buy_price == 0.0 || open_price > anchor_buy_price)
                     anchor_buy_price = open_price;
                  if(open_price < lowest_buy_price)
                     lowest_buy_price = open_price;
                 }
               else if(m_position.PositionType() == POSITION_TYPE_SELL)
                 {
                  double open_price = m_position.PriceOpen();
                  total_sells++;
                  if(anchor_sell_price == 0.0 || open_price < anchor_sell_price)
                     anchor_sell_price = open_price;
                  if(open_price > highest_sell_price)
                     highest_sell_price = open_price;
                 }
              }
           }
        }
     }
     
   GetLayerCounts(buy_layer_count, sell_layer_count);
     
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double gap = PipToPrice(PipStep);
   
   // --- ATURAN 1: KONDISI AWAL (Langsung Open Buy & Sell) ---
   if(total_buys == 0 && total_sells == 0)
     {
      // Pastikan total trade keseluruhan di symbol ini belum menyentuh batas maksimum
      if(buy_layer_count < MaxLayers && sell_layer_count < MaxLayers)
        {
         if(TimeCurrent() - last_trade_time > 3)
           {
            double initial_buy_tp = NormalizeDouble(ask + gap, _Digits);
            double initial_sell_tp = NormalizeDouble(bid - gap, _Digits);

            BuyWithRetry(BaseLot, _Symbol, ask, 0, initial_buy_tp, "Initial Buy");
            SellWithRetry(BaseLot, _Symbol, bid, 0, initial_sell_tp, "Initial Sell");
            last_trade_time = TimeCurrent();
           }
        }
      return;
     }

   // Pastikan semua posisi layer punya TP broker-side yang sama (anchor posisi pertama)
   SyncBasketTP(anchor_buy_price, anchor_sell_price, gap);
     
   // --- ATURAN 2: GRID LAYERING (Counter Trend / Averaging) ---
   
   // Layer Buy saat harga turun
   if(total_buys > 0 && buy_layer_count < MaxLayers && ask <= (lowest_buy_price - gap))
     {
      if(TimeCurrent() - last_trade_time > 3)
        {
         double grid_buy_tp = NormalizeDouble(anchor_buy_price + gap, _Digits);
         BuyWithRetry(BaseLot, _Symbol, ask, 0, grid_buy_tp, "Grid Buy Layer");
         last_trade_time = TimeCurrent();
        }
     }
     
   // Layer Sell saat harga naik
   if(total_sells > 0 && sell_layer_count < MaxLayers && bid >= (highest_sell_price + gap))
     {
      if(TimeCurrent() - last_trade_time > 3)
        {
         double grid_sell_tp = NormalizeDouble(anchor_sell_price - gap, _Digits);
         SellWithRetry(BaseLot, _Symbol, bid, 0, grid_sell_tp, "Grid Sell Layer");
         last_trade_time = TimeCurrent();
        }
     }
     
   // --- ATURAN 3: TP GLOBAL STABIL (Berdasarkan Posisi Pertama menggunakan parameter PipStep) ---
   if(total_buys > 0)
     {
      double global_tp_buy = anchor_buy_price + PipToPrice(PipStep);
      if(bid >= global_tp_buy)
        {
         CloseAllDirection(POSITION_TYPE_BUY);
         Print("TP Global Buy Terpenuhi.");
        }
     }
     
   if(total_sells > 0)
     {
      double global_tp_sell = anchor_sell_price - PipToPrice(PipStep);
      if(ask <= global_tp_sell)
        {
         CloseAllDirection(POSITION_TYPE_SELL);
         Print("TP Global Sell Terpenuhi.");
        }
     }
  }

//+------------------------------------------------------------------+
//| Fungsi Mass Close Per Arah Posisi                                |
//+------------------------------------------------------------------+
void CloseAllDirection(ENUM_POSITION_TYPE type)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == MagicNumber && m_position.PositionType() == type)
           {
            PositionCloseWithRetry(m_position.Ticket());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Fungsi Mass Close Semua Posisi EA                                |
//+------------------------------------------------------------------+
void CloseAllEAOrders()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Symbol() == _Symbol && m_position.Magic() == MagicNumber)
           {
            PositionCloseWithRetry(m_position.Ticket());
           }
        }
     }
  }
//+------------------------------------------------------------------+