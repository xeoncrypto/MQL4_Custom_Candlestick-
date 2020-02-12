//+------------------------------------------------------------------+
//|                                                        Crypt.mqh |
//|                                      Copyright 2019, Dale Woods. |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Dale Woods."
#property link      "https://www.theforexguy.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Crypt {

   public:
   
   
   //+------------------------------------------------------------------+
   //|  SHA 256 ENCODING                                                |
   //+------------------------------------------------------------------+
   static string SHA256(const string encodeMe) {
      const int size = StringLen(encodeMe);
      const string EMPTY_SHA256 = "01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b";
      
      if( size == 0 ) { return EMPTY_SHA256; }   
      
      uchar result[], data[];
      const uchar key[1] = { 0 };
   
      StringToCharArray(encodeMe, data, 0 , size);   
      CryptEncode(CRYPT_HASH_SHA256, data, key, result);
      
      //convert hex to asci
      string resultStr = "";
      
      for ( int i = 0 ; i < ArraySize(result); i ++) {
         #ifdef __MQL5__
            StringConcatenate(resultStr, resultStr, StringFormat( "%02x" , result[i]) );
         #else
            resultStr = StringConcatenate(resultStr, StringFormat( "%02x" , result[i]) );
         #endif   
      } 
      
      return resultStr;
   }
   
   
   /** 
    *    Standard MD5 Hash Algo
   **/
   static string Crypt::MD5(const string encodeMe) {
      const int size = StringLen(encodeMe);
      const string EMPTY_MD5 = "d41d8cd98f00b204e9800998ecf8427e";
      
      if( size == 0 ) { return EMPTY_MD5; }   
      
      uchar result[], data[];
      const uchar key[1] = { 0 };
   
      StringToCharArray(encodeMe, data, 0 , size);   
      CryptEncode(CRYPT_HASH_MD5, data, key, result);
      
      //convert hex to asci
      string resultStr = "";
      for ( int i = 0 ; i < ArraySize(result); i ++) {
         #ifdef __MQL5__
            StringConcatenate(resultStr, resultStr, StringFormat( "%02x" , result[i]) );
         #else
            resultStr = StringConcatenate(resultStr, StringFormat( "%02x" , result[i]) );
         #endif   
      }
      
      return resultStr;
   }


   /** 
    *    Standard BASE64 encode
   **/
   static string Crypt::Base64Encode(const string encodeMe) {
      const int length = StringLen(encodeMe);
      
      if(length == 0) { return ""; }
    
      uchar result[], data[];   
      const uchar key[1] = {0};
   
      StringToCharArray(encodeMe, data, 0, length);   
      CryptEncode(CRYPT_BASE64, data, key, result);
         
      return CharArrayToString(result);
   }
   
};