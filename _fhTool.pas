unit _fhTool;

interface

uses
  Controls, Classes,

  RCore, RTypes, RGeom,  RIntf, RCurve, RBezier, RUndo,
  RCrvUtils,

  DouglasPeuckers;

type

  TRFreeHandNewPointEvent = procedure(Layer: TRLayer; Curve: TRCurve; I: Integer) of object;
  TRFreeHandCreateEvent = procedure(Layer: TRLayer; var Curve: TRCurve) of object;

  TRFreeHandMode = (fhmPoint, fhmContinuous);

  TRFreeHandTool = class(TRTool)
  private
    FCurve: TRCurve;
    FOnInitNewPoint: TRFreeHandNewPointEvent;
    FOnCreate: TRFreeHandCreateEvent;
    FMode: TRFreeHandMode;
    FFirstPt: TPointF;

    procedure InternalAddPoint(Sheet: TRSheet; const Pt: TPointF);
  protected
    function GetPrevPoint: TPointF;
    function GetPrevScreenPoint(Layer: TRLayer): TPoint;
    procedure DrawLine(Sheet: TRSheet; const Rect: TRect;
      const FirstPt, SecondPt: TPoint);
    procedure _DrawLine(Sheet: TRSheet; const Pt0, Pt1: TPoint);

    procedure BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean); override;
    procedure EndHandleMouse(Sheet: TRSheet); override;

    function CreateCurve(Sheet: TRSheet): TRCurve;
    procedure AddPointEx(Sheet: TRSheet; const Pt: TPointF);
    procedure Clear(Sheet: TRSheet);
    procedure ReduceCurve(Sheet: TRSheet); virtual;

    procedure Activate(Value: Boolean); override;

    function KeepActiveFigure(Sheet: TRSheet): Boolean; override; 
  public
    property OnInitNewPoint: TRFreeHandNewPointEvent read FOnInitNewPoint write FOnInitNewPoint;
    property OnCreate: TRFreeHandCreateEvent read FOnCreate write FOnCreate;
    property Mode: TRFreeHandMode read FMode write FMode;
  end;

function FreeHandTool: TRFreeHandTool;

implementation

uses
  Math, SysUtils,
  RFigHlp, RCrvHlp, RTool;

var
  theFreeHandTool: TRFreeHandTool;

function FreeHandTool: TRFreeHandTool;
begin
  if theFreeHandTool = nil then
    theFreeHandTool := TRFreeHandTool.Create('FreeHand');
  Result := theFreeHandTool;
end;

{---------------------------- TRFreeHandTool ----------------------------------}

procedure TRFreeHandTool.InternalAddPoint(Sheet: TRSheet; const Pt: TPointF);
var i: Integer;
begin
  i := TRCurveHelper(FCurve).AddBlock(1);
  FCurve.Points[i] := Pt;
  if Assigned(FOnInitNewPoint) then
    FOnInitNewPoint(Sheet.WorkingLayer, FCurve, i);
end;

procedure TRFreeHandTool.AddPointEx(Sheet: TRSheet; const Pt: TPointF);
begin
  if IsEmptyF(FFirstPt) then
  begin
    Assert(FCurve = nil);
    FFirstPt := Pt;
  end
  else
  if not Assigned(FCurve) then
  begin
    if (FFirstPt.X <> Pt.X)and(FFirstPt.Y <> Pt.Y) then
    begin
      FCurve := CreateCurve(Sheet);
      InternalAddPoint(Sheet, FFirstPt);
      InternalAddPoint(Sheet, Pt);
    end;
  end
  else
  begin
    InternalAddPoint(Sheet, Pt);
  end;
end;

function TRFreeHandTool.CreateCurve(Sheet: TRSheet): TRCurve;
begin
  Result := nil;

  if Assigned(FOnCreate) then
    FOnCreate(Sheet.WorkingLayer, Result);

  if Assigned(Result) then
    UndoStack(Sheet).Push( TRCreationUndoPoint.Create(Result, Sheet, Sheet.WorkingLayer) );
end;

procedure TRFreeHandTool.BeginHandleMouse(Sheet: TRSheet; var Handled: Boolean);
begin
  Handled := True;
  if not Assigned(Sheet.WorkingLayer) then Exit;

  Sheet.WorkingLayer.Prepare(prHandleMouse);

  case Sheet.Event of
    {...............................}
    evMouseDown:
    begin
      if Sheet.DblClick then
      begin
        Clear(Sheet);
        Exit;
      end;
      if FMode = fhmPoint then
        AddPointEx(Sheet, Sheet.WorkingLayer.DownPt);
    end;
    {...............................}
    evMouseMove:
    begin
      if Sheet.LBtnDown and (FMode = fhmContinuous) then
      begin
        AddPointEx(Sheet, Sheet.WorkingLayer.CurrPt);
        Sheet.Redraw := True;
      end;

      if (FMode = fhmPoint) then
      begin
        XORDraw(Sheet, DrawLine);
      end;
    end;
    {...............................}
    evMouseUp:
      if (FMode = fhmContinuous) then
      begin
        Clear(Sheet);
        Sheet.WorkingLayer.Deselect;
      end;
  end;
end;

procedure TRFreeHandTool.EndHandleMouse(Sheet: TRSheet);
begin

end;

procedure TRFreeHandTool.DrawLine(Sheet: TRSheet; const Rect: TRect;
  const FirstPt, SecondPt: TPoint);
var prevPt: TPoint;
begin
  if IsEmptyF(FFirstPt) then Exit;
  prevPt := GetPrevScreenPoint(Sheet.WorkingLayer);
  _DrawLine(Sheet, prevPt, SecondPt);
end;

procedure TRFreeHandTool._DrawLine(Sheet: TRSheet; const Pt0, Pt1: TPoint);
begin
  Sheet.Canvas.MoveTo(Pt0.X, Pt0.Y);
  Sheet.Canvas.LineTo(Pt1.X, Pt1.Y);
end;

procedure TRFreeHandTool.Activate(Value: Boolean);
begin
  //if Value then
  Clear(nil);
end;

function TRFreeHandTool.GetPrevPoint: TPointF;
begin
  if Assigned(FCurve)
    then Result := FCurve.Points[FCurve.Length-1]
    else Result := FFirstPt;
end;

function TRFreeHandTool.GetPrevScreenPoint(Layer: TRLayer): TPoint;
var pt: TPointF;
begin
  pt := GetPrevPoint;
  Layer.Converter.LogicToScreen(pt, Result);
end;

procedure TRFreeHandTool.Clear(Sheet: TRSheet);
begin
  if Assigned(Sheet) and
     Assigned(FCurve) and
     (FMode = fhmContinuous) then
    ReduceCurve(Sheet);

  FCurve := nil;
  FFirstPt := EmptyPointF;
end;

procedure TRFreeHandTool.ReduceCurve(Sheet: TRSheet);
var L: Integer;
    org, res: TDynArrayOfTPoint;
begin
  org := GetCurveArrayScr(FCurve, Sheet.WorkingLayer);
  SetLength(res, Length(org));
  L := PolySimplifyInt2D(1.5, org, res);
  SetLength(res, L);
  SetCurveArrayScr(FCurve, Sheet.WorkingLayer, res);
end;

function TRFreeHandTool.KeepActiveFigure(Sheet: TRSheet): Boolean;
begin
  Result := False; 
end;

initialization
finalization
  theFreeHandTool.Free;
end.
