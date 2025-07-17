//+------------------------------------------------------------------+
//|                                                  Robo_MM_IFR.mq5 |
//|                                             rafaelfvcs@gmail.com |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "rafaelfvcs@gmail.com"
#property link      "https://www.mql5.com"
#property version   "1.00"
//---
enum ENTRY_STRATEGY
{
   ONLY_MA,     // Only Moving Averages
   ONLY_RSI,    // Only RSI
   MA_AND_RSI   // Moving Averages and RSI
};
//---

// Input Variables
sinput string s0; //-----------Entry Strategy-------------
input ENTRY_STRATEGY entry_strategy  = MA_AND_RSI;     // Trader Entry Strategy

sinput string s1; //-----------Moving Averages-------------
input int fast_ma_period             = 12;         // Fast MA Period
input int slow_ma_period             = 36;         // Slow MA Period
input ENUM_TIMEFRAMES ma_timeframe   = PERIOD_CURRENT; // Chart Timeframe
input ENUM_MA_METHOD  ma_method      = MODE_EMA;   // Method
input ENUM_APPLIED_PRICE  ma_price   = PRICE_CLOSE; // Applied Price

sinput string s2; //-----------RSI-------------
input int rsi_period                 = 5;          // RSI Period
input ENUM_TIMEFRAMES rsi_timeframe  = PERIOD_CURRENT; // RSI Chart Timeframe
input ENUM_APPLIED_PRICE rsi_price   = PRICE_CLOSE; // Applied Price

int rsi_overbought             = 70;         // Overbought Level
int rsi_oversold               = 30;         // Oversold Level

sinput string s3; //---------------------------
int lot_size                   = 0.1;        // Number of Lots
double take_profit             = 30;         // Take Profit
double stop_loss               = 30;         // Stop Loss

sinput string s4; //---------------------------
input string close_position_time     = "17:40";    // Position Closing Time Limit
//---
//+------------------------------------------------------------------+
//| Indicator Variables                                              |
//+------------------------------------------------------------------+
//--- Moving Averages
// FAST - shorter period
int fast_ma_Handle;      // Handle for fast moving average
double fast_ma_Buffer[]; // Buffer for storing fast moving average data

// SLOW - longer period
int slow_ma_Handle;      // Handle for slow moving average
double slow_ma_Buffer[]; // Buffer for storing slow moving average data

//--- RSI
int rsi_Handle;           // Handle for RSI
double rsi_Buffer[];      // Buffer for storing RSI data

//+------------------------------------------------------------------+
//| Variables for Functions                                          |
//+------------------------------------------------------------------+

int magic_number = 972090; // Robot's magic number


MqlRates candles[];        // Variable for storing candles
MqlTick tick;              // Variable for storing ticks

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Create handles for indicators
   fast_ma_Handle = iMA(_Symbol, ma_timeframe, fast_ma_period, 0, ma_method, ma_price);
   slow_ma_Handle = iMA(_Symbol, ma_timeframe, slow_ma_period, 0, ma_method, ma_price);
   rsi_Handle = iRSI(_Symbol, rsi_timeframe, rsi_period, rsi_price);

   if(fast_ma_Handle < 0 || slow_ma_Handle < 0 || rsi_Handle < 0)
   {
      Alert("Error creating indicator handles - error: ", GetLastError(), "!");
      return(-1);
   }
   
   CopyRates(_Symbol, _Period, 0, 4, candles);
   ArraySetAsSeries(candles, true);

   ChartIndicatorAdd(0, 0, fast_ma_Handle);
   ChartIndicatorAdd(0, 0, slow_ma_Handle);
   ChartIndicatorAdd(0, 1, rsi_Handle);
   
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(fast_ma_Handle);
   IndicatorRelease(slow_ma_Handle);
   IndicatorRelease(rsi_Handle);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    CopyBuffer(fast_ma_Handle, 0, 0, 4, fast_ma_Buffer);
    CopyBuffer(slow_ma_Handle, 0, 0, 4, slow_ma_Buffer);
    CopyBuffer(rsi_Handle, 0, 0, 4, rsi_Buffer);

    CopyRates(_Symbol, _Period, 0, 4, candles);
    ArraySetAsSeries(candles, true);

    SymbolInfoTick(_Symbol, tick);

    // Logic for Buy and Sell Signals
    bool buy_ma_cross = fast_ma_Buffer[0] > slow_ma_Buffer[0] && fast_ma_Buffer[2] < slow_ma_Buffer[2];
    bool buy_rsi = rsi_Buffer[3] <= rsi_oversold;

    bool sell_ma_cross = slow_ma_Buffer[0] > fast_ma_Buffer[0] && slow_ma_Buffer[2] < fast_ma_Buffer[2];
    bool sell_rsi = rsi_Buffer[3] >= rsi_overbought;

    bool CanBuy = false; // Can Buy?
    bool CanSell = false; // Can Sell?
  

    if(entry_strategy == ONLY_MA)
    {
        CanBuy = buy_ma_cross;
        CanSell = sell_ma_cross;
    } else if(entry_strategy == ONLY_RSI) {
        CanBuy = buy_rsi;
        CanSell = sell_rsi;
    } else {
        CanBuy = buy_ma_cross && buy_rsi;
        CanSell = sell_ma_cross && sell_rsi;
    }

    Print("==================");
    bool hasNewCandle = HasNewCandle();
    
    Print("RSI BUFF : " + rsi_Buffer[3]);
    Print("RSI BUY  : " + buy_rsi + " | " + buy_ma_cross );
    Print("RSI SELL : " + sell_rsi + " | " + sell_ma_cross);
    Print("Candle : " + hasNewCandle);
    Print("CanBuy : " +CanBuy);
    Print("CanSell : " +CanSell);
    //Print(PositionSelect(_Symbol));
    

    if(hasNewCandle)
    {
        if(CanBuy && !PositionSelect(_Symbol))
        {
            Print("Order Buy=====================");
            DrawVerticalLine("Buy", candles[1].time, clrBlue);
            PlaceMarketBuyOrder();
        }
        if(CanSell && !PositionSelect(_Symbol))
        {
            Print("Order Sell=====================");
            DrawVerticalLine("Sell", candles[1].time, clrRed);
            PlaceMarketSellOrder();
        }
    }

    if(TimeToString(TimeCurrent(), TIME_MINUTES) == close_position_time && PositionSelect(_Symbol))
    {
        Print("-----> End of Trading Time: closing open positions!");
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            CloseBuyPosition();
        else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            CloseSellPosition();
    }
}

//+------------------------------------------------------------------+
//| Functions for Visualization                                      |
//+------------------------------------------------------------------+

void DrawVerticalLine(string name, datetime time, color line_color = clrBlueViolet)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_VLINE, 0, time, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, line_color);
}

//+------------------------------------------------------------------+
//| Functions for Order Placement                                    |
//+------------------------------------------------------------------+

// Market Buy Order
void PlaceMarketBuyOrder()
{
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action       = TRADE_ACTION_DEAL;
   request.magic        = magic_number;
   request.symbol       = _Symbol;
   request.volume       = 0.1;
   request.price        = NormalizeDouble(tick.ask, _Digits);
   request.sl           = NormalizeDouble(tick.ask - stop_loss * _Point, _Digits);
   request.tp           = NormalizeDouble(tick.ask + take_profit * _Point, _Digits);
   request.deviation    = 0;
   request.type         = ORDER_TYPE_BUY;
   request.type_filling = ORDER_FILLING_FOK;

   bool sent = OrderSend(request, result);

   if(result.retcode == 10008 || result.retcode == 10009)
      Print("Market Buy Order executed successfully!");
   else
   {
      Print("Market Buy Order - Error sending Buy Order. Error = ", GetLastError());
      ResetLastError();
   }
}

// Market Sell Order
void PlaceMarketSellOrder()
{
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action       = TRADE_ACTION_DEAL;
   request.magic        = magic_number;
   request.symbol       = _Symbol;
   request.volume       = 0.1;
   request.price        = NormalizeDouble(tick.bid, _Digits);
   request.sl           = NormalizeDouble(tick.bid + stop_loss * _Point, _Digits);
   request.tp           = NormalizeDouble(tick.bid - take_profit * _Point, _Digits);
   request.deviation    = 10;
   request.type         = ORDER_TYPE_SELL;
   request.type_filling = ORDER_FILLING_FOK;

   bool sent = OrderSend(request, result);

   if(result.retcode == 10008 || result.retcode == 10009)
      Print("Market Sell Order executed successfully!");
   else
   {
      Print("Market Sell Order - Error sending Sell Order. Error = ", GetLastError());
      ResetLastError();
   }
}

//+------------------------------------------------------------------+
//| Functions for Closing Positions                                  |
//+------------------------------------------------------------------+

void CloseBuyPosition()
{
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action       = TRADE_ACTION_DEAL;
   request.magic        = magic_number;
   request.symbol       = _Symbol;
   request.volume       = lot_size;
   request.price        = NormalizeDouble(tick.bid, _Digits);
   request.type         = ORDER_TYPE_SELL;
   request.type_filling = ORDER_FILLING_RETURN;

   bool sent = OrderSend(request, result);

   if(result.retcode == 10008 || result.retcode == 10009)
      Print("Buy Position closed successfully!");
   else
   {
      Print("Error closing Buy Position. Error = ", GetLastError());
      ResetLastError();
   }
}

void CloseSellPosition()
{
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action       = TRADE_ACTION_DEAL;
   request.magic        = magic_number;
   request.symbol       = _Symbol;
   request.volume       = lot_size;
   request.price        = NormalizeDouble(tick.ask, _Digits);
   request.type         = ORDER_TYPE_BUY;
   request.type_filling = ORDER_FILLING_RETURN;

   bool sent = OrderSend(request, result);

   if(result.retcode == 10008 || result.retcode == 10009)
      Print("Sell Position closed successfully!");
   else
   {
      Print("Error closing Sell Position. Error = ", GetLastError());
      ResetLastError();
   }
}

//+------------------------------------------------------------------+
//| Utility Functions                                                |
//+------------------------------------------------------------------+

// Check for New Candle
bool HasNewCandle()
{
   static string last_time = "";

   string current_time = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
    Print("CURRENT TIME : " + current_time);
   if(last_time == 0)
   {
      last_time = current_time;
      return false;
   }

   if(last_time != current_time)
   {
      last_time = current_time;
      return true;
   }

   return false;
}