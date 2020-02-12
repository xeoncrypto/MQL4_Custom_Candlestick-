//+------------------------------------------------------------------+
//|                                               BaseDataSource.mqh |
//|                              Copyright 2020, www.TheForexGuy.com |
//|                                       http://www.TheForexGuy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, www.TheForexGuy.com"
#property link      "http://www.TheForexGuy.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class BaseDataSource {
      
   
   public:
     // virtual int                GetRateLimit() const = 0;
      virtual int                BarsCount() const=0;
      virtual bool               InitData() = 0;
      virtual bool               CopyRates(MqlRates &out[]) const = 0;

      virtual double             Open(const int shift) const = 0;
      virtual double             High(const int shift) const = 0;
      virtual double             Low(const int shift) const=0;
      virtual double             Close(const int shift) const=0;
      virtual long               Volume(const int shift) const=0;
      virtual datetime           Time(const int shift) const=0;

      virtual int                Digits() const = 0;
      virtual double             Point() const = 0;
      virtual int                BarShift(const datetime time) const=0;

      virtual string             Type() const=0;
   
      virtual bool               UpdateRates()=0;  // Make sure new data is fetched. Like on new chart tick.
      virtual ENUM_TIMEFRAMES    GetDataPeriod() const = 0;
      virtual string             GetSymbol() const =0;
};
//+------------------------------------------------------------------+
