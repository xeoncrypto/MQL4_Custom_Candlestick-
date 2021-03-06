//+------------------------------------------------------------------+
//|                                                         Http.mqh |
//|                             Copyright © 2010 www.theforexguy.com |
//|                                             Coding by Dale Woods |
//+------------------------------------------------------------------+
#property copyright   "Dale Wooods "
#property link        "www.theforexguy.com"
#property version     "1.00"
#property description "HTTP library"
#property library

#import "wininet.dll"
int InternetAttemptConnect(int x);
int InternetOpenW(string sAgent,int lAccessType,string sProxyName,string sProxyBypass,int lFlags);
int InternetConnectW(int hInternet,string lpszServerName,int nServerPort,string lpszUsername,string lpszPassword,int dwService,int dwFlags,int dwContext);
int HttpOpenRequestW(int hConnect,string lpszmethod,string lpszObjectName,string lpszVersion,string lpszReferer,string lplpszAcceptTypes,uint dwFlags,int dwContext);

//int HttpSendRequestW(int hRequest,string &lpszHeaders,int dwHeadersLength,uchar &lpOptional[],int dwOptionalLength);
int HttpSendRequestW(int hRequest, string lpszHeaders, int dwHeadersLength, uchar &lpOptional[], int dwOptionalLength);

int HttpQueryInfoW(int hRequest,int dwInfoLevel,uchar &lpvBuffer[],int lpdwBufferLength,int &lpdwIndex);
int InternetOpenUrlW(int hInternet,string &lpszUrl,string lpszHeaders,int dwHeadersLength,uint dwFlags,int dwContext);
int InternetReadFile(int hFile,uchar &sBuffer[],int lNumBytesToRead,int &lNumberOfBytesRead);
int InternetCloseHandle(int hInet);
#import

#import "kernel32.dll"
   int GetLastError(void);
#import

#define OPEN_TYPE_PRECONFIG           0  // use confuguration by default
#define FLAG_KEEP_CONNECTION 0x00400000  // keep connection
#define FLAG_PRAGMA_NOCACHE  0x00000100  // no cache
#define FLAG_RELOAD          0x80000000  // reload page when request
#define INTERNET_FLAG_SECURE 0x00800000
#define SERVICE_HTTP                  3  // Http service
#define HTTP_QUERY_CONTENT_LENGTH     5

#define INTERNET_DEFAULT_FTP_PORT       21
#define INTERNET_DEFAULT_GOPHER_PORT    70
#define INTERNET_DEFAULT_HTTP_PORT      80
#define INTERNET_DEFAULT_HTTPS_PORT     443
#define INTERNET_DEFAULT_SOCKS_PORT     1080
//+------------------------------------------------------------------+
class Http {

      string            _host;         // host name
      int               _port;         // port
      int               _session;      // session handle
      int               _hConnect;     // connection handle
      
   public:
                        Http();
                       ~Http();
      bool              Open(string aHost,int aPort);
      void              Close(); 
      bool              Request(const string method, const string Object, string &Out, const string addData="", const bool https = false, bool toFile=false, bool fromFile=false);
      bool              OpenURL(string url,string &Out,bool toFile);
      void              ReadPage(int hRequest,string &Out,bool toFile);
      long              GetContentSize(int hURL);
      int               FileToArray(string FileName,uchar &data[]); 
      
      void              ParseURL(string url, string &host, string &path) const;
      string            UrlEncode(string encodeMe) const;
      
      bool              Get(const string host, const string path, string &response, const bool useHttps = false);
      bool              Post(const string host, const string path, const string data, string &response, const bool https = false); 
      
};
//------------------------------------------------------------------ Http
void Http::Http()
  {
   // default values
   _session=-1;
   _hConnect=-1;
   _host="";
  }
//------------------------------------------------------------------ ~Http
void Http::~Http() {
   // close all descriptors
   Close();
}
  
//------------------------------------------------------------------ Open
bool Http::Open(string aHost,int aPort) {
   if(aHost=="")
     {
      Print("-_host is not specified");
      return(false);
     }
     
   // is DLL allowed in the client terminal
   if(!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED)) {
      Print("-DLL is not allowed");
      return(false);
   }
     
   // if session has been opened, close it
   if(_session>0 || _hConnect>0) Close();

   // exit, if connection check has failed
   if(InternetAttemptConnect(0)!=0)
     {
      
      printf("-Err AttemptConnect = %i", kernel32::GetLastError());
      return(false);
     }
   string UserAgent="Mozilla"; string nill="";
   // open session
   _session = InternetOpenW(UserAgent,OPEN_TYPE_PRECONFIG, NULL, NULL,0);
   // exit, if session is not opened
   if(_session<=0) {
      printf("-Err Create _session = %i", kernel32::GetLastError());
      Close();
      return(false);
     }
     
   aPort = INTERNET_DEFAULT_HTTPS_PORT;
   _hConnect = InternetConnectW(_session,aHost,aPort,NULL, NULL, SERVICE_HTTP,0,0);
   
   if(_hConnect<=0) {      
      printf("-Err Create _hConnect = %i", kernel32::GetLastError());
      Close();
      return(false);
     }
   _host=aHost; 
   _port=aPort;
   // overwise all checks successful
   return(true);
}

//------------------------------------------------------------------ Close
void Http::Close() {
   //Print("-Close Inet...");
   if(_session>0) InternetCloseHandle(_session);
   _session=-1;
   if(_hConnect>0) InternetCloseHandle(_hConnect);
   _hConnect=-1;
}

//------------------------------------------------------------------ Request
bool Http::Request(const string method, const string Object, string &Out, const string addData="", const bool https = false, bool toFile=false, bool fromFile=false) {
   if(toFile && Out=="") {
      Print("-File is not specified ");
      return(false);
   }
      
   int hRequest,hSend;
   string Vers="HTTPS/1.1";
   
   uchar data[];
   
   if(fromFile){
      if(FileToArray(addData,data)<0)
        {
         Print("-Err reading file "+addData);
         return(false);
        }
   } // file loaded to the array
   
   else StringToCharArray(addData, data, 0, StringLen(addData));
   
   if(_session<=0 || _hConnect<=0) {
      Close();
      if(!Open(_host,_port)) {
         printf("-Err _hConnect = %i", kernel32::GetLastError());
         Close();
         return(false);
        }
   }
   
   // create descriptor for the request   
   uint 
      nonSSLFlags = FLAG_KEEP_CONNECTION|FLAG_RELOAD|FLAG_PRAGMA_NOCACHE,
      secureflags = FLAG_KEEP_CONNECTION|FLAG_RELOAD|FLAG_PRAGMA_NOCACHE|INTERNET_FLAG_SECURE;
   
   hRequest = HttpOpenRequestW(_hConnect, method, Object, Vers, NULL, NULL, secureflags, 0);
   
   if(hRequest <= 0) {
      printf("HttpOpenRequestW Error = %i", kernel32::GetLastError());
      InternetCloseHandle(_hConnect);
      return(false);
   }
  
   // set headers
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   //headers += ""
   
   // send request
   int headerLen = StringLen(headers), dataLen = ArraySize(data);
   hSend = HttpSendRequestW(hRequest, headers, headerLen, data, dataLen);
   
   if(hSend<=0) {
      printf("-Err SendRequest = %i", kernel32::GetLastError());
      InternetCloseHandle(hRequest);
      Close();
   }
   
   // read page   
   ReadPage(hRequest,Out,toFile);
   
   // close all descriptors
   InternetCloseHandle(hRequest);
   InternetCloseHandle(hSend);
   
   return(true);
  }
//------------------------------------------------------------------ OpenURL
bool Http::OpenURL(string url,string &Out,bool toFile) {
   string nill="";
   if(_session<=0 || _hConnect<=0)
     {
      Close();
      if(!Open(_host,_port))
        {
         Print("-Err _hConnect");
         Close();
         return(false);
        }
     }
   uint hURL=InternetOpenUrlW(_session, url, nill, 0, FLAG_RELOAD|FLAG_PRAGMA_NOCACHE, 0);
   if(hURL<=0)
     {
      Print("-Err OpenUrl");
      return(false);
     }
   // read to Out
   ReadPage(hURL,Out,toFile);
   // close
   InternetCloseHandle(hURL);
   return(true);
}
//------------------------------------------------------------------ ReadPage
void Http::ReadPage(int hRequest,string &Out,bool toFile)
  {
   // read page
   uchar ch[100];
   string toStr="";
   int dwBytes;
   while(InternetReadFile(hRequest,ch,100,dwBytes)) {
      if(dwBytes<=0) break;
      string chunk = CharArrayToString(ch,0,dwBytes);
      
      #ifdef __MQL5__      
         StringConcatenate(toStr, toStr, chunk);
      #else
         toStr = StringConcatenate(toStr, chunk);
      #endif
   }
   if(toFile)
     {
      int h = FileOpen(Out,FILE_BIN|FILE_WRITE);
      FileWriteString(h,toStr);
      FileClose(h);
     }
   else Out=toStr;
  }
//------------------------------------------------------------------ GetContentSize
long Http::GetContentSize(int hRequest)
  {
   int len=2048,ind=0;
   uchar buf[2048];
   int Res=HttpQueryInfoW(hRequest, HTTP_QUERY_CONTENT_LENGTH, buf, len, ind);
   if(Res<=0)
     {
      Print("-Err QueryInfo");
      return(-1);
     }
   string s=CharArrayToString(buf,0,len);
   if(StringLen(s)<=0) return(0);
   return(StringToInteger(s));
  }
//----------------------------------------------------- FileToArray
int Http::FileToArray(string FileName,uchar &data[])
  {
   int h,i,size;
   h=FileOpen(FileName,FILE_BIN|FILE_READ);
   if(h<0) return(-1);
   FileSeek(h,0,SEEK_SET);
   size=(int)FileSize(h);
   ArrayResize(data,(int)size);
   for(i=0; i<size; i++)
     {
      data[i]=(uchar)FileReadInteger(h,CHAR_VALUE);
     }
   FileClose(h); return(size);
  }
//+------------------------------------------------------------------+


void Http::ParseURL(string url, string &host, string &path) const {
   
   // Remove the protocol (http:// https:// ftp://)
   int protocolEnd = StringFind(url,"//") + 2;
   url = StringSubstr(url, protocolEnd);
    
   // Find the next slash to split host / path into two separate strings  
   int hostEnd = StringFind(url,"/");
   
   // If there is no trailing '/' then just return the hostname
   if( hostEnd <= 0 ) { 
      host = url;
      path = "";
      return;
   }
   
   // If trailing / exists, split there into host / path
   host = StringSubstr(url, 0, hostEnd );   
   path = StringSubstr(url, hostEnd);
}



string Http::UrlEncode(string encodeMe) const {
   int len = StringLen(encodeMe); 
   uchar characters[];   
   string encoded = "";
   
   ArrayResize(characters, len);
   StringToCharArray(encodeMe,characters);
   
   for (int i = 0; i<len ;i++) { encoded += StringFormat("%%%02x", characters[i]); }
   
   return encoded;
}




bool Http::Get(const string host, const string path, string &response, const bool useHttps = false) {
   
   int httpport = (useHttps) ? INTERNET_DEFAULT_HTTPS_PORT : INTERNET_DEFAULT_HTTP_PORT;
   
   if( !Open(host, httpport) ) { Close(); return false; }
   
   const bool success = Request("GET", path, response, "", useHttps, false, false);
   
   Close();
   
   return success;   
} 



bool Http::Post(const string host, const string path, const string data, string &response, const bool useHttps = false) {

   int httpport = (useHttps) ? INTERNET_DEFAULT_HTTPS_PORT : INTERNET_DEFAULT_HTTP_PORT;
   
   if( !Open(host, httpport) ) { printf("[%s Error]: Was unable to open connection", __FUNCTION__); Close(); return false; }
   
   const bool success = Request("POST", path, response, data, useHttps, false, false);

   Close();
   
   return success;
}