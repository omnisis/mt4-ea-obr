/*
 *************************************************************************************************
 * A set of common utility functions for dealing with trades.  Including are wrapped methods
 * to place buy/sell orders as well as code for handling common errors that can occur when placing
 * trades.
 *************************************************************************************************
 */
 
#include <stderror.mqh>
#include <stdlib.mqh> 
#include <user/utils_misc.mq4> 


extern int ERROR_RETRY = 0;
extern int ERROR_ABORT = 1;

/**
 * Places a Pending BUY STOP order with the specified parameters.  Note that
 * some aspects of your order (SL,TP) may be changed if they are above/below
 * the required minimum/maximum values.
 * 
 * @param tradeType  Type of trade (OP_BUYSTOP | OP_SELLSTOP)
 * @param Symb       Symbol to place order for  
 * @param ReqPrice   Requested fill price
 * @param Lots       Requested number of lots (volume)
 * @param Dist_SL    Requested SL distance (in points)
 * @param Dist_TP    Requested TP distance (in points)
**/
void PlacePendingStopOrder(
   int    tradeType,
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
   if(!(tradeType == OP_BUYSTOP || tradeType == OP_SELLSTOP))
   {
      Alert("Called PlacePendingStopOrder with a non Pending Stop order!");
      return;
   }
   
   // use a 'tradeFactor' of 1/-1 to control how SL,TP are calculated  
   double tradeFactor = 1.0;
   if(tradeType == OP_SELLSTOP) 
   {
      tradeFactor = -1.0;
   }
   string tradeTypeStr = OrderTypeToStr(tradeType);
   
   // Looks good on the surface....let's do this...
         
   Alert("Attempting to place a ", tradeTypeStr, " STOP order. ",
         "SYM=", Symb, 
         ", ReqPrice=", ReqPrice,
         ", Lots=", Lots, 
         ", Dist_SL=", Dist_SL, 
         ", Dist_TP=", Dist_TP); 
 
   
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
      if(tradeType == OP_SELLSTOP)
         nominalPurchasePrice = NormalizeDouble(Bid - (Min_Dist * Point), Digits);
         
      if(NormalizeDouble(ReqPrice,Digits) < nominalPurchasePrice)
      { 
        ReqPrice=nominalPurchasePrice; // Can't be any closer
        Alert("Changed the requested price: Price = ", ReqPrice);
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
      double SL=ReqPrice - tradeFactor*Dist_SL*Point;    // Requested price of SL
      
      //------
      // Check that the TP Level is within min dist of reqPrice
      //-----
      if (Dist_TP < Min_Dist)                   // If it is less than allowed
      {
         Dist_TP=Min_Dist;                      // Set the allowed
         Alert(" Increased the distance of TP = ",Dist_TP," pt");
      }
      double TP=ReqPrice + (tradeFactor*Dist_TP*Point);   // Requested price of TP
      
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



/**
 * Checks the last order error after close order execution.  Returns
 * int value indicating next action:
 *    ERROR_RETRY - Recoverable (retryable) error
 *    ERROR_ABORT - Non-Recoverable error
 **/
int GetTradeErrorDisposition() 
{
   int err = GetLastError();
   int res = ERROR_ABORT;
   switch(err)
   {
      // Recoverable errors
      case ERR_PRICE_CHANGED:
         Alert("The price has changed. Retrying...");
         res = ERROR_RETRY; break;
      case ERR_OFF_QUOTES:
         Alert("No prices. Waiting for a new tick...");
         while(!RefreshRates()) 
            Sleep(1);
         res = ERROR_RETRY; break;
      case ERR_TRADE_CONTEXT_BUSY:
         Alert("Trading subsystem is busy.  Retrying...");
         Sleep(500);
         RefreshRates();
         res = ERROR_RETRY; break;
         
      // Non-Recoverable errors
      case ERR_COMMON_ERROR:
         Alert("Common Error, WTF?");
         res = ERROR_ABORT; break;
      case ERR_OLD_VERSION:
         Alert("Old version of client terminal!");
         res = ERROR_ABORT; break;
      case ERR_ACCOUNT_DISABLED:
         Alert("Account Disabled!");
         res = ERROR_ABORT; break;
      case ERR_TRADE_DISABLED:
         Alert("Trading is Disabled!");
         res = ERROR_ABORT; break;
      case ERR_TRADE_MODIFY_DENIED:
         Alert("Modification Prohibited, Order is too close to market.");
         res = ERROR_ABORT; break;
      default:
         Alert("Unexpected Error Occurred, ErrorCode:  ",err);
   }
   return(res);
}

/**
 * Closes a market order of the given type (OP_BUY|OP_SELL)
 * and with the specified ticket number.
 **/
void CloseMarketOrder(int type, int ticketNo) 
{
   double Price = OrderOpenPrice();
   double Lot = OrderLots(); // close all lots
   double ClosingPrice = -1.0;
   string OrderTypeStr = OrderTypeToStr(type);
   
   while(true)
   {
      switch(type)
      {
         case OP_BUY:
            ClosingPrice=Bid;
            break;
         case OP_SELL:
            ClosingPrice=Ask;
            break;
      } 
      Alert("Attempt to close ", OrderTypeStr,
         " Order, TicketNo: ", ticketNo);
      bool completed = OrderClose(ticketNo,Lot,ClosingPrice,2);
      // close succeeded
      if(completed)
      {
         Alert("Closed Market Order ",OrderTypeStr,", TicketNo: ",ticketNo);
         break;
      }
      int lastError = GetLastError();
      int disposition = GetTradeErrorDisposition();
      
      // break out of closing cycle if error is no-recoverable
      if(disposition == ERROR_ABORT) break; 
      
   }
}

/**
 * Closes a pending order with the given type 
 * (OP_BUYLIMIIT|OP_SELLLIMIT|OP_BUYSTOP|OP_SELLSTOP)
 * and ticket number.
 **/
void ClosePendingOrder(int type, int ticketNo) 
{
   string OrderTypeStr = OrderTypeToStr(type);
   
   while(true)
   {
   
      Alert("Attempt to delete ", OrderTypeStr,
         " Order, TicketNo: ", ticketNo);
      bool completed = OrderDelete(ticketNo);
      // close succeeded
      if(completed)
      {
         Alert("Deleted Pending Order ",OrderTypeStr,", TicketNo: ",ticketNo);
         break;
      }
      int lastError = GetLastError();
      int disposition = GetTradeErrorDisposition();
      
      // break out of closing cycle if error is no-recoverable
      if(disposition == ERROR_ABORT) break; 
      
   }   
}


/**
 * Closes out all open market orders and deletes any pending orders.
 **/
void CloseAllOutstandingOrders()
{
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS)==true)
      {
            int Tip = OrderType();
            int tktNo = OrderTicket();
            
            if(Tip>1) ClosePendingOrder(Tip, tktNo);
            else if (Tip>=0) CloseMarketOrder(Tip, tktNo);          
            
      }
   }
  
}

/**
 * Prints string description on an OrderType integer.
 **/
string OrderTypeToStr(int type)
{
   switch(type) 
   {
      case OP_BUY: 
        return("BUY");
      case OP_SELL:
        return("SELL");
      case OP_BUYLIMIT:
        return("BUY LIMIT");
      case OP_SELLLIMIT:
        return("SELL LIMIT");
      case OP_BUYSTOP:
        return("BUY STOP");
      case OP_SELLSTOP:
        return("SELL STOP");
      default:
        return("INVALID");
   }
}