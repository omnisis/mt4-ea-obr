/*
 *************************************************************************************************
 * A set of common utility functions for dealing with trades.  Including are wrapped methods
 * to place buy/sell orders as well as code for handling common errors that can occur when placing
 * trades.
 *************************************************************************************************
 */
 
#include <user/utils_misc.mq4> 

/**
 * Places a Pending BUY STOP order with the specified parameters.  Note that
 * some aspects of your order (SL,TP) may be changed if they are above/below
 * the required minimum/maximum values.
 * 
 * @param Symb       Symbol to place order for  
 * @param ReqPrice   Requested fill price
 * @param Lots       Requested number of lots (volume)
 * @param Dist_SL    Requested SL distance (in points)
 * @param Dist_TP    Requested TP distance (in points)
**/
void PlaceBuyStopOrder(int    tradeType,
                       string Symb, 
                       double ReqPrice, 
                       double Lots,
                       double Dist_SL, 
                       double Dist_TP)
                     
{
   // sanity checks
   if(Dist_SL < 0 || Dist_TP < 0 || ReqPrice < 0) 
   {
      Alert("Invalid Parameters! Cannot have negative values for price, sl or tp!");
      return;
   }
   double tradeFactor = 1.0; 
   string tradeTypeStr = "BUY";
   if(tradeType == OP_SELLSTOP) {
      tradeTypeStr = "SELL";
   } 
   
   // Looks good on the surface....let's do this...
         
   Alert("Attempting to place a ", tradeTypeStr, " STOP order: sym=", Symb, ", price=", ReqPrice,
         ", lots=", Lots, ", Dist_SL=", Dist_SL, ", Dist_TP=", Dist_TP); 
 
   
   while(true)                                  // Cycle that opens an order
   {
      int Min_Dist=MarketInfo(Symb,MODE_STOPLEVEL);// Min. distance
      double Min_Lot=MarketInfo(Symb,MODE_MINLOT);// Min. volume
      double Step   =MarketInfo(Symb,MODE_LOTSTEP);//Step to change lots
      double Free   =AccountFreeMargin();       // Free Margin
      double One_Lot=MarketInfo(Symb,MODE_MARGINREQUIRED);//Cost per 1 lot
      
      
      //-----
      // Check the requested price
      //-----
      double nominalPurchasePrice = NormalizeDouble(Ask + (Min_Dist * Point), Digits);
      if(StringFind(tradeTypeStr, "SELL"))
         nominalPurchasePrice = NormalizeDouble(Bid - (Min_Dist * Point), Digits);
         
      if(NormalizeDouble(ReqPrice,Digits) < nominalPurchasePrice)
      { 
        ReqPrice=nominalPurchasePrice; // Can't be any closer
        Alert("Chnaged the requested price: Price = ", ReqPrice);
      }
      
      //-----
      //Check that requested lots is >= Min_Lot (doesn't check bankroll/margin)
      //-----
      if (Lots < Min_Lot)                        // If it is less than allowed
      {
         Alert(" Cannot Place order, minLot for ", Symb, " is ", Min_Lot," lots");
         break;                                 // Exit cycle
      }
       
      //-----
      // Check that requested SL is within Min_Dist, increase if not ...
      //-----
      if (Dist_SL < Min_Dist)                   // If it is less than allowed
      {
         Dist_SL=Min_Dist;                      // Set the allowed
         Alert(" Increased the distance of SL = ",Dist_SL," pt");
      }
      double SL=ReqPrice - Dist_SL*Point;            // Requested price of SL
      
      //------
      // Check that the TP Level is within min dist of reqPrice
      //-----
      if (Dist_TP < Min_Dist)                   // If it is less than allowed
      {
         Dist_TP=Min_Dist;                      // Set the allowed
         Alert(" Increased the distance of TP = ",Dist_TP," pt");
      }
      double TP=ReqPrice + Dist_TP*Point;            // Requested price of TP
      
      //-----
      // Send Order Out
      //-----
      Alert("Sent request to place ", tradeTypeStr, 
            " STOP order: sym=", Symb, 
            ", price=", DblStr(ReqPrice),
            ", lots=", Lots, 
            ", SL=", DblStr(SL),
            ", TP=", DblStr(TP)
      ); 
 
  
      int ticket=OrderSend(Symb,
         tradeType,                        /* order type */
         Lots,                             /* num lots */
         NormalizeDouble(ReqPrice,Digits), /* price */
         2,                                /* slippage */
         SL,                               /* stoploss */
         TP                                /* take profit */ 
      );
         
      //-------------------------------------------------------------------- 7 --
      if (ticket>0)                             // Got it!:)
      {
         Alert ("Opened order Buy ",ticket);
         break;                                 // Exit cycle
      }
      //-------------------------------------------------------------------- 8 --
      int Error=GetLastError();                 // Failed :(
      switch(Error)                             // Overcomable errors
      {
         case 135:Alert("The price has changed. Retrying..");
            RefreshRates();                     // Update data
            continue;                           // At the next iteration
         case 136:Alert("No prices. Waiting for a new tick..");
            while(RefreshRates()==false)        // Up to a new tick
               Sleep(1);                        // Cycle delay
            continue;                           // At the next iteration
         case 146:Alert("Trading subsystem is busy. Retrying..");
            Sleep(500);                         // Simple solution
            RefreshRates();                     // Update data
            continue;                           // At the next iteration
      }
      switch(Error)                             // Critical errors
      {
         case 2 : Alert("Common error.");
            break;                              // Exit 'switch'
         case 5 : Alert("Outdated version of the client terminal.");
            break;                              // Exit 'switch'
         case 64: Alert("The account is blocked.");
            break;                              // Exit 'switch'
         case 133:Alert("Trading forbidden");
            break;                              // Exit 'switch'
         default: Alert("Occurred error ",Error);// Other alternatives   
      }
      break;                                    // Exit cycle
   } // END WHILE
//-------------------------------------------------------------------------- 9 --
   Alert ("The script has completed its operations ---------------------------");
   return;                                      // Exit start()
  }  
//-----------------------

