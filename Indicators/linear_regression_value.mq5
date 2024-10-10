//--------------------------------------------------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Linear regression value"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDarkGray,clrMediumSeaGreen,clrDarkOrange
#property indicator_width1  2

//
//
//

input int                inpPeriod = 25;          // Period
input ENUM_APPLIED_PRICE inpPrice  = PRICE_CLOSE; // Price

//
//
//

double val[],valColor[];

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

int OnInit()
{
   SetIndexBuffer(0,val     ,INDICATOR_DATA);
   SetIndexBuffer(1,valColor,INDICATOR_COLOR_INDEX);
  
      //
      //
      //
            
   return(INIT_SUCCEEDED);
}

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
   int limit = (prev_calculated>0) ? prev_calculated-1 : 0;
  
   //
   //
   //

   for (int i=limit; i<rates_total && !_StopFlag; i++)
      {
         double _slope;
         double _intercept;
          val[i]      = iLinearRegression(iGetPrice(inpPrice,open[i],high[i],low[i],close[i]),inpPeriod,_slope,_intercept,i,rates_total);
          valColor[i] = (i>0) ? (val[i]>val[i-1]) ? 1 : (val[i]<val[i-1]) ? 2 : valColor[i-1] : 0;
      }
      
   //
   //
   //
        
   return(rates_total);
}

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

double iLinearRegression(double value, double period, double& _slope, double& _intercept, int r, int bars)
{
  struct sWorkStruct
      {
            struct sDataStruct
                  {
                        double value;
                        double sumY;
                        double sumXY;
                  };
            sDataStruct data[];
            int         dataSize;
            int         period;
            double      sumX;
            double      sumXX;
            double      divisor;
            
            //
            //
            //
                          
            sWorkStruct() : dataSize(-1), period(-1) { }
      };
   static sWorkStruct m_work;
                  if (m_work.dataSize <= bars) m_work.dataSize = ArrayResize(m_work.data,bars+500,2000);
                  
                  if (period<1) period = 1;
                  if (m_work.period != (int)period)
                        {
                           m_work.period  = (int)period;
                           m_work.sumX    = m_work.period * (m_work.period-1.0) / 2.0;
                           m_work.sumXX   = m_work.period * (m_work.period-1.0) * (2.0 * m_work.period - 1.0) / 6.0;
                           m_work.divisor = m_work.sumX * m_work.sumX - m_work.period * m_work.sumXX;
                              if (m_work.divisor)
                                  m_work.divisor = 1.0/m_work.divisor;
                        }

      //
      //---
      //

         m_work.data[r].value  = value;
        
            //
            //
            //
            
            if (r>=m_work.period)
                  {
                        m_work.data[r].sumY  = m_work.data[r-1].sumY  + value               - m_work.data[r-m_work.period].value;
                        m_work.data[r].sumXY = m_work.data[r-1].sumXY + m_work.data[r].sumY - m_work.data[r-m_work.period].value*(m_work.period-1.0) - value;
                  }
            else
                  {
                        m_work.data[r].sumY  = value;
                        m_work.data[r].sumXY = 0;

                           //
                           //
                           //
                          
                           for (int k=1; k<m_work.period && r>=k; k++)
                                 {
                                       m_work.data[r].sumY  +=   m_work.data[r-k].value;
                                       m_work.data[r].sumXY += k*m_work.data[r-k].value;
                                 }
                  }
        
         _slope     = (m_work.period*m_work.data[r].sumXY - m_work.sumX * m_work.data[r].sumY) * m_work.divisor;
         _intercept = (m_work.data[r].sumY - _slope * m_work.sumX) / (double)m_work.period ;
  
   //
   //
   //

   return(_intercept  + _slope*(m_work.period-1.0));
}

//--------------------------------------------------------------------------------------------------------------
//
//--------------------------------------------------------------------------------------------------------------
//
//
//

double iGetPrice(int tprice, double open, double high, const double low, const double close)
{
   switch (tprice)
      {
         case PRICE_CLOSE:     return(close);
         case PRICE_OPEN:      return(open);
         case PRICE_HIGH:      return(high);
         case PRICE_LOW:       return(low);
         case PRICE_MEDIAN:    return((high+low)/2.0);
         case PRICE_TYPICAL:   return((high+low+close)/3.0);
         case PRICE_WEIGHTED:  return((high+low+close+close)/4.0);
      }
   return(0);
}