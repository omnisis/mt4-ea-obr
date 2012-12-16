//+------------------------------------------------------------------+
//|                                                     JamesOBR.mq4 |
//|                                 Copyright 2012,Clifford H. James |
//|                                                                  |
//+------------------------------------------------------------------+

#include <user/utils_trades.mq4>

#property copyright "Copyright 2012,Clifford H. James"
#property link      ""


// CONSTANTS
extern double OBR_PIP_OFFSET = 0.0002;
extern int EET_START = 10;
extern double OBR_RATIO = 1.9;
extern double ATR_PERIOD = 72;

                                            

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
//---

   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
  
  
//---
// calculates the ORB 
//---
double CalcCurrORB() 
{
  // Get the ATR of the 10EET Bar...we run on the 
  double currATR = iATR(NULL, 0, ATR_PERIOD, 1);
  //Print("Curr ATR(72): ", currATR);
  return (currATR + OBR_PIP_OFFSET);
}



//---
// Generate Daily pending orders based on the specified ORB value
// This will generate both a BUY_STOP and SELL_STOP pending order.
//---
void generateDailyPendingOrders(double orbval) 
{
      
   double tenEETHi = High[1]; //Goes back 1 bar to compute 10EET bar high
   double tenEETLo = Low[1]; // Goes back 1 bar to compute 10EET bar low
   int slippage = 2;
   
   double buyEntry = tenEETHi + orbval;
   double SL = buyEntry - (1.65 * orbval);
   double TP = buyEntry + orbval;
   double SL_Dist = RelDistToPoints(SL);
   double TP_Dist = RelDistToPoints(TP);   
   int lotSize = 1;   
   
   Alert("Current Price: ", Bid,"/",Ask);
      
   // buy side  
   PlacePendingStopOrder(
      OP_BUYSTOP,
      Symbol(),
      buyEntry,
      lotSize,
      SL_Dist,
      TP_Dist
   );
   
   double sellEntry = tenEETLo - orbval;
   SL = sellEntry + (1.65 * orbval);
   TP = sellEntry - orbval;
   SL_Dist = RelDistToPoints(SL);
   TP_Dist = RelDistToPoints(TP);
   
   // sell side
   PlacePendingStopOrder(
      OP_SELLSTOP,
      Symbol(),
      sellEntry,
      lotSize,
      SL_Dist,
      TP_Dist
   );
      
      
}

//---
// determine if we are at the close of the day or not
//---
bool AtCloseOfDay() {
   int currHour=TimeHour(TimeCurrent());
   int currMin=TimeMinute(TimeCurrent());
   return(currHour == 17 && currMin == 30);
   
}


//-------------------------------------------------------------------------------
// Calculate trade volume (lot size) for the current symbol based on:
//    - Current free margin in your account
//    - SL dist in points
//    - Desired risk % (0-100)
//    - Tick Value of current symbol
//
//  Additional MIN/MAX lot constraints for the current symbold are applied
//
//    - If you are requesting a volume < minLots for the current symbol
//      then -1 is returned, this indicates that the current trade cannot be made
//
//    - If you are requesting a volume > maxLots for the current symbol
//      then your trade volume is effectively "capped" at maxLotSize
//-------------------------------------------------------------------------------
double calcTradeVolume(double risk, double stopLossPoints) 
{
   double minLotAllowed = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLotAllowed = MarketInfo(Symbol(), MODE_MAXLOT);

   double vol = (AccountFreeMargin() * (risk/100)) /
               ( stopLossPoints * MarketInfo(Symbol(), MODE_TICKVALUE) );
   
   if(vol < minLotAllowed)
      vol = -1.0;
   if(vol > maxLotAllowed)
      vol = maxLotAllowed;
                             
   return(vol);
}

double calcSLDist(double entryPrice, double stopLossPrice)
{
   return(-1.0);
}




//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {
   //----
   // TODO: Check some start conditions ...
   
   // little magic to detect new bars ...
   static datetime Time0; 
   static bool processedClose;
   
  
   //int currMin = TimeMinute(Time[0]);
   
   if(AtCloseOfDay()) {
      if(!processedClose) {
         //Alert("Got Close of Day @: ", TimeToStr(Time[0],TIME_DATE|TIME_MINUTES));
         //printInfo();
         CloseAllOutstandingOrders();
         processedClose = true;
      }
      return(0);
   }
   processedClose = false; 
   
   // check for first bar of the hour ...
   if (Time0 == Time[0]) return;
   Time0 = Time[0];
   int currHour = TimeHour(Time[0]); 
  
   //Alert("Got a new bar at time: ", TimeToStr(Time[0],TIME_DATE|TIME_MINUTES));
   double currOrb = 0;
   if(currHour == 11) {
        currOrb = CalcCurrORB();
        
        //Alert("ORB value on: ", TimeToStr(Time[0],TIME_DATE|TIME_MINUTES), " is: ", currOrb);
        
        // generate daily pending orders for buy/sell
        generateDailyPendingOrders(currOrb);
   }
  
   
   
//----
   return(0);
  }
//+------------------------------------------------------------------+



