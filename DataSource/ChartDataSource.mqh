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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ChartDataSource : public BaseDataSource {
   public:
      ChartDataSource(
         const string symbol,
         const ENUM_TIMEFRAMES timeframe,
         const datetime historyScanLimit
      ) {
         m_symbol=symbol;
         m_timeframe=timeframe;         
         m_limit = iBarShift(m_symbol, m_timeframe, historyScanLimit);
      }
     
     
      ChartDataSource(
         const string symbol,
         const ENUM_TIMEFRAMES timeframe,
         const int scanbacklimit
      ) {
         m_symbol=symbol;
         m_timeframe=timeframe;         
         m_limit = scanbacklimit;
      }
     
      bool InitData() override { 
         return true;
      }

      int BarsCount() const override {
         return MathMin(iBars(m_symbol, m_timeframe), m_limit);
      }
   
      double Open(const int shift) const override {
         return iOpen(m_symbol, m_timeframe, shift);
      }
   
      double High(const int shift) const override {
         return iHigh(m_symbol, m_timeframe, shift);
      }
   
      double Low(const int shift) const override {
         return iLow(m_symbol, m_timeframe, shift);
      }
   
      double Close(const int shift) const override {
         return iClose(m_symbol, m_timeframe, shift);
      }
   
      long Volume(const int shift) const override {
         return iVolume(m_symbol, m_timeframe, shift);
      }
   
      datetime Time(const int shift) const override {
         return iTime(m_symbol, m_timeframe, shift);
      }
   
      int BarShift(const datetime time) const override {
         return iBarShift(m_symbol, m_timeframe, time);
      }
      
      int Digits() const override {
         return (int) SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
      }
      
      double Point() const override {
         return SymbolInfoDouble(m_symbol, SYMBOL_POINT);      
      }
        
      string Type() const override {
         return typename(this);
      }
   
      bool UpdateRates() override {  
         return true;
      }
      
      ENUM_TIMEFRAMES GetDataPeriod() const override {
         return m_timeframe;
      }
      
      string GetSymbol() const override {
         return m_symbol;
      }
      
      
      bool CopyRates(MqlRates &out[]) const override {
         ArraySetAsSeries(out, true);
         return ::CopyRates( m_symbol, m_timeframe, 0, m_limit, out) > -1;
         
      }

   private:
      string            m_symbol;
      ENUM_TIMEFRAMES   m_timeframe;
      int               m_limit;
};
//+------------------------------------------------------------------+
