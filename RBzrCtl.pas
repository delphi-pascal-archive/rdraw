{*******************************************************************************
*                                                                              *
*                       Author: Reonid                                         *
*                       Categoty: vector graphic                               *
*                       mailto: reonid@yahoo.com                               *
*                                                                              *
*******************************************************************************}

unit RBzrCtl;

interface

uses
  {$IFDEF UNIX} {Unix,} {$ELSE} Windows, {$ENDIF}

  Classes, Graphics, Controls, RCore, RTypes, RCurve, RCrvCtl, RBezier;

type

  TRSelBezierPoint = class(TRSelCurvePoint)
  private
    function GetCtrlPt(id: TCtrlPointEx): TPointF;
    procedure SetCtrlPt(id: TCtrlPointEx; Value: TPointF);
    function GetCtrlPtIndex(id: TCtrlPointEx): Integer;
    function GetSegmentIndex(id: TCtrlPointEx): Integer;
    function GetPointIndex(id: TCtrlPointEx): Integer;
    function GetNodeType: TNodeType;
    function GetSegmentType: TSegmentType;
    procedure SetNodeType(Value: TNodeType);
    procedure SetSegmentType(Value: TSegmentType);
  protected
    procedure Draw(Layer: TRLayer); override;
  public
    property AbsCtrlPt[id: TCtrlPointEx]: TPointF read GetCtrlPt write SetCtrlPt;
    property NodeType: TNodeType read GetNodeType write SetNodeType;
    property SegmentType: TSegmentType read GetSegmentType write SetSegmentType;

    function Curve: TRBezier;
    procedure DeletePoint(Layer: TRLayer); override;

    function CtrlPtRect(Layer: TRLayer; id: TCtrlPointEx): TRect;
  end;

  TRSelBezierPointController = class(TRSelCurvePointController)
  private
    FHitCtrlPointID: TCtrlPointEx;
  protected
    procedure Transmute(Layer: TRLayer); override;
    function SelPoint: TRSelBezierPoint;
  public
    procedure MouseMove(Layer: TRLayer; var Cursor: TCursor); override;
    function Hit(Layer: TRLayer; Pt: TPointF): Boolean; override;
  end;

  TRBezierController = class(TRCurveController)
  protected
    function CreateSelPoint: TRSelCurvePoint; override;
    function CreateSelection: TRCurveSelection; override;
  end;

  TRBezierSelection = class(TRCurveSelection)
  protected
    function SourceCurve: TRBezier;
    function GetNodeType: TNodeType;
    function GetSegmentType: TSegmentType;
    procedure SetNodeType(Value: TNodeType);
    procedure SetSegmentType(Value: TSegmentType);
  public
    property NodeType: TNodeType read GetNodeType write SetNodeType;
    property SegmentType: TSegmentType read GetSegmentType write SetSegmentType;

    procedure Scale(XC, YC, KX, KY: TFloat); override;
    procedure Rotate(XC, YC, Angle: TFloat); override;
  end;

implementation

uses
  Math, RGeom;

const
  ControlPointRadius = 3;

{-------------------------- TRSelBezierPoint ----------------------------------}

function TRSelBezierPoint.Curve: TRBezier;
begin
  Result := inherited Curve as TRBezier;
end;

function TRSelBezierPoint.CtrlPtRect(Layer: TRLayer; id: TCtrlPointEx): TRect;
var ctrlPt: TPointF;
    scrCPt: TPoint;
begin
  ctrlPt := AbsCtrlPt[id];
  Layer.Converter.LogicToScreen(ctrlPt.X, ctrlPt.Y, scrCPt.X, scrCPt.Y);
  Result := PointRect(scrCPt, ControlPointRadius, ControlPointRadius);
end;

procedure TRSelBezierPoint.Draw(Layer: TRLayer);
var ip1, im1: Integer;

    procedure DrawCtrlPt(MainPoint, CtrlPoint: TPointF);
    var mpt, cpt: TPoint;
    begin
      Layer.Converter.LogicToScreen(MainPoint.X, MainPoint.Y, mpt.X, mpt.Y);
      Layer.Converter.LogicToScreen(CtrlPoint.X, CtrlPoint.Y, cpt.X, cpt.Y);

      Layer.Canvas.Pen.Mode := pmNotXor;
      Layer.Canvas.Pen.Style := psDot;
      Layer.Canvas.Pen.Color := clBlue;
      Layer.Canvas.Brush.Style := bsClear;
      Layer.Canvas.MoveTo(mpt.X, mpt.Y);
      Layer.Canvas.LineTo(cpt.X, cpt.Y);

      Layer.Canvas.Pen.Mode := pmCopy;
      Layer.Canvas.Pen.Style := psSolid;
      Layer.Canvas.Pen.Color := clBlack;
      Layer.Canvas.Brush.Color := clBlack;

      Layer.Canvas.Rectangle(PointRect(cpt, ControlPointRadius, ControlPointRadius));
    end;

begin
  inherited;
  if Empty then Exit;
  if Imaginary then Exit;

  ip1 := (Index + 1) mod Curve.Length;
  im1 := (Index - 1 + Curve.Length) mod Curve.Length;

  if (  (Index > Curve.Low )or(Curve.Closed)  )and
     (Curve.SegmentType[im1] = stBezier) then
  begin
    DrawCtrlPt(CurvePoint, AbsCtrlPt[cpLeft]);
    DrawCtrlPt(PointF(Curve.X[im1], Curve.Y[im1]), AbsCtrlPt[cpPrevRight]);
  end;
  if (  (Index < Curve.High)or(Curve.Closed)  )and
     (Curve.SegmentType[Index] = stBezier) then
  begin
    DrawCtrlPt(CurvePoint, AbsCtrlPt[cpRight]);
    DrawCtrlPt(PointF(Curve.X[ip1], Curve.Y[ip1]), AbsCtrlPt[cpNextLeft]);
  end;
end;

procedure TRSelBezierPoint.DeletePoint(Layer: TRLayer);
const DelFactor = 1;
var i, ip1, im1: Integer;
    LL, RR, LL_ip1, RR_im1, alfa_ip1, alfa_im1: Double;
begin
  i := Index;
  with Curve do
    if Length > 1 then
    begin
      ip1 := NextIndex(i, Length, True);
      im1 := PrevIndex(i, Length, True);

      LL := ScalarF(LCtrlPt[i]);
      RR := ScalarF(RCtrlPt[i]);

      LL_ip1 := ScalarF(LCtrlPt[ip1]);
      RR_im1 := ScalarF(RCtrlPt[ip1]);

      alfa_ip1 := ArcTan2(LCtrlPt[ip1].Y, LCtrlPt[ip1].X);
      alfa_im1 := ArcTan2(RCtrlPt[im1].Y, RCtrlPt[im1].X);

      LCtrlPt[ip1] := PointF(DelFactor*(LL_ip1 + LL)*cos(alfa_ip1),
                             DelFactor*(LL_ip1 + LL)*sin(alfa_ip1) );

      RCtrlPt[im1] := PointF(DelFactor*(RR_im1 + RR)*cos(alfa_im1),
                             DelFactor*(RR_im1 + RR)*sin(alfa_im1) );

      if NodeType[im1] = ntSymmet then NodeType[im1] := ntSmooth;
      if NodeType[ip1] = ntSymmet then NodeType[ip1] := ntSmooth;
    end;

  inherited;
end;

function TRSelBezierPoint.GetCtrlPtIndex(id: TCtrlPointEx): Integer;
begin
  Result := -1;
  case id of
    cpNone:           Result := -1;
    cpLeft, cpRight:  Result := Index;
    cpPrevRight:      Result := PrevIndex(Index, Curve.Length, {Curve.Closed} True);
    cpNextLeft:       Result := NextIndex(Index, Curve.Length, {Curve.Closed} True);
  end;
end;

function TRSelBezierPoint.GetSegmentIndex(id: TCtrlPointEx): Integer;
begin
  Result := -1;
  case id of
    cpNone:                Result := -1;
    cpRight, cpNextLeft:   Result := Index;
    cpLeft, cpPrevRight:   Result := PrevIndex(Index, Curve.Length, Curve.Closed);
  end;
end;

function TRSelBezierPoint.GetPointIndex(id: TCtrlPointEx): Integer;
begin
  Result := -1;
  case id of
    cpNone:           Result := -1;
    cpRight, cpLeft:  Result := Index;
    cpPrevRight:      Result := PrevIndex(Index, Curve.Length, Curve.Closed);
    cpNextLeft:       Result := NextIndex(Index, Curve.Length, Curve.Closed);
  end;
end;

function TRSelBezierPoint.GetCtrlPt(id: TCtrlPointEx): TPointF;
var i: Integer;
begin
  i := GetCtrlPtIndex(id);
  case id of
    cpLeft, cpNextLeft:   Result := Curve.LCtrlPt[i];
    cpRight, cpPrevRight: Result := Curve.RCtrlPt[i];
  end;
  OffsetPointF(Result, Curve.X[i], Curve.Y[i]);
end;

procedure TRSelBezierPoint.SetCtrlPt(id: TCtrlPointEx; Value: TPointF);
var i: Integer;
begin
  i := GetCtrlPtIndex(id);
  OffsetPointF(Value, -Curve.X[i], -Curve.Y[i]);
  case id of
    cpLeft, cpNextLeft:   Curve.LCtrlPt[i] := Value;
    cpRight, cpPrevRight: Curve.RCtrlPt[i] := Value;
  end;
end;

function TRSelBezierPoint.GetNodeType: TNodeType;
begin
  if Imaginary
    then Result := ntNone
    else Result := Curve.NodeType[Index];
end;

procedure TRSelBezierPoint.SetNodeType(Value: TNodeType);
begin
  if not Imaginary then Curve.NodeType[Index] := Value;
end;

function TRSelBezierPoint.GetSegmentType: TSegmentType;
begin
  Result := Curve.SegmentType[Index];
end;

procedure TRSelBezierPoint.SetSegmentType(Value: TSegmentType);
begin
  Curve.SegmentType[Index] := Value;
end;

{--------------------- TRSelBezierPointController -----------------------------}

function TRSelBezierPointController.SelPoint: TRSelBezierPoint;
begin
  Result := Controllee as TRSelBezierPoint;
end;

function TRSelBezierPointController.Hit(Layer: TRLayer; Pt: TPointF): Boolean;
var
  cp: TCtrlPointEx;
  scrPt: TPoint;
  ptRect: TRect;

  function HitCtrlPt(CPt: TPointF; Sens: Integer; id: TCtrlPointEx): Boolean;
  var scrCPt: TPoint;
      segIdx, ptIdx: Integer;
  begin
    Result := False;
    segIdx := SelPoint.GetSegmentIndex(id);
    ptIdx  := SelPoint.GetPointIndex(id);

    if (segIdx = -1)or(SelPoint.Curve.SegmentType[segIdx] = stLine)or
       (  (not SelPoint.Curve.Closed) and
          (   (  ptIdx = -1)or
              (  (ptIdx = SelPoint.Curve.High) and (id in [cpRight, cpPrevRight])  )or
              (  (ptIdx = SelPoint.Curve.Low)  and (id in [cpLeft, cpNextLeft])    )

          )
       ) then Exit;

    Layer.Converter.LogicToScreen(CPt.X, CPt.Y, scrCPt.X, scrCPt.Y);
    ptRect := PointRect(scrCPt, Sens, Sens);
    Result := PtInRect(ptRect, scrPt);
  end;

begin
  FHitCtrlPointID := cpNone;
  Result := inherited Hit(Layer, Pt);
  if Result or SelPoint.Imaginary then Exit;

  Layer.Converter.LogicToScreen(Pt.X, Pt.Y, scrPt.X, scrPt.Y);

  for cp := cpLeft to cpNextLeft do
    if HitCtrlPt( SelPoint.AbsCtrlPt[cp], ControlPointRadius + 1, cp) then
      FHitCtrlPointID := cp;

  Result := FHitCtrlPointID <> cpNone;
end;

procedure TRSelBezierPointController.Transmute(Layer: TRLayer);
begin
  case FHitCtrlPointId of
    cpNone: inherited Transmute(Layer);
    cpLeft..cpNextLeft:
    begin
      SelPoint.AbsCtrlPt[FHitCtrlPointId] := Layer.CurrPt;
      Layer.Sheet.Redraw := True;
    end;
  end;
end;

procedure TRSelBezierPointController.MouseMove(Layer: TRLayer; var Cursor: TCursor);
var cp: TCtrlPointEx;
    pt: TPoint;
    r: TRect;
begin
  inherited;
  if SelPoint.Empty then Exit;

  pt := Layer.Sheet.CurrPt;
  for cp := cpLeft to cpNextLeft do
  begin
    r := SelPoint.CtrlPtRect(Layer, cp);
    if PtInRect(r, pt) then
      Cursor := crMovePoint; 
  end;
end;

{---------------------------- TRBezierController ------------------------------}

function TRBezierController.CreateSelPoint: TRSelCurvePoint;
begin
  Result := TRSelBezierPoint.Create;
  Result.Controller := TRSelBezierPointController.Create(Self);
end;

function TRBezierController.CreateSelection: TRCurveSelection;
begin
  Result := TRBezierSelection.Create;
end;

{----------------------- TRBezierSelMultiPoint --------------------------------}

function TRBezierSelection.GetNodeType: TNodeType;
var i: Integer;
    allEqual: Boolean;
begin
  allEqual := True;

  Result := SourceCurve.NodeType[GetIndex(Low)];
  for i := Low+1 to High do
    if Result <> SourceCurve.NodeType[GetIndex(i)] then
    begin
      allEqual := False;
      Break;
    end;
  if not allEqual then Result := ntNone;
end;

function TRBezierSelection.GetSegmentType: TSegmentType;
var i: Integer;
    allEqual: Boolean;
begin
  allEqual := True;
  Result := SourceCurve.SegmentType[GetIndex(Low)];
  for i := Low+1 to High do
    if Result <> SourceCurve.SegmentType[GetIndex(i)] then
    begin
      allEqual := False;
      Break;
    end;
  if not allEqual then Result := stNone;
end;

procedure TRBezierSelection.SetNodeType(Value: TNodeType);
var i: Integer;
begin
  for i := Low to High do
    SourceCurve.NodeType[GetIndex(i)] := Value;
end;

procedure TRBezierSelection.SetSegmentType(Value: TSegmentType);
var i: Integer;
begin
  for i := Low to High do
    SourceCurve.SegmentType[GetIndex(i)] := Value;
end;

function TRBezierSelection.SourceCurve: TRBezier;
begin
  Result := inherited SourceCurve as TRBezier;
end;

type
  THackBezier = class(TRBezier);

procedure TRBezierSelection.Scale(XC, YC, KX, KY: TFloat);
var k, i: Integer;
    pt: TPointF;
    bzr: THackBezier; 
begin
  {before inherited}

  bzr := THackBezier(SourceCurve);
  for k := Low to High do
  begin
    i := GetIndex(k);

    pt := bzr.LCtrlPt[i];
    pt.X := pt.X*KX;
    pt.Y := pt.Y*KY;
    bzr.SetCtrlPoint(cpLeft, i, pt);

    pt := bzr.RCtrlPt[i];
    pt.X := pt.X*KX;
    pt.Y := pt.Y*KY;
    bzr.SetCtrlPoint(cpRight, i, pt);
  end;

  inherited; // => UpdateNode
end;

procedure TRBezierSelection.Rotate(XC, YC, Angle: TFloat);
var k, i: Integer;
    pt, pt2: TPointF;
    bzr: THackBezier;
begin
  {before inherited}

  bzr := THackBezier(SourceCurve);
  for k := Low to High do
  begin
    i := Self.GetIndex(k);

    pt := bzr.LCtrlPt[i];
    pt2.X := pt.X*Cos(Angle) - pt.Y*Sin(Angle);
    pt2.Y := pt.Y*Cos(Angle) + pt.X*Sin(Angle);
    bzr.SetCtrlPoint(cpLeft, i, pt2);

    pt := bzr.RCtrlPt[i];
    pt2.X := pt.X*Cos(Angle) - pt.Y*Sin(Angle);
    pt2.Y := pt.Y*Cos(Angle) + pt.X*Sin(Angle);
    bzr.SetCtrlPoint(cpRight, i, pt2);
  end;

  inherited; // => UpdateNode
end;

end.
