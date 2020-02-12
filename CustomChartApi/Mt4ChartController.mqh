//+------------------------------------------------------------------+
//|                                           Mt4ChartController.mqh |
//|                                       Copyright 2018, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dale Woods"
#property link      "https://www.theforexguy.com"
#property version   "1.00"
#property strict

#include <Arrays/List.mqh>
#include "Mt4CustomChart.mqh";


class Mt4ChartController {
   private:
      CList* _chartApis;
      
   public:
      Mt4ChartController();
      ~Mt4ChartController();
      
      void Add(Mt4CustomChart* chartPtr);
      CList* Charts() { return _chartApis; }
      
      bool BuildCharts();
      
      void OpenAll();
      
      void CloseAll();
      void Clear();
      
      void UpdateAll();
};


Mt4ChartController::Mt4ChartController() {
   _chartApis = new CList();
}


Mt4ChartController::~Mt4ChartController() {

   Clear();
   delete _chartApis;
}

//+------------------------------------------------------------------+
void Mt4ChartController::Add(Mt4CustomChart* chartPtr) {
   _chartApis.Add(chartPtr);
}


void Mt4ChartController::CloseAll() { 
   FORLIST(_chartApis);
      Mt4CustomChart* ptr = _chartApis.GetNodeAtIndex(i);
      ptr.Close();
   ENDFOR
}


void Mt4ChartController::Clear() {
   CloseAll();
   _chartApis.FreeMode(true);
   _chartApis.Clear();
   Mt4CustomChart::CurrentOpenCharts().Resize(0);
  // delete _chartApis;
  // _chartApis = new CList();   
}



void Mt4ChartController::UpdateAll() {
   FORLIST(_chartApis);
      Mt4CustomChart* ptr = _chartApis.GetNodeAtIndex(i);
      ptr.OnTick();
   ENDFOR
}



bool Mt4ChartController::BuildCharts() {
   
   FORLIST(_chartApis);
      Mt4CustomChart* ptr = _chartApis.GetNodeAtIndex(i);
      if( !ptr.Create() ) { return false; }      
   ENDFOR
   
   return true;
}



void Mt4ChartController::OpenAll() {
   
   FORLIST(_chartApis);
      Mt4CustomChart* ptr = _chartApis.GetNodeAtIndex(i);
      ptr.Open();
      
      // Wait for chart to become responsive
      for(int j=0; j<100; j++) {
         Sleep(10);

         long value=0;

         if(ChartGetInteger(ptr.GetChartID(),CHART_WIDTH_IN_PIXELS,0,value)) {
            if(value!=0) { break; }
         }
      }      
   ENDFOR
}

