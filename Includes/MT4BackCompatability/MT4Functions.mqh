//+------------------------------------------------------------------+
//|                                                 MT4Functions.mqh |
//|                                      Copyright 2019, Dale Woods. |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Dale Woods."
#property link      "https://www.theforexguy.com"

#ifndef __MQL4__

#include "..\Common\Compatibility.mqh"

int WindowHandle(const  string symbol, const int tf) {
   ENUM_TIMEFRAMES timeframe = To_TFENUM(tf);
   long currChart,prevChart=ChartFirst();
   int i=0,limit=100;
   while(i<limit)
     {
      currChart=ChartNext(prevChart);
      if(currChart<0) break;
      if(ChartSymbol(currChart)==symbol
         && ChartPeriod(currChart)==timeframe)
         return((int)currChart);
      prevChart=currChart;
      i++;
     }
   return(0);
}




int WindowFind(const string name) {
   int window=-1;
   if( (ENUM_PROGRAM_TYPE) MQLInfoInteger(MQL_PROGRAM_TYPE) == PROGRAM_INDICATOR)
     {
      window=ChartWindowFind();
     }
   else
     {
      window=ChartWindowFind(0,name);
      if(window==-1) Print(__FUNCTION__+"(): Error = ",GetLastError());
     }
   return(window);
}


int TimeDayOfWeek(datetime date) {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.day_of_week);
}


int TimeDay(datetime date) {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.day);
}


int TimeHour(datetime date) {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.hour);
}


int TimeMonth(datetime date) {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.mon);
}


int TimeYear(datetime date) {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.year);
}

datetime StrToTime(string value) {
   return StringToTime(value);
}


bool RefreshRates() { return true; }


bool IsConnected() {
    return (bool) TerminalInfoInteger(TERMINAL_CONNECTED);
}


double MarketInfo(string symbol, int type) {
   return 0;
   /*
   switch(type)
     {
      case MODE_LOW:
         return(SymbolInfoDouble(symbol,SYMBOL_LASTLOW));
      case MODE_HIGH:
         return(SymbolInfoDouble(symbol,SYMBOL_LASTHIGH));
      case MODE_TIME:
         return(SymbolInfoInteger(symbol,SYMBOL_TIME));
      case MODE_BID:
         return(Bid);
      case MODE_ASK:
         return(Ask);
      case MODE_POINT:
         return(SymbolInfoDouble(symbol,SYMBOL_POINT));
      case MODE_DIGITS:
         return(SymbolInfoInteger(symbol,SYMBOL_DIGITS));
      case MODE_SPREAD:
         return(SymbolInfoInteger(symbol,SYMBOL_SPREAD));
      case MODE_STOPLEVEL:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL));
      case MODE_LOTSIZE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_CONTRACT_SIZE));
      case MODE_TICKVALUE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE));
      case MODE_TICKSIZE:
         return(SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE));
      case MODE_SWAPLONG:
         return(SymbolInfoDouble(symbol,SYMBOL_SWAP_LONG));
      case MODE_SWAPSHORT:
         return(SymbolInfoDouble(symbol,SYMBOL_SWAP_SHORT));
      case MODE_STARTING:
         return(0);
      case MODE_EXPIRATION:
         return(0);
      case MODE_TRADEALLOWED:
         return(0);
      case MODE_MINLOT:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN));
      case MODE_LOTSTEP:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP));
      case MODE_MAXLOT:
         return(SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX));
      case MODE_SWAPTYPE:
         return(SymbolInfoInteger(symbol,SYMBOL_SWAP_MODE));
      case MODE_PROFITCALCMODE:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_CALC_MODE));
      case MODE_MARGINCALCMODE:
         return(0);
      case MODE_MARGININIT:
         return(0);
      case MODE_MARGINMAINTENANCE:
         return(0);
      case MODE_MARGINHEDGED:
         return(0);
      case MODE_MARGINREQUIRED:
         return(0);
      case MODE_FREEZELEVEL:
         return(SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL));

      default: return(0);
     } */
   return(0);
}

#endif 


