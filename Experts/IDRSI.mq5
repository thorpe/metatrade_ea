//+------------------------------------------------------------------+
//|                                                  Robo_MM_IFR.mq5 |
//|                                             rafaelfvcs@gmail.com |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2024, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"
//---

int rsi_period = 14;                            // RSI Period
ENUM_TIMEFRAMES rsi_timeframe = PERIOD_CURRENT; // RSI Chart Timeframe
ENUM_APPLIED_PRICE rsi_price = PRICE_CLOSE;     // Applied Price

//---
//+------------------------------------------------------------------+
//| Indicator Variables                                              |
//+------------------------------------------------------------------+
int rsi_Handle; // Handle for RSI

//+------------------------------------------------------------------+
//| Variables for Functions                                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   rsi_Handle = iRSI(_Symbol, rsi_timeframe, rsi_period, rsi_price);

   ChartIndicatorAdd(0, 1, rsi_Handle);

   return (INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}
