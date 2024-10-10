//+------------------------------------------------------------------+
//|                               Position Risk Calculation Tool.mq5 |
//+------------------------------------------------------------------+
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots 1

#property indicator_label1 "Virtual SL"
#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_color1 clrPurple


enum PositionType{

    buy, // Buy
    sell // Sell
};


input double lotSize = 1.0;         // Trade volume (lot size)
input PositionType posType = buy; // Position Type

double virtSL[];

double balance;
double maxLoss;
double bid, ask;
double BidAsk;
  

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
  
   SetIndexBuffer(0, virtSL, INDICATOR_DATA);
  
   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);  
   ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   balance = AccountInfoDouble(ACCOUNT_BALANCE);  
    
   ArraySetAsSeries(virtSL, true);
  
   Comment("Click on the chart at the desired stop loss level...");
  
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   balance = AccountInfoDouble(ACCOUNT_BALANCE); // updated now on every recalculation
  
   bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
  
   posType == buy ? BidAsk = ask : bid;
  
   return(rates_total);
  }


void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam){                
                    
   if (id == CHARTEVENT_CLICK){
  
         int all_bars = Bars(_Symbol, _Period);
            
         for(int x = 10; x >= 0; x--){
        
            virtSL[x] = GetMouseY(dparam);  
         }    
        
         for(int x = 11; x < all_bars; x++){
        
            virtSL[x] = EMPTY_VALUE;  
         }    
                
        
         double virtualStopLossPoints = MathAbs(BidAsk - GetMouseY(dparam))/_Point;
        
         maxLoss = MaxLossCalc(lotSize, virtualStopLossPoints);    
        
         string calculation =
        
         ".:: Position Risk Calculator ::."
         + "\n\n"
         + "Lot size: " + DoubleToString(lotSize, 2)
         + "\n"
         + "Stop loss points: " + DoubleToString(virtualStopLossPoints, 2)
         + "\n\n"
         + "Risking:"
         + "\n"
         + DoubleToString(virtualStopLossPoints > 0 ? maxLoss : balance, 2) + " "
         + AccountInfoString(ACCOUNT_CURRENCY) + " "
         + "(" + DoubleToString(virtualStopLossPoints > 0 ? (maxLoss/balance) * 100 : 100, 2) + "%" + ")";
        
         Comment(calculation);            
                      
         ChartNavigate(0, CHART_END);      
    }
}

double GetMouseY(const double &dparam){

        long chartHeightInPixels = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        double priceRange = ChartGetDouble(0, CHART_PRICE_MAX) - ChartGetDouble(0, CHART_PRICE_MIN);
        double pixelsPerPrice = chartHeightInPixels / priceRange;
        double mouseYValue = ChartGetDouble(0, CHART_PRICE_MAX) - dparam / pixelsPerPrice;
        
        return mouseYValue;
}


//+------------------------------------------------------------------+
//|     Calculating monetary risk based on lot size and stop loss    |
//|                                                                  |
//+------------------------------------------------------------------+
double MaxLossCalc(double lot, double sl_points) {

   // Get tick value for the current symbol (value per pip in the account currency per 1 lot)
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
  
   double stopLossValue = sl_points * tickValue;

   maxLoss = lot * stopLossValue;

   return maxLoss;  // Return the max loss in monetary terms
}


void OnDeinit(const int reason){

   Comment("");
}
