//+------------------------------------------------------------------+
//|                                                     JamesOBR.mq4 |
//|                                 Copyright 2012,Clifford H. James |
//|                                                                  |
//+------------------------------------------------------------------+

#include "utils_trades.mq4"

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
//PrintEnvInfo();
PlaceBuyStopOrder(Symbol(), 1.2, 2.0, 1.24, 2.25);
   
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
  
  
//+-----
//| calculates the ORB 
//+-----
double CalcCurrORB() 
{
  // Get the ATR of the 10EET Bar...we run on the 
  double currATR = iATR(NULL, 0, ATR_PERIOD, 1);
  Print("Curr ATR(72): ", currATR);
  return (currATR + OBR_PIP_OFFSET);
}



//+-----
//| generatePendingBuy()
//+-----
void generateDailyPendingOrders(double orbval) 
{
      
   double tenEETHi = High[1]; //Goes back 1 bar to compute 10EET bar high
   double tenEETLo = Low[1]; // Goes back 1 bar to compute 10EET bar low
   double buyEntry = tenEETHi + orbval;
   Alert("Buy Entry for: ", TimeToStr(TimeCurrent(),TIME_DATE|TIME_MINUTES), " is: ", buyEntry);
   Alert("Current Bid: ",Bid,", Current Ask: ", Ask);
      
   // buy side   
   int buyTicket = OrderSend(Symbol(),
      OP_BUYSTOP,
      1,                            // Volume / Lots
      buyEntry,                     // Desired Strike Price                       
      2,                            // slippage
      tenEETHi - (1.65 * orbval),   // SL
      buyEntry + orbval,              // TP
      "test buy order",
      42,
      0,
      Green);
      
   if(buyTicket<0) {
         Print("BuyOrder Placement failed with error#: ",GetLastError());
   }
   
   // sell side
   double sellEntry = tenEETLo - orbval;
   int sellTicket = OrderSend(Symbol(),
      OP_SELLSTOP,
      1,                            // Lots 
      sellEntry,                    // strike price
      2,                            // slippage
      tenEETLo - (1.65 * orbval),   // SL
      sellEntry - orbval,           // TP
      "test sell buy",  
      43,
      0,
      Red);
   if(sellTicket<0) {
      Print("SellOrder Placement failed with error#: ",GetLastError());
   }
      
      
      
}

bool AtCloseOfDay() {
   int currHour=TimeHour(TimeCurrent());
   int currMin=TimeMinute(TimeCurrent());
   return(currHour == 17 && currMin == 30);
   
}

void CloseAllOpenOrders() {
   //TODO: close all open orders here ...
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


void makeBuyOrder(string symb, double reqPrice) {
   double distSL = 2;  //stop-loss(pt)
   int    distTP = 3;  //take-profit(pt)
   double prots = 0.35; //percentage of free margin
   
  
   // repeat-until-successful loop for recoverable errors
   while(true) {
  
     //-----
     // grab some mkt info
     //-----
      int minDist = MarketInfo(symb, MODE_STOPLEVEL); // min stop dist
      double minLot = MarketInfo(symb, MODE_MINLOT); // min lots
      double step = MarketInfo(symb, MODE_LOTSTEP); // step to change lots
      double freeMargin = AccountFreeMargin(); // free margin
      double oneLot = MarketInfo(symb, MODE_MARGINREQUIRED); // cost of 1 lot
   
      //-----
      // check margin conditions (bankroll)
      //-----
      // 2000=1        
      double lots = MathFloor(freeMargin * prots * oneLot) * step; // actual lots 
      if(lots < minLot) {
         Alert(" Not enough money for ",minLot," lots!");
         break;
      }
      
      //-----
      // check min SL dist conditions
      //-----
      //double slDist = (Bid - reqSL)/Point;
      if(distSL < minDist) {
         distSL = minDist;
         Alert(" Increased the distance of SL = ",distSL," pt");
      }
      double SL = Bid - distSL * Point;

      //-----
      // check TP dist conditions
      //-----
      if(distTP < minDist) {
         distTP = minDist;
         Alert(" Increased the distance of TP = ", distTP," pt");
      } 
      
      double TP = Bid + distTP * Point;
      
      //-----
      // Send out the Order
      //----
      Alert(" Sending Order request to server ...");
      int ticket = OrderSend(symb, OP_BUYSTOP, lots, reqPrice, 2, SL, TP);
      if (ticket>0) {
         Alert("Opened order BUY ",ticket);
         break;
      }  
      
      //-----
      // handle potential errors
      //-----
      int err = GetLastError();
      switch(err)
      {
         
      }
       
   }   
   
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
         Alert("Got Close of Day @: ", TimeToStr(Time[0],TIME_DATE|TIME_MINUTES));
         //printInfo();
         CloseAllOpenOrders();
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
        
        Alert("ORB value on: ", TimeToStr(Time[0],TIME_DATE|TIME_MINUTES), " is: ", currOrb);
        
        // generate daily pending orders for buy/sell
        //generateDailyPendingOrders(currOrb);
   }
  
   
   
//----
   return(0);
  }
//+------------------------------------------------------------------+



