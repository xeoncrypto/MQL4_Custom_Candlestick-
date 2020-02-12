//+------------------------------------------------------------------+
//|                                                       Macros.mqh |
//|                                       Copyright 2018, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dale Woods"
#property link      "https://www.theforexguy.com"
#property strict


#define FOR(from, to)      for(int i = from; i<to; i++) {
#define FORREV(from, to)   for(int i = from; i>=to; i--) {

#define FORARRAY(arr)      for(int i = 0; i<ArraySize(arr); i++) {
#define FORARRAYINNER(arr)      for(int j = 0; j<ArraySize(arr); j++) {

#define FORARRAYREV(arr)   for(int i = ArraySize(arr)-1; i>=; i++) {
#define FORLIST(list)      for(int i = 0; i<list.Total(); i++) { 
#define ENDFOR }

#define FOREACH(arr, value) for(int i = 0; i<ArraySize(arr); i++) { value = arr[i];
#define ENDFOREACH }
