

/** 
 * Calculates SL pips given a risk percentage, symbol and lot size.
 *
 * @param symbol    Symbol of currency pair to trade
 * @param percent   Risk percentage (0-100) 
 * @param lots      Desired Lot Size
 **/
double AccountPercentStopPips(string symbol, double percent, double lots)
{
    Alert("Calculating SL Pips for symbol: ", symbol, " Risk: ", percent, "%, Lots: ", lots);
    double balance      = AccountBalance();
    double moneyrisk    = balance * percent / 100;
    Alert("Money To Risk: ", moneyrisk);
    double spread       = MarketInfo(symbol, MODE_SPREAD);
    double point        = MarketInfo(symbol, MODE_POINT);
    double ticksize     = MarketInfo(symbol, MODE_TICKSIZE);
    double tickvalue    = MarketInfo(symbol, MODE_TICKVALUE);
    double tickvaluefix = tickvalue * point / ticksize; // A fix for an extremely rare occasion when a change in ticksize leads to a change in tickvalue
    
    double stoploss = moneyrisk / (lots * tickvaluefix ) - spread;
    
    if (stoploss < MarketInfo(symbol, MODE_STOPLEVEL)) // Current symbol stop level has to be at least symbol stopLevel
        Alert(" Caculated SL < MIN SL, increased SL to:  ",stoploss," pt");
        stoploss = MarketInfo(symbol, MODE_STOPLEVEL); // This may rise the risk over the requested
        
    // normalize stop loss to the value of sig digits
    stoploss = NormalizeDouble(stoploss, Digits);
    
    return (stoploss);
}


double CalcLotSize(string symbol, double price, double slDist)
{
  return(1.0);
}