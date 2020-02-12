//+------------------------------------------------------------------+
//|                                                       Market.mqh |
//|                                       Copyright 2017, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Dale Woods"
#property link      "https://www.theforexguy.com"
#property version   "1.00"
#property strict

class Market {
   private:
   
   public:
      Market();
      ~Market();
      
      static bool IsOpen(const string symbol) {
       
         if( StringLen(symbol) > 1 ) {
            datetime  begin = 0, end = 0, now = TimeCurrent();
            uint      session_index=0;
      
            MqlDateTime today;
            TimeToStruct(now,today);
            
            if(SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK) today.day_of_week,session_index,begin,end)==true) {
               string 
                  snow     = TimeToString(now,TIME_MINUTES|TIME_SECONDS),
                  sbegin   = TimeToString(begin,TIME_MINUTES|TIME_SECONDS),
                  send     = TimeToString(end-1,TIME_MINUTES|TIME_SECONDS);
      
               now         = StringToTime(snow);
               begin       = StringToTime(sbegin);
               end         = StringToTime(send);
      
               if(now>=begin && now<=end) { return true; }
               else { return false; }
              }
           }
           
         printf("[ERROR] %s: was passed an invalid symbol!");         
         return false;
      }
};

