//+------------------------------------------------------------------+
//|                                                        Array.mqh |
//|                                       Copyright 2017, Dale Woods |
//|                                      https://www.theforexguy.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Dale Woods"
#property link      "https://www.theforexguy.com"
#property strict

#include "MemoryManager.mqh"


class Array {
   
   public: 
            
      /** 
       * 	Check if array holds primitive numbers or strings
      **/
      template <typename T>
      static bool IsPrimitiveType(const T &arr[]) {
         string arrayType = typename(arr);
         
         return(
            IsPrimitiveNumberType(arr)      ||
            arrayType == typename(string)
         );
      }
            
      
      
      /** 
       * 	Check if the array holds primative numbers
      **/
      template <typename T>
      static bool IsPrimitiveNumberType(const T &arr[]) {
         string arrayType = typename(arr);
         
         return(
            arrayType == typename(int)       || 
            arrayType == typename(uint)      ||
            arrayType == typename(long)      ||
            arrayType == typename(ulong)     ||            
            arrayType == typename(double)    ||
            arrayType == typename(float)     ||
            arrayType == typename(ushort)    ||            
            arrayType == typename(bool) 
         );
      }
      
      
      
      /** 
       * 	Check if array is accessed as series
      **/
      template <typename T>
      static bool IsSeries(T &arr[]) {
         return ArrayGetAsSeries(arr) || ArrayIsSeries(arr);
      }
   
   
   
      /** 
       * 	Check how many elements remain to the end of array from position
       *    How many 
      **/
      template <typename T>
      static int IndexRemainingOnLeft(const int fromIndex, T &arr[]) {
         
         const int lastIndex = ArraySize(arr) - 1;      
         return lastIndex - fromIndex;     
      }
   
      
      /** 
       * 	Add element to the end of a time series array
      **/
      template <typename T>
      static void AddToSeries(T &value, T &arr[]) {
         const int size = Size(arr);
         
         T tmp[];
         
         //set tmp array as timeseries
         ArraySetAsSeries(tmp, true);
         
         ArrayResize(tmp, size+1);
         
         //copy existing array to tmp array
         for( int i = size-1, j = size; i >= 0; i--, j-- ) { tmp[j] = arr[i]; }        
         //ArrayCopy(tmp, arr, 1, 0, size);
         
         //resize existing array
         ArrayResize( arr, size+1 );
         
         //copy temp holder array back to original now with new element
         for( int i = size-1; i <= 1; i-- ) { arr[i] = tmp[i]; }

         arr[0] = value;
      }
      
      
      
      /** 
       * 	Add element to the end of a time series array
      **/
      template <typename T>
      static void AddToSeries(const T &value, T &arr[]) {
         const int size = Size(arr);
         
         T tmp[];
         
         //set tmp array as timeseries
         ArraySetAsSeries(tmp, true);
         
         ArrayResize(tmp, size+1);
         
         //copy existing array to tmp array
         for( int i = size-1, j = size; i >= 0; i--, j-- ) { tmp[j] = arr[i]; }        
         //ArrayCopy(tmp, arr, 1, 0, size);
         
         //resize existing array
         ArrayResize( arr, size+1 );
         
         //copy temp holder array back to original now with new element
         for( int i = size-1; i <= 1; i-- ) { arr[i] = tmp[i]; }

         arr[0] = value;
      }      
      
 
      
      /** 
       * 	Get the size of the array
      **/ 
      template <typename T>
      static int Size(const T &arr[]) {
         return ArraySize(arr);
      }
      
      
      /** 
       * 	Clone sizes of the array
      **/ 
      template <typename T>
      static void CloneSize(const T &arr[], T &clone[]) {
         const int size = Size(arr);
         ArraySetAsSeries(clone, ArrayGetAsSeries(arr));   
         ArrayResize(clone, size);
       //  ZeroMemory(clone);
        // if( IsPrimitiveNumberType(arr) ) { ArrayInitialize(clone, 0); }
      }
      
      
      template <typename T>
      static void CloneSizePtr(T* const &arr[], T* &clone[]) {
         const int size = Size(arr);
         ArraySetAsSeries(clone, ArrayGetAsSeries(arr));   
         ArrayResize(clone, size);
       //  ZeroMemory(clone);
         //ArrayInitialize(clone, NULL);
      }
      
      
      /** 
       * 	Check if array holds primitive numbers or strings
      **/
      template <typename T>
      static void Copy(T &source[], T &dest[]) {
         Array::CloneSize(source,dest);
         
         for(int i=0; i<Size(source); i++) { dest[i] = source[i]; }
      } 
      
      template <typename T>
      static void CopyPtrs(T* const &source[], T* &dest[]) {
         Array::CloneSizePtr(source, dest);
         
         for(int i=0; i<Size(source); i++) { dest[i] = source[i]; }
      }        
                    
            
      /** 
       * 	Return true if array is Empty
      **/ 
      template <typename T>
      static bool IsEmpty(const T &arr[]) {
         return ArraySize(arr) == 0;
      }
      
      
      
      /** 
       * 	Return the last index number
      **/ 
      template <typename T>
      static int LastIndex(const T &arr[]) {
         return ArraySize(arr)-1;
      }
      
      
      
      /** 
       * 	Is Index Out Of Array Range
      **/ 
      template <typename T>
      static bool IsOutOfRange(const T &arr[], const int index) {
         return ( index > ArraySize(arr)-1 || index < 0 );
      }      
      
      
      
      /** 
       *    Push a value onto the end of an array
      **/
      template <typename T>
      static void Push(T &value, T &arr[]) {
      
         //array is timeseries         
         if( ArrayGetAsSeries(arr) ) { AddToSeries(value, arr); }
         
         //normal array
         else {
            const int arrSize = Size(arr);
            ArrayResize(arr, arrSize+1);
            arr[arrSize] = value;
         }         
      }
      
      
     
      /** 
       *    Push a value onto the end of an array
      **/ 
      template <typename T>
      static void Push(const T &value, T &arr[]) {
      
         //array is timeseries         
         if( ArrayGetAsSeries(arr) ) { AddToSeries(value, arr); }
         
         //normal array
         else {
            const int arrSize = Size(arr);
            ArrayResize(arr, arrSize+1);
            arr[arrSize] = value;
         }         
      }
      
       
      
      /** 
       *    Another call for push
      **/ 
      template <typename T>
      static void Append(T &value, T &arr[]) {
         Push(value, arr);
      }
      
      
      
      /** 
       *    Another call for push
      **/ 
      template <typename T>
      static void Append(const T &value, T &arr[]) {
         Push(value, arr);
      }
   
         
      
      /** 
       *    Find the higest index  
      **/ 
      template <typename T>
      static int HighestIndex(const int startAtIndex, const int count, const T &arr[]) {
         if( !IsPrimitiveNumberType(arr) )      { printf("[%s ERROR]: You can not perform this operation on a non-primative datatype", __FUNCTION__); return -1; }         
         if( startAtIndex < 0 || count < 0 )    { printf("[%s ERROR]: Bad inputs!", __FUNCTION__); return -1; }
         
         const int lastInx = LastIndex(arr);         
         if( startAtIndex > lastInx ) { printf("[%s ERROR]: Start index is beyond array boundaries!", __FUNCTION__); return -1; }
         
         // Correct counter with limied data points to the left         
         int _scanBack = count;
         if( startAtIndex+count > lastInx ) { _scanBack = lastInx - startAtIndex; }          
         
         // Data tracking
         int highestIndex = startAtIndex;
         T lastHighestVal = arr[startAtIndex];
         
         for(int i = startAtIndex; i < startAtIndex+_scanBack; i++) { 
            if( arr[i] > lastHighestVal ) { 
               highestIndex = i;
               lastHighestVal = arr[i];
            }
         }
         
         return highestIndex;         
      }
      
      
      
      /** 
       *    Find the lowest index  
      **/ 
      template <typename T>
      static int LowestIndex(const int startAtIndex, const int count, const T &arr[]) {
         if( !IsPrimitiveNumberType(arr) )      { printf("[%s ERROR]: You can not perform this operation on a non-primative number datatype", __FUNCTION__); return -1; }
         if( startAtIndex < 0 || count < 0 )    { printf("[%s ERROR]: Bad inputs!", __FUNCTION__); return -1; }
         
         const int lastInx = LastIndex(arr);         
         if( startAtIndex > lastInx ) { printf("[%s ERROR]: Start index is beyond array boundaries!", __FUNCTION__); return -1; }
         
         // Correct counter with limied data points to the left
         int _scanBack = count;
         if( startAtIndex+count > lastInx ) { _scanBack = lastInx - startAtIndex; }          
         
         // Data tracking
         int lowestIndex = startAtIndex;
         T lastLowestVal = arr[startAtIndex];
         
         for(int i = startAtIndex; i < startAtIndex+_scanBack; i++) { 
            if( arr[i] < lastLowestVal ) { 
               lowestIndex = i;
               lastLowestVal = arr[i];
            }
         }
         
         return lowestIndex;  
      }      
      
      
      
      /** 
       *    Get the highest value 
      **/
      template <typename T> 
      static double HighestValue(const int startAtIndex, const int count, const T &arr[]) {
         int result = HighestIndex(startAtIndex, count, arr);
         if( result == -1 )   { return 0; }
         else                 { return arr[result]; } 
      }      
      
      
      
      /** 
       *    Get the lowest value 
      **/ 
      template <typename T>
      static double LowestValue(const int startAtIndex, const int count, const T &arr[]) {
         int result = LowestIndex(startAtIndex, count, arr);
         if( result == -1 )   { return 0; }
         else                 { return arr[result]; } 
      }      
      
      
      
      /** 
       *    MIN/MAX Spread 
      **/       
      template <typename T>
      static bool MinMaxDiff(const int startAtIndex, const int count, const T &arr[], T &outVal) {
         T hVal = 0, lVal = 0;
         
         bool 
            hResult = HighestValue(startAtIndex, count, arr, hVal),
            lResult = LowestValue(startAtIndex, count, arr, lVal);
            
         if( !hResult || !lResult )  { outVal = 0; return false;  }
         else { 
            outVal = hVal - lVal;
            return true;
         } 
      }
      
      
      
      /** 
       *    Sort Ascending
      **/ 
      template <typename T>   
      static bool SortAsc(T &arr[]) {     
         
         if( !IsPrimitiveNumberType(arr) ) { 
            printf("[%s ERROR]: You can not perform this operation on a non-primative number datatype",  __FUNCTION__);
            return false;
         }
         
         const int size = Array::Size(arr);
         T temp;
         
         for(int i=0; i < size; i++) {
            for(int j=i+1; j < size; j++) {
               if(arr[i] > arr[j]) {
                  temp = arr[i];
                  arr[i] = arr[j];
                  arr[j] = temp;
               }
            }           
         }         
         
         return true;      
      }
      
      
      
      /** 
       *    Sort Descending
      **/ 
      template <typename T>   
      static bool SortDesc(T &arr[]) {     
         
         if( !IsPrimitiveNumberType(arr) ) { 
            printf("[%s ERROR]: You can not perform this operation on a non-primative number datatype",  __FUNCTION__);
            return false;
         }
         
         const int size = Array::Size(arr);
         T temp;
         
         for(int i=0; i < size; i++) {
            for(int j=i+1; j< size; j++) {
               if(arr[i] < arr[j]) {
                  temp = arr[i];
                  arr[i] = arr[j];
                  arr[j] = temp;
               }
            }           
         }         
         
         return true;      
      }
      
      
      
};


