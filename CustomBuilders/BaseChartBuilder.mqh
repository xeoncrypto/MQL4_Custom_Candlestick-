//+------------------------------------------------------------------+
//|                                             BaseChartBuilder.mqh |
//|                       Copyright 2020, TheForexGuy.com Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, www.TheForexGuy.com"
#property link      "https://www.TheForexGuy.com"
#property strict

#include "..\DataSource\BaseDataSource.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class BaseChartBuilder
  {
public:
   BaseChartBuilder(BaseDataSource *&dataSource);
   ~BaseChartBuilder();
         
   string            GetSymbol() const { return m_dataSource.GetSymbol(); }
   int               GetDigits() const { return m_dataSource.Digits(); }
   
   virtual void      BuildRates()=0;
   virtual bool      UpdateRates()=0;
   
   void              GetAllRates(MqlRates &rates[]);
   virtual int       GetPeriod() const = 0;
   
   bool              GetRates(const datetime since, MqlRates &rates[]) const;
   bool              GetRate(const int atIndex, MqlRates &out) const;
   
   void              SetRates(const MqlRates &rates[]);
   
   int               GetBarShift(const datetime time, const bool exact=false) const;

protected:
   BaseDataSource    *m_dataSource;
   MqlRates          m_customRates[];

   void              Append(MqlRates &newRates, MqlRates &arr[]) const;
   void              AddElement(MqlRates &arr[]) const;
   
   int               PipsToPoints(const int pips) const;

  };
//+------------------------------------------------------------------+


BaseChartBuilder::BaseChartBuilder(BaseDataSource *&dataSource) {
   m_dataSource = dataSource;
   ArraySetAsSeries(m_customRates, true);
   ZeroMemory(m_customRates);
}
  
  
BaseChartBuilder::~BaseChartBuilder() {
   delete m_dataSource;
}
//+------------------------------------------------------------------+


void BaseChartBuilder::GetAllRates(MqlRates &rates[]) {
   
   int size = ArraySize(m_customRates);
   ArrayFree(rates);
   ArraySetAsSeries(rates, true);
  
   if( size < 1 ) { 
      printf("[%s] Error: No rates available", __FUNCTION__);
      return; 
   }
   
 //  printf("Trying to resize array to %d", size);
   ArrayResize(rates, ArraySize(m_customRates));
   
   ArrayCopy(rates,m_customRates);
}
//+------------------------------------------------------------------+


void BaseChartBuilder::AddElement(MqlRates &arr[]) const {
   const int size = ArraySize(arr);

   //return if empty array passed
   if(size == 0) {
      return;
   }

   MqlRates tmp[];

   //set tmp array as timeseries
   ArraySetAsSeries(tmp, true);
   ArrayResize(tmp, size+1);

   //copy existing array to tmp array
   int copied = 0;

   ResetLastError();

   for(int i = 0; i < size; i++) {
      tmp[i+1] = arr[i];
      copied++;
  }

   if(copied == 0){
      printf("%s: ArrayCopy Error = %i", __FUNCTION__, GetLastError());
   }

   //clear original array's data
   ArrayFree(arr);
   ArraySetAsSeries(arr, true);

   //resize existing array
   ArrayResize(arr, size+1);

   for(int i = 0; i < size+1; i++) {
      arr[i] = tmp[i];
   }

   if(copied == 0) {
      printf("%s: ArrayCopy Error = %i", __FUNCTION__, GetLastError());
   }
   
   else{
      ZeroMemory(arr[0]);
   }

}


void BaseChartBuilder::Append(MqlRates &newRates, MqlRates &arr[]) const {
   AddElement(arr);
   arr[0] = newRates;
}
//+------------------------------------------------------------------+


int BaseChartBuilder::GetBarShift(const datetime time, const bool exact=false) const {

   const int size = ArraySize(m_customRates);
   
   if( size < 1 ) {   
      printf("[%s %d] Error: No custom rates exist.", __FUNCTION__, __LINE__);  
      return -1; 
   }
   
   datetime lastRateTime = m_customRates[0].time;      

   //if time > lastRateTime we always return 0
   if(time >= lastRateTime) {
      return(0);
   }
   
   for(int i = 1; i < size; i++) {
      // Time is in between the two candle open times, or equal to current open time 
      if( 
         time >= m_customRates[i].time && 
         time < m_customRates[i-1].time
      ) { 
        // printf("[%s %d] returning %d", __FUNCTION__, __LINE__, i);  
         return i;
      }
   }
   
   // Nothing found 
   return -1; 
}



/*
 * Call with timestamp to get all rates since the timestamp
 *    Eg: If a new candle has formed, ratesOut will have 2 elements, the previous candle with the passed timestamp, and the new candle
 */
bool BaseChartBuilder::GetRates(const datetime since, MqlRates &ratesOut[]) const {
   
   ArrayFree(ratesOut);
   ArraySetAsSeries(ratesOut, true);
   
   if( ArraySize(m_customRates) < 1 ) { return false; }
   
   ArrayResize(ratesOut, 1);
   
   const int candlesCnt = BaseChartBuilder::GetBarShift(since) + 1;
  // printf("%s candleshift for %s = %d", __FUNCTION__, TimeToString(since),candlesCnt-1 );
   ArrayResize(ratesOut, candlesCnt);
   
   for(int i = candlesCnt-1; i>=0; i--) {
      ratesOut[i] = m_customRates[i];
   }
   
   return true;
}



bool BaseChartBuilder::GetRate(const int atIndex, MqlRates &out) const {
   
   if( ArraySize(m_customRates)-1 < atIndex ) { return false; }

   out = m_customRates[atIndex];   
   return true;
}



void BaseChartBuilder::SetRates(const MqlRates &rates[]) {
   const int size = ArraySize(rates);
   
   if( size < 1) { 
      printf("[%s %d]: No rates were built.", __FUNCTION__, __LINE__);
      return;
   }   
   
   if( !ArrayGetAsSeries(rates) ) { 
      printf("[%s %d]: Expecting Series Array.", __FUNCTION__, __LINE__);
      return;
   }
   
   ArrayResize(m_customRates, size);
   
   for(int i = size-1; i>=0; i-- ) { m_customRates[i] = rates[i]; }
}



int BaseChartBuilder::PipsToPoints(const int pips) const {

   //++++ These are adjusted for 5 digit brokers.
   int     pips2points;    // slippage  3 pips    3=points    30=points
   double  pips2dbl;             // Stoploss 15 pips    0.0015      0.00150     
   const  string s = GetSymbol();
   double symPoint = SymbolInfoDouble(s, SYMBOL_POINT);
   
   // DE30=1/JPY=3/EURUSD=5 forum.mql4.com/43064#515262
   if ( SymbolInfoInteger(s, SYMBOL_DIGITS) % 2 == 1){      
      pips2dbl = symPoint*10; pips2points = 10;
   } 
   
   else {
      pips2dbl = symPoint;
      pips2points =  1;
   }
   
   return (int) (pips / pips2dbl);   

}