{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

////        Remains of the old library adapted for the new one              ////

unit RAxesOld;

interface

uses
  {$IFDEF UNIX}
  {$ELSE}
  Windows,
  {$ENDIF}
  Classes, Graphics, RTypes, RCore;

type

  TRRange = TRectF;

  {----------- TRAxes -------------}

  TRAxes = class;

  TTickLabelPosition = (tlpMinus, tlpPlus);
  TXLabelPosition = (lpTop, lpBottom);
  TYLabelPosition = (lpLeft, lpRight);
//  TLabelPosition = (lpLeftTop, lpRightBottom);
  TAxesAlign = (aaNone, aaCenter, aaLeftBottom, aaLeftTop, aaRightBottom, aaRightTop);

  TLabelPosProc = function(Layer: TRLayer; Position: Double; const Text: string): TPoint of object;
  TDrawAdditionalLabelsEvent = procedure(Layer: TRLayer; Proc: TLabelPosProc) of object;

  TRAxis = class(TRFigure)
  private
    FAxes: TRAxes;

    FIncrement: Double;
    FCenter: Double;

    FMinorTickLength: Integer;
    FMajorTickLength: Integer;
    FMinorTickNumber: Integer;
    FTickLabelPosition: TTickLabelPosition;

    FMinorPlusTicks: Boolean;
    FMinorMinusTicks: Boolean;
    FMajorPlusTicks: Boolean;
    FMajorMinusTicks: Boolean;

    FMinorGrid: Boolean;
    FMajorGrid: Boolean;

    FShowLabels: Boolean;

    FOnDrawAdditionalLabels: TDrawAdditionalLabelsEvent;

    function GetCenter: Double;
    procedure SetCenter(Value: Double);

    procedure SetTickLabelPosition(Value: TTickLabelPosition);
    procedure SetMinorMinusTicks(Value: Boolean);
    procedure SetMinorPlusTicks(Value: Boolean);
    procedure SetMajorMinusTicks(Value: Boolean);
    procedure SetMajorPlusTicks(Value: Boolean);

    procedure SetIncrement(Value: Double);
    procedure SetMinorTickLength(Value: Integer);
    procedure SetMajorTickLength(Value: Integer);
    procedure SetMinorTickNumber(Value: Integer);

    procedure SetMajorGrid(Value: Boolean);
    procedure SetMinorGrid(Value: Boolean);
    procedure SetShowLabels(Value: Boolean);
  protected
    FOnChange: TNotifyEvent;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    procedure Changed;
  public
    property TickLabelPosition: TTickLabelPosition read FTickLabelPosition write SetTickLabelPosition;
    property MinorMinusTicks: Boolean read FMinorMinusTicks write SetMinorMinusTicks;
    property MinorPlusTicks: Boolean read FMinorPlusTicks write SetMinorPlusTicks;
    property MajorMinusTicks: Boolean read FMajorMinusTicks write SetMajorMinusTicks;
    property MajorPlusTicks: Boolean read FMajorPlusTicks write SetMajorPlusTicks;

    property OnDrawAdditionalLabels: TDrawAdditionalLabelsEvent
      read FOnDrawAdditionalLabels write FOnDrawAdditionalLabels;

    constructor Create; override;
    procedure Assign(Source: TPersistent); override;

  published
    property Increment: Double read FIncrement write SetIncrement;
    property Visible;
    property Center: Double read GetCenter write SetCenter;
    property MinorTickLength: Integer read FMinorTickLength write SetMinorTickLength;
    property MajorTickLength: Integer read FMajorTickLength write SetMajorTickLength;
    property MinorTickNumber: Integer read FMinorTickNumber write SetMinorTickNumber;

    property MajorGrid: Boolean read FMajorGrid write SetMajorGrid;
    property MinorGrid: Boolean read FMinorGrid write SetMinorGrid;
    property ShowLabels: Boolean read FShowLabels write SetShowLabels;
  end;

  {$WARNINGS OFF}
  TRXAxis = class(TRAxis)
  private
    function GetXLabelPos: TXLabelPosition;
    procedure SetXLabelPos(Value: TXLabelPosition);

    function _XLabelPos(Layer: TRLayer; LogicPosition: Double; const Text: string): TPoint;
  protected
    procedure Draw(Layer: TRLayer); override;
  published
    property LabelPosition: TXLabelPosition read GetXLabelPos write SetXLabelPos;
    property MinorTopTicks: Boolean read FMinorMinusTicks write SetMinorMinusTicks;
    property MinorBottomTicks: Boolean read FMinorPlusTicks write SetMinorPlusTicks;
    property MajorTopTicks: Boolean read FMajorMinusTicks write SetMajorMinusTicks;
    property MajorBottomTicks: Boolean read FMajorPlusTicks write SetMajorPlusTicks;
  end;

  TRYAxis = class(TRAxis)
  private
    function GetYLabelPos: TYLabelPosition;
    procedure SetYLabelPos(Value: TYLabelPosition);

    function _YLabelPos(Layer: TRLayer; LogicPosition: Double; const Text: string): TPoint;

  protected
    procedure Draw(Layer: TRLayer); override;
  published
    property LabelPosition: TYLabelPosition read GetYLabelPos write SetYLabelPos;
    property MinorLeftTicks: Boolean read FMinorMinusTicks write SetMinorMinusTicks;
    property MinorRightTicks: Boolean read FMinorPlusTicks write SetMinorPlusTicks;
    property MajorLeftTicks: Boolean read FMajorMinusTicks write SetMajorMinusTicks;
    property MajorRightTicks: Boolean read FMajorPlusTicks write SetMajorPlusTicks;
  end;
  {$WARNINGS ON}

  TRAxes = class(TRFigure)
  private
    FFont: TFont;
    FPen: TPen;
    FMajorGridPen: TPen;
    FMinorGridPen: TPen;
    FRange: TRRange;
    FX: TRXAxis;
    FY: TRYAxis;
    FShowFrame: Boolean;
    FShowArrows: Boolean;
    FAlign: TAxesAlign;
    FTickTowardsLabel: Boolean;
    FFontIsExternal: Boolean;

    function GetColor: TColor;
    procedure SetColor(Value: TColor);
    procedure SetFont(Value: TFont);
    procedure SetPen(Value: TPen);
    procedure SetMinorGridPen(Value: TPen);
    procedure SetMajorGridPen(Value: TPen);
    procedure SetX(Value: TRXAxis);
    procedure SetY(Value: TRYAxis);
    procedure SetRange(Value: TRRange);

    procedure SetAlign(Value: TAxesAlign);
    procedure SetShowFrame(Value: Boolean);
    procedure SetTickTowardsLabel(Value: Boolean);

    procedure ChangeStyle(Sender: TObject);
  protected
    procedure Changed;
    procedure _AccomodatePen(Layer: TRLayer);
    procedure _AccomodateFont(Layer: TRLayer);
    procedure _AccomodateSize(Layer: TRLayer; var ASize: Integer);
  public
    property ShowArrows: Boolean read FShowArrows write FShowArrows;
    property FontIsExternal: Boolean read FFontIsExternal;

    constructor Create; override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure AttachExternalFont(Value: TFont);

    procedure Draw(Layer: TRLayer); override;
    procedure PrepareAxes(Layer: TRLayer);
    procedure DrawGrid(Layer: TRLayer);
    procedure DrawFrame(Layer: TRLayer);
  //published
  public
    property Color: TColor read GetColor write SetColor;
    property Font: TFont read FFont write SetFont;
    property Pen: TPen read FPen write SetPen;
    property Align: TAxesAlign read FAlign write SetAlign;
    property MinorGridPen: TPen read FMinorGridPen write SetMinorGridPen;
    property MajorGridPen: TPen read FMajorGridPen write SetMajorGridPen;
    property Range: TRRange read FRange write SetRange;
    property XAxis: TRXAxis read FX write SetX;
    property YAxis: TRYAxis read FY write SetY;
    property ShowFrame: Boolean read FShowFrame write SetShowFrame;
    property Visible;
    property TickTowardsLabel: Boolean read FTickTowardsLabel write SetTickTowardsLabel;
  end;


implementation

uses
  SysUtils, StrFunc, Math;

var
{ --- Axes Params --- }

  X0, Y0: Double;

  MajorXInc: Double;
  FirstMajorXTick: Double;
  NMajorXTicks: Integer;

  MinorXInc: Double;
  FirstMinorXTick: Double;
  NMinorXTicks: Integer;

  MajorYInc: Double;
  FirstMajorYTick: Double;
  NMajorYTicks: Integer;

  MinorYInc: Double;
  FirstMinorYTick: Double;
  NMinorYTicks: Integer;

  MajorTickX0, MajorTickX1: Integer;
  MajorTickY0, MajorTickY1: Integer;
  MinorTickX0, MinorTickX1: Integer;
  MinorTickY0, MinorTickY1: Integer;

  //NNNX, NNNY: Integer;

  L, T, W, H{, B, R}: Integer;
  XX, YY: Integer;
  XMin, YMin, XMax, YMax, XCoef, YCoef: Double;

function IntTenIn(N: Integer): Int64;
const
  Tens: array[0..18] of Int64 = (
    1, 10, 100, 1000, 10000,
    1*100000, 10*100000, 100*100000, 1000*100000, 10000*100000,
    1*10000000000, 10*10000000000, 100*10000000000, 1000*10000000000, 10000*10000000000,
    1*1000000000000000, 10*1000000000000000, 100*1000000000000000, 1000*1000000000000000);
begin
  if (N >= 0)and(N < Length(Tens))
    then Result := Tens[N]
    else Result := 1;
end;

function FltTenIn(N: Integer): Double;
begin
  if (N <= 18)and(N >= -18) then
  begin
    if N >= 0
      then Result := IntTenIn(N)
      else Result := 1/IntTenIn(-N);
  end
  else
    Result := Power(10, N);
end;

function OrderOf(X: Double): Integer;
begin
  if X >= 1
    then Result := -Trunc(-Ln(Abs(X))/Ln(10))
    else Result := -Trunc(-Ln(Abs(X))/Ln(10))-1;
end;

function FindIncrement(Interval: Double; N: Integer; Coord: Char): Double;
var D, T, R, _sign: Double;
    OrderD: Integer;
begin
         {*} _sign := 2*BoolToInt(Interval > 0)-1;  
         {*} Interval := Abs(Interval);

  if (N < 1)or(N > 50)then begin Result := 1E9; Exit; end;

  D := Interval/N;
  OrderD := OrderOf(D);

  if Coord in ['x', 'X'] then
  begin
    if (OrderD > 5) or (OrderD < -3) then N := 8;
    if (OrderD > 7) or (OrderD < -5) then N := 6;

    D := Interval/N;
    OrderD := OrderOf(D);
  end;

  T := FltTenIn(OrderD);
  D := D/T;
  if D < 1.64 then R := 1 else
  if D < 2.36 then R := 2 else
  if D < 3.59 then R := 2.5 else
  if D < 8.16 then R := 5 else R := 10;
  Result := R*T;

         {*} Result := Result*_sign;
end;

   (*
function FindIncrementEx(Canvas: TCanvas; AMin, AMax: Double; NMax: Integer; var Prec: Integer): Double;
var RawInc, Delta, D, T, R: Double;
    {BaseOrder,} DeltaOrder, {IncDigits,} N{, m}: Integer;
begin
  Delta := AMax - AMin;
  //BaseOrder := Max(OrderOf(AMin), OrderOf(AMin));
  DeltaOrder := OrderOf(Delta);
  N := 15;
  if (DeltaOrder > 4) or (DeltaOrder < -4) then N := 10;
  if (DeltaOrder > 6) or (DeltaOrder < -6) then N := 6;

  RawInc := Delta/N;
{  if RawInc > 1
    then IncDigits := -OrderOf(RawInc)
    else IncDigits := 0; }

  T := FltTenIn(DeltaOrder);
  D := RawInc/T;

  {m := 1;}
  if D < 1.64 then R := 1 else
  if D < 2.36 then R := 2 else
  if D < 3.59 then begin R := 2.5; {m := 2;} end else
  if D < 8.16 then R := 5 else R := 10;

  Result := R*T;
end;
     *)
     
function __Dbl2Str(pt: Double): string;
const zero = 1e-15;
begin
  if abs(pt) < zero then Result :='0'
  else Result := Format('%g',[Pt]);

  if (Pos('000000', Result) > 0)and
     (Abs(pt)<10000) then
    Result := StrBetween(Result, '', '000000', True, True);
end;

function _Dbl2Str(pt: Double): string;
begin
  Result := __Dbl2Str(pt);
  if (Pos('9999999', Result) > 0)then 
    Result := __Dbl2Str(pt*1.000000001);
end;

function TextOfXLabel(i: Integer): string;
var pt: Double;
begin
  pt := FirstMajorXTick + i*MajorXInc;
  Result := _Dbl2Str(pt);
end;

function TextOfYLabel(i: Integer): string;
var pt: Double;
begin
  pt := FirstMajorYTick + i*MajorYInc;
  Result := _Dbl2Str(pt);
end;


{----------------- TRAxis----------------------------}

constructor TRAxis.Create;
begin
//  Visible := True;
//  Clipped := False;
//  StdDraw := True;

  FIncrement := 0;

  FMinorTickLength := 2;
  FMajorTickLength := 5;
  FMinorTickNumber := 2;
  FTickLabelPosition := tlpPlus;

  FMinorPlusTicks := True;
  FMinorMinusTicks := False;
  FMajorPlusTicks := True;
  FMajorMinusTicks := False;

  FMinorGrid := False;
  FMajorGrid := False;
  FShowLabels := True;

  FCenter := 0;
end;

procedure TRAxis.Assign(Source: TPersistent);
begin
  if Source is TRAxis then
  begin
    FIncrement := TRAxis(Source).FIncrement;
//    FVisible := TRAxis(Source).FVisible;

    FMinorTickLength := TRAxis(Source).FMinorTickLength;
    FMajorTickLength := TRAxis(Source).FMajorTickLength;
    FMinorTickNumber := TRAxis(Source).FMinorTickNumber;
    FTickLabelPosition := TRAxis(Source).FTickLabelPosition;

    FMinorPlusTicks := TRAxis(Source).FMinorPlusTicks;
    FMinorMinusTicks := TRAxis(Source).FMinorMinusTicks;
    FMajorPlusTicks := TRAxis(Source).FMajorPlusTicks;
    FMajorMinusTicks := TRAxis(Source).FMajorMinusTicks;

    FMinorGrid := TRAxis(Source).FMinorGrid;
    FMajorGrid := TRAxis(Source).FMajorGrid;
  end;
  inherited Assign(Source);
end;

function TRAxis.GetCenter: Double;
begin
  Result := FCenter;
end;

procedure TRAxis.SetCenter(Value: Double);
begin
  if FCenter <> Value then
  begin
    FCenter := Value;
    Changed;
  end;
end;

procedure TRAxis.SetTickLabelPosition(Value: TTickLabelPosition);
begin
  if Value <> FTickLabelPosition then
  begin
    FTickLabelPosition := Value;
    Changed;
  end;
end;

procedure TRAxis.SetMinorMinusTicks(Value: Boolean);
begin
  if Value <> FMinorMinusTicks then
  begin
    FMinorMinusTicks := Value;
//    TickTowardsLabel := False;
    Changed;
  end;
end;

procedure TRAxis.SetMinorPlusTicks(Value: Boolean);
begin
  if Value <> FMinorPlusTicks then
  begin
    FMinorPlusTicks := Value;
//    TickTowardsLabel := False;
    Changed;
  end;
end;

procedure TRAxis.SetMajorMinusTicks(Value: Boolean);
begin
  if Value <> FMajorMinusTicks then
  begin
    FMajorMinusTicks := Value;
//    TickTowardsLabel := False;
    Changed;
  end;
end;

procedure TRAxis.SetMajorPlusTicks(Value: Boolean);
begin
  if Value <> FMajorPlusTicks then
  begin
    FMajorPlusTicks := Value;
//    TickTowardsLabel := False;
    Changed;
  end;
end;

procedure TRAxis.SetIncrement(Value: Double);
begin
  if (Value <> FIncrement)and(Value >= 0) then
  begin
    FIncrement := Value;
    Changed;
  end;
end;

procedure TRAxis.SetMinorTickLength(Value: Integer);
begin
  if Value <> FMinorTickLength then
  begin
    FMinorTickLength := Value;
    Changed;
  end;
end;

procedure TRAxis.SetMajorTickLength(Value: Integer);
begin
  if Value <> FMajorTickLength then
  begin
    FMajorTickLength := Value;
    Changed;
  end;
end;

procedure TRAxis.SetMinorTickNumber(Value: Integer);
begin
  if Value <> FMinorTickNumber then
  begin
    FMinorTickNumber := Value;
    Changed;
  end;
end;

procedure TRAxis.SetMajorGrid(Value: Boolean);
begin
  if Value <> FMajorGrid then
  begin
    FMajorGrid := Value;
    Changed;
  end;
end;

procedure TRAxis.SetMinorGrid(Value: Boolean);
begin
  if Value <> FMinorGrid then
  begin
    FMinorGrid := Value;
    Changed;
  end;
end;

procedure TRAxis.SetShowLabels(Value: Boolean);
begin
  if Value <> FShowLabels then
  begin
    FShowLabels := Value;
    Changed;
  end;
end;

{------------------TRXYAxis--------------------------------}
procedure TRXAxis.Draw(Layer: TRLayer);
var
  i: Integer;
  XX, YY: Integer;
  TxtW2, TxtH: Integer;
  Txt: string;
begin
  with Layer do
  begin
    Txt := '0';
    TxtH := Canvas.TextHeight(Txt);
    for i := 0 to NMajorXTicks do
    begin
      Converter.LogicToScreen(FirstMajorXTick + i*MajorXInc, 0, XX, YY{});
      //XX := ScreenX(FirstMajorXTick + i*MajorXInc);

      Canvas.MoveTo(XX, MajorTickY0);
      Canvas.LineTo(XX, MajorTickY1);

      Txt := TextOfXLabel(i);
      TxtW2 := Canvas.TextWidth(Txt) div 2;
      if FAxes.XAxis.ShowLabels then
      begin
        if FAxes.XAxis.TickLabelPosition = tlpPlus then
          Canvas.TextOut(XX - TxtW2, MajorTickY1 , Txt )
        else
          Canvas.TextOut(XX - TxtW2, MajorTickY0 - TxtH, Txt );
      end;
    end;

    if ShowLabels then
      if Assigned(FOnDrawAdditionalLabels) then
        FOnDrawAdditionalLabels(Layer, _XLabelPos);

    for i := 0 to NMinorXTicks do
    begin
      Converter.LogicToScreen(FirstMinorXTick + i*MinorXInc, 0, XX, YY);
      //XX := ScreenX(FirstMinorXTick + i*MinorXInc);
      Canvas.MoveTo(XX, MinorTickY0);
      Canvas.LineTo(XX, MinorTickY1);
    end;

    if FAxes.ShowArrows {or Sheet.Printing} then
    begin
      Converter.LogicToScreen(0, Y0, XX, YY);
      //YY := ScreenY(Y0);
      Canvas.MoveTo(L, YY);
      Canvas.LineTo(L+W, YY);
    end;
  end;
end;

function TRXAxis._XLabelPos(Layer: TRLayer; LogicPosition: Double; const Text: string): TPoint;
var XX, YY: Integer;
    TxtW2, TxtH: Integer;
begin
  Layer.Converter.LogicToScreen(LogicPosition, 0, XX, YY{});

  TxtW2 := Layer.Canvas.TextWidth(Text) div 2;
  TxtH := Layer.Canvas.TextHeight(Text);

  if FAxes.XAxis.TickLabelPosition = tlpPlus
    then Result := Point(XX - TxtW2, MajorTickY1)
    else Result := Point(XX - TxtW2, MajorTickY0 - TxtH);
end;

function TRXAxis.GetXLabelPos: TXLabelPosition;
begin
  if FTickLabelPosition = tlpPlus then
    Result := lpBottom
  else
    Result := lpTop;
end;

procedure TRXAxis.SetXLabelPos( Value: TXLabelPosition);
begin
  if Value = lpBottom then
    FTickLabelPosition := tlpPlus
  else
    FTickLabelPosition := tlpMinus;
  Changed;
end;

     {-----------------}
procedure TRYAxis.Draw(Layer: TRLayer);
var
  i: Integer;
  XX, YY: Integer;
  TxtW, TxtH2: Integer;
  Txt: string;

  function ScreenX(LX: Double): Integer;
  var _: Integer;
  begin
    Layer.Converter.LogicToScreen(LX, 0, Result, _);
  end;

  function ScreenY(LY: Double): Integer;
  var _: Integer;
  begin
    Layer.Converter.LogicToScreen(0, LY, _, Result);
  end;

begin
  with Layer do
  begin
    Txt := '0';
    TxtH2 := Canvas.TextHeight(Txt) div 2;
    for i := 0 to NMajorYTicks do
    begin
      //Converter.LogicToScreen(0, FirstMajorYTick + i*MajorYInc, XX, YY);
      YY := ScreenY(FirstMajorYTick + i*MajorYInc);

      Canvas.MoveTo(MajorTickX0, YY);
      Canvas.LineTo(MajorTickX1, YY);

      Txt := TextOfYLabel(i);
      TxtW := Canvas.TextWidth(Txt);
      if FAxes.YAxis.ShowLabels then
      begin
        if FAxes.YAxis.TickLabelPosition = tlpPlus then
          Canvas.TextOut(MajorTickX1 + 2, YY - TxtH2, Txt )
        else
          Canvas.TextOut(MajorTickX0 - TxtW - 2, YY - TxtH2, Txt );
      end;
    end;

    if ShowLabels then
      if Assigned(FOnDrawAdditionalLabels) then
        FOnDrawAdditionalLabels(Layer, _YLabelPos);

    for i := 0 to NMinorYTicks do
    begin
      //Converter.LogicToScreen(0, FirstMinorYTick + i*MinorYInc, XX, YY);
      YY := ScreenY(FirstMinorYTick + i*MinorYInc);

      Canvas.MoveTo(MinorTickX0, YY);
      Canvas.LineTo(MinorTickX1, YY);
    end;

    if FAxes.ShowArrows {or Sheet.Printing} then
    begin
      //Converter.LogicToScreen(X0, 0, XX, YY);
      XX := ScreenX(X0);

//      Canvas.MoveTo(XX, T);
//      Canvas.LineTo(XX, T + H);
      Canvas.MoveTo(XX, T);
      Canvas.LineTo(XX, T+H);
    end;
  end;
end;

function TRYAxis._YLabelPos(Layer: TRLayer; LogicPosition: Double; const Text: string): TPoint;
var XX, YY: Integer;
    TxtW, TxtH2: Integer;
begin
  Layer.Converter.LogicToScreen(0, LogicPosition, XX, YY);

  TxtW := Layer.Canvas.TextWidth(Text);
  TxtH2 := Layer.Canvas.TextHeight(Text) div 2;

  if FAxes.YAxis.TickLabelPosition = tlpPlus
    then Result := Point(MajorTickX1 + 2, YY - TxtH2)
    else Result := Point(MajorTickX0 - TxtW - 2, YY - TxtH2);
end;

function TRYAxis.GetYLabelPos: TYLabelPosition;
begin
  if FTickLabelPosition = tlpMinus then
    Result := lpLeft
  else
    Result := lpRight;
end;

procedure TRYAxis.SetYLabelPos( Value: TYLabelPosition);
begin
  if Value = lpLeft then
    FTickLabelPosition := tlpMinus
  else
    FTickLabelPosition := tlpPlus;
  Changed;
end;

{--------------------TRAxes--------------------------------}
constructor TRAxes.Create;
begin
  Visible := True;
//  Clipped := False;
//  StdDraw := True;

  FFont := TFont.Create;
    FFont.OnChange := ChangeStyle;
  FPen := TPen.Create;
    FPen.OnChange := ChangeStyle;

  FAlign := aaNone;
  FTickTowardsLabel := True;
  FShowFrame := True;
  FShowArrows := True;
  FFontIsExternal := False;

  FMajorGridPen := TPen.Create;
    FMajorGridPen.Color := clBlue;
    //FMajorGridPen.OnChange := ChangeStyle;
  FMinorGridPen := TPen.Create;
    FMinorGridPen.Color := clLime;
    //FMinorGridPen.OnChange := ChangeStyle;
//    FMinorGridPen.Style := psDot;
//    gluke: if set psDot, psSolid cannot be set

  {
  FRange := TRRange.Create(-1,1,-1,1);
    FRange.OnChange := ChangeStyle;
  }

  FX := TRXAxis.Create;
    FX.Visible := True;
    //FX.OnChange := ChangeStyle;
    FX.FAxes := Self;
  FY := TRYAxis.Create;
    FY.Visible := True;
    //FY.OnChange := ChangeStyle;
    FY.FAxes := Self;
  FY.FTickLabelPosition := tlpMinus;
  FY.FMinorPlusTicks := False;
  FY.FMajorPlusTicks := False;
  FY.FMinorMinusTicks := True;
  FY.FMajorMinusTicks := True;

    FMajorGridPen.OnChange := ChangeStyle;
    FMinorGridPen.OnChange := ChangeStyle;
    FX.OnChange := ChangeStyle;
    FY.OnChange := ChangeStyle;

end;

destructor TRAxes.Destroy;
begin
  if not FFontIsExternal then FFont.Free;
  FPen.Free;
  FMajorGridPen.Free;
  FMinorGridPen.Free;
  {
  FRange.Free;
  }
  FX.Free;
  FY.Free;
end;

procedure TRAxes.AttachExternalFont(Value: TFont);
begin
  if not FFontIsExternal then FFont.Free;
  FFont := Value;
  FFont.Color := FPen.Color;
  FFontIsExternal := True;
end;

function TRAxes.GetColor: TColor;
begin
  Result := FFont.Color;
end;

procedure TRAxes.SetColor(Value: TColor);
begin
  FFont.Color := Value;
  FPen.Color := Value;
end;

procedure TRAxes.SetFont(Value: TFont);
begin
  FFont.Assign(Value);
end;

procedure TRAxes.SetPen(Value: TPen);
begin
  FPen.Assign(Value);
end;

procedure TRAxes.SetMinorGridPen(Value: TPen);
begin
  FMinorGridPen.Assign(Value);
end;

procedure TRAxes.SetMajorGridPen(Value: TPen);
begin
  FMajorGridPen.Assign(Value);
end;

procedure TRAxes.SetX(Value: TRXAxis);
begin
  FX.Assign(Value);
end;

procedure TRAxes.SetY(Value: TRYAxis);
begin
  FY.Assign(Value);
end;

procedure TRAxes.SetRange(Value: TRRange);
begin
  //FRange.Assign(Value);
  FRange := Value;
end;

procedure TRAxes.SetAlign(Value: TAxesAlign);
begin
  if Value <> FAlign then
  begin
    FAlign := Value;
    Changed;
  end;
end;

procedure TRAxes.SetShowFrame(Value: Boolean);
begin
  if Value <> FShowFrame then
  begin
    FShowFrame := Value;
    Changed;
  end;
end;

procedure TRAxes.SetTickTowardsLabel(Value: Boolean);
begin
  if Value <> FTickTowardsLabel then
  begin
    FTickTowardsLabel := Value;
    Changed;
  end;
end;

procedure TRAxes.ChangeStyle(Sender: TObject);
begin
  Changed;
end;

procedure TRAxes.Assign(Source: TPersistent);
begin
  if Source is TRAxes then
  begin
    FFont.Assign(TRAxes(Source).FFont);
    FPen.Assign(TRAxes(Source).FPen);
    FMajorGridPen.Assign(TRAxes(Source).FMajorGridPen);
    FMinorGridPen.Assign(TRAxes(Source).FMinorGridPen);
    //FRange.Assign(TRAxes(Source).FRange);
    FRange := TRAxes(Source).FRange;
    FX.Assign(TRAxes(Source).FX);
    FY.Assign(TRAxes(Source).FY);
  end;
  inherited Assign(Source);
end;

procedure TRAxes.Draw(Layer: TRLayer);
begin                                                                           
  PrepareAxes(Layer);

  DrawGrid(Layer);

  with Layer do
  begin
    Canvas.Pen := Pen;
    Canvas.Font := Font;

    if Printing then
    begin
      _AccomodatePen(Layer);
      _AccomodateFont(Layer);
    end;

    if ShowFrame then DrawFrame(Layer);

    Draw(XAxis);
    Draw(YAxis);
  end;
end;

procedure TRAxes.DrawFrame(Layer: TRLayer);
begin
  with Layer do
  begin
    Canvas.MoveTo(L, T);
    Canvas.LineTo(L, T + H);
    Canvas.LineTo(L + W, T + H);
    Canvas.LineTo(L + W, T);
    Canvas.LineTo(L, T);
  end;
end;

procedure TRAxes.DrawGrid(Layer: TRLayer);
var i: Integer;

  function ScreenX(LX: Double): Integer;
  var _: Integer;
  begin
    Layer.Converter.LogicToScreen(LX, 0, Result, _);
  end;

  function ScreenY(LY: Double): Integer;
  var _: Integer;
  begin
    Layer.Converter.LogicToScreen(0, LY, _, Result);
  end;

begin
  with Layer do
  begin
    if (XAxis.MinorGrid){and(AAxes.X.Visible)} then
    begin
      Canvas.Pen := MinorGridPen;
      _AccomodatePen(Layer);
      for i := 0 to NMinorXTicks do
      begin
        //Converter.LogicToScreen(FirstMinorXTick + i*MinorXInc, 0, XX, YY);
        XX := ScreenX(FirstMinorXTick + i*MinorXInc);

        Canvas.MoveTo(XX, T);
        Canvas.LineTo(XX, T + H);
      end;
    end;

    if (YAxis.MinorGrid){and(AAxes.Y.Visible)} then
    begin
      Canvas.Pen := MinorGridPen;
      _AccomodatePen(Layer);
      for i := 0 to NMinorYTicks do
      begin
        //Converter.LogicToScreen(0, FirstMinorYTick + i*MinorYInc, XX, YY);
        YY := ScreenY(FirstMinorYTick + i*MinorYInc);

        Canvas.MoveTo(L, YY);
        Canvas.LineTo(L + W, YY);
      end;
    end;
{----------------- Major ------------------}
    if (XAxis.MajorGrid){and(AAxes.X.Visible)} then
    begin
      Canvas.Pen := MajorGridPen;
      _AccomodatePen(Layer);
      for i := 0 to NMajorXTicks do
      begin
        //Converter.LogicToScreen(FirstMajorXTick + i*MajorXInc, 0, XX, YY);
        XX := ScreenX(FirstMajorXTick + i*MajorXInc);

        Canvas.MoveTo(XX, T);
        Canvas.LineTo(XX, T + H);
      end;
    end;

    if (YAxis.MajorGrid){and(AAxes.Y.Visible)} then
    begin
      Canvas.Pen := MajorGridPen;
      _AccomodatePen(Layer);
      for i := 0 to NMajorYTicks do
      begin
        //Converter.LogicToScreen(0, FirstMajorYTick + i*MajorYInc, XX, YY);
        YY := ScreenY(FirstMajorYTick + i*MajorYInc);

        Canvas.MoveTo(L, YY);
        Canvas.LineTo(L + W, YY);
      end;
    end;
  end;
end;

procedure TRAxes.PrepareAxes(Layer: TRLayer);
var
  WT, HT, N, xMinTickLen, xMajTickLen, yMinTickLen, yMajTickLen: Integer;
  DeltaX, DeltaY: Double;

  function ScreenX(LX: Double): Integer;
  var _: Integer;
  begin
    Layer.Converter.LogicToScreen(LX, 0, Result, _);
  end;

  function ScreenY(LY: Double): Integer;
  var _: Integer;
  begin
    Layer.Converter.LogicToScreen(0, LY, _, Result);
  end;

begin
  with Layer do
  begin
    Canvas.Brush.Style := bsClear;

    XMin := Layer.ViewPort.XMin;
    XMax := Layer.ViewPort.XMax;
    YMin := Layer.ViewPort.YMin;
    YMax := Layer.ViewPort.YMax;

    L := Layer.Rect.Left;
    T := Layer.Rect.Top;
    H := Layer.Rect.Bottom - T;
    W := Layer.Rect.Right - L;

    XCoef := W/(XMax - XMin);
    YCoef := H/(YMax - YMin);

    {------------------------------------------------------------}

    DeltaX := XMax - XMin;
    DeltaY := YMax - YMin;

    if DeltaX < 1.5   then WT := Canvas.TextWidth('00000')  else
    if DeltaX < 15    then WT := Canvas.TextWidth('0000')  else
    if DeltaX < 150   then WT := Canvas.TextWidth('000')    else
    if DeltaX < 1500  then WT := Canvas.TextWidth('0000')   else
    if DeltaX < 15000 then WT := Canvas.TextWidth('00000')  else
                              WT := Canvas.TextWidth('000000');

    if Abs(Range.XMin)/DeltaX > 50 then WT := WT + Canvas.TextWidth('0');
    if W > 200 then WT := WT + Canvas.TextWidth('0');
    HT := Trunc( 1.7{1.3}{1.9}*Canvas.TextHeight('0') );

  {---------------- X Axis -----------------------}
    xMinTickLen := XAxis.MinorTickLength;
    xMajTickLen := XAxis.MajorTickLength;
    _AccomodateSize(Layer, xMinTickLen);
    _AccomodateSize(Layer, xMajTickLen);

    MajorXInc := XAxis.Increment;
    if (MajorXInc*(W div WT + 1) < DeltaX)or(MajorXInc > 1.3*DeltaX) then
    begin
      N := W div WT - 2;
      if Layer.Sheet.Printing then N := (N*3) div 5; //(N*2) div 3;   
      if N > 12 then N := 12;
      MajorXInc := FindIncrement(DeltaX, N, 'X');
    end;

    if Align = aaNone then
      Y0 := YAxis.Center  else
    if (Align = aaLeftBottom)or(Align = aaRightBottom) then
      Y0 := YMin  else
    if (Align = aaLeftTop)or(Align = aaRightTop) then
      Y0 := YMax else
      Y0 := (YMax + YMin)/2;

    FirstMajorXTick := MajorXInc*( 1 + Trunc( (XMin - MajorXInc/100)/MajorXInc ) );
      if XMin < MajorXInc/100 then FirstMajorXTick := FirstMajorXTick - MajorXInc;
    NMajorXTicks := Trunc((XMax - FirstMajorXTick + MajorXInc/100)/MajorXInc);
    MajorTickY0 := ScreenY(Y0); MajorTickY1 := ScreenY(Y0);
    if (XAxis.MajorMinusTicks and not TickTowardsLabel)or(TickTowardsLabel and (XAxis.LabelPosition = lpTop)) then
      MajorTickY0 := MajorTickY0 - xMajTickLen;
    if (XAxis.MajorPlusTicks and not TickTowardsLabel)or(TickTowardsLabel and (XAxis.LabelPosition = lpBottom)) then
      MajorTickY1 := MajorTickY1 + xMajTickLen + 1;

    if XAxis.MinorTickNumber > 0 then
    begin
      MinorXInc := MajorXInc/XAxis.MinorTickNumber;
      FirstMinorXTick := MinorXInc*( 1 + Trunc( (XMin - MinorXInc/100)/MinorXInc ) );
        if XMin < MajorYInc/100 then FirstMinorXTick := FirstMinorXTick - MinorXInc;
      NMinorXTicks := Trunc((XMax - FirstMinorXTick)/MinorXInc);
      MinorTickY0 := ScreenY(Y0); MinorTickY1 := ScreenY(Y0);
      if (XAxis.MinorMinusTicks and not TickTowardsLabel)or(TickTowardsLabel and (XAxis.LabelPosition = lpTop)) then
        MinorTickY0 := MinorTickY0 - xMinTickLen;
      if (XAxis.MinorPlusTicks and not TickTowardsLabel)or(TickTowardsLabel and (XAxis.LabelPosition = lpBottom)) then
        MinorTickY1 := MinorTickY1 + xMinTickLen + 1;
    end
    else
    begin
      NMinorXTicks := -1;
    end;

  {---------------- Y Axis -----------------------}
    yMinTickLen := YAxis.MinorTickLength;
    yMajTickLen := YAxis.MajorTickLength;
    _AccomodateSize(Layer, yMinTickLen);
    _AccomodateSize(Layer, yMajTickLen);

    MajorYInc := YAxis.Increment;
    if (MajorYInc*(H div HT + 1) < DeltaY)or(MajorYInc > 1.3*DeltaY) then
    begin
      N := H div HT - 2; if N > 8 then N := 8; // 12
      MajorYInc := FindIncrement(DeltaY, N, 'Y');
    end;

    if Align = aaNone then
      X0 := XAxis.Center  else
    if (Align = aaLeftBottom)or(Align = aaLeftTop) then
      X0 := XMin  else
    if (Align = aaRightBottom)or(Align = aaRightTop) then
      X0 := XMax else
      X0 := (XMax + XMin)/2;

    FirstMajorYTick := MajorYInc*( 1 + Trunc( (YMin - MajorYInc/100)/MajorYInc ) );
      if YMin < MajorYInc/100 then FirstMajorYTick := FirstMajorYTick - MajorYInc;

    NMajorYTicks := Trunc((YMax - FirstMajorYTick + MajorYInc/100)/MajorYInc);
    MajorTickX0 := ScreenX(X0); MajorTickX1 := ScreenX(X0);
    if (YAxis.MajorMinusTicks and not TickTowardsLabel)or(TickTowardsLabel and (YAxis.LabelPosition = lpLeft)) then
      MajorTickX0 := MajorTickX0 - yMajTickLen;
    if (YAxis.MajorPlusTicks and not TickTowardsLabel)or(TickTowardsLabel and (YAxis.LabelPosition = lpRight)) then
      MajorTickX1 := MajorTickX1 + yMajTickLen + 1;

    if YAxis.MinorTickNumber > 0 then
    begin
      MinorYInc := MajorYInc/YAxis.MinorTickNumber;
      FirstMinorYTick := MinorYInc*( 1 + Trunc( (YMin - MinorYInc/100)/MinorYInc ) );
        if YMin <0 then FirstMinorYTick := FirstMinorYTick - MinorYInc;
      NMinorYTicks := Trunc((YMax - FirstMinorYTick)/MinorYInc);
      MinorTickX0 := ScreenX(X0); MinorTickX1 := ScreenX(X0);
      if (YAxis.MinorMinusTicks and not TickTowardsLabel)or(TickTowardsLabel and (YAxis.LabelPosition = lpLeft)) then
        MinorTickX0 := MinorTickX0 - yMinTickLen;
      if (YAxis.MinorPlusTicks and not TickTowardsLabel)or(TickTowardsLabel and (YAxis.LabelPosition = lpRight)) then
        MinorTickX1 := MinorTickX1 + yMinTickLen + 1;
    end
    else
    begin
      NMinorYTicks := -1;
    end;

  end;
end;

procedure TRAxis.Changed;
begin
  // obsolete
end;

procedure TRAxes.Changed;
begin
  // obsolete
end;

procedure TRAxes._AccomodatePen(Layer: TRLayer);
begin
  if Layer.Printing then
    with Layer.Canvas.Pen do
      Width := Round(  Width * MinPtCoordF(Layer.Sheet.PrintData.PixelScale)  );
end;

procedure TRAxes._AccomodateFont(Layer: TRLayer);
begin
  if Layer.Printing then
    with Layer.Canvas.Font do
      Height := Round(  Height * MinPtCoordF(Layer.Sheet.PrintData.FontScale)  );
end;

procedure TRAxes._AccomodateSize(Layer: TRLayer; var ASize: Integer);
begin
  if Layer.Printing then
  begin
    ASize := Round(  ASize * MinPtCoordF(Layer.Sheet.PrintData.RectScale)  );
  end;
end;

end.
