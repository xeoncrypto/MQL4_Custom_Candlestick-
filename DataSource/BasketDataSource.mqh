//+------------------------------------------------------------------+
//|                                              ChartDataSource.mqh |
//|                              Copyright 2015, www.TheForexGuy.com |
//|                                       http://www.TheForexGuy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, www.TheForexGuy.com"
#property link      "http://www.TheForexGuy.com"
#property version   "1.00"
#property strict

#include "BaseDataSource.mqh"

#include "..\..\..\..\Shared Projects\DaleLib\Basket\Includes\ArithmeticPCTBasketIndex.mqh"


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class BasketDataSource : public BaseDataSource {
   public:
   
      BasketDataSource(
          BaseBasketBuilder* inBaksetPtr  
      ) {
        m_basket = inBaksetPtr;
      }
   
      BasketDataSource(
         const t_timeframe inTimeFrame, 
         const int inScanLimit,
         const double inBaseIndexNum = 100.00
      ) {
         m_basket = new ArithmeticPCTBasketIndex(inTimeFrame, inScanLimit, inBaseIndexNum);
      }
      
   
      ~BasketDataSource() {
         delete m_basket;
      }
      
      
      bool CopyRates(MqlRates &out[]) const override {
         m_basket.GetRates(out);
         return true;
      }
      
      bool InitData() override {
         m_basket.BuildData();                   
         return true;     
      }
   
      int BarsCount() const override {
         return m_basket.GetBasketCandleCount();
      }
   
      double Open(const int shift) const override {
         return m_basket.O(shift);
      }
   
      double High(const int shift) const override {
         return m_basket.H(shift);
      }
   
      double Low(const int shift) const override {
         return m_basket.L(shift);
      }
   
      double Close(const int shift) const override {
         return m_basket.C(shift);
      }
   
      long Volume(const int shift) const override {
         return 1;
      }
   
      datetime Time(const int shift) const override {
         return m_basket.T(shift);
      }
      
      int BarShift(const datetime time) const override {
         return m_basket.BarShift(time);
      }
   
      string Type() const override {
         return typename(this);
      }
      
      int Digits() const override {
         return 3;
      }
      
      double Point() const override {
         return 0.001;      
      }
   
      bool UpdateRates() override {
         m_basket.Update();
        /* RefreshRates();
   
         if(ArraySize(m_basket)<1)
           {
            return false;
           }
         int cntOfNewRates=0;
   
         m_basket.Update();
         if(m_basketItemsCount==0)
           {
            m_basketItemsCount=m_basket.BasketCandleCount();
           }
   
         bool incomeNewCandles=m_basketItemsCount<m_basket.BasketCandleCount();
         if(incomeNewCandles)
           {
            int countOfNewCandles=m_basket.BasketCandleCount()-m_basketItemsCount;
   
            MqlRates rates[];
   
            m_basket.GetIndexUpdate(rates,countOfNewCandles+1);
   
            MqlRates newRates[];
            ArrayResize(newRates,ArraySize(m_basket)+ArraySize(rates)-1);
   
            int index = 0;
            for(int i = 0; i < ArraySize(rates); i++)
              {
               newRates[index]=rates[i];
               index++;
              }
   
            for(int i=1; i<ArraySize(m_basket); i++)
              {
               newRates[index]=m_basket[i];
               index++;
              }
   
            ArrayFree(m_basket);
            ArrayCopy(m_basket,newRates);
            m_basketItemsCount=m_basket.BasketCandleCount();
           }
         else
           {
            if(ArraySize(m_basket)>0)
              {
               MqlRates newTick;
               m_basket.GetIndexUpdate(newTick);
               m_basket[0]=newTick;
              }
           }
   
         return true; */
         return true;
      }
      
      ENUM_TIMEFRAMES  GetDataPeriod() const {
         return (ENUM_TIMEFRAMES) m_basket.GetCandleTimeFrame();
      }
      
      string GetSymbol() const {
         const string s =  m_basket.GetSymbol();
         
         if( StringLen(s) <= 0 ) { 
            printf("[%s] WARNING: Basket Symbol was not set - this may effect other objects using this data source!", __FUNCTION__);
         }
         
         return s;
      }

   private:
      BaseBasketBuilder* m_basket;
};
//+------------------------------------------------------------------+
