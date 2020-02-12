//+------------------------------------------------------------------+
//|                                                Mt4CustomChart.mqh |
//|                       Copyright 2020, TheForexGuy.com Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, www.TheForexGuy.com"
#property link      "https://www.TheForexGuy.com"
#property strict

#include <Object.mqh>
#include <Arrays\ArrayLong.mqh>
#include <Arrays\List.mqh>
#include <Arrays\ArrayObj.mqh>

#include "..\Includes\Common\MemoryManager.mqh"
#include "..\Includes\Common\Macros.mqh"
#include "..\Includes\Common\Debug.mqh"

#include "..\CustomBuilders\BaseChartBuilder.mqh"
#include "..\DataSource\ChartDataSource.mqh"
#include "..\Includes\Win32\dazWinApi.mqh"



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Mt4CustomChart : public CObject {
   
   static int        s_total;

   static uint       m_MT4InternalMsg;
  // static CArrayLong s_chartsOpen;
   static CArrayObj* s_chartsOpen;
   
   bool              m_historyFileCreated; 
   int               m_filePeriod;   
   string            m_usingSymbol;
   int               m_rateSize;
   datetime          m_lastFetchedCandleTime;
   string            m_customTabName;
   
   int               m_globalListIndex;
      
   BaseChartBuilder* m_chartBuilder;
   
   public:
     
      Mt4CustomChart(
         BaseChartBuilder* const chartBuilder
      );
         
      ~Mt4CustomChart();
      
      static CArrayObj* CurrentOpenCharts();
   
      string            HistoryFilename() const  { return(m_historyFileName); }
      string            GetHistoryFilePath() const;
      
      
      bool              FileBuildChartHistory();
      void              CloseHistoryFile();
      bool              WriteUpdatedRates(MqlRates &rates[]);
      bool              WriteNewRate(MqlRates &inTick);
      
      bool              Create();
      bool              Create(MqlRates &rates[]);
      void              Open();
      void              Close();            
      void              SendTick() const;
      void              RenameTab(const string text) const;
      
      void              OnTick();
      
      bool              GetRate(const int atIndex, MqlRates &out) const;
      long              GetChartID() const { return m_chartID; };
      string            GetSymbol() const { return m_usingSymbol; }
      int               GetFilePeriod() const { return m_filePeriod; }
      
      string            CustomTabName() const { return m_customTabName; }
      void              CustomTabName(const string _name) { m_customTabName = _name; }
      
      static void       ClearOpenCharts();
     // static void       PrintAllChartsInUse();
     
     void               AddMetaData(const string name, const string value) const;
      
   
   protected:
      int               m_digits;
      string            m_historyFileName;
      long              m_hwnd;
      int               m_historyFileHandle;
      ulong             m_historyFileHeaderSize;
      long              m_chartID;
      double            m_lastKnownClose;
      bool              IsStdTimeFrame(const int period) const;
      int               GetNextAvailableHistoryFilePeriod( const string symbol, const int periodNum ) const;
      
      void              ClearHistoryFile();
      bool              OpenHistoryFile(const bool clearContents = false);
      bool              WriteHistoryFileHeader();
      
      bool              WriteRates(MqlRates &rates[]);
      void              UpdateChartWindow();
      
      string            GetHistoryDir() const;      
      bool              FindFilesInSubDir(string subDirPath, string markFilename) const;
};


uint Mt4CustomChart::m_MT4InternalMsg=0;
int Mt4CustomChart::s_total = 0;

static CArrayObj* Mt4CustomChart::s_chartsOpen;
static CArrayObj* Mt4CustomChart::CurrentOpenCharts() { return Mt4CustomChart::s_chartsOpen; }

//+------------------------------------------------------------------+

Mt4CustomChart::Mt4CustomChart(
   BaseChartBuilder* const chartBuilder
) {
   Mt4CustomChart::s_total++;
   
   if( !MemoryManager::PtrValid( Mt4CustomChart::s_chartsOpen ) ) {
      Mt4CustomChart::s_chartsOpen = new CArrayObj();
   }
   
   Mt4CustomChart::s_chartsOpen.Add( GetPointer(this) );
   
   
   m_chartBuilder             = chartBuilder; 
   m_usingSymbol              = m_chartBuilder.GetSymbol();
       
   m_historyFileHandle        = -1;
   m_globalListIndex          = -1;
   m_digits                   = m_chartBuilder.GetDigits();
   m_lastKnownClose           = 0;
   m_lastFetchedCandleTime    = -1;
   m_historyFileHeaderSize    = 0;
   m_rateSize                 = sizeof(MqlRates);
   m_customTabName            = NULL;
   
   m_filePeriod               = GetNextAvailableHistoryFilePeriod( m_usingSymbol, m_chartBuilder.GetPeriod() );   
   m_historyFileName          = m_usingSymbol + (string)m_filePeriod;
   
   if(m_MT4InternalMsg==0) {
      m_MT4InternalMsg=RegisterWindowMessageA("MetaTrader4_Internal_Message");
   }
}



Mt4CustomChart::~Mt4CustomChart() { 
   Mt4CustomChart::s_total--;
   
   CloseHistoryFile();
   
   if( Mt4CustomChart::s_total == 0 ) {
      s_chartsOpen.FreeMode(true);
      s_chartsOpen.Clear();
      delete s_chartsOpen;
   }
   
   else {
      s_chartsOpen.FreeMode(false);
      
      if( s_chartsOpen.Total() > 0 ) {
      
         // Remove this object from static list
         for(int i = s_chartsOpen.Total()-1 ; i <= 0 ; i-- ) { 
            Mt4CustomChart* ptr = s_chartsOpen.At(i);
            
            if( !MemoryManager::PtrValid(ptr) ) { 
               s_chartsOpen.Delete(i);   
               continue; 
            }
            
            if( ptr == GetPointer(this) ) { 
               s_chartsOpen.Delete(i);
               break;
            }    
         }
      }      
   }
   
   MemoryManager::Release(m_chartBuilder);
}




//+------------------------------------------------------------------+
//|   CUSTOM CHART WINDOW TRACKING                                   |
//+------------------------------------------------------------------+
bool Mt4CustomChart::IsStdTimeFrame(const int period) const {
   bool result = period == PERIOD_M1; 
   result |= period == PERIOD_M1;
   result |= period == PERIOD_M5;
   result |= period == PERIOD_M15;
   result |= period == PERIOD_M30;
   result |= period == PERIOD_H1;
   result |= period == PERIOD_H4;
   result |= period == PERIOD_D1;
   result |= period == PERIOD_W1;
   result |= period == PERIOD_MN1;
   return result;
}


int Mt4CustomChart::GetNextAvailableHistoryFilePeriod( const string symbol, const int period ) const {
   int customFilePeriod = period;
   
   if( IsStdTimeFrame(period) )  {
      customFilePeriod++;
   }
   
   s_chartsOpen.FreeMode(false);
   
   if( s_chartsOpen.Total() <= 0 ) { return customFilePeriod; }
         
   for( int i = s_chartsOpen.Total()-1; i>=0; i-- ) {      
      
      Mt4CustomChart* ptr = s_chartsOpen.At(i);
      
      if( !MemoryManager::PtrValid(ptr) ) { continue; }
      
      if( ptr == GetPointer(this) ) { continue; }
      
      if( ptr.GetSymbol() == symbol && ptr.GetFilePeriod() == customFilePeriod ) {
         customFilePeriod++;
         
         // Restart loop to recheck all
         i = 0;
         continue;
      } 
   }
   
   return customFilePeriod;
}



//+------------------------------------------------------------------+
//|   CUSTOM CHART HISTORY FILE CREATION                             |
//+------------------------------------------------------------------+
void Mt4CustomChart::ClearHistoryFile() {

   // If a handle is active, that is simple confirmation the hst file exists  
   bool fileExists = m_historyFileHandle > 0;
   
   // Clear any existing handles
   if( m_historyFileHandle > 0 ) { 
      FileClose(m_historyFileHandle);
   }
   
   ResetLastError();  
   if( fileExists ) { 
      // Open file with write permission, then close straight after to clear contents.   
      int handle = FileOpenHistory(m_historyFileName+".hst",FILE_BIN|FILE_SHARE_WRITE|FILE_SHARE_READ);
      
      if( handle <= 0) {         
         printf("[%s %d]: Could not open history file to clear it - Error: %d", __FUNCTION__, __LINE__, GetLastError());
      }
      
      else {
         FileClose(handle);
      }  
   }    
}


bool Mt4CustomChart::OpenHistoryFile(const bool clearContents = false) {
      
   // Quickly open the file with write only conditions to clear it's contents
   if( clearContents ) { ClearHistoryFile(); }   
   
   ResetLastError();
   m_historyFileHandle = FileOpenHistory(m_historyFileName+".hst", FILE_BIN|FILE_WRITE|FILE_SHARE_WRITE|FILE_SHARE_READ|FILE_ANSI); 
   
   if(m_historyFileHandle<0) {
      int errr=GetLastError();
      printf("[%s %d]: Error opening history file %s.hst, error code: %d",__FUNCTION__, __LINE__, m_historyFileName,errr);
      return(false);
   }
   
   s_chartsOpen.Add( GetPointer(this) );
   
   return true;
}



bool Mt4CustomChart::WriteHistoryFileHeader() {
   string   c_copyright  = "(C)opyright 2020, The Forex Guy.";
   int      file_version = 401;
   int      i_unused[13];
   ArrayInitialize(i_unused,0);

   FileSeek(m_historyFileHandle, 0, SEEK_SET);

   FileWriteInteger(m_historyFileHandle,file_version,LONG_VALUE);
   FileWriteString(m_historyFileHandle,c_copyright,64);
   FileWriteString(m_historyFileHandle,m_usingSymbol,12);
   FileWriteInteger(m_historyFileHandle,m_filePeriod,LONG_VALUE);
   FileWriteInteger(m_historyFileHandle,m_digits,LONG_VALUE);
   FileWriteInteger(m_historyFileHandle,0,LONG_VALUE);
   FileWriteInteger(m_historyFileHandle,0,LONG_VALUE);
   FileWriteArray(m_historyFileHandle,i_unused,0,13);   
   
   // Record file ptr so we know where we can start writing rates from
   m_historyFileHeaderSize = FileTell(m_historyFileHandle);
   
   //printf("file header size = %i", m_historyFileHeaderSize);
   return(true);
}

  
  
void Mt4CustomChart::CloseHistoryFile() {
   ResetLastError();
   
   if( m_historyFileHandle>=0 ) {     
      FileClose(m_historyFileHandle);
      
      m_historyFileHandle=-1;
      int err=GetLastError();

      if(err!=0) {
         PrintFormat("%s - Error closing history file %s.hst, error code: %d",__FUNCTION__,m_historyFileName,err);
      }
   }
}    


//+------------------------------------------------------------------+
//|  HISTORY FILE DATA WRITING                                       |
//+------------------------------------------------------------------+
bool Mt4CustomChart::WriteRates(MqlRates &rates[]) {

   if(ArraySize(rates)<1) {
      return false;
   }

   // Move to first rates position after header
   //printf("[%s %d] Seeking to header end = %d", __FUNCTION__, __LINE__,  m_historyFileHeaderSize);
   FileSeek(m_historyFileHandle, m_historyFileHeaderSize, SEEK_SET);

   for(int i=ArraySize(rates)-1; i>=0; i--) {      
      FileWriteStruct(m_historyFileHandle,rates[i]);      
   }

   if(m_lastKnownClose != rates[0].close) {
      m_lastKnownClose=rates[0].close;
   }
   
   FileFlush(m_historyFileHandle);
   
   if( m_chartID > 0 ) { UpdateChartWindow(); }
   return true;
}
 


/*
 * More than 1 rate will be considered new candles to print
*/
bool Mt4CustomChart::WriteUpdatedRates(MqlRates &rates[]) {
   
   if( !ArrayGetAsSeries(rates)) { 
      printf("[%s %d] Error: Expecting series array", __FUNCTION__, __LINE__);
      return false;
   }
   
   ResetLastError();
   
   int size = ArraySize(rates);
   
   if( size < 1 ) { return false; }

   FileSeek(m_historyFileHandle, -m_rateSize, SEEK_END);
   
   for(int i=size-1; i>=0; i--)  {
      FileWriteStruct(m_historyFileHandle,rates[i]);
   }

   if(m_lastKnownClose!=rates[0].close) {
      m_lastKnownClose=rates[0].close;
      FileFlush(m_historyFileHandle);
   }

   return(true);   

}



bool Mt4CustomChart::WriteNewRate(MqlRates &inTick) {   
   MqlRates rates[1];   
   rates[0] = inTick;   
   return WriteUpdatedRates(rates);
}  
  

  
//+------------------------------------------------------------------+
//|   DIRECTIORY HELPERS                                             |
//+------------------------------------------------------------------+  
/* 
 * Addresses bug in MT4 where history folder cannot be resolved if the server is not connected!
 * Place a "marker" file in the history filer with the FileOpenHistory call
 * Search for it and return the path with windows API calls
*/
string Mt4CustomChart::GetHistoryDir() const {
   string markFile="tofindhst";
   int h=FileOpenHistory(markFile,FILE_BIN|FILE_WRITE|FILE_READ|FILE_SHARE_WRITE|FILE_SHARE_READ);
   FileClose(h);
  
   ushort Buffer[300];
   ArrayInitialize(Buffer,0);
   
   string HistoryPath=TerminalPath()+"\\history";
   int handle=FindFirstFileW(HistoryPath+"\\*.*",Buffer);
   bool isFound=false;
   string dirName="";
   
   if(handle>0) {
      do {
         int filesize=(int)Buffer[16]+(int)Buffer[17]*USHORT_MAX;
         if(filesize==0)
           {
            dirName=ShortArrayToString(Buffer,22,152);
            if(dirName!="." && dirName!="..")
              {
               isFound=FindFilesInSubDir(HistoryPath+"\\"+dirName,markFile);
               if(isFound==true) break;
              }
           }      
         ArrayInitialize(Buffer,0);
      } while(FindNextFileW(handle,Buffer));
        
      FindClose(handle);
   }
   
   return dirName;
}



bool Mt4CustomChart::FindFilesInSubDir(string subDirPath, string markFilename) const {
   bool is_Found=false;
   ushort Result[300];
   ArrayInitialize(Result,0);
   int hand_sub=FindFirstFileW(subDirPath+"\\*hst",Result);
   if(hand_sub>0) {
      do {
         string fileName=ShortArrayToString(Result,22,152);
         if(fileName==markFilename) is_Found=true;
         ArrayInitialize(Result,0);
      } while(FindNextFileW(hand_sub,Result));
   }
   
   FindClose(hand_sub);
   
   if(is_Found==true) {
      DeleteFileW(subDirPath+"\\"+markFilename);
   }
   
   return is_Found;
}



string Mt4CustomChart::GetHistoryFilePath() const {
   if( StringLen(m_historyFileName) <= 0 ) { 
      printf("[%s %d] Error: No history file set", __FUNCTION__, __LINE__);
      return "";
   }
   
   return TerminalInfoString(TERMINAL_DATA_PATH)+"\\history\\"+ GetHistoryDir() + "\\" + m_historyFileName + ".hst";
}


//+------------------------------------------------------------------+
//|   CUSTOM CHART WINDOW                                            |
//+------------------------------------------------------------------+
void  Mt4CustomChart::Open() { 
   m_chartID = ChartOpen(m_usingSymbol,m_filePeriod); 
   //AddChartId(m_chartID);
   m_hwnd = (long) ChartGetInteger(m_chartID, CHART_WINDOW_HANDLE);   
   UpdateChartWindow();
}



void  Mt4CustomChart::Close() { 
   if( m_chartID > 0 ) {
      ChartClose(m_chartID);
   }   
   // RemoveChartId(m_chartID);  
   m_chartID = -1; 
   m_hwnd = -1;
} 

 
/*
 * SEND A SYNTHETIC TICK TO MT4 WINDOW
 *    Need to force types to call the PostMessageW signature with types that work with MT4
 *    Import: int PostMessageW(int hWnd,int Msg,int wParam,int lParam) from user32.dll
 */
void Mt4CustomChart::SendTick() const {
   
   if(m_hwnd <= 0) { return; }   
      
   if( PostMessageW( (uint)m_hwnd, (uint) WM_COMMAND, (uint)0x822c, 1 ) == 0 ) {
      return;
   }
  
   PostMessageW( (uint)m_hwnd, (uint)m_MT4InternalMsg, 2, 1);
   //PostMessageA(m_hwnd, WM_COMMAND, 33324, 0);
   return;
}


void Mt4CustomChart::UpdateChartWindow() {
   SendTick();
}


void Mt4CustomChart::RenameTab(const string text) const { 
   string inputs = IntegerToString(AccountNumber()) + "|" + m_usingSymbol + "|" + text;
   //string _temp = tabrenamingfunc(inputs, GetParent((int)m_hwnd));
   SendTick();
}


//+------------------------------------------------------------------+
//|  OPERATIONS                                                      |
//+------------------------------------------------------------------+   
bool Mt4CustomChart::FileBuildChartHistory() {

  return false; 
}


 
bool Mt4CustomChart::Create() {
  // m_chartBuilder.BuildRates();  
  
   m_chartBuilder.BuildRates();

   MqlRates rates[];    
   ArrayFree(rates);  
   m_chartBuilder.GetAllRates(rates);

   return Create(rates);
}



bool Mt4CustomChart::Create(MqlRates &rates[]) {
   const int size = ArraySize(rates);
   
   if( size < 1) { 
      printf("[%s %d]: No rates were built.", __FUNCTION__, __LINE__);
      return false;
   }
   
   if( !ArrayGetAsSeries(rates) ) { 
      printf("[%s %d]: Expecting Series Array.", __FUNCTION__, __LINE__);
      return false;   
   }
   
   m_chartBuilder.SetRates(rates);   
   m_chartBuilder.BuildRates();
      
   if( !OpenHistoryFile(true) ) { return false; }

   WriteHistoryFileHeader();
   
   m_historyFileCreated = WriteRates(rates);
   
   /*
   FORNEG(size-1,size-6)
      printf( "Candle time[%d] = %s", i, TimeToString(rates[i].time) );
   ENDFOR
   
   FORNEG(0,5)
      printf( "Candle time[%d] = %s", i, TimeToString(rates[i].time) );
   ENDFOR */
   
   m_lastFetchedCandleTime = rates[0].time;
   m_lastKnownClose = rates[0].close;
      
   //printf( "Writing last candle time as = %s", TimeToString(m_lastFetchedCandleTime) );
   return m_historyFileCreated;
}



void Mt4CustomChart::OnTick() { 
   RefreshRates();
   m_chartBuilder.UpdateRates();
   
   MqlRates newRates[];   
   m_chartBuilder.GetRates(m_lastFetchedCandleTime, newRates); // CBaseChartBuilder
   
   const int size = ArraySize(newRates);
   
   // Array returned empty! Problem
   if( size < 1 ) { return; }
   
   datetime latestTime = newRates[0].time;
   
   if( latestTime != m_lastFetchedCandleTime ) {
      m_lastFetchedCandleTime = latestTime;
   }

   WriteUpdatedRates(newRates);// CCustomChart
   UpdateChartWindow();
}



//+------------------------------------------------------------------+
//|     GETTERS                                                      |
//+------------------------------------------------------------------+  
bool Mt4CustomChart::GetRate(const int atIndex, MqlRates &out) const {
   return m_chartBuilder.GetRate(atIndex, out);
}



//+------------------------------------------------------------------+
//|     CHART META DATA                                              |
//+------------------------------------------------------------------+ 
void Mt4CustomChart::AddMetaData(const string name, const string value) const {
   //printf("adding %s to %d", name, m_chartID);
   
   if( m_chartID <= 0 ) {
      printf("[%s %d]: Cannot add meta data to chart because it is not open, or chart ID is invalid.", __FUNCTION__, __LINE__);
      return; 
   }
   
  // printf("%s Setting %s to %s", ChartSymbol(m_chartID), name, value);
   
   if( !ObjectCreate(m_chartID, name, OBJ_TEXT, 0, 0, 0) ) {
      printf("[%s %d]: Could not create meta data text | Error NO = %d", __FUNCTION__, __LINE__, GetLastError() );
   }
   
   ObjectSetInteger(m_chartID, name, OBJPROP_XDISTANCE, 50);
   ObjectSetInteger(m_chartID, name, OBJPROP_YDISTANCE, 50);
   ObjectSetInteger(m_chartID, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(m_chartID, name, OBJPROP_FONTSIZE, 1);
   ObjectSetInteger(m_chartID, name, OBJPROP_COLOR, clrNONE);   
   ObjectSetInteger(m_chartID, name, OBJPROP_HIDDEN, true);
   
   if( !ObjectSetString(m_chartID,  name, OBJPROP_TEXT, value) ) {
      printf("[%s %d]: Could not set meta data text | Error No. = %d", __FUNCTION__, __LINE__, GetLastError() );
   }
   
   ChartRedraw(m_chartID);
}



//+------------------------------------------------------------------+
//|     DEBUG                                                        |
//+------------------------------------------------------------------+  

//+------------------------------------------------------------------+
//|     UNUSED ASYNC CODE                                            |
//+------------------------------------------------------------------+  
// Mt4CustomChart::UpdateRates ASync Rates code
//   ResetLastError();
//
//   if(ArraySize(rates)<1)
//     {
//      return false;
//     }
//
//   if(ArraySize(rates)==1)
//     {
//      AddRateAsynch(TerminalInfoString(TERMINAL_DATA_PATH)+"\\history\\"+AccountInfoString(ACCOUNT_SERVER)+"\\"+m_historyFileName+".hst",rates[0],true);
//     }
//   else
//     {
//      for(int i=0; i<ArraySize(rates); i++)
//        {
//         AddRateAsynch(TerminalInfoString(TERMINAL_DATA_PATH)+"\\history\\"+AccountInfoString(ACCOUNT_SERVER)+"\\"+m_historyFileName+".hst",rates[i],false);
//        }
//     }
//
//   if(m_lastKnownClose!=rates[ArraySize(rates)-1].close)
//     {
//      m_lastKnownClose=rates[ArraySize(rates)-1].close;
//      m_lastFpos=FileTell(m_historyFileHandle);
//
//      UpdateChartWindow();
//     }
//
//   return(true);


// Mt4CustomChart::UpdateRates ASync Rates code
   /* 
   string account = AccountInfoString(ACCOUNT_SERVER);
   
   // If account is not connected this will be blank, use "marker file" strategy with win32 calls to find history folder
   if( StringLen(account) == 0 ) {
      account = GetHistoryDir();
   }
 
    string historyFilePath = TerminalInfoString(TERMINAL_DATA_PATH) + "\\history\\" + account;
   StopRatesUpdating(historyFilePath + "\\" + m_historyFileName + ".hst");
   */ 