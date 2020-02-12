//+------------------------------------------------------------------+
//|                                                        Debug.mqh |
//|                                      Copyright 2018, Dale Woods. |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dale Woods."
#property link      "https://www.theforexguy.com"

#define pDebug(eMsg) { DebugLine(__FUNCTION__, __LINE__, eMsg); } 

void DebugLine(const string func, const int line, const string errorMsg) { 
   printf("[%s DEBUG] [%i]: %s", func, line, errorMsg);
}



string ToString(const MqlRates &rate) {
   return StringFormat("Writing new candle... %s | %f %f %f %f | realv = %d tickv = %d | spread = %d", 
      TimeToString(rate.time),
      rate.high,
      rate.open,
      rate.low,
      rate.close,
      rate.real_volume,
      rate.tick_volume,
      rate.spread
   );
}