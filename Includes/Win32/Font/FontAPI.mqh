//+------------------------------------------------------------------+
//|                                                      FontAPI.mqh |
//|                                      Copyright 2019, Dale Woods. |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Dale Woods."
#property link      "https://www.theforexguy.com"
#property version   "1.00"

#include "..\FileApi\FileAPI.mqh"
//#include "..\..\Dll\TFGDllApi.mqh"

class FontAPI {
   private:
   
   
   public:
      FontAPI();
      ~FontAPI();
      
      int DisplayAcceptAdminPrivNotice(const long chartID = 0) const;
      
      string GetTerminalFileDirPath() const;
      
      string FontAPI::MakeFontInstallBatFile(
         const string fontName,
         const string fontFileName,
         const string fontFileDir,
         const string batFileName = "installFont"
      ) const;
      
      bool IsInstalled(const string fontName) const;
};
//+------------------------------------------------------------------+



FontAPI::FontAPI() {
}



FontAPI::~FontAPI() {
}


/*
 * Returns the path Files dir inside the Mtx data folder
 */
string FontAPI::GetTerminalFileDirPath() const {
   string terminalPath = "";
   #ifdef __MQL4__
      terminalPath = StringConcatenate(TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL4\\Files\\");      
   #endif 
   
   #ifdef __MQL5__
      StringConcatenate(terminalPath, TerminalInfoString(TERMINAL_DATA_PATH),"\\MQL5\\Files\\");
   #endif
   
   return terminalPath;
}



/*
 * Returns the path of the new file
 */
string FontAPI::MakeFontInstallBatFile(
   const string fontName,
   const string fontFileName,
   const string fontFileDir,
   const string batFileName = "installFont"
) const { 
      
   string terminalPath = GetTerminalFileDirPath();
   
   string filename = StringFormat("%s.txt", batFileName);   
   
   
   //int _BatHandle = Win32OpenFile(terminalPath + batFileName + ".bat");
   FileAPI fileapi();
   
   bool result = fileapi.OpenFile(terminalPath + batFileName + ".bat", "w");
   
   if( result ) {
      fileapi.WriteString(StringFormat("@set fontName=%s\n", fontName) );
      fileapi.WriteString(StringFormat("@set fontFile=%s\n", fontFileName));
      fileapi.WriteString(StringFormat("@set fontDir=%s\n", fontFileDir));      
      fileapi.WriteString(StringFormat("@set fontPath=%s%s\n", fontFileDir, fontFileName));
      
      fileapi.WriteString("@copy \"%fontPath%\" \"%WINDIR%\\Fonts\"\n" );      
      fileapi.WriteString("reg add \"HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts\" /v \"%fontName% (TrueType)\" /t REG_SZ /d %fontFile% /f\n");
      //WriteToFile(_BatHandle, "pause");
   }
   
   else {
     // printf("Get last error = %d", GetLastError());
   }
   
   fileapi.CloseFile();
   
   return terminalPath + batFileName + ".bat";
}


int FontAPI::DisplayAcceptAdminPrivNotice(const long chartID = 0) const {
   #ifdef __MQL5__      
      string notice = "";
      StringConcatenate( notice, 
         "A font is missing which is needed to display symbols on the panels correctly. \n\n",
         "After this notice, a window prompt will appear asking if it is ok for a program to make changes to your computer. \n\n",
         "This is the font installer and it needs your permission to add it to the windows font archive. \n\n",
         "You may select no, and install the font manually if you have the knowledge to do so. \n\n",
         "May the force be with you..."
      );  
   #else
      const string notice = StringConcatenate(
         "A font is missing which is needed to display symbols on the panels correctly. \n\n",
         "After this notice, a window prompt will appear asking if it is ok for a program to make changes to your computer. \n\n",
         "This is the font installer and it needs your permission to add it to the windows font archive. \n\n",
         "You may select no, and install the font manually if you have the knowledge to do so. \n\n",
         "May the force be with you..."
      );  
   #endif
   
   long _hwnd = ChartGetInteger( chartID, CHART_WINDOW_HANDLE );
   int userPressed = MessageBoxW( _hwnd, notice, "Font is Missing :O", MB_OK|MB_ICONINFORMATION);
   return userPressed;
}


bool FontAPI::IsInstalled(const string fontName) const { 
   return false;
   //return TFGDllApi::IsFontInstalled(fontName);
}  