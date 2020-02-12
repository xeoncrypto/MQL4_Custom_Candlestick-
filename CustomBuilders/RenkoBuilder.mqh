//+------------------------------------------------------------------+
//|                                                 RenkoBuilder.mqh |
//|                       Copyright 2020, TheForexGuy.com Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, www.TheForexGuy.com"
#property link      "https://www.TheForexGuy.com"
#property strict

#include "BaseChartBuilder.mqh"
#include <stdlib.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class RenkoBuilder : public BaseChartBuilder {
   public:
      RenkoBuilder (
         BaseDataSource *&dataSource,       
         int renkoBoxSize
      );
         
      bool              UpdateRates() override;  
      void              BuildRates() override;
      int               GetBarsCount();
      
      int               GetPeriod() const override { return m_renkoBoxSizePips; }
   
   private:
      int               m_digits;
      double            m_points;
      int               m_pips2PointsMultiplier;
      
      int               m_renkoBoxSizePips;
      int               m_renkoBoxOffset;
      bool              m_showWicks;
   
      double            m_boxPoints;
      double            m_upWick;
      double            m_dnWick;
      double            m_prevLow;
      double            m_prevHigh;
      double            m_prevOpen;
      double            m_prevClose;
      double            m_curVolume;
      double            m_curLow;
      double            m_curHigh;
      double            m_curOpen;
      double            m_curClose;
      datetime          m_prevTime;
      
      void              SetChartValues();

      double            CalculateATRBoxSize(string instrument,int atr_timeframe,int atr_period,int atr_shift,int ma_method,int ma_period);
   
      virtual void      UpdateAllRates();
};


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
RenkoBuilder::RenkoBuilder (
   BaseDataSource *&dataSource,       
   int renkoBoxSize
) : BaseChartBuilder(dataSource) {

   m_renkoBoxSizePips    = renkoBoxSize;
   m_renkoBoxOffset  = 0;
   m_showWicks       = true;   
   
   if( MathAbs(m_renkoBoxOffset) >= m_renkoBoxSizePips ) {
      printf("[%s %d]Error: m_renkoBoxOffset should be less than m_renkoBoxSizePips!", __FUNCTION__, __LINE__);
      return;
   }
  
   SetChartValues();
   
}



void RenkoBuilder::SetChartValues() { 
   m_digits       = m_dataSource.Digits();
   m_points       = m_dataSource.Point();
   
   m_pips2PointsMultiplier = 1;
   
   if( m_digits==3 || m_digits==5 ) {      
      m_pips2PointsMultiplier = 10;
   }
   
   else {
      m_pips2PointsMultiplier=1;
   }
   
   // Box size in the format of price spread 
   m_boxPoints    = NormalizeDouble( ((double) m_renkoBoxSizePips * m_pips2PointsMultiplier) * m_points, m_digits );
    
    // printf("[%s] m_digits = %d | m_pips2PointsMultiplier = %d 
  //  m_pips2PointsMultiplier=1;
  /* printf("[%s] m_digits = %d | m_pips2PointsMultiplier = %d | m_points = %f | m_boxPoints = %f",       
      __FUNCTION__,
      m_digits,
      m_pips2PointsMultiplier,
      m_points,
      m_boxPoints
   ); */
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int RenkoBuilder::GetBarsCount() {

   int count=0;
   
   m_prevLow      = m_renkoBoxOffset * (m_points + MathFloor( m_dataSource.Close(m_dataSource.BarsCount()-1) / m_boxPoints )) * m_boxPoints;
   m_prevLow      = NormalizeDouble( m_prevLow, m_digits );

   m_dnWick       = m_prevLow;
   m_prevHigh     = m_prevLow+m_boxPoints;
   m_upWick       = m_prevHigh;
   m_prevOpen     = m_prevLow;
   m_prevClose    = m_prevHigh;
   m_curVolume    = 1;
   m_prevTime     = m_dataSource.Time(m_dataSource.BarsCount()-1);

   int i = m_dataSource.BarsCount()-2;
   
   while(i>=0) {
      m_curVolume=m_curVolume+m_dataSource.Volume(i);

      m_upWick = MathMax(m_upWick, m_dataSource.High(i));
      m_dnWick = MathMin(m_dnWick, m_dataSource.Low(i));

      // update low before high or the revers depending on is closest to prev. bar
      bool uptrend = ( m_dataSource.High(i) + m_dataSource.Low(i) ) > ( m_dataSource.High(i+1) + m_dataSource.Low(i+1) );

      while(uptrend && (m_dataSource.Low(i)<m_prevLow-m_boxPoints || CompareDoubles(m_dataSource.Low(i),m_prevLow-m_boxPoints))) {
         if(m_upWick>=m_prevHigh && m_upWick>=(m_prevHigh+m_boxPoints))
           {
            while(m_upWick>=m_prevHigh && m_upWick>=(m_prevHigh+m_boxPoints))
              {
               m_prevHigh= m_prevHigh+m_boxPoints;
               m_prevLow = m_prevLow+m_boxPoints;
               m_prevOpen= m_prevLow;
               m_prevClose=m_prevHigh;

               count++;

               if(m_prevTime<m_dataSource.Time(i)) m_prevTime=m_dataSource.Time(i);
               else m_prevTime++;
              }
            m_dnWick=EMPTY_VALUE;
            break;
           }
         m_prevHigh= m_prevHigh-m_boxPoints;
         m_prevLow = m_prevLow-m_boxPoints;
         m_prevOpen= m_prevHigh;
         m_prevClose=m_prevLow;

         count++;

         m_upWick = 0;
         m_dnWick = EMPTY_VALUE;
         m_curVolume=0;
         m_curHigh= m_prevLow;
         m_curLow = m_prevLow;

         if(m_prevTime<m_dataSource.Time(i)) m_prevTime=m_dataSource.Time(i);
         else m_prevTime++;
      }

      while(uptrend && (m_dataSource.High(i)>m_prevHigh+m_boxPoints || CompareDoubles(m_dataSource.High(i),m_prevHigh+m_boxPoints))) {
         if(m_dnWick<=m_prevLow && m_dnWick<=(m_prevLow-m_boxPoints))
           {
            while(m_dnWick<=m_prevLow && m_dnWick<=(m_prevLow-m_boxPoints))
              {
               m_prevHigh= m_prevHigh-m_boxPoints;
               m_prevLow = m_prevLow-m_boxPoints;
               m_prevOpen= m_prevHigh;
               m_prevClose=m_prevLow;

               count++;

               if(m_prevTime<m_dataSource.Time(i)) m_prevTime=m_dataSource.Time(i);
               else m_prevTime++;
              }
            m_upWick=0;
            break;
           }
         m_prevHigh= m_prevHigh+m_boxPoints;
         m_prevLow = m_prevLow+m_boxPoints;
         m_prevOpen= m_prevLow;
         m_prevClose=m_prevHigh;

         count++;

         m_upWick = 0;
         m_dnWick = EMPTY_VALUE;
         m_curVolume=0;
         m_curHigh= m_prevHigh;
         m_curLow = m_prevHigh;

         if(m_prevTime<m_dataSource.Time(i)) m_prevTime=m_dataSource.Time(i);
         else m_prevTime++;
      }

      while(!uptrend && (m_dataSource.Low(i)<m_prevLow-m_boxPoints || CompareDoubles(m_dataSource.Low(i),m_prevLow-m_boxPoints))) {
         if(m_upWick>=m_prevHigh && m_upWick>=(m_prevHigh+m_boxPoints))
           {
            while(m_upWick>=m_prevHigh && m_upWick>=(m_prevHigh+m_boxPoints))
              {
               m_prevHigh= m_prevHigh+m_boxPoints;
               m_prevLow = m_prevLow+m_boxPoints;
               m_prevOpen= m_prevLow;
               m_prevClose=m_prevHigh;

               count++;

               if(m_prevTime<m_dataSource.Time(i)) m_prevTime=m_dataSource.Time(i);
               else m_prevTime++;
              }
            m_dnWick=EMPTY_VALUE;
            break;
           }
         m_prevHigh= m_prevHigh-m_boxPoints;
         m_prevLow = m_prevLow-m_boxPoints;
         m_prevOpen= m_prevHigh;
         m_prevClose=m_prevLow;

         count++;

         m_upWick = 0;
         m_dnWick = EMPTY_VALUE;
         m_curVolume=0;
         m_curHigh= m_prevLow;
         m_curLow = m_prevLow;

         if(m_prevTime<m_dataSource.Time(i)) m_prevTime=m_dataSource.Time(i);
         else m_prevTime++;
      }
      
      i--;
   }

   if( m_dataSource.Close(0) > MathMax(m_prevClose,m_prevOpen) ) {
       m_curOpen  = MathMax(m_prevClose,m_prevOpen);
   }
       
   else if( m_dataSource.Close(0) < MathMin(m_prevClose,m_prevOpen) ) {
      m_curOpen   = MathMin(m_prevClose,m_prevOpen);
   }
      
   else {
      m_curOpen   = m_dataSource.Close(0);
   }
   
   m_curClose = m_dataSource.Close(0);

   if( m_upWick > m_prevHigh )   m_curHigh = m_upWick;
   if( m_dnWick < m_prevLow )    m_curLow = m_dnWick;

   count++;

   return(count);
// End historical data / Init        
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RenkoBuilder::BuildRates() override {
   //   return;
   ArrayFree(m_customRates);
   
   /*
    * This method was designed to build the data in a non-series array
    * Since migrating m_customRates to a series array we cheat here a little by switching it temporaritly
    * back to a non-series array, write the data, and restore it to a series array at the end of the data building
    */
    
   ArraySetAsSeries(m_customRates, false);

   int BoxSize =  m_renkoBoxSizePips;
   int BoxOffset  =  m_renkoBoxOffset;
   
   m_prevLow      = NormalizeDouble( BoxOffset*m_points + MathFloor( m_dataSource.Close(m_dataSource.BarsCount()-1)/m_boxPoints)*m_boxPoints, m_digits );

   m_dnWick       = m_prevLow;
   m_prevHigh     = m_prevLow+m_boxPoints;
   m_upWick       = m_prevHigh;
   m_prevOpen     = m_prevLow;
   m_prevClose    = m_prevHigh;
   m_curVolume    = 1;
   m_prevTime     = m_dataSource.Time(m_dataSource.BarsCount()-1);

   int i=m_dataSource.BarsCount()-2;
   while(i>=0)
     {
      m_curVolume=m_curVolume+m_dataSource.Volume(i);

      m_upWick = MathMax(m_upWick, m_dataSource.High(i));
      m_dnWick = MathMin(m_dnWick, m_dataSource.Low(i));

      // update low before high or the revers depending on is closest to prev. bar
      bool uptrend=m_dataSource.High(i)+m_dataSource.Low(i)>m_dataSource.High(i+1)+m_dataSource.Low(i+1);

      while(uptrend && (m_dataSource.Low(i)<m_prevLow-m_boxPoints || CompareDoubles(m_dataSource.Low(i),m_prevLow-m_boxPoints)))
        {
         if(m_upWick>=m_prevHigh && m_upWick>=(m_prevHigh+m_boxPoints))
           {
            while(m_upWick>=m_prevHigh && m_upWick>=(m_prevHigh+m_boxPoints))
              {
               m_prevHigh= m_prevHigh+m_boxPoints;
               m_prevLow = m_prevLow+m_boxPoints;
               m_prevOpen= m_prevLow;
               m_prevClose=m_prevHigh;

               int index=ArraySize(m_customRates);
               ArrayResize(m_customRates,index+1);

               m_customRates[index].time = m_prevTime;
               m_customRates[index].open = m_prevOpen;
               m_customRates[index].high = m_prevHigh;
               m_customRates[index].low=m_prevLow;
               m_customRates[index].close=m_prevClose;
               m_customRates[index].tick_volume=(int)m_curVolume;

               if(m_prevTime<m_dataSource.Time(i))
                 {
                  m_prevTime=m_dataSource.Time(i);
                 }
               else
                 {
                  m_prevTime++;
                 }
              }

            m_dnWick=EMPTY_VALUE;

            break;
           }

         m_prevHigh= m_prevHigh-m_boxPoints;
         m_prevLow = m_prevLow-m_boxPoints;
         m_prevOpen= m_prevHigh;
         m_prevClose=m_prevLow;

         int index=ArraySize(m_customRates);
         ArrayResize(m_customRates,index+1);

         m_customRates[index].time = m_prevTime;
         m_customRates[index].open = m_prevOpen;
         if(m_showWicks && m_upWick>m_prevHigh)
           {
            m_customRates[index].high=m_upWick;
           }
         else
           {
            m_customRates[index].high=m_prevHigh;
           }
         m_customRates[index].low=m_prevLow;
         m_customRates[index].close=m_prevClose;
         m_customRates[index].tick_volume=(int)m_curVolume;

         m_upWick = 0;
         m_dnWick = EMPTY_VALUE;
         m_curVolume=0;
         m_curHigh= m_prevLow;
         m_curLow = m_prevLow;

         if(m_prevTime<m_dataSource.Time(i))
           {
            m_prevTime=m_dataSource.Time(i);
           }
         else
           {
            m_prevTime++;
           }
        }

      while(uptrend && (m_dataSource.High(i)>m_prevHigh+m_boxPoints || CompareDoubles(m_dataSource.High(i),m_prevHigh+m_boxPoints)))
        {
         if(m_dnWick<=m_prevLow && m_dnWick<=(m_prevLow-m_boxPoints))
           {
            while(m_dnWick<=m_prevLow && m_dnWick<=(m_prevLow-m_boxPoints))
              {
               m_prevHigh= m_prevHigh-m_boxPoints;
               m_prevLow = m_prevLow-m_boxPoints;
               m_prevOpen= m_prevHigh;
               m_prevClose=m_prevLow;

               int index=ArraySize(m_customRates);
               ArrayResize(m_customRates,index+1);

               m_customRates[index].time = m_prevTime;
               m_customRates[index].open = m_prevOpen;
               m_customRates[index].high = m_prevHigh;
               m_customRates[index].low=m_prevLow;
               m_customRates[index].close=m_prevClose;
               m_customRates[index].tick_volume=(int)m_curVolume;

               if(m_prevTime<m_dataSource.Time(i))
                 {
                  m_prevTime=m_dataSource.Time(i);
                 }
               else
                 {
                  m_prevTime++;
                 }
              }

            m_upWick=0;
            break;
           }
         m_prevHigh= m_prevHigh+m_boxPoints;
         m_prevLow = m_prevLow+m_boxPoints;
         m_prevOpen= m_prevLow;
         m_prevClose=m_prevHigh;

         int index=ArraySize(m_customRates);
         ArrayResize(m_customRates,index+1);

         m_customRates[index].time = m_prevTime;
         m_customRates[index].open = m_prevOpen;
         m_customRates[index].high = m_prevHigh;

         if(m_showWicks && m_dnWick<m_prevLow)
           {
            m_customRates[index].low=m_dnWick;
           }
         else
           {
            m_customRates[index].low=m_prevLow;
           }
         m_customRates[index].close=m_prevClose;
         m_customRates[index].tick_volume=(int)m_curVolume;

         m_upWick = 0;
         m_dnWick = EMPTY_VALUE;
         m_curVolume=0;
         m_curHigh= m_prevHigh;
         m_curLow = m_prevHigh;

         if(m_prevTime<m_dataSource.Time(i))
           {
            m_prevTime=m_dataSource.Time(i);
           }
         else
           {
            m_prevTime++;
           }
        }

      while(!uptrend && (m_dataSource.Low(i)<m_prevLow-m_boxPoints || CompareDoubles(m_dataSource.Low(i),m_prevLow-m_boxPoints)))
        {
         if(m_upWick>=m_prevHigh && m_upWick>=(m_prevHigh+m_boxPoints))
           {
            while(m_upWick>=m_prevHigh && m_upWick>=(m_prevHigh+m_boxPoints))
              {
               m_prevHigh= m_prevHigh+m_boxPoints;
               m_prevLow = m_prevLow+m_boxPoints;
               m_prevOpen= m_prevLow;
               m_prevClose=m_prevHigh;

               int index=ArraySize(m_customRates);
               ArrayResize(m_customRates,index+1);

               m_customRates[index].time = m_prevTime;
               m_customRates[index].open = m_prevOpen;
               m_customRates[index].high = m_prevHigh;
               m_customRates[index].low=m_prevLow;
               m_customRates[index].close=m_prevClose;
               m_customRates[index].tick_volume=(int)m_curVolume;

               if(m_prevTime<m_dataSource.Time(i))
                 {
                  m_prevTime=m_dataSource.Time(i);
                 }
               else
                 {
                  m_prevTime++;
                 }
              }
            m_dnWick=EMPTY_VALUE;
            break;
           }
         m_prevHigh= m_prevHigh-m_boxPoints;
         m_prevLow = m_prevLow-m_boxPoints;
         m_prevOpen= m_prevHigh;
         m_prevClose=m_prevLow;

         int index=ArraySize(m_customRates);
         ArrayResize(m_customRates,index+1);

         m_customRates[index].time = m_prevTime;
         m_customRates[index].open = m_prevOpen;
         if(m_showWicks && m_upWick>m_prevHigh)
           {
            m_customRates[index].high=m_upWick;
           }
         else
           {
            m_customRates[index].high=m_prevHigh;
           }
         m_customRates[index].low=m_prevLow;
         m_customRates[index].close=m_prevClose;
         m_customRates[index].tick_volume=(int)m_curVolume;

         m_upWick = 0;
         m_dnWick = EMPTY_VALUE;
         m_curVolume=0;
         m_curHigh= m_prevLow;
         m_curLow = m_prevLow;

         if(m_prevTime<m_dataSource.Time(i))
           {
            m_prevTime=m_dataSource.Time(i);
           }
         else
           {
            m_prevTime++;
           }
        }
      i--;
     }

   if(m_dataSource.Close(0)>MathMax(m_prevClose,m_prevOpen))
     {
      m_curOpen=MathMax(m_prevClose,m_prevOpen);
     }
   else if(m_dataSource.Close(0)<MathMin(m_prevClose,m_prevOpen))
     {
      m_curOpen=MathMin(m_prevClose,m_prevOpen);
     }
   else
     {
      m_curOpen=m_dataSource.Close(0);
     }

   m_curClose=m_dataSource.Close(0);

   if(m_upWick>m_prevHigh)
     {
      m_curHigh=m_upWick;
     }
   if(m_dnWick<m_prevLow)
     {
      m_curLow=m_dnWick;
     }

   int index=ArraySize(m_customRates);
   ArrayResize(m_customRates,index+1);

   m_customRates[index].time = m_prevTime;
   m_customRates[index].open = m_curOpen;
   m_customRates[index].high = MathMax(MathMax(m_curHigh, m_curOpen), m_curClose);
   m_customRates[index].low=MathMin(MathMin(m_curLow,m_curOpen),m_curClose);
   m_customRates[index].close=m_curClose;
   m_customRates[index].tick_volume=(int)m_curVolume;
   ArraySetAsSeries(m_customRates, true);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RenkoBuilder::UpdateRates() {
   m_dataSource.UpdateRates();
   
   if(ArraySize(m_customRates)<1) {
      return false;
   }
   
   /*
    * This method was designed to build the data in a non-series array
    * Since migrating m_customRates to a series array we cheat here a little by switching it temporaritly
    * back to a non-series array, write the data, and restore it to a series array at the end of the data building
    */
    
   ArraySetAsSeries(m_customRates, false);
   int cntOfNewRates=0;

   // Begin live data feed
   m_upWick = MathMax(m_upWick, m_dataSource.Close(0));
   m_dnWick = MathMin(m_dnWick, m_dataSource.Close(0));

   m_curVolume++;
   
   //-------------------------------------------------------------------------                       
   // up box (new bar)                     
   if(m_dataSource.Close(0)>m_prevHigh+m_boxPoints || CompareDoubles(m_dataSource.Close(0),m_prevHigh+m_boxPoints))
     {
      cntOfNewRates=2;
      int index=ArraySize(m_customRates);
      ArrayResize(m_customRates,index+1);

      m_prevHigh= m_prevHigh+m_boxPoints;
      m_prevLow = m_prevLow+m_boxPoints;
      m_prevOpen= m_prevLow;
      m_prevClose=m_prevHigh;

      m_customRates[index].time = m_prevTime;
      m_customRates[index].open = m_prevOpen;
      m_customRates[index].high = m_prevHigh;
      if(m_showWicks && m_dnWick<m_prevLow)
        {
         m_customRates[index].low=m_dnWick;
        }
      else
        {
         m_customRates[index].low=m_prevLow;
        }
      
      m_curClose = m_customRates[index].high; 
      m_customRates[index].close=m_curClose;
      m_customRates[index].tick_volume=(int)m_curVolume;

      if(m_prevTime<TimeCurrent())
        {
         m_prevTime=TimeCurrent();
        }
      else
        {
         m_prevTime++;
        }

      m_curVolume=0;
      m_curHigh= m_prevHigh;
      m_curLow = m_prevHigh;

      m_upWick = 0;
      m_dnWick = EMPTY_VALUE;
     }
      //-------------------------------------------------------------------------                       
      // down box (new bar)
   else if( m_dataSource.Close(0)<m_prevLow-m_boxPoints || CompareDoubles( m_dataSource.Close(0),m_prevLow-m_boxPoints))
     {
      cntOfNewRates=2;
      int index=ArraySize(m_customRates);
      ArrayResize(m_customRates,index+1);

      m_prevHigh= m_prevHigh-m_boxPoints;
      m_prevLow = m_prevLow-m_boxPoints;
      m_prevOpen= m_prevHigh;
      m_prevClose=m_prevLow;

      m_customRates[index].time = m_prevTime;
      m_customRates[index].open = m_prevOpen;
      if(m_showWicks && m_upWick>m_prevHigh)
        {
         m_customRates[index].high=m_upWick;
        }
      else
        {
         m_customRates[index].high=m_prevHigh;
        }      
      m_customRates[index].low=m_prevLow;
      
      m_curClose = m_customRates[index].low; // !!!!
      m_customRates[index].close=m_curClose;
      m_customRates[index].tick_volume=(int)m_curVolume;

      if(m_prevTime<TimeCurrent())
        {
         m_prevTime=TimeCurrent();
        }
      else
        {
         m_prevTime++;
        }

      m_curVolume=0;
      m_curHigh= m_prevLow;
      m_curLow = m_prevLow;

      m_upWick = 0;
      m_dnWick = EMPTY_VALUE;

     }
      //-------------------------------------------------------------------------                       
      // no box - high/low not hit (just update current bar)               
   else
     {
      if( m_dataSource.Close(0)>m_curHigh)
        {
         m_curHigh= m_dataSource.Close(0);
        }
      if( m_dataSource.Close(0)<m_curLow)
        {
         m_curLow= m_dataSource.Close(0);
        }

      if(m_prevHigh<= m_dataSource.Close(0))
        {
         m_curOpen=m_prevHigh;
        }
      else if(m_prevLow>= m_dataSource.Close(0))
        {
         m_curOpen=m_prevLow;
        }
      else
        {
         m_curOpen= m_dataSource.Close(0);
        }

      m_curClose= m_dataSource.Close(0);

      int index=ArraySize(m_customRates)-1;
      m_customRates[index].time = m_prevTime;
      m_customRates[index].open = m_curOpen;
      m_customRates[index].high = m_curHigh;
      m_customRates[index].low=m_curLow;      
      m_customRates[index].close=m_curClose;
      m_customRates[index].tick_volume=(int)m_curVolume;

      cntOfNewRates=1;
     }
   /*
   ArrayResize(rates,cntOfNewRates);
   for(int i=0; i<cntOfNewRates; i++) {
      rates[i]=m_customRates[ArraySize(m_customRates) -(cntOfNewRates-i)];
   }
   
   for(int i=0; i<cntOfNewRates; i++) {
      rates[i]=m_customRates[ArraySize(m_customRates) -(cntOfNewRates-i)];
   }*/
   
   ArraySetAsSeries(m_customRates, true);
   return true;
  }
//+------------------------------------------------------------------+
