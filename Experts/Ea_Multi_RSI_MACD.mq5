//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Bingaman"
#property version   "1.00"

#include <Trade\Trade.mqh>
CTrade trade;


// ------ Input parameters ------
// General
input int      StopLoss          =  5;       // Pips, kk
input int      TakeProfit        =  5;       // Pips, jj
input double   Lot               =  1.0;

// MACD
input int      MACD_EMA_fast     =  10;      // MACD EMA fast period
input int      MACD_EMA_slow     =  10;      // MACD EMA slow period
input int      MACD_period       =  10;      // MACD EMA period

// RSI
input int      RSI_thresh        =  25;      // RSI threshold
input int      RSI_period        =  14;      // RSI Period
input int      RSI_win           =  3;       // Number of candles for open activity after RSI threshold cross
input int      RSI_thresh_hi     =  70;
input int      RSI_thresh_lo     =  30;


// ------ Local parameters ------
// Indicator handles
int MACDHandle;
int RSIHandle;

// Local data
double MACDdata[];      // Local MACD data copied from indicator
double RSIdata[];       // Local RSI data copied from indicator
int n_local_win = 10;   // Number of candles to copy over locally to work with




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
   {
      //--- Get the handle for MA indicator
      MACDHandle  = iMACD(_Symbol,_Period,MACD_EMA_fast,MACD_EMA_slow,MACD_period,PRICE_TYPICAL);
      RSIHandle   = iRSI(_Symbol,_Period,RSI_period,PRICE_CLOSE);
      
      //--- What if handle returns Invalid Handle
      if(MACDHandle<0 || RSIHandle<0)
      {
         Alert("Error Creating Handles for indicators - error: ",GetLastError(),"!");
      }
      
      // Add indicators to the current window
      //--- receive the number of a new subwindow, to which MACD indicator is added
      int subwindow=(int)ChartGetInteger(0,CHART_WINDOWS_TOTAL);
      PrintFormat("Adding new indicator on %d chart window",subwindow);
      if(!ChartIndicatorAdd(0,1,RSIHandle))
      {
         PrintFormat("Failed to add new indicator on %d chart window. Error code  %d",subwindow,GetLastError());
         //--- reset the error code
         ResetLastError();
      }
      
      ChartIndicatorAdd(0,0,MACDHandle);

   //---
   return(INIT_SUCCEEDED);
   }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
   {
   IndicatorRelease(MACDHandle);
   IndicatorRelease(RSIHandle);
   
   }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   { 
   }