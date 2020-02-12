//+------------------------------------------------------------------+
//|                                                    DataTypes.mqh |
//|                                       Copyright 2018, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dale Woods"
#property link      "https://www.theforexguy.com"
#property strict

enum enum_Custom_Chart_Type {
   CHART_TYPE_UNKNOWN      = -1,
   CHART_TYPE_CANDLESTICK  = 0,
   CHART_TYPE_RENKO        = 1,
   CHART_TYPE_MEAN_RENKO = 2,    
   CHART_TYPE_HEIKEN_ASHI  = 3,
   CHART_TYPE_RANGE_BARS    = 4
};