﻿//+------------------------------------------------------------------+
//|                                                          smc.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

MqlRates rates[];
double high, low, high2, low2;
datetime time, time2;
//#region variable declaration
//Constant
string IDM_TEXT = "IDM";
string CHOCH_TEXT = "CHoCH";
string BOS_TEXT = "BOS";
string PDH_TEXT = "PDH";
string PDL_TEXT = "PDL";
string MID_TEXT = "0.5";
string ULTRAVOLUME = " has UltraVolume";

//high low
double puHigh, puLow, L, H, idmLow, idmHigh, lastH, lastL, H_lastH, L_lastHH, H_lastLL, L_lastL, motherHigh, motherLow;

//bar indexes
datetime motherBar, puBar, puHBar, puLBar, idmLBar, idmHBar, HBar, LBar, lastHBar, lastLBar;

//structure confirm
bool mnStrc, prevMnStrc, isPrevBos, findIDM, isBosUp, isBosDn, isCocUp, isCocDn;

//poi
bool isSweepOBS = false;
int current_OBS = 0;
double high_MOBS ,low_MOBS;

bool isSweepOBD = false;
int current_OBD;
double low_MOBD;
double high_MOBD;

//Array
//Array
datetime arrTopBotBar[];
double arrTop[];
double arrBot[];

datetime arrPbHBar[];
double arrPbHigh[];
datetime arrPbLBar[];
double arrPbLow[];

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
   ArraySetAsSeries(rates, true);
   // Khai bao ban dau
   definedFunction();
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
//---
   bool isInsideBar = isb();
   // Neu la insidebar
   if (isInsideBar) {
      motherHigh = motherHigh;
      motherLow = motherLow;
      motherBar = motherBar;
   } else {
      motherHigh = rates[1].high;
      motherLow = rates[1].low;
      motherBar = rates[1].time;
   }
   Print(puHigh);
   Print("motherHigh: "+ motherHigh +" motherLow: "+ motherLow +" high: "+rates[1].high +" low "+rates[1].low);
  }
//+------------------------------------------------------------------+

//#region drawing function
bool isGreenBar(double open, double close) {
   return (close > open)? true : false;
}

int textCenter(int left, int right) {
  return (left + right) / 2;
}

// Hàm lấy kiểu nhãn
int getStyleLabel(bool style) { // -1: OBJPROP_STYLE_LABEL_DOWN; 1: OBJPROP_STYLE_LABEL_UP
    //return style ? OBJPROP_STYLE_LABEL_DOWN : OBJPROP_STYLE_LABEL_UP;
    return style ? -1 : 1;
}

// Hàm lấy kiểu mũi tên
int getStyleArrow(bool style) { // -1 : Down; 1 : Up
    //return style ? OBJPROP_ARROW_DOWN : OBJPROP_ARROW_UP;
    return style ? -1 : 1;
}

// Hàm lấy vị trí Y
int getYloc(bool style) { // -1 : OBJ_YLOC_BELOWBAR ; 1: OBJ_YLOC_ABOVEBAR
    return style ? 1 : -1;
}

void getDirection(bool trend, int HBar, int LBar, double H, double L, datetime &x, double &y) {
    if (trend) {
        x = HBar;
        y = H;
    } else {
        x = LBar;
        y = L;
    }
}

string getTextLabel(double current, double last, string same, string diff) {
    return (current > last) ? same : diff;
}

datetime getPdhlBar(float value, int i_loop, double pdh, double pdl) {
    datetime x = -1; // Giả sử giá trị không xác định là -1
    if (value == pdh) {
        for (int i = i_loop; i >= 1; i--) {
            if (rates[i].high == pdh) {
                x = rates[i].time;
                break;
            }
        }
    } else {
        for (int i = i_loop; i >= 1; i--) {
            if (rates[i].low == pdl) {
                x = rates[i].time;
                break;
            }
        }
    }
    return x;
}

void updateTopBotValue(double& arrTop[], double& arrBot[], datetime& arrTopBotBar[]) {
    ArrayResize(arrTop, ArraySize(arrTop) + 1);
    arrTop[ArraySize(arrTop) - 1] = high;

    ArrayResize(arrBot, ArraySize(arrBot) + 1);
    arrBot[ArraySize(arrBot) - 1] = low;

    ArrayResize(arrTopBotBar, ArraySize(arrTopBotBar) + 1);
    arrTopBotBar[ArraySize(arrTopBotBar) - 1] = time;
}

void updateLastHLValue(double& arrLastH[], int& arrLastHBar[], double& arrLastL[], int& arrLastLBar[], double lastH, int lastHBar, double lastL, int lastLBar) {
    ArrayResize(arrLastH, ArraySize(arrLastH) + 1);
    arrLastH[ArraySize(arrLastH) - 1] = lastH;

    ArrayResize(arrLastHBar, ArraySize(arrLastHBar) + 1);
    arrLastHBar[ArraySize(arrLastHBar) - 1] = lastHBar;

    ArrayResize(arrLastL, ArraySize(arrLastL) + 1);
    arrLastL[ArraySize(arrLastL) - 1] = lastL;

    ArrayResize(arrLastLBar, ArraySize(arrLastLBar) + 1);
    arrLastLBar[ArraySize(arrLastLBar) - 1] = lastLBar;
}

void updateIdmHigh(double low, double L, double puHigh, int puHBar, double& arrIdmHigh[], int& arrIdmHBar[]) {
    if (low < L) {
        ArrayResize(arrIdmHigh, ArraySize(arrIdmHigh) + 1);
        arrIdmHigh[ArraySize(arrIdmHigh) - 1] = puHigh;

        ArrayResize(arrIdmHBar, ArraySize(arrIdmHBar) + 1);
        arrIdmHBar[ArraySize(arrIdmHBar) - 1] = puHBar;
    }
}

void updateIdmLow(double high, double H, double puLow, int puLBar, double& arrIdmLow[], int& arrIdmLBar[]) {
    if (high > H) {
        ArrayResize(arrIdmLow, ArraySize(arrIdmLow) + 1);
        arrIdmLow[ArraySize(arrIdmLow) - 1] = puLow;

        ArrayResize(arrIdmLBar, ArraySize(arrIdmLBar) + 1);
        arrIdmLBar[ArraySize(arrIdmLBar) - 1] = puLBar;
    }
}

double getNLastValue(double& arr[], int n) {
    int size = ArraySize(arr);
    if (size > n - 1) {
        return arr[size - n];
    }
    // Trả về giá trị không xác định (ví dụ: 0 hoặc EMPTY_VALUE)
    return 0; 
}

//void removeNLastLabel(int& arr[], int n) {
//    int size = ArraySize(arr);
//    if (size > n - 1) {
//        int label_id = arr[size - n];
//        ObjectDelete(label_id);
//    }
//}
//
//void removeNLastLine(int& arr[], int n) {
//    int size = ArraySize(arr);
//    if (size > n - 1) {
//        int line_id = arr[size - n];
//        ObjectDelete(line_id);
//    }
//}
//
//void removeLastLabel(int& arr[], int n) {
//    int size = ArraySize(arr);
//    if (size > n - 1) {
//        for (int i = 1; i <= n; i++) {
//            int label_id = arr[size - i];
//            ObjectDelete(label_id);
//        }
//    }
//}
//
//void removeLastLine(int& arr[], int n) {
//    int size = ArraySize(arr);
//    if (size > n - 1) {
//        for (int i = 1; i <= n; i++) {
//            int line_id = arr[size - i];
//            ObjectDelete(line_id);
//        }
//    }
//}

//void fixStrcAfterBos() {
//    removeLastLabel(arrBCLabel, 1);
//    removeLastLine(arrBCLine, 1);
//    removeLastLabel(arrIdmLabel, 1);
//    removeLastLine(arrIdmLine, 1);
//    removeLastLabel(arrHLLabel, 2);
//    removeLastLabel(arrHLCircle, 2);
//}
//
//void fixStrcAfterChoch() {
//    removeLastLabel(arrBCLabel, 2);
//    removeLastLine(arrBCLine, 2);
//    removeNLastLabel(arrHLLabel, 2);
//    removeNLastLabel(arrHLLabel, 3);
//    removeNLastLabel(arrHLCircle, 2);
//    removeNLastLabel(arrHLCircle, 3);
//    removeNLastLabel(arrIdmLabel, 2);
//    removeNLastLine(arrIdmLine, 2);
//}

void drawIDM(bool trend, int idmLBar, int idmHBar, double idmLow, double idmHigh, bool showIDM, double H_lastH, double L_lastHH, double H_lastLL, double L_lastL, color colorIDM) {
    datetime x;
    double y;
    getDirection(trend, idmLBar, idmHBar, idmLow, idmHigh, x, y);
    
    string _direction = trend ? " ⇑ " : " ⇓ ";
    string zone = trend ? "bull" : "bear";
    color colorText = (trend && H_lastH > L_lastHH) || (!trend && H_lastLL > L_lastL) ? clrRed : colorIDM;

    if (showIDM) {
        int ln = ObjectCreate(0, "lineIDM", OBJ_TREND, 0, x, y, time, y);
        ObjectSetInteger(0, "lineIDM", OBJPROP_COLOR, colorIDM);
        ObjectSetInteger(0, "lineIDM", OBJPROP_STYLE, STYLE_DOT);

        int lbl = ObjectCreate(0, "labelIDM", OBJ_TEXT, 0, time, y);
        ObjectSetInteger(0, "labelIDM", OBJPROP_COLOR, clrNONE);
        //ObjectSetInteger(0, "labelIDM", OBJPROP_TEXTCOLOR, colorText);
        ObjectSetInteger(0, "labelIDM", OBJPROP_CORNER, 0);
        ObjectSetInteger(0, "labelIDM", OBJPROP_FONTSIZE, 8);
        ObjectSetString(0, "labelIDM", OBJPROP_TEXT, IDM_TEXT);

        //if (BarStateIsLast()) {
        //    string str = _direction + " Price Cross " + IDM_TEXT + (GetVolume() ? " ULTRAVOLUME" : "");
        //    //AlertBarPattern(zone, str, true);
        //}

//        ArrayResize(arrIdmLine, ArraySize(arrIdmLine) + 1);
//        arrIdmLine[ArraySize(arrIdmLine) - 1] = ln;
//
//        ArrayResize(arrIdmLabel, ArraySize(arrIdmLabel) + 1);
//        arrIdmLabel[ArraySize(arrIdmLabel) - 1] = lbl;
    }

    if (trend) {
        ArrayFree(arrIdmLow);
        ArrayFree(arrIdmLBar);
    } else {
        ArrayFree(arrIdmHigh);
        ArrayFree(arrIdmHBar);
    }
}

void drawStructure(string name, bool trend, int lastHBar, int lastLBar, double lastH, double lastL, int bull, int bear, bool showBOS, bool showChoChStructure, bool barstate_isconfirmed, int ULTRAVOLUME) {
    datetime x;
    double y;
    getDirection(trend, lastHBar, lastLBar, lastH, lastL, x, y);
    color colorTrend = trend ? clrGreen : clrRed;
    string _direction = trend ? " ⇑ " : " ⇓ ";
    string zone = trend ? "bull" : "bear";
    if (name == "BOS" && showBOS) {
        int ln = ObjectCreate(0, "BOS_Line", OBJ_TREND, 0, x, y, time, y);
        ObjectSetInteger(0, "BOS_Line", OBJPROP_COLOR, colorTrend);
        ObjectSetInteger(0, "BOS_Line", OBJPROP_STYLE, STYLE_DASH);

        int lbl = ObjectCreate(0, "BOS_Label", OBJ_TEXT, 0, textCenter(time, x), y);
        //ObjectSetInteger(0, "BOS_Label", OBJPROP_COLOR, transp);
        ObjectSetInteger(0, "BOS_Label", OBJPROP_CORNER, getStyleLabel(trend));
        //ObjectSetInteger(0, "BOS_Label", OBJPROP_TEXTCOLOR, colorTrend);
        ObjectSetInteger(0, "BOS_Label", OBJPROP_FONTSIZE, 8); // size.tiny equivalent

        //if (barstate_isconfirmed) {
        //    string str = "BOS_TEXT" + _direction + (getVolume() ? ULTRAVOLUME : "");
        //    alertBarPattern(zone, str, true);
        //}
        //array_push(arrBCLine, ln);
        //array_push(arrBCLabel, lbl);
    }
    if (name == "ChoCh" && showChoChStructure) {
        int ln = ObjectCreate(0, "ChoCh_Line", OBJ_TREND, 0, x, y, time, y);
        ObjectSetInteger(0, "ChoCh_Line", OBJPROP_COLOR, colorTrend);
        ObjectSetInteger(0, "ChoCh_Line", OBJPROP_STYLE, STYLE_DASH);

        int lbl = ObjectCreate(0, "ChoCh_Label", OBJ_TEXT, 0, textCenter(time, x), y);
        //ObjectSetInteger(0, "ChoCh_Label", OBJPROP_COLOR, transp);
        ObjectSetInteger(0, "ChoCh_Label", OBJPROP_CORNER, getStyleLabel(trend));
        //ObjectSetInteger(0, "ChoCh_Label", OBJPROP_TEXTCOLOR, colorTrend);
        ObjectSetInteger(0, "ChoCh_Label", OBJPROP_FONTSIZE, 8); // size.tiny equivalent

        //if (barstate_isconfirmed) {
        //    string str = "CHOCH_TEXT" + _direction + (getVolume() ? ULTRAVOLUME : "");
        //    alertBarPattern(zone, str, true);
        //}
        //array_push(arrBCLine, ln);
        //array_push(arrBCLabel, lbl);
    }
}

void drawLiveStrc(bool condition, bool direction, color color1, color color2, string txt, int length) {
    if (condition && IsLastBar()) {
        color colorText = direction ? color1 : color2;
        datetime x;
        double y;

        if (txt == "IDM_TEXT") {
            getDirection(direction, idmHBar, idmLBar, idmHigh, idmLow, x, y);
        } else {
            getDirection(direction, lastHBar, lastLBar, lastH, lastL, x, y);
        }

        string _txt = txt + " - " + DoubleToString(y);
        int ln = ObjectCreate(0, "LiveStrc_Line", OBJ_TREND, 0, x, y, time + length * PeriodSeconds(), y);
        //ObjectSetInteger(0, "LiveStrc_Line", OBJPROP_COLOR, colorIDM);
        ObjectSetInteger(0, "LiveStrc_Line", OBJPROP_STYLE, STYLE_DOT);

        int lbl = ObjectCreate(0, "LiveStrc_Label", OBJ_TEXT, 0, time + length * PeriodSeconds(), y);
        //ObjectSetInteger(0, "LiveStrc_Label", OBJPROP_COLOR, transp);
        //ObjectSetInteger(0, "LiveStrc_Label", OBJPROP_TEXTCOLOR, colorText);
        ObjectSetInteger(0, "LiveStrc_Label", OBJPROP_CORNER, ALIGN_RIGHT);
        ObjectSetInteger(0, "LiveStrc_Label", OBJPROP_FONTSIZE, 8); // size.tiny equivalent
        ObjectSetString(0, "LiveStrc_Label", OBJPROP_TEXT, _txt);

        if (x == iTime(NULL, 0, 1)) {
            //ObjectDelete("LiveStrc_Line");
            //ObjectDelete("LiveStrc_Label");
        }
    }
}

bool IsLastBar() {
    return (rates[0].time == TimeCurrent());
}


//#region Inside Bar
bool isb() {
   high = iHigh(_Symbol, PERIOD_CURRENT, 1);
   low = iLow(_Symbol, PERIOD_CURRENT, 1);
   return (motherHigh > high && motherLow < low) ? true : false;
}

void definedFunction() {
   high = iHigh(_Symbol, PERIOD_CURRENT, 1);
   low = iLow(_Symbol, PERIOD_CURRENT, 1);
   time = iLow(_Symbol, PERIOD_CURRENT, 1);
   
   high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
   low2 = iLow(_Symbol, PERIOD_CURRENT, 2);
   time2 = iLow(_Symbol, PERIOD_CURRENT, 2);
   
   //high low
   puHigh = high;
   puLow = low;
   L = low;
   H = high;
   idmLow = low;
   idmHigh = high;
   lastH = high;
   lastL = low;
   H_lastH = high;
   L_lastHH = low;
   H_lastLL = high;
   L_lastL = low;
   motherHigh = high2;
   motherLow = low2;
   
   //bar indexes
   motherBar = time2;
   HBar = time;
   LBar = time;
   lastHBar = time;
   lastLBar = time;
   
   //structure confirm
   findIDM = false;
   isBosUp = false;
   isBosDn = false;
   isCocUp = true;
   isCocDn = true;
   
   //poi
   isSweepOBS = false;
   isSweepOBD = false;
}