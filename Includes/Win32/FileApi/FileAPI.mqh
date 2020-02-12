//+------------------------------------------------------------------+
//|                                                      FileAPI.mqh |
//|                                      Copyright 2019, Dale Woods. |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Dale Woods."
#property link      "https://www.theforexguy.com"
#property version   "1.00"
// Ref @ https://gist.github.com/currencysecrets/11353588 "The famous WinFile.mqh file from MTIntelligence.com"
/*
#import "kernel32.dll"
   int CreateFileW(const string file_name,uint desired_access,uint share_mode,long security_attributes,uint creation_disposition,uint flags_and_attributes,int template_file);
   int ReadFile(int FileHandle, int BufferPtr, int BufferLength, int & BytesRead[], int PassAsZero);
   int WriteFile(int file,const uchar &buffer[],uint number_of_bytes_to_write,uint &number_of_bytes_written,long overlapped);
   
   int SetFilePointer(int FileHandle, int Distance, int PassAsZero, int FromPosition);
   int GetFileSize(int FileHandle, int PassAsZero);
   int CloseHandle(int FileHandle);
      
   /* 
   // Used for temporary conversion of an array into a block of memory, which
   // can then be passed as an integer to ReadFile
   int LocalAlloc(int Flags, int Bytes);
   int RtlMoveMemory(int DestPtr, double & Array[], int Length);
   int LocalFree(int lMem);

   // Used for converting the address of an array to an integer 
   int GlobalLock(double & Array[]);
   bool GlobalUnlock(int hMem); */
//#import

#include "..\dazWinApi.mqh"

#define GENERIC_READ            0x80000000
#define GENERIC_WRITE           0x40000000

//#define FILE_SHARE_READ         1
//#define FILE_SHARE_WRITE        2

#define CREATE_NEW              1
#define CREATE_ALWAYS           2
#define OPEN_ALWAYS             4
#define OPEN_EXISTING           3
#define TRUNCATE_EXISTING       5

#define FILE_BEGIN              0
#define FILE_CURRENT            1
#define FILE_END                2

#import "kernel32.dll"
   int    WriteFile(HANDLE file,const uchar &buffer[],uint number_of_bytes_to_write,uint &number_of_bytes_written,PVOID overlapped);
#import

#import "shlwapi.dll"
   bool     PathFileExistsW(string filePath); 
#import
   

class FileAPI {
   private:
      HANDLE _handle;
   public:
      FileAPI();
      ~FileAPI();
      void To_ushortArr(const string str, ushort &arr[]) const;
      
      bool FileExists(const string file) const;
      
      bool WriteString(string DataToWrite) const;
      bool OpenFile(const string path, const string accessMode, const bool shared = false);
      
      void CloseFile();
};


//+------------------------------------------------------------------+



FileAPI::FileAPI() {

   _handle = 0;
}



FileAPI::~FileAPI() {

   if( _handle > 0 ) { CloseFile(); }
}


bool FileAPI::FileExists(const string filePath) const {
   return PathFileExistsW(filePath);
}



bool FileAPI::OpenFile(const string path, const string accessMode, const bool shared = false) { 
   int ShareMode = 0;
   PVOID _zero = 0;  
   
   uint accessFlag = GENERIC_WRITE;
   
   if( accessMode == "w" ) {
      accessFlag = GENERIC_WRITE;     
   }
   
   if( accessMode == "r" ) {
      accessFlag = GENERIC_READ;     
   }
   
   // Seems to be the way to open exsisting files also
   if( !FileExists(path) ) {
      _handle = CreateFileW(path, accessFlag, ShareMode, 0, CREATE_NEW, 0, _zero);
   } 
   
   else {
      _handle = (int) CreateFileW(path, accessFlag, ShareMode, 0, OPEN_EXISTING, 0, _zero);
   }  
   
   return _handle > 0;   
}


void FileAPI::CloseFile() { 
   CloseHandle(_handle);
}


void FileAPI::To_ushortArr(const string str, ushort &arr[]) const {
   
   const int size = StringLen(str);
   
   ArrayResize(arr, size);

   for(int i = 0; i<size; i++) {
      #ifdef __MQL4__
         arr[i] = (uchar) StringGetChar(str, i);   
      #else
         arr[i] = (uchar) StringGetCharacter(str, i);
      #endif   
   }
}



bool FileAPI::WriteString(string DataToWrite) const {
   // Receives the number of bytes written to the file. Note that MQL can only pass 
   // arrays as by-reference parameters to DLLs
   uint BytesWritten = 0;

   // Get the length of the string 
   int szData = StringLen(DataToWrite);
   
   uchar stringArr[];
   
   
   //To_ushortArr(DataToWrite, stringArr);
   
   StringToCharArray(DataToWrite, stringArr);
   
   // Do the write 
   WriteFile(_handle, stringArr, szData, BytesWritten, 0);
   
   // Return true if the number of bytes written matches the expected number 
   return (BytesWritten == szData);   
}
