//+------------------------------------------------------------------+
//|                                                        Cache.mqh |
//|                                      Copyright 2019, Dale Woods. |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Dale Woods."
#property link      "https://www.theforexguy.com"
#property version   "1.00"

template <typename T>  
class Cache {
   private:
      datetime _cacheExpires;
      
      T _cachedValue;
         
      datetime Now() const;
      
   public:
     
      Cache();           
      Cache(T startValue);
      
      ~Cache();
      
      bool IsExpired() const;
      void SetExpireTime( const datetime newCacheExpire ) { _cacheExpires = newCacheExpire; }
      void SetExpireTimeInSeconds( const int seconds );
       
      T GetValue() const { return _cachedValue; }

      void SetValue(T newVal) { _cachedValue = newVal; }
      
      void ClearCache();
   
};

//+------------------------------------------------------------------+
template <typename T>
Cache::Cache() {
   _cacheExpires = 0;
}


template <typename T>    
Cache::Cache(T startValue) {
   _cacheExpires = 0;
   _cachedValue = startValue;
}


template <typename T>  
Cache::~Cache() {

}


template <typename T>  
bool Cache::IsExpired() const {
   
   if( _cacheExpires > 0 && Now() < _cacheExpires  ) {       
       return false;
   }

   return true;
}


template <typename T>  
datetime Cache::Now() const {
   datetime now = 0;
   
   #ifdef __MQL5__
      now = TimeTradeServer();
   #else
      now = TimeCurrent();
   #endif
   
   return now;
}   


template <typename T>  
void Cache::SetExpireTimeInSeconds( const int seconds ) { 
   _cacheExpires = Now() + seconds;
}

template <typename T> 
void Cache::ClearCache() {
   _cacheExpires = 0;
   _cachedValue = 0;
}