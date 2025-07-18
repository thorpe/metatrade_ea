//+------------------------------------------------------------------+
//|                                                  Robo_MM_IFR.mq5 |
//|                                             rafaelfvcs@gmail.com |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "rafaelfvcs@gmail.com"
#property link "https://www.mql5.com"
#property version "1.00"

#include <Trade\Trade.mqh>
CTrade trade;

double takeProfit = 100;  // Take Profit
double stopLoss = 200;    // Stop Loss
int magicNumber = 546812; // Robot's magic number
int lotSize = 0.1;        // Number of Lots

//+------------------------------------------------------------------+
//| RSI Variables                                              |
//+------------------------------------------------------------------+
input int rsi_period_01 = 7;                          // RSI Period
input int rsi_period_02 = 14;                         // RSI Period
input int rsi_period_03 = 21;                         // RSI Period
input int rsi_period_04 = 28;                         // RSI Period
input ENUM_TIMEFRAMES rsi_timeframe = PERIOD_CURRENT; // RSI Chart Timeframe
input ENUM_APPLIED_PRICE rsi_price = PRICE_CLOSE;     // Applied Price

int rsiSellPostion = 70; // Overbought Level
int rsiBuyPostion = 30;  // Oversold Level

//+------------------------------------------------------------------+
//| Indicator Variables                                              |
//+------------------------------------------------------------------+
int rsiHandle1;      // Handle for RSI
int rsiHandle2;      // Handle for RSI
int rsiHandle3;      // Handle for RSI
int rsiHandle4;      // Handle for RSI
double rsiBuffer1[]; // Buffer for storing RSI data
double rsiBuffer2[]; // Buffer for storing RSI data
double rsiBuffer3[]; // Buffer for storing RSI data
double rsiBuffer4[]; // Buffer for storing RSI data
//+------------------------------------------------------------------+
//| Variables for Functions                                          |
//+------------------------------------------------------------------+
MqlRates candles[]; // Variable for storing candles
MqlTick tick;       // Variable for storing ticks

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   rsiHandle1 = iRSI(_Symbol, rsi_timeframe, rsi_period_01, rsi_price);
   rsiHandle2 = iRSI(_Symbol, rsi_timeframe, rsi_period_02, rsi_price);
   rsiHandle3 = iRSI(_Symbol, rsi_timeframe, rsi_period_03, rsi_price);
   rsiHandle4 = iRSI(_Symbol, rsi_timeframe, rsi_period_04, rsi_price);

   if (rsiHandle1 < 0)
   {
      Alert("Error creating indicator handles - error: ", GetLastError(), "!");
      return (-1);
   }

   CopyRates(_Symbol, _Period, 0, 4, candles);
   ArraySetAsSeries(candles, true);

   ChartIndicatorAdd(0, 1, rsiHandle1);
   ChartIndicatorAdd(0, 1, rsiHandle2);
   ChartIndicatorAdd(0, 1, rsiHandle3);
   ChartIndicatorAdd(0, 1, rsiHandle4);

   return (INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(rsiHandle1);
   IndicatorRelease(rsiHandle2);
   IndicatorRelease(rsiHandle3);
   IndicatorRelease(rsiHandle4);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   CopyBuffer(rsiHandle1, 0, 0, 4, rsiBuffer1);
   CopyBuffer(rsiHandle2, 0, 0, 4, rsiBuffer2);
   CopyBuffer(rsiHandle3, 0, 0, 4, rsiBuffer3);
   CopyBuffer(rsiHandle4, 0, 0, 4, rsiBuffer4);

   CopyRates(_Symbol, _Period, 0, 4, candles);
   ArraySetAsSeries(candles, true);

   SymbolInfoTick(_Symbol, tick);

   bool isLongSignal = false;
   bool isShortSignal = false;

   if (rsiBuffer1[0] <= rsiBuyPostion && rsiBuffer1[1] <= rsiBuyPostion && rsiBuffer1[2] <= rsiBuyPostion && rsiBuffer1[3] <= rsiBuyPostion)
   {
      isLongSignal = true;
   }

   if (rsiBuffer1[0] >= rsiSellPostion && rsiBuffer1[1] >= rsiSellPostion && rsiBuffer1[2] >= rsiSellPostion && rsiBuffer1[3] >= rsiSellPostion)
   {
      isShortSignal = true;
   }

   if (HasNewCandle())
   {
      if (isLongSignal && !PositionSelect(_Symbol))
      {
         Print("===================== Open Long Position =====================");
         DrawVerticalLine(candles[0].time, candles[0].time, clrBlue);
         // OpenLongPostion();
      }

      if (isShortSignal && !PositionSelect(_Symbol))
      {
         Print("===================== Open Short Position =====================");
         DrawVerticalLine("Sell", candles[0].time, clrRed);
         // OpenShortPostion();
      }
   }

   if (PositionSelect(_Symbol))
   {

      if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
      {
         Print("===================== Close Long Position =====================");
         // DrawVerticalLine(candles[0].time, candles[0].time, clrPurple);
         // CloseLongPosition();
      }
      else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
      {
         Print("===================== Close Short Position =====================");
         // DrawVerticalLine("Clear", candles[0].time, clrPurple);
         // CloseShortPosition();
      }
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
void OpenLongPostion()
{
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.magic = magicNumber;
   request.symbol = _Symbol;
   request.volume = 0.1;
   request.price = NormalizeDouble(tick.ask, _Digits);
   request.sl = NormalizeDouble(tick.ask - stopLoss * _Point, _Digits);
   request.tp = NormalizeDouble(tick.ask + takeProfit * _Point, _Digits);
   request.deviation = 10;
   request.type = ORDER_TYPE_BUY;
   request.type_filling = ORDER_FILLING_FOK;

   bool sent = OrderSend(request, result);

   if (result.retcode == 10008 || result.retcode == 10009)
      Print("Market Buy Order executed successfully!");
   else
   {
      Print("Market Buy Order - Error sending Buy Order. Error = ", GetLastError());
      ResetLastError();
   }
}

// Market Sell Order
void OpenShortPostion()
{
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.magic = magicNumber;
   request.symbol = _Symbol;
   request.volume = 0.1;
   request.price = NormalizeDouble(tick.bid, _Digits);
   request.sl = NormalizeDouble(tick.bid + stopLoss * _Point, _Digits);
   request.tp = NormalizeDouble(tick.bid - takeProfit * _Point, _Digits);
   request.deviation = 10;
   request.type = ORDER_TYPE_SELL;
   request.type_filling = ORDER_FILLING_FOK;

   bool sent = OrderSend(request, result);

   if (result.retcode == 10008 || result.retcode == 10009)
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
void CloseLongPosition()
{
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   ulong postionTicket = PositionGetTicket(0);
   if (PositionSelectByTicket(postionTicket))
   {
      request.action = TRADE_ACTION_DEAL;
      request.magic = magicNumber;
      request.symbol = _Symbol;
      request.volume = 0.1;
      request.type = ORDER_TYPE_SELL;
      request.position = postionTicket;
      request.price = NormalizeDouble(tick.bid, _Digits);
      request.deviation = 10;
      request.type_filling = ORDER_FILLING_FOK;

      bool sent = OrderSend(request, result);

      if (result.retcode == 10008 || result.retcode == 10009)
         Print("Buy Position closed successfully!");
      else
      {
         Print("Error closing Buy Position. Error = ", GetLastError());
         ResetLastError();
      }
   }
}

void CloseShortPosition()
{
   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.magic = magicNumber;
   request.symbol = _Symbol;
   request.volume = 0.1;
   request.price = NormalizeDouble(tick.ask, _Digits);
   request.type = ORDER_TYPE_BUY;
   request.type_filling = ORDER_FILLING_RETURN;

   bool sent = OrderSend(request, result);

   if (result.retcode == 10008 || result.retcode == 10009)
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
bool HasNewCandle()
{
   static string last_time = "";
   string current_time = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES | TIME_SECONDS);
   Print("CURRENT TIME : " + current_time);
   if (last_time == 0)
   {
      last_time = current_time;
      return false;
   }

   if (last_time != current_time)
   {
      last_time = current_time;
      return true;
   }

   return false;
}