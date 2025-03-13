//+------------------------------------------------------------------+
//|                                                          smc.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

bool enabledComment = true;
bool disableComment = false;
MqlRates waveRates[],rates[];
double high, low, high2, low2;
datetime time, time2;

int GANN_STRUCTURE = 1;
int INTERNAL_STRUCTURE = 2;
int INTERNAL_STRUCTURE_KEY = 3;
int MAJOR_STRUCTURE = 4;
bool enabledDraw = true;
bool disableDraw = false;

// Gann Wave
double highEst, lowEst;
double Highs[], Lows[];
datetime hightime, lowtime;
datetime HighsTime[], LowsTime[];
int LastSwingMeter = 0; // finding high or low 1 is high; -1 is low

// Internal Structure
double intSHighs[], intSLows[];
datetime intSHighTime[], intSLowTime[];
int LastSwingInternal = 0; // finding high or low 1 is high; -1 is low
int iTrend = 0; // trend is Up wave or Down wave, 1 is Up; -1 is down 


// array pullback swing high or low
double arrTop[], arrBot[];
datetime arrTopTime[], arrBotTime[];
int mTrend = 0; // trend is Up wave or Down wave, 1 is Up; -1 is down 
int sTrend = 0; // trend is Up wave or Down wave, 1 is Up; -1 is down 
datetime arrPbHTime[];
double arrPbHigh[];
datetime arrPbLTime[];
double arrPbLow[];

double arrChoHigh[], arrChoLow[];
datetime arrChoHighTime[], arrChoLowTime[];
double arrBoHigh[], arrBoLow[];
datetime arrBoHighTime[], arrBoLowTime[];

int LastSwingMajor = 0; // finding high or low 1 is high; -1 is low
//high low
//double puHigh, puLow, L, H, idmLow, idmHigh, lastH, lastL, H_lastH, L_lastHH, H_lastLL, L_lastL, motherHigh, motherLow;
int lastTimeH = 0;
int lastTimeL = 0;
double L, H, idmLow, idmHigh, L_idmLow, L_idmHigh , lastH, lastL, H_lastH, L_lastHH, H_lastLL, L_lastL, motherHigh, motherLow;
double findHigh, findLow;

//bar indexes
//datetime motherBar, puBar, puHBar, puLBar, idmLBar, idmHBar, HBar, LBar, lastHBar, lastLBar;
datetime idmLowTime, idmHighTime, L_idmLowTime, L_idmHighTime , HTime, LTime;

//structure confirm
//bool mnStrc, prevMnStrc, isPrevBos, findIDM, isBosUp, isBosDn, isCocUp, isCocDn;

// POI
struct PoiZone {
   double high, low, open, close;
   datetime time;
   int mitigated;
};
PoiZone zHighs[], zLows[], zIntSHighs[], zIntSLows[], zArrTop[], zArrBot[];
PoiZone zArrPbHigh[], zArrPbLow[];
PoiZone zPoiExtremeBull[], zPoiExtremeBear[], zPoiBull[], zPoiBear[];

//---
//--- -----------------------------------------------------------------
//---
input ENUM_TIMEFRAMES Timeframe = PERIOD_CURRENT;
//#region variable declaration
input int _PointSpace = 1000; // space for draw with swing, line
input int poi_limit = 50; // poi limit save to array

//Constant
string IDM_TEXT = "idm";
string IDM_TEXT_LIVE = "idm-l";
string CHOCH_TEXT = "CHoCH";
string I_CHOCH_TEXT = "i-choch";
string BOS_TEXT = "BOS";
string I_BOS_TEXT = "i-bos";
string PDH_TEXT = "PDH";
string PDL_TEXT = "PDL";
string MID_TEXT = "0.5";
string ULTRAVOLUME = " has UltraVolume";

int iWingding_gann_high = 159;
int iWingding_gann_low = 159;
int iWingding_internal_high = 225;
int iWingding_internal_low = 226;
int iWingding_internal_key_high = 225;
int iWingding_internal_key_low = 226;

//poi
bool isSweepOBS = false;
int current_OBS = 0;
double high_MOBS ,low_MOBS;

bool isSweepOBD = false;
int current_OBD;
double low_MOBD;
double high_MOBD;

//demandZone[];
//supplyZone[];
//mitigatedZoneSupply[];
//mitigatedZoneDemand[];

double arrIdmHigh[];
double arrIdmLow[];
datetime arrIdmHBar[];
datetime arrIdmLBar[];
double arrLastH[];
datetime arrLastHBar[];
double arrLastL[];
datetime arrLastLBar[];
//arrIdmLine[];
//arrIdmLabel[];
//arrBCLine[];
//arrBCLabel[];
//arrHLLabel[];
//arrHLCircle[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ArraySetAsSeries(waveRates, true);
   ArraySetAsSeries(rates, true);
   
   // Khai bao ban dau
   definedFunction();
   
   // draw swing wave before function active
   gannWave();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 50, rates);
   high = rates[1].high;
   low = rates[1].low;
   
   if(!IsNewBar()) return;
   
   realGannWave();
//---
   //bool isInsideBar = isb();
   
  }
//+------------------------------------------------------------------+

void firstArray(double price, double& array[], datetime time, datetime& arrayTime[]) {
   ArrayResize(array, MathMin(ArraySize(array) + 1, 10));
   array[0] = price;
   ArrayResize(arrayTime, MathMin(ArraySize(arrayTime) + 1, 10));
   arrayTime[0] = time;
}

//#region define function
void definedFunction() {
   int copied = CopyRates(_Symbol, PERIOD_CURRENT, 0, 100, waveRates);
   
   int firstBar = ArraySize(waveRates) - 1;
   double firstBarHigh     = waveRates[firstBar].high;
   double firstBarLow      = waveRates[firstBar].low;
   datetime firstBarTime   = waveRates[firstBar].time;
      
   highEst = firstBarHigh;
   lowEst = firstBarLow;
   hightime = firstBarTime;
   lowtime = firstBarTime;
   // Gann structure
   firstArray(firstBarHigh, Highs, firstBarTime, HighsTime);
   firstArray(firstBarLow, Lows, firstBarTime, LowsTime);
      
   // internal structure
   firstArray(firstBarHigh, intSHighs, firstBarTime, intSHighTime);
   firstArray(firstBarLow, intSLows, firstBarTime, intSLowTime);
   
   // pullback structure
   firstArray(firstBarHigh, arrTop, firstBarTime, arrTopTime);
   firstArray(firstBarLow, arrBot, firstBarTime, arrBotTime);
   
   firstArray(firstBarHigh, arrPbHigh, firstBarTime, arrPbHTime);
   firstArray(firstBarLow, arrPbLow, firstBarTime, arrPbLTime);
   
   firstArray(0, arrChoHigh, firstBarTime, arrChoHighTime);
   firstArray(0, arrChoLow, firstBarTime, arrChoLowTime);
   firstArray(0, arrBoHigh, firstBarTime, arrBoHighTime);
   firstArray(0, arrBoLow, firstBarTime, arrBoLowTime);
   
   high = iHigh(_Symbol, PERIOD_CURRENT, 1);
   low = iLow(_Symbol, PERIOD_CURRENT, 1);
   time = iTime(_Symbol, PERIOD_CURRENT, 1);
   
   high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
   low2 = iLow(_Symbol, PERIOD_CURRENT, 2);
   time2 = iTime(_Symbol, PERIOD_CURRENT, 2);
   
   //high low   
   lastH = high;
   lastL = low;
   
//   puHigh = high;
//   puLow = low;
//   L = low;
//   H = high;
//   idmLow = low;
//   idmHigh = high;
//   
//   H_lastH = high;
//   L_lastHH = low;
//   H_lastLL = high;
//   L_lastL = low;
//   motherHigh = high2;
//   motherLow = low2;
//   
//   //bar indexes
//   motherBar = time2;
//   HBar = time;
//   LBar = time;
//   lastHBar = time;
//   lastLBar = time;
//   
//   //structure confirm
//   findIDM = false;
//   isBosUp = false;
//   isBosDn = false;
//   isCocUp = true;
//   isCocDn = true;
//   
//   //poi
//   isSweepOBS = false;
//   isSweepOBD = false;
}

//#region drawing function
bool isGreenBar(double open, double close) {
   return (close > open)? true : false;
}

int textCenter(int left, int right) {
  return (left + right) / 2;
}

void realGannWave() {
   MqlRates bar1, bar2, bar3;
   bar1 = rates[1];
   bar2 = rates[2];
   bar3 = rates[3];
   Print("------------------------------");
   int resultStructure = drawStructureInternal(bar1, bar2, bar3, disableComment);
   
   updatePointTopBot(bar1, bar2, bar3, enabledComment);
   drawZone(bar1);
}

string inInfoBar(MqlRates& bar1, MqlRates& bar2, MqlRates& bar3) {
   string text = " Bar1 high: "+ (string) bar1.high +" - low: "+ (string) bar1.low + " --- "+" Bar2 high: "+ (string) bar2.high +" - low: "+ (string) bar2.low+ " --- "+" Bar3 high: "+ (string) bar3.high +" - low: "+ (string) bar3.low; 
   return text;
}

void gannWave(){
   MqlRates bar1, bar2, bar3; 
   // danh dau vi tri bat dau
   createObj(waveRates[ArraySize(waveRates) - 1].time, waveRates[ArraySize(waveRates) - 1].low, 238, -1, clrRed, "Start");
   // 
   for (int j = ArraySize(waveRates) - 3; j >=0; j--){
      
      Print("No:" + (string) j);
      Print(inInfoBar(bar1, bar2, bar3));
      //Print("Highs[]: " + ArraySize(Highs)); ArrayPrint(Highs);
      //Print("Lows[]: " + ArraySize(Lows)); ArrayPrint(Lows);
      bar1 = waveRates[j];
      bar2 = waveRates[j+1];
      bar3 = waveRates[j+2];
      
      int resultStructure = drawStructureInternal(bar1, bar2, bar3, disableComment);
      updatePointTopBot(bar1, bar2, bar3, enabledComment);
      drawZone(bar1);
      Print(" --- End ---");
   }
}

void updatePointTopBot(MqlRates& bar1, MqlRates& bar2, MqlRates& bar3, bool isComment = false){
   
   if(isComment) {
      Print("Highs: "); ArrayPrint(Highs);ArrayPrint(zHighs);
      Print("Lows: "); ArrayPrint(Lows);ArrayPrint(zLows);
      Print("arrTop: "); ArrayPrint(arrTop);
      Print("arrBot: "); ArrayPrint(arrBot);
      Print("arrPbHigh: "); ArrayPrint(arrPbHigh);
      Print("arrPbLow: "); ArrayPrint(arrPbLow);
      
      //Print("arrBoHigh: "+(string) arrBoHigh[0]);
      //Print("arrBoLow: "+(string) arrBoLow[0]);
      //Print("arrChoHigh: "+(string) arrChoHigh[0]);
      //Print("arrChoLow: "+(string) arrChoLow[0]);
   }
   string text;
   text += "First: STrend: "+ (string) sTrend + " - mTrend: "+(string) mTrend+" - LastSwingMajor: "+(string) LastSwingMajor+ " findHigh: "+(string) findHigh+" - idmHigh: "+(string) idmHigh+" findLow: "+(string) findLow+" - idmLow: "+(string) idmLow+" H: "+ (string) H +" - L: "+(string) L;
   text += "\n"+inInfoBar(bar1, bar2, bar3);
   
   double barHigh = bar1.high;
   double barLow  = bar1.low;
   double barTime = bar1.time;
   
   // Lan dau tien
   if(sTrend == 0 && mTrend == 0 && LastSwingMajor == 0) {
      if (barLow < arrBot[0]){
         text += "\n 0.-1. barLow < arrBot[0]"+" => "+(string) barLow+" < "+(string) arrBot[0];
         text += " => Cap nhat idmLow = Highs[0] = "+(string) Highs[0]+"; sTrend = -1; mTrend = -1; LastSwingMajor = 1;";
         
         L_idmLow = idmLow;
         L_idmLowTime = idmLowTime;
         
         idmLow = Highs[0];
         idmLowTime = HighsTime[0];
         sTrend = -1; mTrend = -1; LastSwingMajor = 1;
         
      } else if (barHigh > arrTop[0]) { 
         text += "\n 0.1. barHigh > arrTop[0]"+" => "+barHigh+" > "+arrTop[0];
         text += " => Cap nhat idmHigh = Lows[0] = "+Lows[0]+"; sTrend = 1; mTrend = 1; LastSwingMajor = -1;";
         
         L_idmHigh = idmHigh;
         L_idmHighTime = idmHighTime;
         
         idmHigh = Lows[0]; idmHighTime = LowsTime[0];
         sTrend = 1; mTrend = 1; LastSwingMajor = -1;
      }
   }
   // End Lan dau tien
   
   if (bar3.high < bar2.high && bar2.high > bar1.high) { // tim thay dinh high
      text += "\n 0.2. Find Swing High";
      if (findHigh == 1 && bar2.high > H) {
         text += " => findhigh == 1 , H new > H old "+bar2.high+" > "+H+". Update new High = "+bar2.high;
         
         H = bar2.high;
         HTime = bar2.time;
      }
   }
   if (bar3.low > bar2.low && bar2.low < bar1.low) { // tim thay swing low 
      text += "\n 0.-2. Find Swing Low";
      if (findLow == 1 && bar2.low < L) {
         text += " => findlow == 1 , L new < L old "+bar2.low+" < "+L+". Update new Low = "+bar2.low;
         
         L = bar2.low;
         LTime = bar2.time;
      }
   }
   
   if(sTrend == 1 && mTrend == 1) {
      // continue BOS 
      if (LastSwingMajor == -1 && bar1.high > arrTop[0] && arrTop[0] != arrBoHigh[0]) {
         text += "\n 1.1. continue BOS, sTrend == 1 && mTrend == 1 && LastSwingMajor == -1 && bar1.high > arrTop[0] : "+ 
         bar1.high +" > "+arrTop[0];
         text += "\n => Cap nhat: findLow = 0, idmHigh = Lows[0] = "+Lows[0]+" ; sTrend == 1; mTrend == 1; LastSwingMajor == 1;";
         
         updatePointStructure(arrTop[0], arrTopTime[0], arrBoHigh, arrBoHighTime, false);
         updatePointStructure(intSLows[0], intSLowTime[0], arrBot, arrBotTime, false);
         // update POI Bullish
         updateZoneToZone(zIntSLows[0], zArrBot, false, poi_limit);
         // cap nhat Zone
         updateZoneToZone(zIntSLows[0], zPoiBull, false, poi_limit);
         
         L_idmHigh = idmHigh;
         L_idmHighTime = idmHighTime;
         
         sTrend = 1; mTrend = 1; LastSwingMajor = 1;
         findLow = 0; idmHigh = Lows[0]; idmHighTime = LowsTime[0];
      }
      
      if (bar3.high < bar2.high && bar2.high > bar1.high) { // tim thay dinh high 
         // continue BOS swing high
         if (LastSwingMajor == 1 && bar2.high > arrTop[0]) {
            text += "\n 1.2. swing high, sTrend == 1 && mTrend == 1 && LastSwingMajor == 1 && barHigh > arrTop[0]";
            text += "=> Cap nhat: arrTop[0] = bar2.high = "+bar2.high+" ; sTrend == 1; mTrend == 1; LastSwingMajor == -1;";
            // Update Array Top[0]
            if(arrTop[0] != bar2.high) {
               updatePointStructure(bar2.high, bar2.time, arrTop, arrTopTime, false);
               // cap nhat Zone
               updatePointZone(bar2, zArrTop, false, poi_limit);
            } 
            
            sTrend = 1; mTrend = 1; LastSwingMajor = -1;
         }
         // HH > HH 
         if (LastSwingMajor == -1 && bar2.high > arrTop[0]) {
            text += "\n 1.3. sTrend == 1 && mTrend == 1 && LastSwingMajor == -1 && bar2.high > arrTop[0]";
            text += "=> Xoa label, Cap nhat: arrTop[0] = bar2.high = "+bar2.high+" ; sTrend == 1; mTrend == 1; LastSwingMajor == -1;";
            
            // Update Array Top[0] , conditions : L new != L old
            if(arrTop[0] != bar2.high) {
               updatePointStructure(bar2.high, bar2.time, arrTop, arrTopTime, true);
               // cap nhat Zone
               updatePointZone(bar2, zArrTop, false, poi_limit);
            }
            sTrend = 1; mTrend = 1; LastSwingMajor = -1;
         }
      }
      
      //Cross IDM
      if (  
         //LastSwingMajor == 1 && 
         findLow == 0 && bar1.low < idmHigh) {
         text += "\n 1.4. Cross IDM Uptrend.  sTrend == 1 && mTrend == 1 && LastSwingMajor == random && bar1.low < idmHigh : " + bar1.low + "<" + idmHigh;
         // cap nhat arPBHighs
         if(arrTop[0] != arrPbHigh[0]) {
            updatePointStructure(arrTop[0], arrTopTime[0], arrPbHigh, arrPbHTime, false);
            // cap nhat Zone
            updateZoneToZone(zArrTop[0], zArrPbHigh, false);
         }
         drawPointStructure(1, arrPbHigh[0], arrPbHTime[0], MAJOR_STRUCTURE, false, enabledDraw);
         drawLine(IDM_TEXT, idmHighTime, idmHigh, bar1.time, idmHigh, 1, IDM_TEXT, clrAliceBlue, STYLE_DOT);
         text += "\n => Cap nhat findLow = 1; L = bar1.low = "+ bar1.low;
         
         // active find Low
         findLow = 1; L = bar1.low; LTime = bar1.time;
         findHigh = 0; H = 0;
      }
      
      // CHoCH Low
      if (
         //LastSwingMajor == 1 && 
         bar1.low < arrPbLow[0] && arrPbLow[0] != arrChoLow[0]) {
         text += "\n 1.5 sTrend == 1 && mTrend == 1 && LastSwingMajor == random && bar1.low < arrPbLow[0] :" + bar1.low + "<" + arrPbLow[0];
         text += "\n => Cap nhat => Ve line. sTrend = -1; mTrend = -1; LastSwingMajor = -1; findHigh = 0; idmLow = Highs[0]= "+ Highs[0];
         // draw choch Low
         drawLine(I_CHOCH_TEXT, arrPbLTime[0], arrPbLow[0], barTime, arrPbLow[0], 1, I_CHOCH_TEXT, clrRed, STYLE_SOLID);
         
         updatePointStructure(arrPbLow[0], arrPbLTime[0], arrChoLow, arrChoLowTime, false);
         text += "\n => Cap nhat => POI Bearish : arrPbHigh[0] "+ arrPbHigh[0];
         // update Extreme POI Bearish ????
         updateZoneToZone(zArrPbHigh[0], zPoiExtremeBear, false, poi_limit);
         
         LastSwingMajor = -1;
         L_idmLow = idmLow;
         L_idmLowTime = idmLowTime;
         
         sTrend = -1; mTrend = -1; LastSwingMajor = -1;
         findHigh = 0; idmLow = Highs[0]; idmLowTime = HighsTime[0];
      }
      
      // continue Up, Continue BOS up
      if (
         //LastSwingMajor == -1 && 
         bar1.high > arrPbHigh[0] && arrPbHigh[0] != arrChoHigh[0]) {
         text += "\n 1.6 Continue Bos UP. sTrend == 1 && mTrend == 1 && LastSwingMajor == random && bar1.high > arrPbHigh && arrPbHigh: "+ arrPbHigh[0] + " != arrChoHigh[0]: "+arrChoHigh[0];
         
         updatePointStructure(arrPbHigh[0], arrPbHTime[0], arrChoHigh, arrChoHighTime, false);
         
         // update Point HL
         if (L != 0 && L != arrPbLow[0]) {
            updatePointStructure(L, LTime, arrPbLow, arrPbLTime, false);
            // update POI Extreme Bullish ????
            updateZoneToZone(zArrPbLow[0], zPoiExtremeBull, false, poi_limit);     
         }
         text += "\n => cap nhat : POI Bullish L : "+L;
         
         
         drawPointStructure(-1, arrPbLow[0], arrPbLTime[0], MAJOR_STRUCTURE, false, enabledDraw);
         drawLine(BOS_TEXT, arrPbHTime[0], arrPbHigh[0], bar1.time, arrPbHigh[0], -1, BOS_TEXT, clrAliceBlue, STYLE_SOLID);
         
         L_idmHigh = idmHigh;
         L_idmHighTime = idmHighTime;
         
         findLow = 0; idmHigh = Lows[0]; idmHighTime = LowsTime[0];
         L = 0; 
      }
   }

   if(sTrend == 1 && mTrend == -1) {
      // continue Up, Continue Choch up
      if (LastSwingMajor == -1 && bar1.high > arrPbHigh[0] && arrPbHigh[0] != arrChoHigh[0]) {
         text += "2.1 CHoCH up. sTrend == 1 && mTrend == -1 && LastSwingMajor == -1 && bar1.high > arrPbHigh[0]";
         
         updatePointStructure(arrPbHigh[0], arrPbHTime[0], arrChoHigh, arrChoHighTime, false);
         
         if (L != 0 && L != arrPbLow[0]) updatePointStructure(L, LTime, arrPbLow, arrPbLTime, false);
         drawPointStructure(-1, arrPbLow[0], arrPbLTime[0], MAJOR_STRUCTURE, false, enabledDraw);
         drawLine(I_CHOCH_TEXT, arrPbHTime[0], arrPbHigh[0], bar1.time, arrPbHigh[0], -1, I_CHOCH_TEXT, clrAliceBlue, STYLE_SOLID);
         text += "\n => Cap nhat => POI Bullish : L = "+ L;
         // update POI Extreme Bullish
         updateZoneToZone(zArrPbLow[0], zPoiExtremeBull, false, poi_limit);
         
         L_idmHigh = idmHigh;
         L_idmHighTime = idmHighTime;
         
         findLow = 0; idmHigh = Lows[0]; idmHighTime = LowsTime[0];
         L = 0; 
      }
      // CHoCH DOwn. 
      if (LastSwingMajor == -1 && bar1.low < arrPbLow[0] && arrPbLow[0] != arrChoLow[0]) {
         text += "\n 2.2 sTrend == 1 && mTrend == -1 && LastSwingMajor == -1 && bar1.low < arrPbLow[0] : " + bar1.low + "<" + arrPbLow[0];
         text += "\n => Cap nhat => POI Low. sTrend = -1; mTrend = -1; LastSwingMajor = -1; findHigh = 0; idmLow = Highs[0] = "+Highs[0];
         updatePointStructure(arrPbLow[0], arrPbLTime[0], arrChoLow, arrChoLowTime, false);
         // draw choch low
         drawLine(I_CHOCH_TEXT, arrPbLTime[0], arrPbLow[0], bar1.time, arrPbLow[0], 1, I_CHOCH_TEXT, clrRed, STYLE_SOLID);
         
         // update POI Extreme Bearish
         updateZoneToZone(zArrPbHigh[0], zPoiExtremeBear, false, poi_limit);
         
         L_idmLow = idmLow;
         L_idmLowTime = idmLowTime;
         
         sTrend = -1; mTrend = -1; LastSwingMajor = -1;
         findHigh = 0; idmLow = Highs[0]; idmLowTime = HighsTime[0];
      }
   }
   
   if(sTrend == -1 && mTrend == -1) {
      // continue BOS 
      if (LastSwingMajor == 1 && bar1.low < arrBot[0] && arrBot[0] != arrBoLow[0]) {
         text += "\n -3.1. continue BOS, sTrend == -1 && mTrend == -1 && LastSwingMajor == 1 && bar1.low < arrBot[0] : "+ bar1.low +" > "+arrBot[0];
         text += "\n => Cap nhat: findHigh = 0, idmLow = Highs[0] = "+Highs[0]+" ; sTrend == -1; mTrend == -1; LastSwingMajor == -1;";
         
         updatePointStructure(arrBot[0], arrBotTime[0], arrBoLow, arrBoLowTime, false);
         updatePointStructure(intSHighs[0], intSHighTime[0], arrTop, arrTopTime, false);
         
         // update POI Bearish
         updateZoneToZone(zArrTop[0], zPoiBear, false, poi_limit);
         
         L_idmLow = idmLow;
         L_idmLowTime = idmLowTime;
         
         sTrend = -1; mTrend = -1; LastSwingMajor = -1;
         findHigh = 0; idmLow = Highs[0]; idmLowTime = HighsTime[0];
      }
      
      if (bar3.low > bar2.low && bar2.low < bar1.low) { // tim thay swing low 
         // continue BOS swing low
         if (LastSwingMajor == -1 && bar2.low < arrBot[0]) {
            text += "\n -3.2. swing low, sTrend == -1 && mTrend == -1 && LastSwingMajor == -1 && bar2.low < arrBot[0]";
            text += "=> Cap nhat: arrBot[0] = bar2.low = "+bar2.low+" ; sTrend == -1; mTrend == -1; LastSwingMajor == 1;";
            
            // Update ArrayBot[0]
            if(arrBot[0] != bar2.low) 
               updatePointStructure(bar2.low, bar2.time, arrBot, arrBotTime, false);
            
            sTrend = -1; mTrend = -1; LastSwingMajor = 1;
         }

         // LL < LL
         if (LastSwingMajor == 1 && bar2.low < arrBot[0]) {
            text += "\n -3.3. sTrend == -1 && mTrend == -1 && LastSwingMajor == 1 && bar2.low < arrBot[0]";
            text += "=> Xoa label, Cap nhat: arrBot[0] = bar2.low = "+bar2.low+" ; sTrend == -1; mTrend == -1; LastSwingMajor == 1;";
            
            // Update ArrayBot[0]
            if(arrBot[0] != bar2.low) 
               updatePointStructure(bar2.low, bar2.time, arrBot, arrBotTime, true);
               
            sTrend = -1; mTrend = -1; LastSwingMajor = 1;   
         }
      }
   
      //Cross IDM
      if (
         //LastSwingMajor == -1 && 
         findHigh == 0 && bar1.high > idmLow) {
         text += "\n -3.4. Cross IDM Downtrend, sTrend == -1 && mTrend == -1 && LastSwingMajor == random && bar1.high > idmLow :" + bar1.high + ">" + idmLow;
         // cap nhat arPBLows
         if(arrBot[0] != arrPbLow[0]) updatePointStructure(arrBot[0], arrBotTime[0], arrPbLow, arrPbLTime, false);
         drawPointStructure(-1, arrPbLow[0], arrPbLTime[0], MAJOR_STRUCTURE, false, enabledDraw);
         drawLine(IDM_TEXT, idmLowTime, idmLow, bar1.time, idmLow, -1, IDM_TEXT, clrRed, STYLE_DOT);
         text += "\n => Cap nhat findHigh = 1; H = bar1.high = "+ bar1.high;
         
         // active find High
         findHigh = 1; H = bar1.high; HTime = bar1.time;
         findLow = 0; L = 0;
      }
      
      // CHoCH High
      if (
         //LastSwingMajor == -1 && 
         bar1.high > arrPbHigh[0] && arrPbHigh[0] != arrChoHigh[0]) {
         text += "\n -3.5 sTrend == -1 && mTrend == -1 && LastSwingMajor == random && bar1.high > arrPbHigh[0] :" + bar1.high + ">" + arrPbHigh[0];
         text += "\n => Cap nhat => sTrend = 1; mTrend = 1; LastSwingMajor = 1; findLow = 0; idmHigh = Lows[0] = "+Lows[0];
         text += "\n => Cap nhat => POI Bullish = arrPbLow[0] : "+ arrPbLow[0];
         updatePointStructure(arrPbHigh[0], arrPbHTime[0], arrChoHigh, arrChoHighTime, false);
         
         // update POI Extreme Bullish
         updateZoneToZone(zArrPbLow[0], zPoiExtremeBull, false, poi_limit);
         
         // draw choch high
         drawLine(I_CHOCH_TEXT, arrPbHTime[0], arrPbHigh[0], bar1.time, arrPbHigh[0], -1, I_CHOCH_TEXT, clrAliceBlue, STYLE_SOLID);
         
         LastSwingMajor = 1;
         L_idmHigh = idmHigh;
         L_idmHighTime = idmHighTime;
         
         sTrend = 1; mTrend = 1; LastSwingMajor = 1;
         findHigh = 0; idmHigh = Lows[0]; idmHighTime = LowsTime[0];
      }
      
      // continue Down, COntinue BOS down
      if (
         //LastSwingMajor == 1 && 
         bar1.low < arrPbLow[0] && arrPbLow[0] != arrChoLow[0]) {
         text += "\n -3.6 sTrend == -1 && mTrend == -1 & LastSwingMajor == random && bar1.low < arrPbLow[0]";
         
         updatePointStructure(arrPbLow[0], arrPbLTime[0], arrChoLow, arrChoLowTime, false);
         
         // update Point LH         
         if (H != 0 && H != arrPbHigh[0]) updatePointStructure(H, HTime, arrPbHigh, arrPbHTime, false);
         
         drawPointStructure(1, arrPbHigh[0], arrPbHTime[0], MAJOR_STRUCTURE, false, enabledDraw);
         drawLine(BOS_TEXT, arrPbLTime[0], arrPbLow[0], bar1.time, arrPbLow[0], 1, BOS_TEXT, clrRed, STYLE_SOLID);
         text += "\n => Cap nhat => POI Bearish H:" + H;
         
         // update POI Extreme Bearish
         updateZoneToZone(zArrPbHigh[0], zPoiExtremeBear, false, poi_limit);
         
         L_idmLow = idmLow;
         L_idmLowTime = idmLowTime;
         
         findHigh = 0; idmLow = Highs[0]; idmHighTime = LowsTime[0]; H = 0;
      }
      
   }
   if (sTrend == -1 && mTrend == 1) {
      // continue Down, COntinue Choch down
      if (LastSwingMajor == 1 && bar1.low < arrPbLow[0] && arrPbLow[0] != arrChoLow[0]) {
         text += "\n -4.1 sTrend == -1 && mTrend == 1 && LastSwingMajor == 1 && bar1.low < arPbLow[0]";
         updatePointStructure(arrPbLow[0], arrPbLTime[0], arrChoLow, arrChoLowTime, false);
         
         if (H != 0 && H != arrPbHigh[0]) updatePointStructure(H, HTime, arrPbHigh, arrPbHTime, false);
         drawPointStructure(1, arrPbHigh[0], arrPbHTime[0], MAJOR_STRUCTURE, false, enabledDraw);
         drawLine(I_CHOCH_TEXT, arrPbLTime[0], arrPbLow[0], bar1.time, arrPbLow[0], 1, I_CHOCH_TEXT, clrRed, STYLE_SOLID);
         
         text += "\n => Cap nhat => POI bearish H: "+H;
         // update POI Extreme Bearish
         updateZoneToZone(zArrPbHigh[0], zPoiExtremeBear, false, poi_limit);
         
         L_idmLow = idmLow;
         L_idmLowTime = idmLowTime;
         
         findHigh = 0; idmLow = Highs[0]; idmHighTime = LowsTime[0]; H = 0;
      }
      // CHoCH Up. 
      if (LastSwingMajor == 1 && bar1.high > arrPbHigh[0] && arrPbHigh[0] != arrChoHigh[0]) {
            
         text += "\n -4.2 sTrend == -1 && mTrend == 1 && LastSwingMajor == 1 && bar1.high > arrPbHigh[0] : " + bar1.high + ">" + arrPbHigh[0];
         text += "\n => Cap nhat => sTrend = 1; mTrend = 1; LastSwingMajor = 1; findLow = 0; idmHigh = Lows[0] = "+Lows[0];
         text += "\n => Cap nhat => POI Bullish = arrPbLow[0] : "+ arrPbLow[0];
         updatePointStructure(arrPbHigh[0], arrPbHTime[0], arrChoHigh, arrChoHighTime, false);
         
         // update POI Extreme Bullish
         updateZoneToZone(zArrPbLow[0], zPoiExtremeBull, false, poi_limit);
         
         // draw choch low
         drawLine(I_CHOCH_TEXT, arrPbHTime[0], arrPbHigh[0], bar1.time, arrPbHigh[0], -1, I_CHOCH_TEXT, clrAliceBlue, STYLE_SOLID);

         L_idmHigh = idmHigh;
         L_idmHighTime = idmHighTime;
         
         sTrend = 1; mTrend = 1; LastSwingMajor = 1;
         findLow = 0; idmHigh = Lows[0]; idmHighTime = LowsTime[0];
      }
   }
   
   if(isComment) {
      text += "\n Last: STrend: "+ sTrend + " - mTrend: "+mTrend+" - LastSwingMajor: "+LastSwingMajor+ " findHigh: "+findHigh+" - idmHigh: "+idmHigh+" findLow: "+findLow+" - idmLow: "+idmLow+" H: "+ H +" - L: "+L;
      Print(text);
      Print("arrTop: "); ArrayPrint(arrTop);
      Print("arrBot: "); ArrayPrint(arrBot);
      Print("arrPbHigh: "); ArrayPrint(arrPbHigh);
      Print("arrPbLow: "); ArrayPrint(arrPbLow);
      
      //Print("arrBoHigh: "+arrBoHigh[0]);
      //Print("arrBoLow: "+arrBoLow[0]);
      //Print("arrChoHigh: "+arrChoHigh[0]);
      //Print("arrChoLow: "+arrChoLow[0]);
      //Print("\n ");
   }
}


void drawZone(MqlRates& bar1) {
   // IDM Live 
   if (sTrend == 1 && findLow == 0 && L_idmHigh != 0) {
      if (L_idmHigh > 0) {
         deleteObj(L_idmHighTime, L_idmHigh, 0, "");
         deleteLine(L_idmHighTime, L_idmHigh, IDM_TEXT_LIVE);
         deleteObj(L_idmHighTime, L_idmHigh, 0, IDM_TEXT_LIVE);
      }
      drawLine(IDM_TEXT_LIVE, idmHighTime, idmHigh, bar1.time, idmHigh, 1, IDM_TEXT_LIVE, clrAliceBlue, STYLE_DOT);
   }
   if (sTrend == -1 && findHigh == 0 && L_idmLow != 0) {
      if (L_idmLow > 0) {
         deleteObj(L_idmLowTime, L_idmLow, 0, "");
         deleteLine(L_idmLowTime, L_idmLow, IDM_TEXT_LIVE);
         deleteObj(L_idmLowTime, L_idmLow, 0, IDM_TEXT_LIVE);
      }
      drawLine(IDM_TEXT_LIVE, idmLowTime, idmLow, bar1.time, idmLow, -1, IDM_TEXT_LIVE, clrRed, STYLE_DOT);
   }
}

//---
//--- Ham cap nhat ve cau truc song gann, internal struct, major struct
//---
int drawStructureInternal(MqlRates& bar1, MqlRates& bar2, MqlRates& bar3, bool isComment = false) {
   int resultStructure = 0;
   string textGannHigh = "";
   string textGannLow = "";
   
   string textInternalHigh = "";
   string textInternalLow = "";
   
   string textTop = "";
   string textBot = "";
   
   int indexLastH = iBarShift(_Symbol,PERIOD_CURRENT,lastTimeH);
   int indexLastL = iBarShift(_Symbol,PERIOD_CURRENT,lastTimeL);
   
   // swing high
   if (bar3.high < bar2.high && bar2.high > bar1.high) { // tim thay dinh high
      textGannHigh += "\n" + "---> Find High: "+bar2.high+" + Highest: "+ highEst;
      // gann finding high
      if (LastSwingMeter == 1 || LastSwingMeter == 0) {
         // cap nhat high moi
         updatePointStructure(bar2.high, bar2.time, Highs, HighsTime, false);
         drawPointStructure(1, bar2.high, bar2.time, GANN_STRUCTURE, false, enabledDraw);
         LastSwingMeter = -1;
         // cap nhat Zone
         updatePointZone(bar2, zHighs, false);
      }
      // gann finding low
      if (LastSwingMeter == -1) {
         // xoa high cu. viet high moi
         if (bar2.high > highEst) {
            // xoa high cu
            if (ArraySize(Highs) > 1) deleteObj(HighsTime[0], Highs[0], iWingding_gann_high, "");
            // cap nhat high moi
            updatePointStructure(bar2.high, bar2.time, Highs, HighsTime, true);
            drawPointStructure(1, bar2.high, bar2.time, GANN_STRUCTURE, true, enabledDraw);
            LastSwingMeter = -1;
            // cap nhat Zone
            updatePointZone(bar2, zHighs, true);
         }
      }
      
      if (isComment) {
         Print(textGannHigh);
         ArrayPrint(Highs);
      }
      
      // Internal Structure
      textInternalHigh += "\n"+"---> Find Internal High: "+ bar2.high +" ### So Sanh iTrend: " +iTrend+", LastSwingInternal: "+LastSwingInternal+ " , intSHighs[0]: "+ intSHighs[0];
      textInternalHigh += "\n"+"lastTimeH: "+lastTimeH+" lastH: "+ lastH +" <----> "+" intSHighTime[0] "+intSHighTime[0]+" intSHighs[0] "+ intSHighs[0];
      // finding High
      
      // DONE 1
      // HH
      if ( (iTrend == 0 || iTrend == 1 && LastSwingInternal == 1) && bar2.high > intSHighs[0]){ // BOS
         // Update new intSHigh
         updatePointStructure(bar2.high, bar2.time, intSHighs, intSHighTime, false);
         drawPointStructure(1, bar2.high, bar2.time, INTERNAL_STRUCTURE, false, enabledDraw);
         
         iTrend = 1;
         LastSwingInternal = -1;
         resultStructure = 1;
         textInternalHigh += "\n"+"## High 1 BOS --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSHighs[0]: "+bar2.high;
         // cap nhat Zone
         updatePointZone(bar2, zIntSHighs, false);
      }
      
      // HH 2
      if (iTrend == 1 && LastSwingInternal == -1 && bar2.high > intSHighs[0] && bar2.high > intSHighs[1]){
         // Delete Label
         if (ArraySize(intSHighs) > 1) deleteObj(intSHighTime[0], intSHighs[0], iWingding_internal_high, "");
         // Update new intSHigh
         updatePointStructure(bar2.high, bar2.time, intSHighs, intSHighTime, true);
         drawPointStructure(1, bar2.high, bar2.time, INTERNAL_STRUCTURE, true, enabledDraw);
         
         iTrend = 1;
         LastSwingInternal = -1;
         resultStructure = 2;
         textInternalHigh += "\n"+"## High 2 --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSHighs[0]: "+bar2.high + ", Xoa intSHighs[0] old: "+intSHighs[0];
         // cap nhat Zone
         updatePointZone(bar2, zIntSHighs, true);
         
      }
      
      // DONE 3
      if (iTrend == -1 && LastSwingInternal == 1 && bar2.high > intSHighs[0]) {  // CHoCH
         // update new intSHigh
         updatePointStructure(bar2.high, bar2.time, intSHighs, intSHighTime, false);
         drawPointStructure(1, bar2.high, bar2.time, INTERNAL_STRUCTURE, false, enabledDraw);
         
         iTrend = 1;
         LastSwingInternal = -1;
         resultStructure = 3;
         textInternalHigh += "\n"+"## High 3 CHoCH --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSHighs[0]: "+bar2.high;
         
         // cap nhat Zone
         updatePointZone(bar2, zIntSHighs, false);
      }
      
      // DONE 4 
      // LH
      if (iTrend == -1 && LastSwingInternal == 1 && bar2.high < intSHighs[0]) { 
         // update new intSHigh
         updatePointStructure(bar2.high, bar2.time, intSHighs, intSHighTime, false);
         drawPointStructure(1, bar2.high, bar2.time, INTERNAL_STRUCTURE, false, enabledDraw);
         iTrend = -1;
         LastSwingInternal = -1;
         resultStructure = 4;
         textInternalHigh += "\n"+ "## High 4 --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSHighs[0]: "+bar2.high;
         
         // cap nhat Zone
         updatePointZone(bar2, zIntSHighs, false);
      }
      
      // DONE 5
      if (iTrend == -1 && LastSwingInternal == -1 && bar2.high > intSHighs[0] ) {    // CHoCH
         // Delete prev label
         if (ArraySize(intSHighs) > 1) deleteObj(intSHighTime[0], intSHighs[0], iWingding_internal_high, "");
         // Update new intSHigh
         updatePointStructure(bar2.high, bar2.time, intSHighs, intSHighTime, true);
         drawPointStructure(1, bar2.high, bar2.time, INTERNAL_STRUCTURE, true, enabledDraw);
                  
         iTrend = (bar2.high <= intSHighs[1])? -1 : 1;
         LastSwingInternal = -1;
         resultStructure = 5;
         textInternalHigh += "\n"+"## High 5 CHoCH --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSHighs[0]: "+bar2.high+", Xoa intSHighs[0] old: "+intSHighs[0];
         
         // cap nhat Zone
         updatePointZone(bar2, zIntSHighs, true);
      }
      if( isComment) {
         Print(textInternalHigh);
         ArrayPrint(intSHighs);
      }
      
   }
   
   // swing low
   if (bar3.low > bar2.low && bar2.low < bar1.low) { // tim thay dinh low
      textGannLow += "\n"+"---> Find Low: +" +bar2.low+ " + Lowest: "+lowEst;
      // gann finding low
      if (LastSwingMeter == -1 || LastSwingMeter == 0) {
         // cap nhat low moi
         updatePointStructure(bar2.low, bar2.time, Lows, LowsTime, false);
         drawPointStructure(-1, bar2.low, bar2.time, GANN_STRUCTURE, false, enabledDraw);
         LastSwingMeter = 1;
         // cap nhat Zone
         updatePointZone(bar2, zLows, false);
      }
      // gann finding high
      if (LastSwingMeter == 1) {
         // xoa low cu. viet high moi
         if (bar2.low < lowEst) {
            // xoa low cu
            if (ArraySize(Lows) > 1) deleteObj(LowsTime[0], Lows[0], iWingding_gann_low, "");
            // cap nhat low moi
            updatePointStructure(bar2.low, bar2.time, Lows, LowsTime, true);
            drawPointStructure(-1, bar2.low, bar2.time, GANN_STRUCTURE, true, enabledDraw);
            LastSwingMeter = 1;
            // cap nhat Zone
            updatePointZone(bar2, zLows, true);
         }
      }
      if (isComment) {
         Print(textGannLow);
         ArrayPrint(Lows);
      }
      
      // Internal Structure 
      textInternalLow += "\n"+"---> Find Internal Low: "+ bar2.low +" ### So Sanh iTrend: " +iTrend+", LastSwingInternal: "+LastSwingInternal+ " , intSLows[0]: "+ intSLows[0];
      textInternalLow += "\n"+"lastTimeL: "+lastTimeL+" lastL: "+ lastL +" <----> "+" intSLowTime[0] "+intSLowTime[0]+" intSLows[0] "+ intSLows[0];
      // finding Low
      // DONE 1
      // LL
      if ((iTrend == 0 || iTrend == -1) && LastSwingInternal == -1 && bar2.low < intSLows[0]){ // BOS
         // Update new intSLows
         updatePointStructure(bar2.low, bar2.time, intSLows, intSLowTime, false);
         drawPointStructure(-1, bar2.low, bar2.time, INTERNAL_STRUCTURE, false, enabledDraw);
                  
         iTrend = -1;
         LastSwingInternal = 1;
         resultStructure = -1;
         textInternalLow += "\n"+("## Low 1 BOS --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSLows[0]: "+bar2.low);
         // cap nhat Zone
         updatePointZone(bar2, zIntSLows, false);
      }
      
      // LL
      if (iTrend == -1 && LastSwingInternal == 1 && bar2.low < intSLows[0] && bar2.low < intSLows[1]){
         // Delete Label
         if (ArraySize(intSLows) > 1) deleteObj(intSLowTime[0], intSLows[0], iWingding_internal_low, "");
         // Update new intSLows
         updatePointStructure(bar2.low, bar2.time, intSLows, intSLowTime, true);
         drawPointStructure(-1, bar2.low, bar2.time, INTERNAL_STRUCTURE, true, enabledDraw);
                  
         iTrend = -1;
         LastSwingInternal = 1;
         resultStructure = -2;
         textInternalLow += "\n"+("## Low 2 --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSLows[0]: "+bar2.low +", Xoa intSLows[0] old: "+intSLows[0]);
         // cap nhat Zone
         updatePointZone(bar2, zIntSLows, true);
      }
      
      // DONE 3
      if (iTrend == 1 && LastSwingInternal == -1 && bar2.low < intSLows[0]) { // CHoCH
         // update intSLows
         updatePointStructure(bar2.low, bar2.time, intSLows, intSLowTime, false);
         drawPointStructure(-1, bar2.low, bar2.time, INTERNAL_STRUCTURE, false, enabledDraw);
         
         iTrend = -1;
         LastSwingInternal = 1;
         resultStructure = -3;
         textInternalLow += "\n"+("## Low 3 CHoCH --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSLows[0]: "+bar2.low);
         // cap nhat Zone
         updatePointZone(bar2, zIntSLows, false);
      }
      
      // DONE 4
      // Trend Tang. HL
      if (iTrend == 1 && LastSwingInternal == -1 && bar2.low > intSLows[0]) {
         updatePointStructure(bar2.low, bar2.time, intSLows, intSLowTime, false);
         drawPointStructure(-1, bar2.low, bar2.time, INTERNAL_STRUCTURE, false, enabledDraw);
         iTrend = 1;
         LastSwingInternal = 1;
         resultStructure = -4;
         textInternalLow += "\n"+("## Low 4 --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSLows[0]: "+bar2.low);
         // cap nhat Zone
         updatePointZone(bar2, zIntSLows, false);
      }
      
      // DONE 5
      if (iTrend == 1 && LastSwingInternal == 1 && bar2.low < intSLows[0] ) {  // CHoCH
         // Delete Label
         if (ArraySize(intSLows) > 1) deleteObj(intSLowTime[0], intSLows[0], iWingding_internal_low, "");
         // update intSLows
         updatePointStructure(bar2.low, bar2.time, intSLows, intSLowTime, true);
         drawPointStructure(-1, bar2.low, bar2.time, INTERNAL_STRUCTURE, true, enabledDraw);
                  
         iTrend = (bar2.low >= intSLows[1]) ? 1 : -1;
         LastSwingInternal = 1;
         resultStructure = -5;
         textInternalLow += "\n"+("## Low 5 CHoCH --> Update: "+ "iTrend: "+iTrend + ", LastSwingInternal: "+ LastSwingInternal+", Update intSLows[0]: "+bar2.low+", Xoa intSLows[0] old: "+intSLows[0]);
         // cap nhat Zone
         updatePointZone(bar2, zIntSLows, true);
      }
      if(isComment) {
         Print(textInternalLow);
         ArrayPrint(intSLows);
      }
   }
   return resultStructure;
}

void drawPointStructure(int itype, double priceNew, double timeNew, int typeStructure, bool del, bool isDraw) { // type: 1 High, -1 Low
   int iWingding;
   color iColor;
   // Color and wingdings
   if (typeStructure == GANN_STRUCTURE) {
      iWingding  = (itype == 1)? iWingding_gann_high : iWingding_gann_low;
      iColor   = (itype == 1)? clrDeepSkyBlue : clrYellow;
   } else if (typeStructure == INTERNAL_STRUCTURE) {
      iWingding  = (itype == 1)? iWingding_internal_high : iWingding_internal_low;
      iColor   = (itype == 1)? clrRoyalBlue : clrLightSalmon;
   } else if (typeStructure == INTERNAL_STRUCTURE_KEY){
      iWingding  = (itype == 1)? iWingding_internal_high : iWingding_internal_low;
      iColor   = (itype == 1)? clrGreen : clrRed;
   }else if (typeStructure == MAJOR_STRUCTURE) {
      iWingding  = (itype == 1)? 116 : 116;
      iColor   = (itype == 1)? clrForestGreen : clrRed;
   }
   
   string text    = (itype == 1)? "Update High" : "Update Low";
   int iDirection = (itype == 1)? -1 : 1;
   //Print(text +" Type: "+ itype + " , Xoa swing: "+ (string) del);
   
   if (isDraw) {
      createObj(timeNew, priceNew, iWingding, iDirection, iColor, "");
   }
   // update High, Low for gann swing
   if (itype == 1) { // find high
      highEst = priceNew;
   } else if(itype == -1) { // find low
      lowEst = priceNew;
   }
   // Update Bartime high, low for BOS, CHOCH internal struct
   if (typeStructure == INTERNAL_STRUCTURE) {
      if (itype == 1) { // find high
         lastTimeH = timeNew;
         lastH = priceNew;
      } else if (itype == -1) { // find low
         lastTimeL = timeNew;
         lastL = priceNew;
      }
   }
}

void updateZoneToZone(PoiZone& zone, PoiZone& array[], bool del, int limit = 20) {
   if (ArraySize(array) >= 1 && del == true) {
      // cap nhat lai arPrice
      ArrayRemove(array, 0, 1);
   }
   // Store value in array[]
   // shift existing elements in array[] to make space for the new value
   ArrayResize(array, MathMin(ArraySize(array) + 1, limit));
   for(int i = ArraySize(array) - 1; i > 0; --i) {
      array[i] = array[i-1];   
   }
   // Store newvalue in arPrice[0], the first position
   array[0] = zone;
}

void updatePointZone(MqlRates& bar, PoiZone& array[], bool del, int limit = 30) {
   if (ArraySize(array) >= 1 && del == true) {
      // cap nhat lai arPrice
      ArrayRemove(array, 0, 1);
   }
   // Store value in array[]
   // shift existing elements in array[] to make space for the new value
   ArrayResize(array, MathMin(ArraySize(array) + 1, limit));
   for(int i = ArraySize(array) - 1; i > 0; --i) {
      array[i] = array[i-1];   
   }
   // Store newvalue in arPrice[0], the first position
   array[0].high = bar.high;
   array[0].low = bar.low;
   array[0].open = bar.open;
   array[0].close = bar.close;
   array[0].time = bar.time;
   array[0].mitigated = 0;
}

void updatePointStructure(double priceNew, double timeNew, double& arPrice[], datetime& arTime[], bool del, int limit = 10) {
   if (ArraySize(arPrice) >= 1 && del == true) {
      // cap nhat lai arPrice
      ArrayRemove(arPrice, 0, 1);
      ArrayRemove(arTime, 0, 1);
   }
   
   // Store value in arPrice[]
   // shift existing elements in arPrice[] to make space for the new value
   ArrayResize(arPrice, MathMin(ArraySize(arPrice) + 1, limit));
   for(int i = ArraySize(arPrice) - 1; i > 0; --i) {
      arPrice[i] = arPrice[i-1];   
   }
   // Store newvalue in arPrice[0], the first position
   arPrice[0] = priceNew;
   
   // Store newtime in arTime[]
   // shift existing elements in arTime[] to make space for the new value
   ArrayResize(arTime, MathMin(ArraySize(arTime) + 1, limit));
   for(int i = ArraySize(arTime) - 1; i > 0; --i) {
      arTime[i] = arTime[i-1];   
   }
   // Store newtime in arTime[0], the first position
   arTime[0] = timeNew;
}

//+------------------------------------------------------------------+
void drawLine(string name, datetime  time_start, double price_start, datetime time_end, double price_end, int direction, string displayName, color iColor, int styleDot){
   string objname = name + TimeToString(time_start);
   if (ObjectFind(0, objname) < 0) {
      ObjectCreate(0, objname, OBJ_TREND, 0, time_start, price_start, time_end, price_end);
      ObjectSetInteger(0, objname, OBJPROP_COLOR, iColor);
      ObjectSetInteger(0, objname, OBJPROP_WIDTH, 1);
      if (styleDot == STYLE_DASH) {
         ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_DASH);
      } else if (styleDot == STYLE_DASHDOT) {
         ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_DASHDOT);
      } else if (styleDot == STYLE_DASHDOTDOT) {
         ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_DASHDOTDOT);
      } else if (styleDot == STYLE_DOT) {
         ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_DOT);
      } else if (styleDot == STYLE_SOLID) {
         ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_SOLID);
      }
       
      createObj(time_start, price_start, 0, direction, iColor, displayName);
   }
}

//+------------------------------------------------------------------+
void createObj(datetime time, double price, int arrowCode, int direction, color clr, string txt)
  {
   string objName ="";
   StringConcatenate(objName, "Signal@", time, "at", DoubleToString(price, _Digits), "(", arrowCode, ")");

   double ask=SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid=SymbolInfoDouble(Symbol(), SYMBOL_BID);
   double spread=ask-bid;

   if(direction > 0){
      price -= _PointSpace*spread * _Point;
   } else if(direction < 0){
      price += _PointSpace*spread * _Point;
   }

   if(ObjectCreate(0, objName, OBJ_ARROW, 0, time, price))
     {
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      if( direction > 0)
         ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      if(direction < 0)
         ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
   string objNameDesc = objName + txt;
   if (ObjectCreate(0, objNameDesc, OBJ_TEXT, 0, time, price)) {
      ObjectSetString(0, objNameDesc, OBJPROP_TEXT, " "+txt);
      ObjectSetInteger(0, objNameDesc, OBJPROP_COLOR, clr);
      if( direction > 0)
         ObjectSetInteger(0, objNameDesc, OBJPROP_ANCHOR, ANCHOR_TOP);
      if(direction < 0)
         ObjectSetInteger(0, objNameDesc, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
   }
}

//+------------------------------------------------------------------+
//| Function to delete objects created by createObj                   |
//+------------------------------------------------------------------+
void deleteObj(datetime time, double price, int arrowCode, string txt) {
   // Create the object name using the same format as createObj
   string objName = "";
   StringConcatenate(objName, "Signal@", time, "at", DoubleToString(price, _Digits), "(", arrowCode, ")");
   
   // Delete the arrow object
   if(ObjectFind(0, objName) != -1) // Check if the object exists
     {
      ObjectDelete(0, objName);
     }
   
   // Create the description object name
   string objNameDesc = objName + txt;
   
   // Delete the text object
   if(ObjectFind(0, objNameDesc) != -1) // Check if the object exists
     {
      ObjectDelete(0, objNameDesc);
     }
}

//+------------------------------------------------------------------+
//| Function to delete line created by drawline                      |
//+------------------------------------------------------------------+
void deleteLine(datetime time, double price, string name) {
   // Create the object name using the same format as drawline
   string objName = name + TimeToString(time);
   //StringConcatenate(objName, "Signal@", time, "at", DoubleToString(price, _Digits), "(", arrowCode, ")");
   
   // Delete the arrow object
   if(ObjectFind(0, objName) != -1) // Check if the object exists
     {
      ObjectDelete(0, objName);
     }
}

bool IsNewBar(){
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, Timeframe, 0);
   if (previousTime != currentTime) {
      previousTime = currentTime; 
      return true;
   }
   return false;
}

bool IsLastBar() {
    return (rates[0].time == TimeCurrent());
}


//#region Inside Bar
//bool isb() {
//   high = iHigh(_Symbol, PERIOD_CURRENT, 1);
//   low = iLow(_Symbol, PERIOD_CURRENT, 1);
//   return (motherHigh > high && motherLow < low) ? true : false;
//}

