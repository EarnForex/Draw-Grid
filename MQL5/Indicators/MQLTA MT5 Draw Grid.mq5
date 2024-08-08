#property link          "https://www.earnforex.com/metatrader-indicators/draw-grid/"
#property version       "1.02"

#property copyright     "EarnForex.com - 2019-2024"
#property description   "Draw a chart grid with a given gap and subgap."
#property description   ""
#property description   "WARNING: Use this software at your own risk."
#property description   "The creator of this indicator cannot be held responsible for any damage or loss."
#property description   ""
#property description   "Find More on www.EarnForex.com"
#property icon          "\\Files\\EF-Icon-64x64px.ico"

#property indicator_chart_window
#property indicator_plots 0

#include <MQLTA Utils.mqh>

enum ENUM_THICKNESS
{
    One = 1,    // 1
    Two = 2,    // 2
    Three = 3,  // 3
    Four = 4,   // 4
    Five = 5    // 5
};

input string Comment_1 = "====================";         // Draw Grid Settings
input string IndicatorName = "DG";                       // Indicator Name (used to draw objects)

input string Comment_2 = "====================";         // Grid Settings
input double StartPrice = 0;                             // Start Price (0 = Current)
input bool UpdateStartPrice = false;                     // Keep Updating Start Price with Bid?
input double LowRange = 0;                               // Minimum Value (0 = Chart Low)
input double HighRange = 0;                              // Maximum Value (0 = Chart High)
input int MainGap = 1000;                                // Main Grid Gap (Points)
input ENUM_LINE_STYLE MainStyle = STYLE_SOLID;           // Main Grid Style
input color MainColor = clrRoyalBlue;                    // Main Grid Color
input ENUM_THICKNESS MainThick = Two;                    // Main Grid Thickness
input bool ShowSubGrid = true;                           // Show Secondary Grid
input int SubGap = 250;                                  // Secondary Grid Gap (Points)
input ENUM_LINE_STYLE SubStyle = STYLE_DASH;             // Secondary Grid Style
input color SubColor = clrRoyalBlue;                     // Secondary Grid Color
input ENUM_THICKNESS SubThick = One;                     // Secondary Grid Thickness
input bool LinesBackground = true;                       // Draw Lines as Background?

input string Comment_4 = "====================";         // Panel Position & Looks
input int Xoff = 20;                                     // Horizontal spacing for the control panel
input int Yoff = 20;                                     // Vertical spacing for the control panel
input string Font = "Consolas";                          // Panel Font
input int FontSize = 8;                                  // Font Size

int eDigits = 0;
double DPIScale; // Scaling parameter for the panel based on the screen DPI.
int PanelMovX, PanelMovY, PanelLabX, PanelLabY, PanelRecX;
int SetGLabelX, SetGLabelEX, SetGLabelY, SetButtonX, SetButtonY;
int _XOffset, _YOffset;
double _StartPrice, _LowRange, _HighRange;
int _MainGap, _SubGap;
bool _ShowSubGrid;

int OnInit()
{
    IndicatorSetString(INDICATOR_SHORTNAME, IndicatorName);

    eDigits = (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
    CleanChart();

    ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, 1); // Enable mouse movement events for panel dragging.

    DPIScale = (double)TerminalInfoInteger(TERMINAL_SCREEN_DPI) / 96.0;

    PanelMovX = (int)MathRound(26 * DPIScale);
    PanelMovY = (int)MathRound(26 * DPIScale);
    PanelLabX = (int)MathRound(101 * DPIScale);
    PanelLabY = PanelMovY;
    PanelRecX = (PanelMovX + 2) * 3 + PanelLabX + 1;

    SetGLabelX = (int)MathRound(100 * DPIScale);
    SetGLabelEX = (int)MathRound(80 * DPIScale);
    SetGLabelY = (int)MathRound(20 * DPIScale);
    SetButtonX = (int)MathRound(90 * DPIScale);
    SetButtonY = SetGLabelY;

    _XOffset = Xoff;
    _YOffset = Yoff;
    _StartPrice = StartPrice;
    if (_StartPrice == 0) _StartPrice = iClose(Symbol(), Period(), 0);
    _LowRange = LowRange;
    _HighRange = HighRange;
    _MainGap = MainGap;
    _SubGap = SubGap;
    _ShowSubGrid = ShowSubGrid;
    
    CreateMiniPanel();
    
    return INIT_SUCCEEDED;
}

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
    if (UpdateStartPrice)
    {
        _StartPrice = iClose(Symbol(), Period(), 0);
        if (ObjectFind(0, SettingsStartPriceE) == 0) // Found on the main window.
        {
            ObjectSetString(0, SettingsStartPriceE, OBJPROP_TEXT, DoubleToString(_StartPrice, eDigits));
        }
    }
    return rates_total;
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    if (id == CHARTEVENT_OBJECT_CLICK)
    {
        ChartSetInteger(ChartID(), CHART_MOUSE_SCROLL, true); // Enable chart sideways scroll.
        if (sparam == PanelExp)
        {
            DrawGrid();
        }
        if (sparam == PanelDel)
        {
            CleanGrid();
            ChartRedraw();
        }
        if (sparam == PanelOptions)
        {
            ShowSettings();
        }
        if (sparam == SettingsClose)
        {
            CloseSettings();
            ChartRedraw();
        }
        if (sparam == SettingsSave)
        {
            SaveSettingsChanges();
        }
        if (sparam == SettingsShowSubE)
        {
            ChangeShowSub();
        }
    }
    else if (id == CHARTEVENT_MOUSE_MOVE)
    {
        if (StringToInteger(sparam) == 1)
        {
            if ((lparam > _XOffset + 2) && (lparam < _XOffset + 2 + PanelLabX) &&
                (dparam > _YOffset + 2) && (dparam < _YOffset + 2 + PanelLabY))
            {
                ChartSetInteger(ChartID(), CHART_MOUSE_SCROLL, false);  // Disable chart sideways scroll.
                _XOffset = (int)lparam - 2 - PanelLabX / 2;
                _YOffset = (int)dparam - 2 - PanelLabY / 2;
                CloseSettings();
                UpdatePanel();
            }
        }
    }
}

void OnDeinit(const int reason)
{
    CleanGrid();
    CleanChart();
}

// Delete all objects except grid.
void CleanChart()
{
    CleanMiniPanel();
    CloseSettings();
    ChartRedraw();
}

void CleanGrid()
{
    ObjectsDeleteAll(0, IndicatorName + "-HLINE-");
}

void CleanMiniPanel()
{
    ObjectsDeleteAll(0, IndicatorName + "-P-");
}

void CloseSettings()
{
    ObjectsDeleteAll(0, IndicatorName + "-S-");
}

void DrawGrid()
{
    CleanGrid();
    CloseSettings();
    
    double GridPrice = 0;
    double Points = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    double MainStep = _MainGap * Points;
    double SubStep = _SubGap * Points;
    
    if (_HighRange == 0) _HighRange = iHigh(Symbol(), Period(), iHighest(Symbol(), Period(), MODE_HIGH, WHOLE_ARRAY, 0)) + MainStep;
    if (_LowRange  == 0) _LowRange  =  iLow(Symbol(), Period(),  iLowest(Symbol(), Period(), MODE_LOW,  WHOLE_ARRAY, 0)) - MainStep;
    if (_LowRange < 0) _LowRange = 0;
    if (_StartPrice == 0) _StartPrice = iClose(Symbol(), Period(), 0);
    
    if ((_StartPrice > _HighRange) || (_StartPrice < _LowRange))
    {
        Print("The start price must be between the minimum and the maximum values. Start Price: ", _StartPrice, ", Minimum: ", _LowRange, ", Maximum: ", _HighRange);
        return;
    }

    GridPrice = _StartPrice;
    while (GridPrice <= _HighRange)
    {
        string LineName = IndicatorName + "-HLINE-M-" + IntegerToString((int)MathRound(GridPrice / Points));
        if (ObjectFind(0, LineName) >= 0)
        {
            GridPrice += MainStep;
            continue;
        }
        ObjectCreate(0, LineName, OBJ_HLINE, 0, 0, GridPrice);
        ObjectSetInteger(0, LineName, OBJPROP_COLOR, MainColor);
        ObjectSetInteger(0, LineName, OBJPROP_STYLE, MainStyle);
        ObjectSetInteger(0, LineName, OBJPROP_WIDTH, MainThick);
        ObjectSetInteger(0, LineName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, LineName, OBJPROP_BACK, LinesBackground);
        GridPrice += MainStep;
    }
    GridPrice = _StartPrice;
    while (GridPrice >= _LowRange)
    {
        string LineName = IndicatorName + "-HLINE-M-" + IntegerToString((int)MathRound(GridPrice / Points));
        if (ObjectFind(0, LineName) >= 0)
        {
            GridPrice -= MainStep;
            continue;
        }
        ObjectCreate(0, LineName, OBJ_HLINE, 0, 0, GridPrice);
        ObjectSetInteger(0, LineName, OBJPROP_COLOR, MainColor);
        ObjectSetInteger(0, LineName, OBJPROP_STYLE, MainStyle);
        ObjectSetInteger(0, LineName, OBJPROP_WIDTH, MainThick);
        ObjectSetInteger(0, LineName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, LineName, OBJPROP_BACK, LinesBackground);
        GridPrice -= MainStep;
    }
    if (_ShowSubGrid)
    {
        GridPrice = _StartPrice;
        while (GridPrice <= _HighRange)
        {
            string LineName = IndicatorName + "-HLINE-S-" + IntegerToString((int)MathRound(GridPrice / Points));
            if (ObjectFind(0, LineName) >= 0)
            {
                GridPrice += SubStep;
                continue;
            }
            ObjectCreate(0, LineName, OBJ_HLINE, 0, 0, GridPrice);
            ObjectSetInteger(0, LineName, OBJPROP_COLOR, SubColor);
            ObjectSetInteger(0, LineName, OBJPROP_STYLE, SubStyle);
            ObjectSetInteger(0, LineName, OBJPROP_WIDTH, SubThick);
            ObjectSetInteger(0, LineName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, LineName, OBJPROP_BACK, LinesBackground);
            GridPrice += SubStep;
        }
        GridPrice = _StartPrice;
        while (GridPrice >= _LowRange)
        {
            string LineName = IndicatorName + "-HLINE-S-" + IntegerToString((int)MathRound(GridPrice / Points));
            if (ObjectFind(0, LineName) >= 0)
            {
                GridPrice -= SubStep;
                continue;
            }
            ObjectCreate(0, LineName, OBJ_HLINE, 0, 0, GridPrice);
            ObjectSetInteger(0, LineName, OBJPROP_COLOR, SubColor);
            ObjectSetInteger(0, LineName, OBJPROP_STYLE, SubStyle);
            ObjectSetInteger(0, LineName, OBJPROP_WIDTH, SubThick);
            ObjectSetInteger(0, LineName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, LineName, OBJPROP_BACK, LinesBackground);
            GridPrice += SubStep;
        }
    }
    ChartRedraw();
}

string PanelBase = IndicatorName + "-P-BAS";
string PanelLabel = IndicatorName + "-P-LAB";
string PanelExp = IndicatorName + "-P-EXP";
string PanelDel = IndicatorName + "-P-DEL";
string PanelOptions = IndicatorName + "-P-OPT";
void CreateMiniPanel()
{
    ObjectCreate(0, PanelBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, PanelBase, OBJPROP_XDISTANCE, _XOffset);
    ObjectSetInteger(0, PanelBase, OBJPROP_YDISTANCE, _YOffset);
    ObjectSetInteger(0, PanelBase, OBJPROP_XSIZE, PanelRecX);
    ObjectSetInteger(0, PanelBase, OBJPROP_YSIZE, (PanelMovY + 2) * 1 + 2);
    ObjectSetInteger(0, PanelBase, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, PanelBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, PanelBase, OBJPROP_STATE, false);
    ObjectSetInteger(0, PanelBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, PanelBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, PanelBase, OBJPROP_COLOR, clrBlack);

    // Caption:
    DrawEdit(PanelLabel,
             _XOffset + 2,
             _YOffset + 2,
             PanelLabX,
             PanelLabY,
             true,
             int(FontSize * 1.5),
             "Drag to move",
             ALIGN_CENTER,
             Font,
             "DRAW GRID",
             false,
             clrNavy,
             clrKhaki,
             clrBlack);

    // Pencil button:
    DrawEdit(PanelExp,
             _XOffset + PanelLabX + 3,
             _YOffset + 2,
             PanelMovX,
             PanelMovX,
             true,
             int(FontSize * 1.5),
             "Click to draw the grid",
             ALIGN_CENTER,
             "Wingdings",
             "!",
             false,
             clrNavy,
             clrKhaki,
             clrBlack);

    // Hand button:
    DrawEdit(PanelDel,
             _XOffset + PanelLabX + (PanelMovX + 2) * 1 + 2,
             _YOffset + 2,
             PanelMovX,
             PanelMovX,
             true,
             int(FontSize * 1.5),
             "Click to delete current grid",
             ALIGN_CENTER,
             "Wingdings",
             "I",
             false,
             clrNavy,
             clrKhaki,
             clrBlack);

    // PC button:
    DrawEdit(PanelOptions,
             _XOffset + (PanelMovX + 2) * 2 + PanelLabX + 1,
             _YOffset + 2,
             PanelMovX,
             PanelMovX,
             true,
             int(FontSize * 1.5),
             "Click to open the options panel",
             ALIGN_CENTER,
             "Wingdings",
             ":",
             false,
             clrNavy,
             clrKhaki,
             clrBlack);
}

void UpdatePanel()
{
    ObjectSetInteger(0, PanelBase, OBJPROP_XDISTANCE, _XOffset);
    ObjectSetInteger(0, PanelBase, OBJPROP_YDISTANCE, _YOffset);
    ObjectSetInteger(0, PanelLabel, OBJPROP_XDISTANCE, _XOffset + 2);
    ObjectSetInteger(0, PanelLabel, OBJPROP_YDISTANCE, _YOffset + 2);
    ObjectSetInteger(0, PanelExp, OBJPROP_XDISTANCE, _XOffset + PanelLabX + 3);
    ObjectSetInteger(0, PanelExp, OBJPROP_YDISTANCE, _YOffset + 2);
    ObjectSetInteger(0, PanelDel, OBJPROP_XDISTANCE, _XOffset + PanelLabX + (PanelMovX + 2) * 1 + 2);
    ObjectSetInteger(0, PanelDel, OBJPROP_YDISTANCE, _YOffset + 2);
    ObjectSetInteger(0, PanelOptions, OBJPROP_XDISTANCE, _XOffset + (PanelMovX + 2) * 2 + PanelLabX + 1);
    ObjectSetInteger(0, PanelOptions, OBJPROP_YDISTANCE, _YOffset + 2);
    ChartRedraw();
}

string SettingsBase = IndicatorName + "-S-Base";
string SettingsSave = IndicatorName + "-S-Save";
string SettingsClose = IndicatorName + "-S-Close";
string SettingsStartPrice = IndicatorName + "-S-StartPrice";
string SettingsStartPriceE = IndicatorName + "-S-StartPriceE";
string SettingsLowRange = IndicatorName + "-S-LowRange";
string SettingsLowRangeE = IndicatorName + "-S-LowRangeE";
string SettingsHighRange = IndicatorName + "-S-HighRange";
string SettingsHighRangeE = IndicatorName + "-S-HighRangeE";
string SettingsMainGap = IndicatorName + "-S-MainGap";
string SettingsMainGapE = IndicatorName + "-S-MainGapE";
string SettingsShowSub = IndicatorName + "-S-ShowSub";
string SettingsShowSubE = IndicatorName + "-S-ShowSubE";
string SettingsSubGap = IndicatorName + "-S-SubGap";
string SettingsSubGapE = IndicatorName + "-S-SubGapE";
void ShowSettings()
{
    int SetXoff = _XOffset;
    int SetYoff = _YOffset + PanelMovY * 1 + (int)MathRound(6 * DPIScale);
    int SetX = SetButtonX * 2 + (int)MathRound(6 * DPIScale);
    int SetY = (SetButtonY + 2) * 7 + 2;
    
    int j = 1; // Vertical offset for setting controls.
    
    string TextStartPrice = "";
    string TextLowRange = "";
    string TextHighRange = "";
    string TextMainGap = IntegerToString(_MainGap);
    string TextShowSub = "";
    string TextSubGap = IntegerToString(_SubGap);
    
    if (_ShowSubGrid) TextShowSub = "ON";
    else TextShowSub = "OFF";

    TextHighRange = DoubleToString(_HighRange, eDigits);
    TextLowRange = DoubleToString(_LowRange, eDigits);
    TextStartPrice = DoubleToString(_StartPrice, eDigits);

    ObjectCreate(0, SettingsBase, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, SettingsBase, OBJPROP_XDISTANCE, SetXoff);
    ObjectSetInteger(0, SettingsBase, OBJPROP_YDISTANCE, SetYoff);
    ObjectSetInteger(0, SettingsBase, OBJPROP_XSIZE, SetX);
    ObjectSetInteger(0, SettingsBase, OBJPROP_YSIZE, SetY);
    ObjectSetInteger(0, SettingsBase, OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, SettingsBase, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, SettingsBase, OBJPROP_STATE, false);
    ObjectSetInteger(0, SettingsBase, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, SettingsBase, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, SettingsBase, OBJPROP_COLOR, clrBlack);

    // Save button:
    DrawEdit(SettingsSave,
             SetXoff + 2,
             SetYoff + 2,
             SetGLabelX,
             SetGLabelY,
             true,
             FontSize,
             "Save changes",
             ALIGN_CENTER,
             Font,
             "Save",
             false,
             clrBlack,
             clrPaleGreen,
             clrBlack);

    // Close button:
    DrawEdit(SettingsClose,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2,
             SetGLabelEX,
             SetButtonY,
             true,
             FontSize,
             "Close settings panel",
             ALIGN_CENTER,
             Font,
             "X",
             false,
             clrBlack,
             clrCrimson,
             clrBlack);

    // Start Price label:
    DrawEdit(SettingsStartPrice,
             SetXoff + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelX,
             SetGLabelY,
             true,
             FontSize,
             "Starting price for the grid",
             ALIGN_CENTER,
             Font,
             "Start Price",
             false,
             clrBlack);

    // Start Price input:
    DrawEdit(SettingsStartPriceE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelEX,
             SetButtonY,
             false,
             FontSize,
             "Starting price for the grid. Click to change.",
             ALIGN_CENTER,
             Font,
             TextStartPrice,
             false,
             clrBlack);

    j++; // New Line.

    // High Price label:
    DrawEdit(SettingsHighRange,
             SetXoff + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelX,
             SetGLabelY,
             true,
             FontSize,
             "Grid highest value",
             ALIGN_CENTER,
             Font,
             "High price",
             false,
             clrBlack);
             
    // High Price input:
    DrawEdit(SettingsHighRangeE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelEX,
             SetButtonY,
             false,
             FontSize,
             "Grid highest value. Click to change.",
             ALIGN_CENTER,
             Font,
             TextHighRange,
             false,
             clrBlack);

    j++; // New line.

    // Low Price label:
    DrawEdit(SettingsLowRange,
             SetXoff + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelX,
             SetGLabelY,
             true,
             FontSize,
             "Grid lowest value",
             ALIGN_CENTER,
             Font,
             "Low price",
             false,
             clrBlack);
    
    // Low Price input:
    DrawEdit(SettingsLowRangeE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelEX,
             SetButtonY,
             false,
             FontSize,
             "Grid lowest value. Click to change.",
             ALIGN_CENTER,
             Font,
             TextLowRange,
             false,
             clrBlack);

    j++; // New line.

    // Main Gap label:
    DrawEdit(SettingsMainGap,
             SetXoff + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelX,
             SetGLabelY,
             true,
             FontSize,
             "Main gap in points",
             ALIGN_CENTER,
             Font,
             "Main gap",
             false,
             clrBlack);
    
    // Main Gap input:
    DrawEdit(SettingsMainGapE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelEX,
             SetButtonY,
             false,
             FontSize,
             "Main gap in points. Click to change.",
             ALIGN_CENTER,
             Font,
             TextMainGap,
             false,
             clrBlack);

    j++;

    // Show Sub Gap label:
    DrawEdit(SettingsShowSub,
             SetXoff + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelX,
             SetGLabelY,
             true,
             FontSize,
             "Show secondary grid",
             ALIGN_CENTER,
             Font,
             "Show sub gap",
             false,
             clrBlack);

    // Show Sub Gap button:
    DrawEdit(SettingsShowSubE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelEX,
             SetButtonY,
             true,
             FontSize,
             "Show secondary grid. Click to change.",
             ALIGN_CENTER,
             Font,
             TextShowSub,
             false,
             clrBlack);

    j++; // New line.

    // Sub Gap label:
    DrawEdit(SettingsSubGap,
             SetXoff + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelX,
             SetGLabelY,
             true,
             FontSize,
             "Secondary gap in points",
             ALIGN_CENTER,
             Font,
             "Sub gap",
             false,
             clrBlack);
    
    // Sub Gap input:
    DrawEdit(SettingsSubGapE,
             SetXoff + 2 + SetGLabelX + 2,
             SetYoff + 2 + (SetButtonY + 2) * j,
             SetGLabelEX,
             SetButtonY,
             false,
             FontSize,
             "Secondary gap in points. Click to change.",
             ALIGN_CENTER,
             Font,
             TextSubGap,
             false,
             clrBlack);
    ChartRedraw();
}

// Processes clicks on the Show Sub Gap button.
void ChangeShowSub()
{
    string Tmp = ObjectGetString(0, SettingsShowSubE, OBJPROP_TEXT);
    if (Tmp == "ON")
    {
        ObjectSetString(0, SettingsShowSubE, OBJPROP_TEXT, "OFF");
    }
    else if (Tmp == "OFF")
    {
        ObjectSetString(0, SettingsShowSubE, OBJPROP_TEXT, "ON");
    }
    ChartRedraw();
}

void SaveSettingsChanges()
{
    double SettingsStartPriceTmp = StringToDouble(ObjectGetString(0, SettingsStartPriceE, OBJPROP_TEXT));
    double SettingsLowRangeTmp = StringToDouble(ObjectGetString(0, SettingsLowRangeE, OBJPROP_TEXT));
    double SettingsHighRangeTmp = StringToDouble(ObjectGetString(0, SettingsHighRangeE, OBJPROP_TEXT));
    string SettingsShowSubTmp = ObjectGetString(0, SettingsShowSubE, OBJPROP_TEXT);
    int SettingsMainLegTmp = (int)StringToInteger(ObjectGetString(0, SettingsMainGapE, OBJPROP_TEXT));
    int SettingsSubLegTmp = (int)StringToInteger(ObjectGetString(0, SettingsSubGapE, OBJPROP_TEXT));
    
    if ((SettingsStartPriceTmp < SettingsLowRangeTmp) || (SettingsStartPriceTmp > SettingsHighRangeTmp))
    {
        Print("The start price must be between the minimum and the maximum values. Start Price: ", SettingsStartPriceTmp, ", Minimum: ", SettingsLowRangeTmp, ", Maximum: ", SettingsHighRangeTmp);
        ShowSettings();
        return;
    }
    
    _StartPrice = SettingsStartPriceTmp;
    _LowRange = SettingsLowRangeTmp;
    _HighRange = SettingsHighRangeTmp;
    _MainGap = SettingsMainLegTmp;
    _SubGap = SettingsSubLegTmp;
    if (SettingsShowSubTmp == "ON") _ShowSubGrid = true;
    else _ShowSubGrid = false;
    ShowSettings();
}
//+------------------------------------------------------------------+