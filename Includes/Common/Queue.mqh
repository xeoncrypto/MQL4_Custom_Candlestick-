//+------------------------------------------------------------------+
//|                                                        Queue.mqh |
//|                                       Copyright 2017, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Dale Woods"
#property link      "https://www.theforexguy.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

class Queue {
   private:
      template <typename T>
      T _QueueList[];
      
   public:
      Queue();
      ~Queue();
      
      template <typename T>
      void Add(T &inData);
      
      template <typename T>
      bool Read(T &outData);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Queue::Queue() {
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Queue::~Queue() {
}
//+------------------------------------------------------------------+

template <typename T>
void Queue::Add(T &inData) {
   int size = ArraySize(_QueueList);
   ArrayResize(_QueueList, size+1);
   _QueueList[size] = inData;   
}

template <typename T>
bool Queue::Read(T &outData) {
   
   int size = ArraySize(_QueueList);
   
   if(size == 0) { return false; }
      
   T tmp[];
   
   outData = _QueueList[0];
   
   ArrayCopy(tmp, _QueueList, 0, 1);
   ArrayFree(_QueueList);
   ArrayCopy(_QueueList, tmp);
   
   return true;
}



//+------------------------------------------------------------------+
//|   TRADE EVENT QUEUE                                              |
//+------------------------------------------------------------------+
#include "..\Trade\TradeDataTypes.mqh"
class TEventQueue {
   private:
      TradeEvent _QueueList[];
      
   public:
      TEventQueue();
      ~TEventQueue();
      
      void Add(TradeEvent &inData);
      bool Read(TradeEvent &outData);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TEventQueue::TEventQueue() {
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
TEventQueue::~TEventQueue() {
}
//+------------------------------------------------------------------+


void TEventQueue::Add(TradeEvent &inData) {
   int size = ArraySize(_QueueList);
   ArrayResize(_QueueList, size+1);
   _QueueList[size] = inData;   
}

bool TEventQueue::Read(TradeEvent &outData) {
   
   int size = ArraySize(_QueueList);
   
   if(size == 0) { return false; }
      
   TradeEvent tmp[];
   
   outData = _QueueList[0];
   
   ArrayCopy(tmp, _QueueList, 0, 1);
   ArrayFree(_QueueList);
   ArrayCopy(_QueueList, tmp);
   
   return true;
}