//+------------------------------------------------------------------+
//|                                                    dataTypes.mqh |
//|                                       Copyright 2017, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Dale Woods"
#property link      "https://www.theforexguy.com"
#property version   "1.00"
#property strict


enum enum_OnOffSwitch {
   OFF   = 0,
   ON    = 1
};

enum logicSetting {
      AND = 1,
      OR  = 2
};


enum enum_sortMode {
   SORT_NONE = 0,
   SORT_ASCENDING = 1,
   SORT_DESCENDING = 2,
   SORT_ABS_ASCENDING = 3,
   SORT_ABS_DESCENDING = 4
};

/* Declared In DazTIme
enum enum_Session {   
   SESSION_NONE = 0,
   SESSION_ASIA = 1,
   SESSION_LONDON = 2,
   SESSION_NEWYORK = 3
}; */

/*
 * Struct to hold a two int vales as a range  
 */
struct IntRange {
   int start, end;
   
   void operator = (const IntRange &source) {
      start = source.start;
      end = source.end;      
   }
   
   IntRange() { 
      start = 0;
      end = 0;
   }
};


/*
 * Struct to hold a two double vales as a range  
 */
struct DoubleRange {
   double start, end;
   
   void operator = (const DoubleRange &source) {
      start = source.start;
      end = source.end;      
   }
   
   DoubleRange() { 
      start = 0;
      end = 0;
   }
};


