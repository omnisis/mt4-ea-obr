//+------------------------------------------------------------------+
//|                                                StopLossCalcs.mq4 |
//|                                 Copyright 2012,Clifford H. James |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012,Clifford H. James"
#property link      ""

#include <user/utils_misc.mq4>
#include <user/utils_trades.mq4>


//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start()
  {
//----
   
   ShowMarketInfo();
   Alert("Points for: 0.00030= ", RelDistToPoints(0.0003));
   //ShowAccountInfo();
   //Alert("TruePoints: ", DoubleToStr(TruePoints(Symbol()), Digits));
   Alert("Point Size: ", DblStr(Point),
         ", MinDist(points): ", DblStr(MarketInfo(Symbol(), MODE_STOPLEVEL)),
         ", MinDist(value): ", DblStr(MarketInfo(Symbol(), MODE_STOPLEVEL)*Point),  
         ", TickSize: ", DblStr(MarketInfo(Symbol(), MODE_TICKSIZE)),
         ", TruePips: ", DblStr(TruePoints(Symbol()))
   );
         
   Alert("current ask: ", DblStr(Ask), 
         ", current bid: ", DblStr(Bid), 
         ", spread: ", DblStr(Ask-Bid), 
         ", spread pips: ", DblStr(RelDistToPips(Symbol(), Ask-Bid)));
   Alert("Bid-2*points: ", DblStr(Bid-2*Point),
         ", Bid-2*truePoints: ", DblStr(Bid-(2*TruePoints(Symbol())))
        );
   //Alert("Dist: ", NormalizeDouble(20*Point, Digits), " Bid - Dist: ", NormalizeDouble(Bid-20*Point, Digits));
   //Alert("DistToPips: ", RelDistToPips(Symbol(), Bid-20*Point));   
   //Alert("SL Pips: ",AccountPercentStopPips(Symbol(), 40, 3));
   Alert("Relative Pips: ", DblStr(RelDistToPips(Symbol(), 0.0002)));
   //Alert("Relative Pips: ", RelDistToPips(Symbol(), Ask-2*Point));
   PlacePendingStopOrder(OP_BUYSTOP, Symbol(), Ask+5*Point, 1, 10,10);
   //PlaceBuyStopOrder(OP_SELLSTOP, Symbol(), Ask-5*Point, 1, 25,25);
 
//----
   return(0);
  }
//+------------------------------------------------------------------+










