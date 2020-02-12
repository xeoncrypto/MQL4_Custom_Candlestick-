//+------------------------------------------------------------------+
//|                                                      Convert.mqh |
//|                                      Copyright 2018, Dale Woods. |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Dale Woods."
#property link      "https://www.theforexguy.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Convert {
   public:
   
   static double PipsToDouble(const string symb) {
      //++++ These are adjusted for 5 digit brokers.
      int     pips2points, pips;    // slippage  3 pips    3=points    30=points
      double  pips2dbl;             // Stoploss 15 pips    0.0015      0.00150     
      
      double symPoint = SymbolInfoDouble(symb, SYMBOL_POINT);
      
      // DE30=1/JPY=3/EURUSD=5 forum.mql4.com/43064#515262
      if ( SymbolInfoInteger(symb, SYMBOL_DIGITS) % 2 == 1){      
         pips2dbl = symPoint*10; pips2points = 10; pips = 1;
      } 
      
      else {
         pips2dbl = symPoint;
         pips2points =  1;
         pips = 0;
      }
      
      return pips2dbl;   
   }
   
   
   
   static double Spread_ToPoints(const double spread, const string symb) {   
      return spread * MathPow(10, SymbolInfoInteger(symb, SYMBOL_DIGITS)); 
   }
    
   
      
   static double Price_ToPips(const double priceSpread, const string symb) {
      if( priceSpread == 0 ) { return 0; }
      return priceSpread / PipsToDouble(symb);
   }
   
   
   //static double Price_ToPoints()
   
   
   
   static int BinaryToInt(string binary){  // With thanks, concept from http://www.cplusplus.com/forum/windows/30135/ (though the code on that page is faulty afaics)
     int out=0;
     if(StringLen(binary)==0){return(0);}
     for(int i=0;i<StringLen(binary);i++){
       if(StringSubstr(binary,i,1)=="1"){
         out+=int(MathPow(2,StringLen(binary)-i-1));
       }else{
         if(StringSubstr(binary,i,1)!="0"){
           printf("Invalid binary string passed to BinaryToInt: %s", binary);
         }
       }
     }
     return(out);
   }
     
   
   
   static string IntToBinary(int i){  // With thanks, code from https://forum.mql4.com/65906#1001494
     if(i==0) return "0";
     if(i<0) return "-" + IntToBinary(-i);
     string out="";
     for(;i!=0;i/=2) out=string(i%2)+out;
     return(out);
   } 
 
 
 
   static string IntToKBKey(const int asciInt) {
      switch(asciInt) { 
         case 66: return "b";
           
         case 68: return "d"; // "d" key pressed
         case 67: return "c"; // "c" key pressed 
         case 73: return "i"; // "i" key pressed
         case 82: return "w"; // "r" key pressed
         case 87: return "w"; // "w" key pressed
         case 77: return "m"; // "m" key pressed
         case 78: return "n"; // "m" key pressed
         case 79: return "o";
         case 80: return "p";
         case 81: return "q"; // "q" key pressed
         
         case 189: return "-";
         case 187: return "=";
         case 8: return "del";
     
         default: return " ";
      }    
   }
 
   
};



