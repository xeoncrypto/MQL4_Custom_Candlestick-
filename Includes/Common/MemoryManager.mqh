//+------------------------------------------------------------------+
//|                                             PointersReleaser.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict

/*
   Crafted with help of the awesome super powers of Sergey the great!
*/

class MemoryManager
{
   public:
      
      template<typename T>
      static bool PtrValid(T &pointer) {
         if( CheckPointer(pointer) == POINTER_DYNAMIC ) { return true; }
         return false;
      }
      
      
      
      template<typename T>
      static void Release(T &pointer) {
         if( PtrValid(pointer) ) { 
            delete pointer; 
            pointer = NULL;
         }
      }

      

      template<typename T>
      static void Release(T &pointersArray[]) {
         for(int i = 0; i < ArraySize(pointersArray); i++) { Release(pointersArray[i]); }
         ArrayFree(pointersArray);
      }
      
      
      
      // Will add pointer to a pointer array
      template<typename T>
      static void AddPtrToArray(T ptr, T &pointersArray[]) {         
         if( PtrValid(ptr) ) { 
            const int arrSize = ArraySize(pointersArray);
            ArrayResize(pointersArray, arrSize+1);
            pointersArray[arrSize] = ptr;         
         }
      }
      
      
      
      // Will clean arrray of null/invalid pointers
      template<typename T>
      static void ClearInvalidPtrs(T &arr[]) {         
         T newArray[];
         
         for( int i = 0; i < ArraySize(arr); i++ ) {
            if( CheckPointer(arr[i]) == POINTER_DYNAMIC ) {
               MemoryManager::AddPtrToArray(arr[i], newArray);      
            }
         }
         
         ArrayFree(arr);
         const int newSize = ArraySize(newArray);
         
         //need to loop manually - arraycopy does not support non priative data copy
         if( newSize > 0 ) {
            ArrayResize(arr, newSize);      
            for(int i = 0; i < newSize; i++ ) { arr[i] = newArray[i]; } 
         }       
      }

};

