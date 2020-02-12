//+------------------------------------------------------------------+
//|                                                  GmtCalcTest.mq4 |
//|                                       Copyright 2018, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dale Woods"
#property link      "https://www.theforexguy.com"
#property version   "1.00"
#property strict

#include "..\ForexSessionTime.mqh"


//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart() {
   
   string comment;
   
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   
   int fileOffset;
   ForexSessionTime::ReadOffsetFromFile(fileOffset);
   
   comment = StringConcatenate(comment, "ForexSessionTime Class Test \n");
   comment = StringConcatenate(comment, StringFormat("Broker GMT Offset = %d \n", ForexSessionTime::GetBrokerGMTOffset()) );
   comment = StringConcatenate(comment, StringFormat("Broker GMT Offset Stored In File = %d \n", fileOffset) );
   comment = StringConcatenate(comment, StringFormat("Broker London Session Open Hour = %d \n", ForexSessionTime::GetSessionBrokerHour(now,SESSION_TIME_LONDON_OPEN)) );
   comment = StringConcatenate(comment, StringFormat("Broker Us Session Open Hour = %d \n", ForexSessionTime::GetSessionBrokerHour(now,SESSION_TIME_NEW_YORK_OPEN)) );
   comment = StringConcatenate(comment, StringFormat("Broker Us Session Close Hour = %d \n", ForexSessionTime::GetSessionBrokerHour(now,SESSION_TIME_NEW_YORK_CLOSE)) );
   
   comment = StringConcatenate(comment, StringFormat("London Open Price = %f \n", ForexSessionTime::GetSessionOpenPrice(_Symbol,SESSION_LONDON)) );
   comment = StringConcatenate(comment, StringFormat("US Open Price = %f \n", ForexSessionTime::GetSessionOpenPrice(_Symbol,SESSION_US)) );
   Comment(comment);

}
//+------------------------------------------------------------------+
