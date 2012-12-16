/**
 * Converts a relative dist move in base currency terms into a pt value.
 **/
double RelDistToPips(string symbol, double diff)
{
   double res = diff/TruePoints(symbol);
   return(res);
}

double RelDistToPoints(double diff)
{
   return(diff/Point);
}


/**
 * Utility Function to show information about the current AccountBalance
 **/
void ShowAccountInfo()
{
   Alert("== Acount Info ==");
   Alert("Balance: ", AccountBalance());
   Alert("Free Margin: ", AccountFreeMargin());
   Alert("Account Leverage: ",AccountLeverage());
   Alert("Account Equity: ", AccountEquity());
   Alert("Account Currency: ", AccountCurrency());
   
}

/**
 *  Utitlity Function to show information about the current market
 **/
void ShowMarketInfo()
{
   string sym = Symbol();
   double spread       = MarketInfo(sym, MODE_SPREAD);
   double point        = MarketInfo(sym, MODE_POINT);
   double ticksize     = MarketInfo(sym, MODE_TICKSIZE);
   double tickvalue    = MarketInfo(sym, MODE_TICKVALUE);
   double stopLevel    = MarketInfo(sym, MODE_STOPLEVEL);
   double minLot       = MarketInfo(sym, MODE_MINLOT);
   double maxLot       = MarketInfo(sym, MODE_MAXLOT);
   double oneLotCost   = MarketInfo(sym, MODE_MARGINREQUIRED);
   double lotStep      = MarketInfo(sym, MODE_LOTSTEP);
   double lotSize      = MarketInfo(sym, MODE_LOTSIZE);
   
   double tickvaluefix = tickvalue * Point / ticksize; // A fix for an extremely rare occasion when a change in ticksize leads to a change in tickvalue
   double balance      = AccountBalance();
   double freeMargin   = AccountFreeMargin();
    
   Alert("== Market Info ==");
   Alert("Digits: ", MarketInfo(sym, MODE_DIGITS));
   Alert("Points: ", DoubleToStr(Point,Digits));
   Alert("Spread: ", spread);
   Alert("TickSize: ", DoubleToStr(ticksize,Digits));
   Alert("TickValue: ", DoubleToStr(tickvalue,Digits));
   Alert("TickValueAdj: ", DoubleToStr(tickvaluefix,Digits));
   Alert("One Lot Margin: ", oneLotCost);
   Alert("Lot Step: ", lotStep);
   Alert("Lot Size: ", lotSize);
   Alert("MinLots: ", minLot);
   Alert("MaxLots: ", maxLot);
   Alert("StopLevel: ", stopLevel);

}

double TruePoints(string sym) 
{
   int digits = MarketInfo(sym, MODE_DIGITS);
   double pts = MarketInfo(sym, MODE_POINT);
   
   if(digits == 3 || digits == 5) 
   {
      return(pts*10.0);
   }
   return(pts);
   
}

string DblStr(double d)
{
  return(DoubleToStr(d,Digits));
}