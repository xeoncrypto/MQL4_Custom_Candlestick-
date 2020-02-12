//+------------------------------------------------------------------+
//|                                   CandlestickPeriodConverter.mqh |
//|                       Copyright 2016, TheForexGuy.com Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, www.TheForexGuy.com"
#property link      "https://www.TheForexGuy.com"
#property strict

#include "BaseChartBuilder.mqh"
#include "..\Includes\Common\Compatibility.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CustomCandleBuilder : public BaseChartBuilder {
   public:
      CustomCandleBuilder (
          BaseDataSource *&dataSource,      
          const int periodMultiplier,
          const int brokerStartHour
      );
      
      void              BuildRates() override;
      bool              UpdateRates() override;      
      int               GetPeriod() const override { return m_customPeriodMinutes; }
      
   
   protected:
      int               m_periodMultiplier;                 // Period multiplier factor 
      int               m_customPeriodMinutes; 
      
      long              m_lastVolume;
      datetime          m_lastKnownCandleTime;
   
      int               m_brokerHourForFirstCandle;
      datetime          m_nextCandleTime;

      int               m_day;
      int               m_month;
      int               m_year;
      datetime          m_weekends;
      datetime          m_weekdays;
      bool              m_check;
   
      
   
      int               CalculateStartPosition();
   
      datetime          NormalizeBarStartTime(datetime inTime);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CustomCandleBuilder::CustomCandleBuilder (
   BaseDataSource *&dataSource,      
   const int periodMultiplier,
   const int brokerStartHour
) : BaseChartBuilder(dataSource) {
      
   m_periodMultiplier            = periodMultiplier;   
   m_brokerHourForFirstCandle    = brokerStartHour;
   m_lastVolume                  = 0;
   
   int basePeriodMinutes = To_Int(dataSource.GetDataPeriod());
   
   // Trying to build a custom chart which is lower in value than the base history time period we're building off
   // If so, default builder to base history.
   if( (m_periodMultiplier * basePeriodMinutes) < basePeriodMinutes ) {
      printf("[%s Input Error]: Trying to set a custom period of %d which is less than the base period of %d - defaulting to base period.", __FUNCTION__, m_periodMultiplier *  basePeriodMinutes, basePeriodMinutes);
      m_customPeriodMinutes = basePeriodMinutes;
   }   
   
   else {
      m_customPeriodMinutes = m_periodMultiplier * basePeriodMinutes;
   } 
     
     
  // printf("Building with custom period %d", m_customPeriodMinutes);  
   /*
   if(m_gmTstart>=0 && m_gmTstart<=23) {
      m_brokerHourForFirstCandle=m_gmTstart+m_brokerGmtOffset;
      if(m_brokerHourForFirstCandle>=24) {
         m_brokerHourForFirstCandle-=24;
      }
      
      else if(m_brokerHourForFirstCandle<0) {
         m_brokerHourForFirstCandle+=24;
      }
   }
   
   else {
      m_brokerHourForFirstCandle=0;
   } */
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+



/*
 * Call to update custom rates on new tick
 */
bool CustomCandleBuilder::UpdateRates() {
   m_dataSource.UpdateRates();

   
   if( ArraySize(m_customRates) < 1 ) {
      return false;
   }
   
   const int customRatesSize = ArraySize(m_customRates);
   int periodseconds = m_customPeriodMinutes*60;

   m_lastKnownCandleTime = m_dataSource.Time(0);

   if((TimeDayOfWeek(m_dataSource.Time(0))==5) && (!m_check)) {
      m_day             = TimeDay(m_dataSource.Time(0));
      m_month           = TimeMonth(m_dataSource.Time(0));
      m_year            = TimeYear(m_dataSource.Time(0));
      m_weekends        = StrToTime((string) m_day + "." + (string) m_month + "." + (string) m_year + " 23:59");
      m_weekdays        = StrToTime((string) (m_day + 3) + "." + (string) m_month + "." + (string) m_year + " 00:00");
      m_check           = true;
   }

   if(m_check) {
      if(m_dataSource.Time(0) > m_weekdays) {
         m_check=false;
      }
      
      else if(m_dataSource.Time(0) > m_weekends) {
         return (false);
      }
   }
   
   // If a new candle has printed, updated the previous candle, then add new element in custom rates arr for new candle data
   if( m_lastKnownCandleTime >= m_nextCandleTime ) {       
      m_customRates[0].low       = MathMin( m_customRates[0].low, m_dataSource.Low(1) );
      m_customRates[0].high      = MathMax( m_customRates[0].high, m_dataSource.High(1) );  
      m_customRates[0].close     = m_dataSource.Close(1);
      m_customRates[0].tick_volume = m_dataSource.Volume(1);
      
      // Add element for new candle
      AddElement(m_customRates);
      
      // Init new candle data
      m_customRates[0].time         = NormalizeBarStartTime(m_nextCandleTime);    
      m_nextCandleTime              = m_customRates[0].time + periodseconds;
      m_customRates[0].open         = m_dataSource.Open(0);
      m_customRates[0].low          = m_dataSource.Low(0);
      m_customRates[0].high         = m_dataSource.High(0);      
      m_customRates[0].close        = m_dataSource.Close(0);
      m_customRates[0].tick_volume  = (long) m_dataSource.Volume(0);
      m_lastVolume                  = m_customRates[0].tick_volume; 
      m_lastKnownCandleTime         = m_customRates[0].time;
   } 
   
   m_customRates[0].low          = MathMin( m_customRates[0].low, m_dataSource.Low(0) );
   m_customRates[0].high         = MathMax( m_customRates[0].high, m_dataSource.High(0) );  
   m_customRates[0].close        = m_dataSource.Close(0);
   m_customRates[0].tick_volume  = (long) m_dataSource.Volume(0);
   m_lastVolume                  = m_customRates[0].tick_volume;
   
   return true;
}
//+------------------------------------------------------------------+
 
  
  
void CustomCandleBuilder::BuildRates() {
   
   m_dataSource.InitData();

   /*
    * This method was designed to build the data in a non-series array
    * Since migrating m_customRates to a series array we cheat here a little by switching it temporaritly
    * back to a non-series array, write the data, and restore it to a series array at the end of the data building
    */
   ArraySetAsSeries(m_customRates, false);
   
   int index=0;
   int start_pos,periodseconds;
   int cntPC=0;
   int weekDay;

   periodseconds= m_customPeriodMinutes*60;
 
      
   int days=1;
   if(m_customPeriodMinutes>=1440) {
      days=m_customPeriodMinutes/1440;
   }
   start_pos=CalculateStartPosition();
   
   ArrayResize(m_customRates, 1, start_pos);
   
   //printf("%s Start Pos = %d", __FUNCTION__, start_pos);

   ResetLastError();

   m_customRates[index].open=m_dataSource.Open(start_pos);
   m_customRates[index].low=m_dataSource.Low(start_pos);
   m_customRates[index].high=m_dataSource.High(start_pos);
   m_customRates[index].tick_volume=(long)m_dataSource.Volume(start_pos);
   m_customRates[index].spread=0;
   m_customRates[index].real_volume=0;
   m_customRates[index].time=NormalizeBarStartTime(m_dataSource.Time(start_pos));

   m_nextCandleTime=m_customRates[index].time+periodseconds;
   weekDay=TimeDayOfWeek(m_customRates[index].time);

   for(int i=start_pos-1; i>=0; i--)
     {
      if(IsStopped())
        {
         break;
        }
      m_lastKnownCandleTime=m_dataSource.Time(i);
      //printf("%s %d m_lastKnownCandleTime= %s ", __FUNCTION__, __LINE__, TimeToString(m_dataSource.Time(i)) );
      
      //--- history may be updated
      if(i==0)
        {
         //--- modify index if history was updated
         if(RefreshRates())
           {
            i=m_dataSource.BarShift(m_lastKnownCandleTime);
           }
        }
      //---
      int time0Weekday=TimeDayOfWeek(m_lastKnownCandleTime);
      int nextCandleTimeWeekDay=TimeDayOfWeek(m_nextCandleTime);

      if(((nextCandleTimeWeekDay-time0Weekday)>days) && (days>0))
        {
         // new week started - recalculate nextcandletime
         MqlDateTime nextBarTime;
         TimeToStruct(m_nextCandleTime,nextBarTime);
         // Replace nextcandletime date with date of current candle
         nextBarTime.day = TimeDay(m_lastKnownCandleTime);
         nextBarTime.mon = TimeMonth(m_lastKnownCandleTime);
         nextBarTime.year= TimeYear(m_lastKnownCandleTime);
         nextBarTime.min = 0;
         if(nextBarTime.hour>m_brokerHourForFirstCandle)
           {
            nextBarTime.hour=m_brokerHourForFirstCandle;
           }
         m_nextCandleTime=StructToTime(nextBarTime);
        }

      if(m_lastKnownCandleTime>=m_nextCandleTime || i==0)
        {
         if(i==0 && m_lastKnownCandleTime<m_nextCandleTime)
           {
            m_customRates[index].tick_volume+=(long)m_dataSource.Volume(0);
            if(m_customRates[index].low>m_dataSource.Low(0))
              {
               m_customRates[index].low=m_dataSource.Low(0);
              }

            if(m_customRates[index].high<m_dataSource.High(0))
              {
               m_customRates[index].high=m_dataSource.High(0);
              }

            m_customRates[index].close=m_dataSource.Close(0);
           }

         m_lastVolume=(long)m_dataSource.Volume(0);

         cntPC++;

         if(m_lastKnownCandleTime>=m_nextCandleTime)
           {
            index=ArraySize(m_customRates);
            ArrayResize(m_customRates,index+1);

            m_customRates[index].time=NormalizeBarStartTime(m_nextCandleTime);

            m_nextCandleTime=m_customRates[index].time+periodseconds;

            m_customRates[index].open=m_dataSource.Open(i);
            m_customRates[index].low=m_dataSource.Low(i);
            m_customRates[index].high=m_dataSource.High(i);
            m_customRates[index].close=m_dataSource.Close(i);
            m_customRates[index].tick_volume=m_lastVolume;
           }
        }
      else
        {
         m_customRates[index].tick_volume+=(long)m_dataSource.Volume(i);

         if(m_customRates[index].low>m_dataSource.Low(i))
           {
            m_customRates[index].low=m_dataSource.Low(i);
           }
         if(m_customRates[index].high<m_dataSource.High(i))
           {
            m_customRates[index].high=m_dataSource.High(i);
           }

         m_customRates[index].close=m_dataSource.Close(i);
        }
        
        m_customRates[index].spread = 1.0;
        m_customRates[index].real_volume = 1;
        m_customRates[index].tick_volume = 1;
        
        //printf("[%d] %s", index, ToString(m_customRates[index]));
     }
     
     ArraySetAsSeries(m_customRates, true);
}   
  
  
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+ 
int CustomCandleBuilder::CalculateStartPosition() {
   if( m_dataSource.GetDataPeriod() < PERIOD_H1 ) {  return m_dataSource.BarsCount()-1; }
   
   if(m_brokerHourForFirstCandle>=0 && m_brokerHourForFirstCandle<=23) {
      // GMTStart is given - compute start bar index      
      for(int i=m_dataSource.BarsCount()-1; i>=0; i--){
         int barHour= TimeHour(m_dataSource.Time(i));
         if(barHour == m_brokerHourForFirstCandle)
            return(i);
      }
   }

   return(m_dataSource.BarsCount()-1);
} 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime CustomCandleBuilder::NormalizeBarStartTime(datetime inTime) {
   if( m_dataSource.GetDataPeriod() < PERIOD_H1 ) {  return inTime; }
   
   MqlDateTime startTime;
   TimeToStruct(inTime,startTime);
   startTime.sec = 0;
   startTime.min = 0;
   return(StructToTime(startTime));
  }
//+------------------------------------------------------------------+



/*

void CustomCandleBuilder::BuildRates() {

   ArrayResize(m_customRates,1);
   int index=0;
   int start_pos,periodseconds;
   int cntPC=0;
   int weekDay;
   
   

   // filling rates array
   periodseconds= m_customPeriodMinutes*60;
   int days=1;
   if(m_customPeriodMinutes>=1440)   {
      days=m_customPeriodMinutes/1440;
     }
   start_pos=CalculateStartPosition();
   
   printf("%s Start Pos = %d", __FUNCTION__, start_pos);

   ResetLastError();

   m_customRates[index].open=m_dataSource.Open(start_pos);
   m_customRates[index].low=m_dataSource.Low(start_pos);
   m_customRates[index].high=m_dataSource.High(start_pos);
   m_customRates[index].tick_volume=(long)m_dataSource.Volume(start_pos);
   m_customRates[index].spread=0;
   m_customRates[index].real_volume=0;
   m_customRates[index].time=NormalizeBarStartTime(m_dataSource.Time(start_pos));

   m_nextCandleTime=m_customRates[index].time+periodseconds;
   weekDay=TimeDayOfWeek(m_customRates[index].time);

   for(int i=start_pos-1; i>=0; i--)
     {
      if(IsStopped())
        {
         break;
        }
      m_lastKnownCandleTime=m_dataSource.Time(i);
      //--- history may be updated
      if(i==0)
        {
         //--- modify index if history was updated
         if(RefreshRates())
           {
            i=m_dataSource.BarShift(m_lastKnownCandleTime);
           }
        }
      //---
      int time0Weekday=TimeDayOfWeek(m_lastKnownCandleTime);
      int nextCandleTimeWeekDay=TimeDayOfWeek(m_nextCandleTime);

      if(((nextCandleTimeWeekDay-time0Weekday)>days) && (days>0))
        {
         // new week started - recalculate nextcandletime
         MqlDateTime nextBarTime;
         TimeToStruct(m_nextCandleTime,nextBarTime);
         // Replace nextcandletime date with date of current candle
         nextBarTime.day = TimeDay(m_lastKnownCandleTime);
         nextBarTime.mon = TimeMonth(m_lastKnownCandleTime);
         nextBarTime.year= TimeYear(m_lastKnownCandleTime);
         nextBarTime.min = 0;
         if(nextBarTime.hour>m_brokerHourForFirstCandle)
           {
            nextBarTime.hour=m_brokerHourForFirstCandle;
           }
         m_nextCandleTime=StructToTime(nextBarTime);
        }

      if(m_lastKnownCandleTime>=m_nextCandleTime || i==0)
        {
         if(i==0 && m_lastKnownCandleTime<m_nextCandleTime)
           {
            m_customRates[index].tick_volume+=(long)m_dataSource.Volume(0);
            if(m_customRates[index].low>m_dataSource.Low(0))
              {
               m_customRates[index].low=m_dataSource.Low(0);
              }

            if(m_customRates[index].high<m_dataSource.High(0))
              {
               m_customRates[index].high=m_dataSource.High(0);
              }

            m_customRates[index].close=m_dataSource.Close(0);
           }

         m_lastVolume=(long)m_dataSource.Volume(0);

         cntPC++;

         if(m_lastKnownCandleTime>=m_nextCandleTime)
           {
            index=ArraySize(m_customRates);
            ArrayResize(m_customRates,index+1);

            m_customRates[index].time=NormalizeBarStartTime(m_nextCandleTime);

            m_nextCandleTime=m_customRates[index].time+periodseconds;

            m_customRates[index].open=m_dataSource.Open(i);
            m_customRates[index].low=m_dataSource.Low(i);
            m_customRates[index].high=m_dataSource.High(i);
            m_customRates[index].close=m_dataSource.Close(i);
            m_customRates[index].tick_volume=m_lastVolume;
           }
        }
      else
        {
         m_customRates[index].tick_volume+=(long)m_dataSource.Volume(i);

         if(m_customRates[index].low>m_dataSource.Low(i))
           {
            m_customRates[index].low=m_dataSource.Low(i);
           }
         if(m_customRates[index].high<m_dataSource.High(i))
           {
            m_customRates[index].high=m_dataSource.High(i);
           }

         m_customRates[index].close=m_dataSource.Close(i);
        }
     }
  } 
 */ 
  