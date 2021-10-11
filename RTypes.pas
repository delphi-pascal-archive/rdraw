{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RTypes;

interface

uses
  RSysDep,

  Classes, Math;

const
  MinScaleCoef = 0.001;

type
  TEventID = (evNone, evDraw, evMouseDown, evMouseMove, evMouseUp, evKeyDown, evKeyUp);
  TMouseEventID = evMouseDown..evMouseUp;
  TKbdEventID   = evKeyDown..evKeyUp;

  PFloat = ^TFloat;
  TFloat = Single;

  TPoint = RSysDep.TPoint;
  TRect = RSysDep.TRect;

  PPoint = ^TPoint;
  PRect = ^TRect;

  PPointF = ^TPointF;
  TPointF = packed record
    X, Y: TFloat;
  end;

  TDynArrayOfTPointF = array of TPointF;
  TDynArrayOfTPoint = array of TPoint;

  TArrayOfTPointF = array[0..$FFFFFF] of TPointF;
  PArrayOfTPointF = ^TArrayOfTPointF;

  TArrayOfTPoint = array[0..$FFFFFF] of TPoint;
  PArrayOfTPoint = ^TArrayOfTPoint;

  PRectF = ^TRectF;
  TRectF = packed record
    XMin, XMax, YMin, YMax: TFloat;
  end;

  TDelta1 = -1..1;

  TCKCoeffs = packed record
    C, K: TFloat;
  end;

  {
  TRCoordConverter2D = class
  public
    procedure Prepare; virtual; abstract;

    procedure ScreenToLogic(SX, SY: TFloat; var LX, LY: TFloat); overload; virtual; abstract;
    procedure LogicToScreen(LX, LY: TFloat; var SX, SY: TFloat); overload; virtual; abstract;

    procedure ScreenToLogic(const SPt: TPoint; var LPt: TPointF); overload;
    procedure LogicToScreen(const LPt: TPointF; var SPt: TPoint); overload;
  end;
  }

  TRCoordConverter = class
  public
    procedure Prepare; virtual; abstract;

    procedure ScreenToLogic(SX, SY: Integer; var LX, LY: TFloat); overload; virtual; abstract;
    procedure LogicToScreen(LX, LY: TFloat; var SX, SY: Integer); overload; virtual; abstract;

    procedure ScreenToLogic(const SPt: TPoint; var LPt: TPointF); overload;
    procedure LogicToScreen(const LPt: TPointF; var SPt: TPoint); overload;
    procedure ScreenToLogic(const SR: TRect; var LR: TRectF); overload;
    procedure LogicToScreen(const LR: TRectF; var SR: TRect); overload;
  end;

  TTransformOp = (opTranslate, opScale, opRotate, opSkew);
  TTransformMode = (tmApply, tmTest, tmAdjust);
                                                                 {$WARNINGS OFF}
  TTransformData = packed record
    Mode: TTransformMode;
    Operation: TTransformOp;
    Center: TPointF;
    case TTransformOp of
      opTranslate: (DX, DY: TFloat);
      opScale:     (KX, KY: TFloat);
      opRotate:    (Angle: TFloat);
      opSkew:      (XAngle, YAngle: TFloat);
  end;

  TRInterfacedObject = class({TObject}TPersistent, IUnknown)
  public
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

const
  NaN = 0/0; {For D5}
  Infinity = 1.0/0.0;
  EmptyRectF: TRectF = (XMin : NaN; XMax : NaN; YMin : NaN; YMax : NaN);
  EmptyPointF: TPointF = (X : NaN; Y : 0);

function RectF(XMin, YMin, XMax, YMax: TFloat): TRectF; overload;
function RectF(const XYMin, XYMax: TPointF): TRectF; overload;
function PointF(X, Y: TFloat): TPointF;
function IsEmptyF(const R: TRectF): Boolean; overload;
function IsEmptyF(const Pt: TPointF): Boolean; overload;

{$IFDEF NO_NAN}
function IsNan(const AValue: Single): Boolean; overload;
function IsNan(const AValue: Double): Boolean; overload;
{$ENDIF}

procedure InitTranslateData(var Data: TTransformData; DX, DY: TFloat);
procedure InitScaleData(var Data: TTransformData; XC, YC, KX, KY: TFloat);
procedure InitRotateData(var Data: TTransformData; XC, YC, Angle: TFloat);

function NextIndex(I: Integer; Length: Integer; Cyclic: Boolean): Integer;
function PrevIndex(I: Integer; Length: Integer; Cyclic: Boolean): Integer;

function MaxValueF(ValueI, ValueJ: TFloat; i, j: Integer; var Index: Integer): TFloat;
function MinValueF(ValueI, ValueJ: TFloat; i, j: Integer; var Index: Integer): TFloat;

procedure CalcAspect(Converter: TRCoordConverter; scrSens: Integer; pt: TPoint;
  var logSensY, Aspect: TFloat);

function MinPtCoordF(const Pt: TPointF): TFloat;

{------------ for debug -------------}
var _RDebugProc: procedure(const Msg: string) of object;
procedure RDebugMsg(const Msg: string);

implementation

uses
  SysUtils;

procedure RDebugMsg(const Msg: string);
begin
  if Assigned(_RDebugProc) then
    _RDebugProc(Msg);
end;

{----------------------------- TRInterfaced -----------------------------------}

function TRInterfacedObject._AddRef: Integer; stdcall;
begin
  Result := -1;
end;

function TRInterfacedObject._Release: Integer; stdcall;
begin
  Result := -1;
end;

function TRInterfacedObject.QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
const E_NOINTERFACE = HResult($80004002);
begin
  if GetInterface(IID, Obj) then Result := 0 else Result := E_NOINTERFACE;
end;

{----------------------------- TRConverter ------------------------------------}

procedure TRCoordConverter.LogicToScreen(const LPt: TPointF; var SPt: TPoint);
begin
  LogicToScreen(LPt.X, LPt.Y, SPt.X, SPt.Y);
end;

procedure TRCoordConverter.ScreenToLogic(const SPt: TPoint; var LPt: TPointF);
begin
  ScreenToLogic(SPt.X, SPt.Y, LPt.X, LPt.Y);
end;

procedure TRCoordConverter.LogicToScreen(const LR: TRectF; var SR: TRect);
begin
  LogicToScreen(LR.XMin, LR.YMax, SR.Left, SR.Top);
  LogicToScreen(LR.XMax, LR.YMin, SR.Right, SR.Bottom);
end;

procedure TRCoordConverter.ScreenToLogic(const SR: TRect; var LR: TRectF);
begin
  ScreenToLogic(SR.Left, SR.Top, LR.XMin, LR.YMax);
  ScreenToLogic(SR.Right, SR.Bottom, LR.XMax, LR.YMin);
end;

procedure CalcAspect(Converter: TRCoordConverter; scrSens: Integer; pt: TPoint; 
  var logSensY, Aspect: TFloat);
var x0, y0, x1, y1: TFloat;
begin
  Converter.ScreenToLogic(pt.X, pt.Y, x0, y0);
  Converter.ScreenToLogic(pt.X + scrSens, pt.Y + scrSens, x1, y1);
  Aspect := Abs( (y1-y0)/(x1-x0) );
  logSensY := Abs(y1-y0);
end;

{------------------------------------------------------------------------------}

procedure InitTranslateData(var Data: TTransformData; DX, DY: TFloat);
begin
  Data.Operation := opTranslate;
  Data.DX := DX;
  Data.DY := DY;
end;

procedure InitScaleData(var Data: TTransformData; XC, YC, KX, KY: TFloat);
begin
  Data.Operation := opScale;
  Data.Center := PointF(XC, YC);
  Data.KX := KX;
  Data.KY := KY;
end;

procedure InitRotateData(var Data: TTransformData; XC, YC, Angle: TFloat);
begin
  Data.Operation := opRotate;
  Data.Center := PointF(XC, YC);
  Data.Angle := Angle;
end;

{------------------------------------------------------------------------------}

function MaxValueF(ValueI, ValueJ: TFloat; i, j: Integer; var Index: Integer): TFloat;
begin
  if ValueI > ValueJ
    then begin Result := ValueI; Index := i; end
    else begin Result := ValueJ; Index := j; end;
end;

function MinValueF(ValueI, ValueJ: TFloat; i, j: Integer; var Index: Integer): TFloat;
begin
  if ValueI < ValueJ
    then begin Result := ValueI; Index := i; end
    else begin Result := ValueJ; Index := j; end;
end;

function NextIndex(I: Integer; Length: Integer; Cyclic: Boolean): Integer;
begin
  Result := (I + 1) mod Length;
  if (not Cyclic)and(Result = 0)then Result := -1;
end;

function PrevIndex(I: Integer; Length: Integer; Cyclic: Boolean): Integer;
begin
  Result := (I - 1);
  if (Cyclic)and(Result = -1)then Result := Length-1;
end;

function RectF(XMin, YMin, XMax, YMax: TFloat): TRectF;
begin
  Result.XMin := XMin;
  Result.XMax := XMax;
  Result.YMin := YMin;
  Result.YMax := YMax;
end;

function RectF(const XYMin, XYMax: TPointF): TRectF;
begin
  Result.XMin := XYMin.X;
  Result.XMax := XYMax.X;
  Result.YMin := XYMin.Y;
  Result.YMax := XYMax.Y;
end;

function PointF(X, Y: TFloat): TPointF;
begin
  Result.X := X;
  Result.Y := Y;
end;
                                                                 {$WARNINGS OFF} // Unsafe operator @
{$IFDEF NO_NAN}
function IsNan(const AValue: Single): Boolean;
begin
  Result := ((PLongWord(@AValue)^ and $7F800000)  = $7F800000) and
            ((PLongWord(@AValue)^ and $007FFFFF) <> $00000000);
end;

function IsNan(const AValue: Double): Boolean;
begin
  Result := ((PInt64(@AValue)^ and $7FF0000000000000)  = $7FF0000000000000) and
            ((PInt64(@AValue)^ and $000FFFFFFFFFFFFF) <> $0000000000000000);
end;
{$ENDIF}
                                                                  {$WARNINGS ON}
function IsEmptyF(const R: TRectF): Boolean;
begin
  Result := IsNaN(R.XMin);
end;

function IsEmptyF(const Pt: TPointF): Boolean;
begin
  Result := IsNaN(Pt.X);
end;

function MinPtCoordF(const Pt: TPointF): TFloat;
begin
  Result := Min(Pt.X, Pt.Y);
end;

end.

