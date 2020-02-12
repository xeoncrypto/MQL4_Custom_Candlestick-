//+------------------------------------------------------------------+
//|                                                      ForexSessionTime.mqh |
//|                                       Copyright 2016, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Dale Woods"
#property link      "https://www.theforexguy.com"
#property version   "1.00"
#property strict


enum enum_Forex_Session {
   SESSION_NONE = 0,
   SESSION_ASIA = 1,
   SESSION_LONDON = 2,
   SESSION_US = 3
};

// Custom chart time GMT Shift
enum enum_Forex_Session_Time {   
   SESSION_TIME_NEW_YORK_CLOSE   = 0,
   SESSION_TIME_LONDON_OPEN      = 1,
   SESSION_TIME_NEW_YORK_OPEN    = 2,
   SESSION_TIME_GMT_HOUR         = 3
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ForexSessionTime {
   private:
      static bool _brokerGMTOffsetCalculated;
      static int _brokerGMTOffset;
      static int CalculateBrokerGMTOffset();
      
      static bool FavorableDayToCheckServerTime(const datetime at);
      
      static const string _offsetFilename;
      
      
   public:
      static void ForexSessionTime::Init();
      
      static void SaveOffsetToFile(const int offset);
      static bool ReadOffsetFromFile(int &offset);
      
      static void SetBrokerGMTOffset(const int setTo);
      static int GetBrokerGMTOffset();      
      static int GetCurrentGMTHour();
      
      static int ToGMTHour(const MqlDateTime &timeStamp);
      static int ToGMTHour(const datetime timeStamp);
      
      static int GetLondonOpenGMTHour(const MqlDateTime &timestamp);
      static int GetUSOpenGMTHour(const MqlDateTime &timestamp); 
      static int GetUSCloseGMTHour(const MqlDateTime &timestamp);
      
      static double GetPriceAtChartHour(const string symbol, const int hour);
      static double GetSessionOpenPrice(const string symbol, const enum_Forex_Session session);
      
      static int GetBrokerHourFromGMTHour(const int GMTHour);
      
      static int GetSessionBrokerHour(
         const MqlDateTime &timestamp, 
         const enum_Forex_Session_Time sessionTime
      );
      
      
      static int GetGMTHourOfSession(
         const MqlDateTime &timestamp, 
         const enum_Forex_Session_Time sessionTime
      );
      
      static bool IsSession(
         const MqlDateTime &timestamp, 
         const enum_Forex_Session
      );
      
}; //end class header

static bool ForexSessionTime::_brokerGMTOffsetCalculated = false;
static int ForexSessionTime::_brokerGMTOffset = 0;
static const string ForexSessionTime::_offsetFilename = "_brokerGMTOffset.txt";


//+------------------------------------------------------------------+
//|     CALCULATE GMT OFFSETS                                        |
//+------------------------------------------------------------------+
static int ForexSessionTime::GetCurrentGMTHour() {   
   MqlDateTime gmt;
   TimeGMT(gmt);
   return(gmt.hour);
}


static int ForexSessionTime::ToGMTHour(const MqlDateTime &timeStamp) {
   datetime unixstamp = StructToTime(timeStamp);   
   return ToGMTHour(unixstamp);
}


static void ForexSessionTime::Init() {
   GetBrokerGMTOffset();
}


static int ForexSessionTime::ToGMTHour(const datetime timeStamp) {
   
   int offset = GetBrokerGMTOffset();
   
   // Remove the gmt offset from the passed timestamp
   datetime gmtStamp = timeStamp + (offset * 3600);   
   
   MqlDateTime gmtStruct;
   TimeToStruct(timeStamp, gmtStruct);
   return gmtStruct.hour;
}



// Don't try check on weekends or mon or friday. Since some TZ's market can be closed
static bool ForexSessionTime::FavorableDayToCheckServerTime(const datetime at) {
   MqlDateTime checkMe;     
   TimeToStruct(at, checkMe);
   
   int d = checkMe.day_of_week;
   
   //  Mon, Tues, Wed, Thurs
   return( d == 1 || d ==  2 || d == 3 || d == 4 );
}


static void ForexSessionTime::SetBrokerGMTOffset(const int setTo) {
   _brokerGMTOffset = setTo;
   _brokerGMTOffsetCalculated = true;
}  


static int ForexSessionTime::GetBrokerGMTOffset() { 
      
   if( _brokerGMTOffsetCalculated ) { return _brokerGMTOffset; }
   
   // Conditoins where we should try read the offset from file only
   if( !TerminalInfoInteger(TERMINAL_CONNECTED) || !FavorableDayToCheckServerTime(TimeCurrent()) ) {
   
      // Last recorded offset wasn't saved while broker was open
      if( !FileIsExist(_offsetFilename) ){
         printf( "[%s %d] No connection to broker and broker GMT offset has not been previously stored to file. Unable to calcualte GMT offset until there is a broker connection.", __FUNCTION__, __LINE__);
         return 0;
      }
      
      int offsetFromFile = 0;
      
      if( !ReadOffsetFromFile(offsetFromFile) ) { 
         printf( "[%s %d] No connection to broker and unable to read offset stored in file. Unable to calcualte GMT offset until there is a broker connection.", __FUNCTION__, __LINE__);  
         return 0;        
      }
      
      _brokerGMTOffset = offsetFromFile;
   }
   
   // Otherwise work off the server time
   else {        
      _brokerGMTOffset = CalculateBrokerGMTOffset();
      SaveOffsetToFile(_brokerGMTOffset);  
   }        
          
  
     
   
   return _brokerGMTOffset;
}


static int ForexSessionTime::CalculateBrokerGMTOffset() {   
   return (int) ( (TimeCurrent()-TimeGMT()) / 3600 );
}


//+------------------------------------------------------------------+
//|     SAVE GMT OFFSET FOR WEEKEND                                  |
//+------------------------------------------------------------------+
static void ForexSessionTime::SaveOffsetToFile(const int offset) {
   ResetLastError();
   int h = FileOpen( _offsetFilename, FILE_WRITE|FILE_ANSI );
   
   if( h <= 0 ) { 
      printf( "[%s %d] Unable to open file to store broker offset. Error = %d", __FUNCTION__, __LINE__, GetLastError() ); 
      return;
   }
   
   FileSeek(h, 0, SEEK_SET);
   
   if( offset == 0 ) {
      FileWriteString(h, "0");  
   }
   
   else {
      FileWriteString(h, IntegerToString(offset));  
   }
   
    
   FileClose(h);   
}



static bool ForexSessionTime::ReadOffsetFromFile(int &offset) {
   ResetLastError();
   int h = FileOpen( _offsetFilename, FILE_READ|FILE_SHARE_READ|FILE_ANSI);
   
   if( h <= 0 ) { 
      printf( "[%s %d] Unable to open file to read broker offset. Error = %d", __FUNCTION__, __LINE__, GetLastError() ); 
      return false;
   }
   
   offset = (int) StringToInteger(FileReadString(h, offset));   
   FileClose(h);   
   return true;
}


/*

int ForexSessionTime::CalculateBrokerGMTOffset(const MqlDateTime &gmtTime) const {
   
   return (int) (( TimeCurrent()-TimeGMT() ) / 3600);
   
   MqlDateTime brokerTime;
   TimeCurrent(brokerTime);
   
   if( !TerminalInfoInteger(TERMINAL_CONNECTED) ) { printf("[%s] Not connected to server, unable to get time data...", __FUNCTION__); return 0; }  
   
   int offset = brokerTime.hour - gmtTime.hour;
   
   if( brokerTime.day > gmtTime.day ) { 
      offset -= 24;
   }
   
   return offset;
   
 
   if( StructToTime(gmtTime) > 0 && StructToTime(brokerTime) > 0 ) {
      
      // Clear minutes and seconds to get time rounded to hours
      brokerTime.min = 0;
      brokerTime.sec = 0;
      gmtTime.min    = 0;
      gmtTime.sec    = 0;
      
      // Convert to timestamps
      datetime brokerTimeStamp = StructToTime(brokerTime);
      datetime gmtTimeStamp    = StructToTime(gmtTime);      
      
      int offset = (int)(brokerTimeStamp - gmtTimeStamp) / 3600;
      
      // Return the value      
      printf("[%s] returning offset %d | faster calc = %d", __FUNCTION__, offset, fasterCalc);
      return offset;
   }
   
   //got here, problem flag as problem  
   else {       
      Print("[GMT OFFSET CALCULATOR] Was not able to calcualte GMT Offset, missing time data from server...");
      return 0;
   } 
}*/




//+------------------------------------------------------------------+
//|     CALCULATE SESSION GMT HOUR OPEN/CLOSE TIMES                  |
//+------------------------------------------------------------------+
static int ForexSessionTime::GetLondonOpenGMTHour(const MqlDateTime &timestamp) {
   
   /*
      UK DAYLIGHT SAVINGS RULES
      Start Sunday in March
      End Sunday in October    
   */
   bool isUKDayLightTime = false;
    
   
   if( timestamp.mon >= 4 && timestamp.mon <=10 ) {
      isUKDayLightTime = true;
   }   
   
   //given the timestamp, calculate when London would have opened
   return (isUKDayLightTime ? 7 : 8);
}


static int ForexSessionTime::GetUSOpenGMTHour(const MqlDateTime &timestamp) {
   
   /*
      US DAYLIGHT SAVINGS RULES
    - begins at 2:00 a.m. on the second Sunday of March and
    - ends at 2:00 a.m. on the first Sunday of November    
   */
   bool isUSDayLightTime = false;
   
   if( timestamp.mon > 3 && timestamp.mon <= 10 ) {
      isUSDayLightTime = true;   
   }
   
   //given the timestamp, calculate when the US session would have opened
   return (isUSDayLightTime ? 12 : 13);
}



static int ForexSessionTime::GetUSCloseGMTHour(const MqlDateTime &timestamp) {
   
   /*
      US DAYLIGHT SAVINGS RULES
    - begins at 2:00 a.m. on the second Sunday of March and
    - ends at 2:00 a.m. on the first Sunday of November    
   */
   bool isUSDayLightTime = false;
   
   if( timestamp.mon > 3 && timestamp.mon <= 10 ) {
      isUSDayLightTime = true;   
   } 
   
   //given the timestamp, calculate when London would have opened
   return (isUSDayLightTime ? 21 : 22);
}


static int ForexSessionTime::GetBrokerHourFromGMTHour(const int GMTHour) {
   
   int brokerGmtOffset = GetBrokerGMTOffset();
   
   return GMTHour + brokerGmtOffset;
}


//+------------------------------------------------------------------+
//|     SESSION CHECKS                                               |
//+------------------------------------------------------------------+
static int ForexSessionTime::GetSessionBrokerHour(
   const MqlDateTime &timestamp, 
   const enum_Forex_Session_Time sessionTime
) {
   
   int brokerGmtOffset = GetBrokerGMTOffset();
   
   switch(sessionTime) {
      case SESSION_TIME_NEW_YORK_CLOSE:
         return GetUSCloseGMTHour(timestamp) + brokerGmtOffset;
      case SESSION_TIME_LONDON_OPEN:
         return GetLondonOpenGMTHour(timestamp) + brokerGmtOffset;
      case SESSION_TIME_NEW_YORK_OPEN:
         return GetUSOpenGMTHour(timestamp) + brokerGmtOffset;
      default:
         printf("[%s %d] Invalid Forex Session Time enum passed", __FUNCTION__, __LINE__); 
         return 0;  
   }
}


static int ForexSessionTime::GetGMTHourOfSession(
   const MqlDateTime &timestamp, 
   const enum_Forex_Session_Time sessionTime
) {
      switch(sessionTime) {
      case SESSION_TIME_NEW_YORK_CLOSE:
         return GetUSCloseGMTHour(timestamp);
      case SESSION_TIME_LONDON_OPEN:
         return GetLondonOpenGMTHour(timestamp);
      case SESSION_TIME_NEW_YORK_OPEN:
         return GetUSOpenGMTHour(timestamp);
      default:
         printf("[%s %d] Invalid Forex Session Time enum passed", __FUNCTION__, __LINE__); 
         return 0;  
   }
}


static bool ForexSessionTime::IsSession(
   const MqlDateTime &timestamp, 
   const enum_Forex_Session session
) {
   
   int GMTHour = ToGMTHour(timestamp);
   
   switch(session) {
      case SESSION_US: {
         int USGMTOpenHour = GetSessionBrokerHour(timestamp, SESSION_TIME_NEW_YORK_OPEN);         
         return (GMTHour >= USGMTOpenHour && GMTHour < USGMTOpenHour+7);
      }   
      case SESSION_LONDON: {
         int londonOpenGMTHour = GetSessionBrokerHour(timestamp, SESSION_TIME_LONDON_OPEN);
         return (GMTHour >= londonOpenGMTHour && GMTHour < londonOpenGMTHour+7);
      } 
        
      default:
         printf("[%s %d] Unimplemented Session enum passed", __FUNCTION__, __LINE__); 
         return false;  
   }
}




//+------------------------------------------------------------------+
//|     SESSION PRICES                                               |
//+------------------------------------------------------------------+
static double ForexSessionTime::GetPriceAtChartHour(const string symbol, const int hour) {
   
   double open[1];
   datetime time[1];
   MqlDateTime candleTime;
   
   int atBar = 0, countUntil = 40;
      
   while( atBar < countUntil && !IsStopped() ) {      
      CopyTime(symbol, PERIOD_H1, atBar, 1, time); 
      TimeToStruct(time[0], candleTime);
     
      if( candleTime.hour == hour ) {        
         CopyOpen(symbol, PERIOD_H1, atBar, 1, open);
         return open[0];
      }   
      
      atBar++;   
   }
   
   return -1;
}   


static double ForexSessionTime::GetSessionOpenPrice(
   const string symbol,
   const enum_Forex_Session session
) {

   int sessionOpenCandleHour = -1;
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   
   switch(session) {
      case SESSION_LONDON:
         sessionOpenCandleHour = GetSessionBrokerHour(now, SESSION_TIME_LONDON_OPEN);
         break;
         
      case SESSION_US:
         sessionOpenCandleHour = GetSessionBrokerHour(now, SESSION_TIME_NEW_YORK_OPEN);
         break;                
   }
   
  // printf( "Searching for %s %s open candle at hour %d", symbol, EnumToString(session), sessionOpenCandleHour);
   return GetPriceAtChartHour( symbol, sessionOpenCandleHour );
}





