//+------------------------------------------------------------------+
//|                                                    RenkoTest.mq4 |
//|                                       Copyright 2018, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dale Woods"
#property link      "https://www.theforexguy.com"
#property version   "1.00"
#property strict


/*
   Task - Rebuild Custom Candle Class ( CustomBuilders\CustomCandleBuilder.mqh )
   
      -  CustomCandleBuilder::BuildRates() currently builds the customer rates in the wrong direction.
         All custom rates are stored in the base class array: m_customRates[]
         
         Please re build this method so the loop decrements from the back of history towards zero, so we build the rates
         from the past toward the current candle.
         
         m_customRates[] is set as a series array already in the base class.
         
      -  Sommetimes there are corrupted candles which print at the current candle area. I believe it is the custom rates building algorithm in this class that 
         is producing the problem.
         
      -  The way this class works is it is fed a 'DataSource' class, which provides the rates you should be using to build the custom candles with.
         Currenly the DateSource is set to PERIOD_H1 to improve build speed. But the algorithm should also work if we swtitch the dataouse to 1 min data.
         
         I don't think this should affect how you design the custom candle buidler algo through. But you will see how it is working currenly,
         it is easy to understand.
         
      -  This custom candle builder should be able to build 2 and 3 day charts also, which it can currently do.
      
      
      To Summarize:
         - Rebuild the custom candle algo, with counts down to be stored in series arr
         - Should work regardless if the datasource is 1 hour or 1 min candles
         - Should be able to handle building 48 and 72 hour candles like it does now. 
         - Correcly work with the broker start hour that is passed in the constructor. No need to do any GMT calcs, this is done externally.
*/



#include "CustomChartApi\Mt4CustomChart.mqh"
#include "CustomBuilders\CustomCandleBuilder.mqh"

#include "Includes\Time\ForexSessionTime.mqh"

Mt4CustomChart *customChart, *customChart2;
BaseChartBuilder *candleBuilder, *candleBuilder2;
BaseDataSource *candleDataSource, *candleDataSource2;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   bool lowtf = false;
   ENUM_TIMEFRAMES dataSourceTimeframe = PERIOD_H1;
   
   if( PeriodSeconds(_Period) < PeriodSeconds(PERIOD_M1) ) { 
      dataSourceTimeframe = (ENUM_TIMEFRAMES) _Period;
   }   
   
   candleDataSource  = new ChartDataSource(_Symbol, dataSourceTimeframe, 1000);
   candleDataSource2  = new ChartDataSource(_Symbol,dataSourceTimeframe, 1000);
   
   // Determine period multiplier from data source time frame
   int periodMultiplier = To_Int(_Period) / To_Int(PERIOD_H1);
   
   if( lowtf ) { 
      periodMultiplier = 1;
   }

   // Calculate broker start hour
   MqlDateTime now;
   TimeToStruct( TimeCurrent(), now);
   
   int londonOpenBrokerHour = ForexSessionTime::GetSessionBrokerHour( now, SESSION_TIME_LONDON_OPEN );
   int usOpenBrokerHour = ForexSessionTime::GetSessionBrokerHour( now, SESSION_TIME_NEW_YORK_OPEN );   
   
   printf("Broker hour for London Open chart set to = %d", londonOpenBrokerHour);
   printf("Broker hour for US Open chart set to = %d", usOpenBrokerHour);
   
   // Intstantiate custom builders
   candleBuilder     = new CustomCandleBuilder(candleDataSource, periodMultiplier, londonOpenBrokerHour);
   candleBuilder2    = new CustomCandleBuilder(candleDataSource2, periodMultiplier, usOpenBrokerHour);
   
   customChart       = new Mt4CustomChart(candleBuilder);
   customChart2      = new Mt4CustomChart(candleBuilder2);
   
   // Open custom charts
   Comment("Building Charts...");
   customChart.Create();
   customChart.Open();
   
   customChart2.Create();
   customChart2.Open();
   
   EventSetMillisecondTimer(1000);
   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   customChart.Close();
   customChart2.Close();
   
   delete customChart;
   delete customChart2;
   EventKillTimer();
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   customChart.OnTick();
   customChart2.OnTick();
}


//+------------------------------------------------------------------+
bool testRan = false;
void OnTimer() { 
   EventKillTimer();
   if( !testRan ) { 
      //WriteDummyCandlesTest();   
      testRan = true;
   }
}


void WriteDummyCandlesTest() {
   
   MqlRates rate[10];
   ZeroMemory(rate);
   ArraySetAsSeries(rate, true);
   
   FOR(0, 9)
      customChart.GetRate(i, rate[i]);
   ENDFOR
   
   MqlRates newCandle[2];
   ZeroMemory(newCandle);
   ArraySetAsSeries(newCandle, true);
   
   datetime timeTracker = rate[0].time;
   int periodInt = PeriodSeconds(_Period);
   
   MqlRates prevTestCandle;
   ZeroMemory(prevTestCandle);
   prevTestCandle = rate[9];
   
   FORREV(8, 0)
      if( IsStopped() ) { break; }
      
      newCandle[1] = prevTestCandle;
      newCandle[0] = rate[i];
      newCandle[0].time = timeTracker;
      prevTestCandle = newCandle[0];
      
      printf("Writing new candle... %s | %f %f %f %f", 
         TimeToString(newCandle[0].time),
         newCandle[0].high,
         newCandle[0].open,
         newCandle[0].low,
         newCandle[0].close
      );
      
      customChart.WriteUpdatedRates(newCandle);
      timeTracker += periodInt;   
      Sleep(1000);
   ENDFOR
   
}