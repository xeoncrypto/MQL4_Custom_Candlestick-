//+------------------------------------------------------------------+
//|                                                Compatibility.mqh |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"


#ifdef __MQL5__
   //timeframe type
   #define t_timeframe ENUM_TIMEFRAMES
   
#else
   
   //timeframe type
   #define t_timeframe int   
   
   //extend MT4 time frame constants
   #define PERIOD_M2             2   
   #define PERIOD_M3             3
   #define PERIOD_M4             4
   #define PERIOD_M6             6
   #define PERIOD_M10            10
   #define PERIOD_M12            12
      
   #define PERIOD_H2             120
   #define PERIOD_H3             180
   #define PERIOD_H6             360
   #define PERIOD_H8             480
   #define PERIOD_H12            720   
#endif

#define PERIOD_H48            2880
#define PERIOD_H72            4320   



int To_Int(const t_timeframe tf) {
   switch(tf) {
      case PERIOD_CURRENT: return(0);
      case PERIOD_M1: return(1);
      case PERIOD_M2: return(2);
      case PERIOD_M3: return(3);
      case PERIOD_M4: return(4);
      case PERIOD_M5: return(5);
      case PERIOD_M6: return(6);
      case PERIOD_M10: return(10);
      case PERIOD_M12: return(12); 
      case PERIOD_M15: return(15);
      case PERIOD_M30: return(30);
      case PERIOD_H1: return(60);
      case PERIOD_H2: return(120);
      case PERIOD_H3: return(180);
      case PERIOD_H4: return(240);
      case PERIOD_H6: return(360);
      case PERIOD_H8: return(480);
      case PERIOD_H12: return(720);
      case PERIOD_D1: return(1440);
      case PERIOD_W1: return(10080);
      case PERIOD_MN1: return(42300);     
      default: return(PERIOD_CURRENT);
   }
}


 
int To_Seconds(const int tf) {
   return tf * 60;
}



int To_Seconds(const ENUM_TIMEFRAMES tf) {
   return To_Int(tf) * 60;
}



ENUM_TIMEFRAMES To_TFENUM(const int tf) {
   switch(tf) {
      case 0: return(PERIOD_CURRENT);
      case 1: return(PERIOD_M1);
      case 2: return(PERIOD_M2);
      case 3: return(PERIOD_M3);
      case 4: return(PERIOD_M4);
      case 5: return(PERIOD_M5);
      case 6: return(PERIOD_M6);
      case 10: return(PERIOD_M10);
      case 12: return(PERIOD_M12); 
      case 15: return(PERIOD_M15);
      case 30: return(PERIOD_M30);
      case 60: return(PERIOD_H1);
      case 120: return(PERIOD_H2);
      case 180: return(PERIOD_H3);
      case 240: return(PERIOD_H4);
      case 360: return(PERIOD_H6);
      case 480: return(PERIOD_H8);
      case 720: return(PERIOD_H12);
      case 1440: return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 42300: return(PERIOD_MN1);
      
      //special mql5 int values
      case 16385: return(PERIOD_H1);
      case 16386: return(PERIOD_H2);
      case 16387: return(PERIOD_H3);
      case 16388: return(PERIOD_H4);
      case 16390: return(PERIOD_H6);
      case 16392: return(PERIOD_H8);
      case 16396: return(PERIOD_H12);
      case 16408: return(PERIOD_D1);
      case 32769: return(PERIOD_W1);
      case 49153: return(PERIOD_MN1);  
      default: return(PERIOD_CURRENT);
   }
}



//+------------------------------------------------------------------+
//|     TIME SERIES ACCESS                                           |
//+------------------------------------------------------------------+
double GetClose(string symbol, t_timeframe tf, int shift) {
   #ifdef __MQL5__
      double timeseries[1];
      return ( CopyClose(symbol, tf, shift, 1,timeseries) == 1 ) ? timeseries[0] : 0;
   #else
      return iClose(symbol, tf, shift);
   #endif
}

double GetOpen(string symbol, t_timeframe tf, int shift) {
   #ifdef __MQL5__
      double timeseries[1];
      return ( CopyOpen(symbol, tf, shift, 1,timeseries) == 1 ) ? timeseries[0] : 0;  
   #else
      return iOpen(symbol, tf, shift);
   #endif
}

double GetHigh(string symbol, t_timeframe tf, int shift) {
   #ifdef __MQL5__
      double timeseries[1];
      ResetLastError();
      if( CopyHigh(symbol, tf, shift, 1,timeseries) == -1) { 
         printf("[%s DEBUG]: copy high error %i", __FUNCTION__, GetLastError());
      }
      return ( CopyHigh(symbol, tf, shift, 1,timeseries) == 1 ) ? timeseries[0] : 0;
   #else
      return iHigh(symbol, tf, shift);
   #endif
}

double GetLow(string symbol, t_timeframe tf, int shift) {
   #ifdef __MQL5__
      double timeseries[1];
      return ( CopyLow(symbol, tf, shift, 1,timeseries) == 1 ) ? timeseries[0] : 0;     
   #else
      return iLow(symbol, tf, shift);
   #endif
}

datetime GetTime(string symbol, t_timeframe tf, int shift) {
   #ifdef __MQL5__
      datetime timeseries[1];
      return ( CopyTime(symbol, tf, shift, 1,timeseries) == 1 ) ? timeseries[0] : 0;     
   #else
      return iTime(symbol, tf, shift);
   #endif
}


datetime GetTime(int shift) {
   #ifdef __MQL5__
      datetime timeseries[1];
      return ( CopyTime(Symbol(), Period(), shift, 1,timeseries) == 1 ) ? timeseries[0] : 0;     
   #else
      return iTime(Symbol(), Period(), shift);
   #endif
}
      
   
   
/*
   Thanks to: Alain Verleyen
   https://www.mql5.com/en/code/1864
*/
int GetBarShift(string symbol, t_timeframe timeframe, datetime time, bool exact=false) {
   #ifdef __MQL5__
      datetime LastBar;
      if(!SeriesInfoInteger(symbol,timeframe,SERIES_LASTBAR_DATE,LastBar)) {
         //-- Sometimes SeriesInfoInteger with SERIES_LASTBAR_DATE return an error,
         //-- so we try an other method
         datetime opentimelastbar[1];
         if(CopyTime(symbol,timeframe,0,1,opentimelastbar)==1)
            LastBar=opentimelastbar[0];
         else
            return(-1);
        }
      //if time > LastBar we always return 0
      if(time>LastBar)
         return(0);
      //---
      int shift=Bars(symbol,timeframe,time,LastBar);
      datetime checkcandle[1];
   
      //-- If time requested doesn't match opening time of a candle, 
      //-- we need a correction of shift value
      if(CopyTime(symbol,timeframe,time,1,checkcandle)==1) {
         if(checkcandle[0]==time)
            return(shift-1);
         else if(exact && time>checkcandle[0]+PeriodSeconds(timeframe))
            return(-1);
         else
            return(shift);
   
         /*
            Can be replaced by the following statement for more concision 
            return(checkcandle[0]==time ? shift-1 : (exact && time>checkcandle[0]+PeriodSeconds(timeframe) ? -1 : shift));
          */
         }
      return(-1);
   #else
      return iBarShift(symbol, timeframe, time, exact);
   #endif      
      
}
   
   
