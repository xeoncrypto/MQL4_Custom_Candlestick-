//+------------------------------------------------------------------+
//|                                         HAshiPeriodConverter.mqh |
//|                       Copyright 2016, TheForexGuy.com Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, www.TheForexGuy.com"
#property link      "https://www.TheForexGuy.com"
#property strict

#include "CustomCandleBuilder.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class HeikenAshiBuilder : public BaseChartBuilder {
   public:
      BaseDataSource *emptyPtr;
      
      HeikenAshiBuilder (
         BaseDataSource *&dataSource,      
         const int periodMultiplier,
         const int brokerStartHour
      );
      
      ~HeikenAshiBuilder();
      
      bool  UpdateRates() override;
      
      int  GetPeriod() const { return m_candleBuilder.GetPeriod(); }
      
   private:
      void  BuildRates() override;
         
      CustomCandleBuilder  *m_candleBuilder;
      
      datetime    m_lastKnownCandleTime;
      
      void WriteHeikenAshi( const MqlRates &normalCandlesticks[] );
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
HeikenAshiBuilder::HeikenAshiBuilder (
   BaseDataSource *&dataSource,      
   const int periodMultiplier,
   const int brokerStartHour
): emptyPtr(NULL), BaseChartBuilder(emptyPtr) {
   m_candleBuilder = new CustomCandleBuilder(dataSource, periodMultiplier, brokerStartHour);
}


HeikenAshiBuilder::~HeikenAshiBuilder() {
   delete m_candleBuilder;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool HeikenAshiBuilder::UpdateRates() {
   
   m_candleBuilder.UpdateRates();
   
   MqlRates candles[];
   m_candleBuilder.GetRates(m_lastKnownCandleTime,candles); 
   WriteHeikenAshi(candles);
   
   if( m_lastKnownCandleTime != m_customRates[0].time ) {
      m_lastKnownCandleTime = m_customRates[0].time;
   }
   return true;
   
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

void HeikenAshiBuilder::WriteHeikenAshi( const MqlRates &normalCandlesticks[] ) {
   
   if( !ArrayGetAsSeries(normalCandlesticks) ) {    
      printf("[%s %d]: Error, Expecting Series Array", __FUNCTION__, __LINE__);
      return;
   }
   
   const int size = ArraySize(normalCandlesticks);   
   const int diff = size - ArraySize(m_customRates);
   
   if( size < 1 ) { 
      printf("[%s %d]: Error, no data passed to converter", __FUNCTION__, __LINE__);
      return;
   }
   
   // More than  one element difference, rebuild whole array
   if( diff > 1 || diff < 0 ) { 
      ArrayFree(m_customRates);
      ArrayResize(m_customRates, size);
   }
   
   // Just one new candle
   if( diff == 1 ) {
      AddElement(m_customRates);
   }
   

   if( size > 1 ) {
      
      m_customRates[size-1] = normalCandlesticks[size-1];
      
      for(int i=size-1; i>=0; i--) {
         m_customRates[i] = normalCandlesticks[i]; 
         
         if( i+1 <= ArraySize(m_customRates)-1 ) {        
            m_customRates[i].open      = (m_customRates[i+1].open + m_customRates[i+1].close)/2;
         }
         
         else {
            m_customRates[i].open     = (m_customRates[i].open + m_customRates[i].close)/2;
         }   
         
         m_customRates[i].close        = (normalCandlesticks[i].open + normalCandlesticks[i].high + normalCandlesticks[i].low + normalCandlesticks[i].close)/4;
         m_customRates[i].high         = MathMax( normalCandlesticks[i].high, MathMax(m_customRates[i].open, m_customRates[i].close) ); 
         m_customRates[i].low          = MathMin( normalCandlesticks[i].low,  MathMin(m_customRates[i].open, m_customRates[i].close) );

      }
   }
}
 
 
void HeikenAshiBuilder::BuildRates() {
     
   m_candleBuilder.BuildRates();
   
   MqlRates candles[];
   ArraySetAsSeries(candles, true);
   
   m_candleBuilder.GetAllRates(candles);
   
   ArrayFree(m_customRates);
   ArrayResize(m_customRates, ArraySize(candles));
   WriteHeikenAshi(candles);
   
   m_lastKnownCandleTime = m_customRates[0].time;
   
} 
 
 